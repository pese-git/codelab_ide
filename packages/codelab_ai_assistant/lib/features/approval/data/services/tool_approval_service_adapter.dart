// Адаптер для миграции ToolApprovalService на UnifiedApprovalService
import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_result.dart';
import '../../../tool_execution/domain/entities/tool_approval.dart'
    as tool_approval;
import '../../../tool_execution/data/services/tool_approval_service_impl.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_response.dart';
import '../../domain/entities/approval_type.dart';
import '../../domain/services/approval_service.dart';
import '../adapters/tool_approval_adapter.dart';

/// Адаптер для постепенной миграции с ToolApprovalServiceImpl на UnifiedApprovalService
///
/// Этот класс реализует интерфейс ToolApprovalService, но внутри использует
/// UnifiedApprovalService через адаптеры. Это позволяет мигрировать код
/// постепенно без breaking changes.
///
/// **Архитектура:**
/// ```
/// ToolApprovalServiceImpl (старый) → ToolApprovalServiceAdapter (новый)
///                                            ↓
///                                   UnifiedApprovalService
///                                            ↓
///                                   ApprovalApiDataSource
/// ```
///
/// **Преимущества:**
/// - Backward compatibility - существующий код продолжает работать
/// - Постепенная миграция - можно мигрировать по одному компоненту
/// - Единая инфраструктура - все approval запросы через один сервис
/// - Clean Architecture - разделение Domain и Data слоев
class ToolApprovalServiceAdapter implements ToolApprovalService {
  final ApprovalService _unifiedService;
  final Logger _logger;

  /// Stream controller для эмуляции старого API
  final StreamController<ApprovalRequestWithCompleter> _approvalController =
      StreamController<ApprovalRequestWithCompleter>.broadcast();

  /// Храним активные completers для восстановления
  final Map<String, Completer<tool_approval.ApprovalDecision>>
  _activeCompleters = {};

  /// Храним отклоненные tool calls чтобы не показывать диалог повторно
  final Set<String> _rejectedToolCalls = {};

  /// Callback для выполнения tool после approve (для восстановленных запросов)
  @override
  Future<ToolResult> Function(ToolCall)? onExecuteRestoredTool;

  /// Callback для отправки rejection на сервер (для восстановленных запросов)
  @override
  Future<void> Function(ToolCall, String reason)? onRejectRestoredTool;

  ToolApprovalServiceAdapter({
    required ApprovalService unifiedService,
    required Logger logger,
  }) : _unifiedService = unifiedService,
       _logger = logger;

  /// Stream запросов на подтверждение с completer (для backward compatibility)
  @override
  Stream<ApprovalRequestWithCompleter> get approvalRequests =>
      _approvalController.stream;

  @override
  Future<tool_approval.ApprovalDecision> requestApproval(
    ToolCall toolCall,
  ) async {
    // Проверяем, не был ли этот tool уже отклонен
    final toolKey = '${toolCall.toolName}_${toolCall.arguments.toString()}';
    if (_rejectedToolCalls.contains(toolKey)) {
      _logger.i(
        'Tool call was previously rejected, auto-rejecting: ${toolCall.toolName}',
      );
      return tool_approval.ApprovalDecision.rejected(
        reason: some('Previously rejected by user'),
      );
    }

    final completer = Completer<tool_approval.ApprovalDecision>();

    // Сохраняем completer для возможного восстановления
    _activeCompleters[toolCall.id] = completer;

    // Конвертируем ToolCall → ApprovalRequest
    final toolApprovalRequest = tool_approval.ToolApprovalRequest(
      requestId: toolCall.id,
      toolCall: toolCall,
      requestedAt: DateTime.now(),
    );

    final approvalRequest = ToolApprovalAdapter.toApprovalRequest(
      toolApprovalRequest,
    );

    // Создаем wrapper для backward compatibility с UI
    final requestWithCompleter = ApprovalRequestWithCompleter(
      toolApprovalRequest,
      completer,
    );

    // Эмитируем запрос в stream для UI
    _approvalController.add(requestWithCompleter);

    // Ожидаем результата от UI слоя (БЕЗ ТАЙМАУТА)
    final decision = await completer.future;

    // Удаляем completer после получения решения
    _activeCompleters.remove(toolCall.id);

    // Если отклонен, запоминаем
    if (decision.isRejected) {
      _rejectedToolCalls.add(toolKey);
      _logger.d('Added to rejected list: $toolKey');
    }

    // Конвертируем tool_approval.ApprovalDecision → ApprovalDecision
    final unifiedDecision = ToolApprovalAdapter.toApprovalDecision(decision);

    // Создаем ApprovalResponse для отправки на сервер
    final approvalResponse = ApprovalResponse(
      approvalRequestId: approvalRequest.approvalRequestId,
      type: ApprovalType.tool,
      decision: unifiedDecision,
      respondedAt: DateTime.now(),
      decisionTimeMs: DateTime.now()
          .difference(approvalRequest.requestedAt)
          .inMilliseconds,
    );

    await _unifiedService.sendDecision(approvalResponse);

    return decision;
  }

  /// Восстановить ожидающие подтверждения с сервера
  ///
  /// Использует UnifiedApprovalService для получения pending approvals
  @override
  Future<void> restorePendingApprovals(String sessionId) async {
    _logger.i('Restoring pending approvals for session: $sessionId');

    try {
      // Получаем все ожидающие подтверждения через UnifiedApprovalService
      final pending = await _unifiedService.restorePendingApprovals(sessionId);

      _logger.i('Found ${pending.length} pending approvals to restore');

      for (final request in pending) {
        // Фильтруем только tool approvals
        if (request.type != ApprovalType.tool) {
          _logger.d('Skipping non-tool approval: ${request.type}');
          continue;
        }

        // Конвертируем ApprovalRequest → ToolApprovalRequest
        final toolApprovalRequest = ToolApprovalAdapter.toToolApprovalRequest(
          request,
        );

        // Проверяем, нет ли уже активного completer
        if (_activeCompleters.containsKey(toolApprovalRequest.toolCall.id)) {
          _logger.d(
            'Completer already exists for ${toolApprovalRequest.toolCall.id}, skipping',
          );
          continue;
        }

        // Создаем новый completer
        final completer = Completer<tool_approval.ApprovalDecision>();
        _activeCompleters[toolApprovalRequest.toolCall.id] = completer;

        // Эмитируем в stream для отображения в UI (с флагом isRestored)
        _approvalController.add(
          ApprovalRequestWithCompleter(
            toolApprovalRequest,
            completer,
            isRestored: true,
          ),
        );

        // Запускаем асинхронное ожидание решения с выполнением tool
        unawaited(
          _waitForRestoredDecision(
            toolApprovalRequest.toolCall,
            completer,
            request,
          ),
        );
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
    ToolCall toolCall,
    Completer<tool_approval.ApprovalDecision> completer,
    ApprovalRequest originalRequest,
  ) async {
    try {
      // Ждем решения (без таймаута)
      final decision = await completer.future;
      _activeCompleters.remove(toolCall.id);
      _logger.d('Decision received for restored approval: ${toolCall.id}');

      // Конвертируем tool_approval.ApprovalDecision → ApprovalDecision
      final unifiedDecision = ToolApprovalAdapter.toApprovalDecision(decision);

      // Создаем ApprovalResponse для отправки на сервер
      final approvalResponse = ApprovalResponse(
        approvalRequestId: originalRequest.approvalRequestId,
        type: ApprovalType.tool,
        decision: unifiedDecision,
        respondedAt: DateTime.now(),
        decisionTimeMs: DateTime.now()
            .difference(originalRequest.requestedAt)
            .inMilliseconds,
      );

      await _unifiedService.sendDecision(approvalResponse);

      // Обрабатываем решение пользователя
      await decision.when(
        approved: () async {
          // Если есть callback для выполнения - вызываем его
          if (onExecuteRestoredTool != null) {
            _logger.i(
              'Executing restored tool after approval: ${toolCall.toolName}',
            );
            await onExecuteRestoredTool!(toolCall);
          }
        },
        rejected: (reason) async {
          // Запоминаем отклоненный tool
          final toolKey =
              '${toolCall.toolName}_${toolCall.arguments.toString()}';
          _rejectedToolCalls.add(toolKey);
          _logger.d('Added to rejected list: $toolKey');

          // Отправляем rejection на сервер
          if (onRejectRestoredTool != null) {
            final rejectReason =
                reason?.fold(() => 'User rejected', (r) => r) ??
                'User rejected';
            _logger.i(
              'Restored tool rejected: ${toolCall.toolName}, reason: $rejectReason',
            );
            await onRejectRestoredTool!(toolCall, rejectReason);
          }
        },
        modified: (modifiedArguments, comment) async {
          // Для modified выполняем tool с измененными аргументами
          if (onExecuteRestoredTool != null) {
            _logger.i(
              'Executing restored tool with modified arguments: ${toolCall.toolName}',
            );
            final modifiedToolCall = toolCall.copyWith(
              arguments: modifiedArguments,
            );
            await onExecuteRestoredTool!(modifiedToolCall);
          }
        },
        cancelled: () async {
          _logger.i('Restored tool cancelled: ${toolCall.toolName}');
          // Для cancelled используем тот же механизм что и для reject
          if (onRejectRestoredTool != null) {
            await onRejectRestoredTool!(toolCall, 'User cancelled');
          }
        },
      );
    } catch (e) {
      _logger.e('Error waiting for decision: $e');
      _activeCompleters.remove(toolCall.id);
    }
  }

  /// Очистить список отклоненных tool calls (например, при новой сессии)
  void clearRejectedTools() {
    _rejectedToolCalls.clear();
    _logger.d('Cleared rejected tools list');
  }

  /// Очистить активные completers при отключении от сессии
  @override
  void clearActiveCompleters() {
    final count = _activeCompleters.length;
    // Просто очищаем completers БЕЗ завершения
    // Pending approvals должны остаться на сервере для восстановления
    _activeCompleters.clear();
    _logger.i(
      'Cleared $count active completers (without sending cancellation)',
    );
  }

  /// Закрывает сервис и освобождает ресурсы
  void dispose() {
    // Очищаем все активные completers для предотвращения memory leak
    for (final completer in _activeCompleters.values) {
      if (!completer.isCompleted) {
        // Завершаем с ошибкой, чтобы не оставлять висящие futures
        completer.completeError(
          StateError(
            'ToolApprovalServiceAdapter disposed while waiting for decision',
          ),
        );
      }
    }
    _activeCompleters.clear();
    _rejectedToolCalls.clear();

    _approvalController.close();
  }
}
