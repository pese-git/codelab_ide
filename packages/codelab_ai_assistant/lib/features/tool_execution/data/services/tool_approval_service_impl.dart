// Реализация сервиса подтверждения tool операций
import 'dart:async';
import 'package:logger/logger.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_approval.dart';
import '../repositories/tool_repository_impl.dart';
import 'approval_sync_service.dart';

/// Обертка запроса на подтверждение с completer для UI
class ApprovalRequestWithCompleter {
  /// Domain entity запроса
  final ToolApprovalRequest request;
  
  /// Completer для возврата результата
  final Completer<ApprovalDecision> completer;

  ApprovalRequestWithCompleter(this.request, this.completer);
  
  /// Удобный доступ к toolCall
  ToolCall get toolCall => request.toolCall;
}

/// Реализация ToolApprovalService через event-based механизм
///
/// Использует domain entities напрямую без адаптеров.
/// Поддерживает восстановление ожидающих подтверждений с сервера.
class ToolApprovalServiceImpl implements ToolApprovalService {
  final StreamController<ApprovalRequestWithCompleter> _approvalController =
      StreamController<ApprovalRequestWithCompleter>.broadcast();
  final ApprovalSyncService _syncService;
  final Logger _logger;

  /// Храним активные completers для восстановления
  final Map<String, Completer<ApprovalDecision>> _activeCompleters = {};

  ToolApprovalServiceImpl({
    required ApprovalSyncService syncService,
    required Logger logger,
  })  : _syncService = syncService,
        _logger = logger;

  /// Stream запросов на подтверждение с completer
  Stream<ApprovalRequestWithCompleter> get approvalRequests =>
      _approvalController.stream;

  @override
  Future<ApprovalDecision> requestApproval(ToolCall toolCall) async {
    final completer = Completer<ApprovalDecision>();

    // Сохраняем completer для возможного восстановления
    _activeCompleters[toolCall.id] = completer;

    // Создаем domain entity запроса
    final domainRequest = ToolApprovalRequest(
      requestId: toolCall.id,
      toolCall: toolCall,
      requestedAt: DateTime.now(),
    );

    final requestWithCompleter =
        ApprovalRequestWithCompleter(domainRequest, completer);

    // Эмитируем запрос в stream
    _approvalController.add(requestWithCompleter);

    // Ожидаем результата от UI слоя (БЕЗ ТАЙМАУТА - это правильно!)
    final decision = await completer.future;

    // Удаляем completer после получения решения
    _activeCompleters.remove(toolCall.id);

    return decision;
  }

  /// Восстановить ожидающие подтверждения с сервера
  ///
  /// Вызывается при подключении к сессии для восстановления
  /// запросов на подтверждение после перезапуска/переустановки IDE.
  Future<void> restorePendingApprovals(String sessionId) async {
    _logger.i('Restoring pending approvals for session: $sessionId');

    try {
      // Получаем все ожидающие подтверждения с сервера
      final pending = await _syncService.fetchPendingApprovals(sessionId);

      _logger.i('Found ${pending.length} pending approvals to restore');

      for (final request in pending) {
        // Проверяем, нет ли уже активного completer
        if (_activeCompleters.containsKey(request.toolCall.id)) {
          _logger.d(
              'Completer already exists for ${request.toolCall.id}, skipping');
          continue;
        }

        // Создаем новый completer
        final completer = Completer<ApprovalDecision>();
        _activeCompleters[request.toolCall.id] = completer;

        final requestWithCompleter =
            ApprovalRequestWithCompleter(request, completer);

        // Эмитируем в stream для отображения в UI
        _approvalController.add(requestWithCompleter);

        // Запускаем асинхронное ожидание решения
        _waitForDecision(request.toolCall.id, completer);
      }

      _logger.i('Successfully restored ${pending.length} pending approvals');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to restore pending approvals: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Не выбрасываем исключение, чтобы не блокировать подключение
    }
  }

  /// Ожидание решения для восстановленного запроса
  Future<void> _waitForDecision(
      String callId, Completer<ApprovalDecision> completer) async {
    try {
      // Ждем решения (без таймаута)
      await completer.future;
      _activeCompleters.remove(callId);
      _logger.d('Decision received for restored approval: $callId');
    } catch (e) {
      _logger.e('Error waiting for decision: $e');
      _activeCompleters.remove(callId);
    }
  }

  /// Закрывает сервис и освобождает ресурсы
  void dispose() {
    _approvalController.close();
  }
}
