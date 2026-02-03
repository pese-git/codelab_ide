// Middleware для управления подтверждениями (tool и plan approvals)
import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/send_tool_result.dart';
import '../../../tool_execution/domain/usecases/execute_tool.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_result.dart';
import '../../../tool_execution/domain/entities/tool_approval.dart' as tool_approval;
import '../../../tool_execution/domain/entities/approval_request_with_completer.dart';
import '../../../approval/domain/services/approval_service.dart';
import '../../../approval/domain/entities/approval_request.dart';
import '../../../approval/domain/entities/approval_response.dart';
import '../../../approval/domain/entities/approval_decision.dart';
import '../../../approval/domain/entities/approval_type.dart';
import '../../../approval/data/adapters/approval_request_adapter.dart';

/// Middleware для управления подтверждениями
///
/// Ответственности:
/// - Подписка на approval requests из unified service
/// - Конвертация ApprovalRequest в legacy формат для UI
/// - Обработка решений пользователя (approve/reject/modify/cancel)
/// - Выполнение tool после подтверждения
/// - Отправка результатов на сервер
/// - Восстановление pending approvals после переподключения
class ApprovalMiddleware {
  final ApprovalService _approvalService;
  final ExecuteToolUseCase _executeTool;
  final SendToolResultUseCase _sendToolResult;
  final Logger _logger;

  StreamSubscription<ApprovalRequest>? _approvalSubscription;

  ApprovalMiddleware({
    required ApprovalService approvalService,
    required ExecuteToolUseCase executeTool,
    required SendToolResultUseCase sendToolResult,
    required Logger logger,
  })  : _approvalService = approvalService,
        _executeTool = executeTool,
        _sendToolResult = sendToolResult,
        _logger = logger;

  /// Начать прослушивание approval requests
  ///
  /// Callback onToolApproval вызывается для tool approvals (для UI)
  void startListening({
    required void Function(ApprovalRequestWithCompleter request) onToolApproval,
  }) {
    _logger.d('[ApprovalMiddleware] 🎧 Starting to listen for approval requests');

    _approvalSubscription?.cancel();
    _approvalSubscription = _approvalService.approvalRequests.listen((request) {
      _handleApprovalRequest(request, onToolApproval);
    });
  }

  /// Остановить прослушивание approval requests
  Future<void> stopListening() async {
    _logger.d('[ApprovalMiddleware] 🔇 Stopping approval requests listener');
    await _approvalSubscription?.cancel();
    _approvalSubscription = null;
  }

  /// Восстановить pending approvals после переподключения
  ///
  /// Возвращает количество восстановленных approvals
  Future<int> restorePendingApprovals(String sessionId) async {
    _logger.i('[ApprovalMiddleware] 🔄 Restoring pending approvals for session: $sessionId');

    try {
      final restoredApprovals = await _approvalService.restorePendingApprovals(sessionId);
      _logger.i('[ApprovalMiddleware] ✅ Restored ${restoredApprovals.length} pending approvals');
      return restoredApprovals.length;
    } catch (e) {
      _logger.e('[ApprovalMiddleware] ❌ Failed to restore pending approvals: $e');
      return 0;
    }
  }

  /// Очистить активные completers при отключении
  void clearActiveCompleters() {
    _logger.d('[ApprovalMiddleware] 🧹 Clearing active completers');
    _approvalService.clearActiveCompleters();
  }

  /// Обработать approval request из unified service
  void _handleApprovalRequest(
    ApprovalRequest request,
    void Function(ApprovalRequestWithCompleter request) onToolApproval,
  ) {
    // Обрабатываем только tool approvals
    // Plan approvals обрабатываются через UI напрямую
    if (request.type != ApprovalType.tool) {
      _logger.d('[ApprovalMiddleware] ⏭️ Skipping non-tool approval: ${request.type}');
      return;
    }

    try {
      _logger.i('[ApprovalMiddleware] 🔔 Tool approval request received: ${request.approvalRequestId}');

      // Конвертируем ApprovalRequest в ToolCall
      final toolCall = ApprovalRequestAdapter.toToolCall(request);

      // Создаем legacy ToolApprovalRequest для обратной совместимости с UI
      final toolApprovalRequest = tool_approval.ToolApprovalRequest(
        requestId: request.approvalRequestId,
        toolCall: toolCall,
        requestedAt: request.requestedAt,
      );

      // Создаем completer для UI
      final completer = Completer<tool_approval.ApprovalDecision>();
      final requestWithCompleter = ApprovalRequestWithCompleter(
        toolApprovalRequest,
        completer,
      );

      // Уведомляем UI о запросе подтверждения
      onToolApproval(requestWithCompleter);

      // Ожидаем решения и обрабатываем его (event-driven подход)
      _waitForDecisionAndProcess(request, completer, toolCall);
    } catch (e) {
      _logger.e('[ApprovalMiddleware] ❌ Error handling approval request: $e');
    }
  }

  /// Ожидать решения пользователя и обработать его
  Future<void> _waitForDecisionAndProcess(
    ApprovalRequest request,
    Completer<tool_approval.ApprovalDecision> completer,
    ToolCall toolCall,
  ) async {
    try {
      // Ждем решения от UI
      final decision = await completer.future;

      _logger.i(
        '[ApprovalMiddleware] 📝 Decision received for ${toolCall.toolName}: ${decision.when(
          approved: () => 'approved',
          rejected: (_) => 'rejected',
          modified: (_, __) => 'modified',
          cancelled: () => 'cancelled',
        )}',
      );

      // Конвертируем tool_approval.ApprovalDecision в unified ApprovalDecision
      final unifiedDecision = _convertToUnifiedDecision(decision);

      // Создаем ApprovalResponse для отправки на сервер
      final response = ApprovalResponse(
        approvalRequestId: request.approvalRequestId,
        type: ApprovalType.tool,
        decision: unifiedDecision,
        respondedAt: DateTime.now(),
        decisionTimeMs: DateTime.now()
            .difference(request.requestedAt)
            .inMilliseconds,
      );

      // Отправляем решение через unified service
      await _approvalService.sendDecision(response);

      // Обрабатываем решение (выполняем или отклоняем tool)
      await _processDecision(decision, toolCall);
    } catch (e) {
      _logger.e('[ApprovalMiddleware] ❌ Error waiting for decision: $e');
    }
  }

  /// Конвертировать legacy ApprovalDecision в unified ApprovalDecision
  ApprovalDecision _convertToUnifiedDecision(tool_approval.ApprovalDecision decision) {
    return decision.when(
      approved: () => const ApprovalDecision.approved(),
      rejected: (reason) => ApprovalDecision.rejected(
        feedback: reason ?? none(),
      ),
      modified: (modifiedArguments, comment) => ApprovalDecision.modified(
        modifiedData: modifiedArguments,
        feedback: comment?.fold(() => '', (c) => c) ?? '',
      ),
      cancelled: () => const ApprovalDecision.cancelled(),
    );
  }

  /// Обработать решение пользователя
  Future<void> _processDecision(
    tool_approval.ApprovalDecision decision,
    ToolCall toolCall,
  ) async {
    await decision.when(
      approved: () async {
        _logger.i('[ApprovalMiddleware] ✅ Executing approved tool: ${toolCall.toolName}');
        await _executeApprovedTool(toolCall);
      },
      rejected: (reason) async {
        final rejectReason = reason?.fold(() => 'User rejected', (r) => r) ?? 'User rejected';
        _logger.i('[ApprovalMiddleware] ❌ Rejecting tool: ${toolCall.toolName}, reason: $rejectReason');
        await _rejectTool(toolCall, rejectReason);
      },
      modified: (modifiedArguments, comment) async {
        _logger.i('[ApprovalMiddleware] ✏️ Executing modified tool: ${toolCall.toolName}');
        final modifiedToolCall = toolCall.copyWith(
          arguments: modifiedArguments,
        );
        await _executeApprovedTool(modifiedToolCall);
      },
      cancelled: () async {
        _logger.i('[ApprovalMiddleware] 🚫 Cancelling tool: ${toolCall.toolName}');
        await _rejectTool(toolCall, 'User cancelled');
      },
    );
  }

  /// Выполнить подтвержденный tool
  Future<void> _executeApprovedTool(ToolCall toolCall) async {
    _logger.i('[ApprovalMiddleware] ▶️ Executing approved tool: ${toolCall.toolName}');

    // Выполняем tool (без повторного запроса подтверждения)
    final result = await _executeTool(
      ExecuteToolParams(toolCall: toolCall.copyWith(requiresApproval: false)),
    );

    await result.fold(
      (failure) async {
        _logger.e('[ApprovalMiddleware] ❌ Tool execution failed: ${failure.message}');

        // Отправляем ошибку на сервер
        await _sendToolResult(
          SendToolResultParams(
            callId: toolCall.id,
            toolName: toolCall.toolName,
            error: failure.message,
          ),
        );
      },
      (toolResult) async {
        _logger.i('[ApprovalMiddleware] ✅ Tool executed successfully: ${toolCall.toolName}');

        // Отправляем результат на сервер
        await toolResult.when(
          success: (id, name, data, duration, time) async {
            await _sendToolResult(
              SendToolResultParams(
                callId: toolCall.id,
                toolName: toolCall.toolName,
                result: data,
              ),
            );
          },
          failure: (id, name, code, msg, details, time) async {
            await _sendToolResult(
              SendToolResultParams(
                callId: toolCall.id,
                toolName: toolCall.toolName,
                error: msg,
              ),
            );
          },
        );
      },
    );
  }

  /// Отклонить tool и отправить rejection на сервер
  Future<void> _rejectTool(ToolCall toolCall, String reason) async {
    _logger.i('[ApprovalMiddleware] 📤 Sending rejection for tool: ${toolCall.toolName}, reason: $reason');

    // Отправляем rejection на сервер
    await _sendToolResult(
      SendToolResultParams(
        callId: toolCall.id,
        toolName: toolCall.toolName,
        error: 'User rejected: $reason',
      ),
    );
  }

  /// Очистить ресурсы при закрытии
  Future<void> dispose() async {
    _logger.d('[ApprovalMiddleware] 🔒 Disposing approval middleware');
    await stopListening();
  }
}
