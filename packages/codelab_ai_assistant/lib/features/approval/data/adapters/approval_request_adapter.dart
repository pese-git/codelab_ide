import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../domain/entities/approval_type.dart';
import '../../domain/entities/approval_request.dart';

/// Адаптер для конвертации между tool-specific и generic approval типами
///
/// Обеспечивает совместимость между старой системой tool approval
/// и новой унифицированной системой подтверждений.
///
/// Основные функции:
/// - Конвертация ToolCall → ApprovalRequest
/// - Конвертация ApprovalRequest → ToolCall
/// - Валидация типов при конвертации
class ApprovalRequestAdapter {
  /// Конвертирует ToolCall в ApprovalRequest
  ///
  /// Преобразует tool-specific запрос в generic формат для
  /// использования с UnifiedApprovalService.
  ///
  /// [toolCall] - tool call для конвертации
  ///
  /// Возвращает [ApprovalRequest] с типом tool и данными из toolCall.
  static ApprovalRequest fromToolCall(ToolCall toolCall) {
    return ApprovalRequest(
      approvalRequestId: toolCall.id,
      type: ApprovalType.tool,
      requestedAt: toolCall.createdAt,
      timeoutSeconds: 300, // Default timeout для tool approvals
      data: {
        'tool_name': toolCall.toolName,
        'tool_arguments': toolCall.arguments,
        'tool_id': toolCall.id,
        'requires_approval': toolCall.requiresApproval,
        'created_at': toolCall.createdAt.toIso8601String(),
      },
    );
  }

  /// Конвертирует ApprovalRequest обратно в ToolCall
  ///
  /// Преобразует generic approval request обратно в tool-specific формат.
  /// Используется для обработки восстановленных approvals.
  ///
  /// [request] - approval request для конвертации
  ///
  /// Возвращает [ToolCall] с данными из request.
  ///
  /// Throws [ArgumentError] если request не является tool approval.
  static ToolCall toToolCall(ApprovalRequest request) {
    if (request.type != ApprovalType.tool) {
      throw ArgumentError(
        'Cannot convert non-tool approval to ToolCall. Type: ${request.type}',
      );
    }

    final data = request.data;

    // Валидация обязательных полей
    if (!data.containsKey('tool_name') ||
        !data.containsKey('tool_arguments') ||
        !data.containsKey('tool_id') ||
        !data.containsKey('created_at')) {
      throw ArgumentError(
        'ApprovalRequest data is missing required fields for ToolCall conversion',
      );
    }

    return ToolCall(
      id: data['tool_id'] as String,
      toolName: data['tool_name'] as String,
      arguments: data['tool_arguments'] as Map<String, dynamic>,
      requiresApproval: data['requires_approval'] as bool? ?? true,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  /// Проверяет, является ли ApprovalRequest tool approval
  ///
  /// [request] - approval request для проверки
  ///
  /// Возвращает true если request является tool approval.
  static bool isToolApproval(ApprovalRequest request) {
    return request.type == ApprovalType.tool;
  }

  /// Извлекает tool name из ApprovalRequest
  ///
  /// [request] - approval request
  ///
  /// Возвращает tool name или null если это не tool approval.
  static String? getToolName(ApprovalRequest request) {
    if (!isToolApproval(request)) return null;
    return request.data['tool_name'] as String?;
  }

  /// Извлекает tool arguments из ApprovalRequest
  ///
  /// [request] - approval request
  ///
  /// Возвращает tool arguments или null если это не tool approval.
  static Map<String, dynamic>? getToolArguments(ApprovalRequest request) {
    if (!isToolApproval(request)) return null;
    return request.data['tool_arguments'] as Map<String, dynamic>?;
  }
}
