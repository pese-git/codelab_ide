import 'dart:async';
import 'package:logger/logger.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_response.dart';
import '../../domain/entities/approval_decision.dart';
import '../../domain/services/approval_service.dart';
import '../datasources/approval_api_datasource.dart';

/// Реализация унифицированного сервиса подтверждений
///
/// Предоставляет единый механизм для всех типов подтверждений:
/// - Tool approval
/// - Plan approval
/// - Будущие типы
///
/// Основные возможности:
/// - Generic запрос подтверждения с completer-based архитектурой
/// - Восстановление pending approvals после переподключения
/// - Единый stream для всех типов подтверждений
class UnifiedApprovalServiceImpl implements ApprovalService {
  final ApprovalApiDataSource _apiDataSource;
  final Logger _logger;

  /// Completers для ожидания решений пользователя
  final Map<String, Completer<ApprovalDecision>> _activeCompleters = {};

  /// Stream controller для запросов на подтверждение
  final _requestsController = StreamController<ApprovalRequest>.broadcast();

  UnifiedApprovalServiceImpl({
    required ApprovalApiDataSource apiDataSource,
    required Logger logger,
  })  : _apiDataSource = apiDataSource,
        _logger = logger;

  @override
  Future<ApprovalDecision> requestApproval(ApprovalRequest request) async {
    _logger.i(
      'Requesting approval: type=${request.type.name}, id=${request.approvalRequestId}',
    );

    // Создаем completer для ожидания решения
    final completer = Completer<ApprovalDecision>();
    _activeCompleters[request.approvalRequestId] = completer;

    // Эмитируем запрос в stream для UI
    _requestsController.add(request);

    // Ожидаем решения с таймаутом
    try {
      final decision = await completer.future.timeout(
        Duration(seconds: request.timeoutSeconds),
        onTimeout: () {
          _logger.w(
            'Approval request timed out: ${request.approvalRequestId}',
          );
          return const ApprovalDecision.cancelled();
        },
      );

      _logger.i(
        'Approval decision received: ${request.approvalRequestId} -> ${decision.toDecisionString()}',
      );

      return decision;
    } catch (e) {
      _logger.e('Error waiting for approval decision: $e');
      return const ApprovalDecision.cancelled();
    } finally {
      _activeCompleters.remove(request.approvalRequestId);
    }
  }

  @override
  Future<List<ApprovalRequest>> restorePendingApprovals(
    String sessionId,
  ) async {
    _logger.i('Restoring pending approvals for session: $sessionId');

    try {
      // Получаем pending approvals с сервера
      final pendingApprovals =
          await _apiDataSource.getPendingApprovals(sessionId);

      _logger.i('Found ${pendingApprovals.length} pending approvals to restore');

      // Восстанавливаем completers и эмитируем запросы
      for (final request in pendingApprovals) {
        // Проверяем, нет ли уже активного completer
        if (_activeCompleters.containsKey(request.approvalRequestId)) {
          _logger.d(
            'Completer already exists for ${request.approvalRequestId}, skipping',
          );
          continue;
        }

        // Создаем новый completer
        final completer = Completer<ApprovalDecision>();
        _activeCompleters[request.approvalRequestId] = completer;

        // Эмитируем в stream для отображения в UI
        _requestsController.add(request);

        _logger.d('Restored approval request: ${request.approvalRequestId}');
      }

      _logger.i(
        'Successfully restored ${pendingApprovals.length} pending approvals',
      );

      return pendingApprovals;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to restore pending approvals: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Не выбрасываем исключение, чтобы не блокировать подключение
      return [];
    }
  }

  @override
  Future<void> sendDecision(ApprovalResponse response) async {
    _logger.i(
      'Sending approval decision: ${response.approvalRequestId} -> ${response.decision.toDecisionString()}',
    );

    try {
      // Отправляем решение на сервер
      await _apiDataSource.sendApprovalDecision(response);

      // Завершаем соответствующий completer
      final completer = _activeCompleters.remove(response.approvalRequestId);
      if (completer != null && !completer.isCompleted) {
        completer.complete(response.decision);
        _logger.d('Completed completer for ${response.approvalRequestId}');
      } else {
        _logger.w(
          'No active completer found for ${response.approvalRequestId}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to send approval decision: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Все равно завершаем completer, чтобы не блокировать
      final completer = _activeCompleters.remove(response.approvalRequestId);
      if (completer != null && !completer.isCompleted) {
        completer.complete(response.decision);
      }
      rethrow;
    }
  }

  @override
  Stream<ApprovalRequest> get approvalRequests => _requestsController.stream;

  @override
  void clearActiveCompleters() {
    final count = _activeCompleters.length;
    _logger.i('Clearing $count active completers (without sending cancellation)');

    // Просто очищаем completers БЕЗ завершения
    // Pending approvals должны остаться на сервере для восстановления
    _activeCompleters.clear();
  }

  @override
  void dispose() {
    _logger.i('Disposing UnifiedApprovalService');

    // Завершаем все активные completers с ошибкой
    for (final entry in _activeCompleters.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(
          StateError(
            'UnifiedApprovalService disposed while waiting for decision',
          ),
        );
      }
    }
    _activeCompleters.clear();

    _requestsController.close();
  }
}
