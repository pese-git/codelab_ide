import 'package:fpdart/fpdart.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_approval.dart'
    as tool_approval;
import '../../domain/entities/approval_type.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_response.dart';
import '../../domain/entities/approval_decision.dart';

/// Адаптер для конвертации между Tool Approval entities и Unified Approval entities
///
/// Обеспечивает совместимость между старой системой tool approval
/// и новой унифицированной системой подтверждений.
class ToolApprovalAdapter {
  /// Конвертирует ToolCall в ApprovalRequest
  ///
  /// Преобразует специфичные для tool данные в generic формат
  /// для использования в UnifiedApprovalService.
  static ApprovalRequest toApprovalRequest(
    tool_approval.ToolApprovalRequest toolRequest,
  ) {
    return ApprovalRequest(
      approvalRequestId: toolRequest.requestId,
      type: ApprovalType.tool,
      requestedAt: toolRequest.requestedAt,
      timeoutSeconds: toolRequest.timeoutSeconds,
      data: {
        'tool_name': toolRequest.toolCall.toolName,
        'tool_arguments': toolRequest.toolCall.arguments,
        'tool_id': toolRequest.toolCall.id,
        'requires_approval': toolRequest.toolCall.requiresApproval,
        'created_at': toolRequest.toolCall.createdAt.toIso8601String(),
        'is_critical': toolRequest.isCritical,
      },
      context: toolRequest.context,
    );
  }

  /// Конвертирует ApprovalDecision в tool_approval.ApprovalDecision
  ///
  /// Преобразует generic решение обратно в формат tool approval.
  static tool_approval.ApprovalDecision fromApprovalDecision(
    ApprovalDecision decision,
  ) {
    return decision.when(
      approved: () => const tool_approval.ApprovalDecision.approved(),
      rejected: (feedback) => tool_approval.ApprovalDecision.rejected(
        reason: feedback,
      ),
      modified: (modifiedData, feedback) {
        // Извлекаем модифицированные аргументы из generic data
        final modifiedArguments = modifiedData['tool_arguments'] as Map<String, dynamic>? ??
            modifiedData;
        
        return tool_approval.ApprovalDecision.modified(
          modifiedArguments: modifiedArguments,
          comment: feedback != null ? some(feedback) : none(),
        );
      },
      cancelled: () => const tool_approval.ApprovalDecision.cancelled(),
    );
  }

  /// Конвертирует tool_approval.ApprovalDecision в ApprovalDecision
  ///
  /// Преобразует tool-specific решение в generic формат.
  static ApprovalDecision toApprovalDecision(
    tool_approval.ApprovalDecision decision,
  ) {
    return decision.when(
      approved: () => const ApprovalDecision.approved(),
      rejected: (reason) => ApprovalDecision.rejected(
        feedback: reason,
      ),
      modified: (modifiedArguments, comment) {
        return ApprovalDecision.modified(
          modifiedData: {
            'tool_arguments': modifiedArguments,
          },
          feedback: comment?.fold(() => '', (c) => c) ?? '',
        );
      },
      cancelled: () => const ApprovalDecision.cancelled(),
    );
  }

  /// Конвертирует ApprovalResponse в tool_approval.ToolApprovalResponse
  ///
  /// Преобразует generic ответ в формат tool approval.
  static tool_approval.ToolApprovalResponse toToolApprovalResponse(
    ApprovalResponse response,
  ) {
    return tool_approval.ToolApprovalResponse(
      requestId: response.approvalRequestId,
      decision: fromApprovalDecision(response.decision),
      respondedAt: response.respondedAt,
      decisionTimeMs: response.decisionTimeMs,
    );
  }

  /// Конвертирует tool_approval.ToolApprovalResponse в ApprovalResponse
  ///
  /// Преобразует tool-specific ответ в generic формат.
  static ApprovalResponse fromToolApprovalResponse(
    tool_approval.ToolApprovalResponse response,
  ) {
    return ApprovalResponse(
      approvalRequestId: response.requestId,
      type: ApprovalType.tool,
      decision: toApprovalDecision(response.decision),
      respondedAt: response.respondedAt,
      decisionTimeMs: response.decisionTimeMs,
    );
  }

  /// Извлекает ToolCall из ApprovalRequest
  ///
  /// Восстанавливает оригинальный ToolCall из generic данных.
  /// Используется для обратной совместимости с существующим кодом.
  static ToolCall extractToolCall(ApprovalRequest request) {
    final data = request.data;
    
    return ToolCall(
      id: data['tool_id'] as String,
      toolName: data['tool_name'] as String,
      arguments: data['tool_arguments'] as Map<String, dynamic>,
      requiresApproval: data['requires_approval'] as bool,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  /// Создает ToolApprovalRequest из ApprovalRequest
  ///
  /// Полная конвертация обратно в tool-specific формат.
  static tool_approval.ToolApprovalRequest toToolApprovalRequest(
    ApprovalRequest request,
  ) {
    final toolCall = extractToolCall(request);
    
    return tool_approval.ToolApprovalRequest(
      requestId: request.approvalRequestId,
      toolCall: toolCall,
      requestedAt: request.requestedAt,
      timeoutSeconds: request.timeoutSeconds,
      context: request.context,
    );
  }
}
