// Реализация сервиса подтверждения tool операций
import 'dart:async';
import 'package:logger/logger.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_approval.dart';
import '../../domain/entities/tool_result.dart';
import '../repositories/tool_repository_impl.dart';
import 'approval_sync_service.dart';

/// Обертка запроса на подтверждение с completer для UI
class ApprovalRequestWithCompleter {
  /// Domain entity запроса
  final ToolApprovalRequest request;
  
  /// Completer для возврата результата
  final Completer<ApprovalDecision> completer;
  
  /// Флаг, указывающий что это восстановленный запрос
  final bool isRestored;

  ApprovalRequestWithCompleter(
    this.request,
    this.completer, {
    this.isRestored = false,
  });
  
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
  
  /// Callback для выполнения tool после approve (для восстановленных запросов)
  Future<ToolResult> Function(ToolCall)? onExecuteRestoredTool;
  
  /// Callback для отправки rejection на сервер (для восстановленных запросов)
  Future<void> Function(ToolCall, String reason)? onRejectRestoredTool;

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

        // Эмитируем в stream для отображения в UI (с флагом isRestored)
        _approvalController.add(
          ApprovalRequestWithCompleter(request, completer, isRestored: true),
        );

        // Запускаем асинхронное ожидание решения с выполнением tool
        // Fire-and-forget паттерн с явной обработкой ошибок внутри метода
        unawaited(_waitForRestoredDecision(request.toolCall, completer));
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

  /// Ожидание решения для восстановленного запроса с выполнением tool
  Future<void> _waitForRestoredDecision(
      ToolCall toolCall, Completer<ApprovalDecision> completer) async {
    try {
      // Ждем решения (без таймаута)
      final decision = await completer.future;
      _activeCompleters.remove(toolCall.id);
      _logger.d('Decision received for restored approval: ${toolCall.id}');
      
      // Обрабатываем решение пользователя
      await decision.when(
        approved: () async {
          // Если есть callback для выполнения - вызываем его
          if (onExecuteRestoredTool != null) {
            _logger.i('Executing restored tool after approval: ${toolCall.toolName}');
            await onExecuteRestoredTool!(toolCall);
          }
        },
        rejected: (reason) async {
          // Отправляем rejection на сервер
          if (onRejectRestoredTool != null) {
            final rejectReason = reason?.fold(() => 'User rejected', (r) => r) ?? 'User rejected';
            _logger.i('Restored tool rejected: ${toolCall.toolName}, reason: $rejectReason');
            await onRejectRestoredTool!(toolCall, rejectReason);
          }
        },
        modified: (modifiedArguments, comment) async {
          // Для modified выполняем tool с измененными аргументами
          if (onExecuteRestoredTool != null) {
            _logger.i('Executing restored tool with modified arguments: ${toolCall.toolName}');
            final modifiedToolCall = toolCall.copyWith(arguments: modifiedArguments);
            await onExecuteRestoredTool!(modifiedToolCall);
          }
        },
        cancelled: () async {
          _logger.i('Restored tool cancelled: ${toolCall.toolName}');
          // Для cancelled просто логируем, не отправляем на сервер
        },
      );
    } catch (e) {
      _logger.e('Error waiting for decision: $e');
      _activeCompleters.remove(toolCall.id);
    }
  }

  /// Закрывает сервис и освобождает ресурсы
  void dispose() {
    // Очищаем все активные completers для предотвращения memory leak
    for (final completer in _activeCompleters.values) {
      if (!completer.isCompleted) {
        // Завершаем с ошибкой, чтобы не оставлять висящие futures
        completer.completeError(
          StateError('ToolApprovalService disposed while waiting for decision'),
        );
      }
    }
    _activeCompleters.clear();
    
    _approvalController.close();
  }
}
