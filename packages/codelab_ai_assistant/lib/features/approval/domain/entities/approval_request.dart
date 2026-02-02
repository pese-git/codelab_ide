import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'approval_type.dart';

part 'approval_request.freezed.dart';

/// Базовый запрос на подтверждение
///
/// Унифицированная структура для всех типов подтверждений в системе.
/// Содержит общие поля и type-specific данные в поле [data].
@freezed
abstract class ApprovalRequest with _$ApprovalRequest {
  const factory ApprovalRequest({
    /// Уникальный идентификатор запроса на подтверждение
    required String approvalRequestId,

    /// Тип подтверждения (tool, plan, etc.)
    required ApprovalType type,

    /// Время создания запроса
    required DateTime requestedAt,

    /// Таймаут в секундах (по умолчанию 300 = 5 минут)
    @Default(300) int timeoutSeconds,

    /// Type-specific данные запроса
    ///
    /// Для tool: {'tool_name': String, 'arguments': Map<String, dynamic>, 'call_id': String}
    /// Для plan: {'plan_id': String, 'plan_summary': Map<String, dynamic>}
    required Map<String, dynamic> data,

    /// Опциональный контекст запроса
    Option<String>? context,
  }) = _ApprovalRequest;

  const ApprovalRequest._();

  /// Получить tool name для tool approval
  String? get toolName =>
      type == ApprovalType.tool ? data['tool_name'] as String? : null;

  /// Получить tool arguments для tool approval
  Map<String, dynamic>? get toolArguments => type == ApprovalType.tool
      ? data['arguments'] as Map<String, dynamic>?
      : null;

  /// Получить call_id для tool approval
  String? get callId =>
      type == ApprovalType.tool ? data['call_id'] as String? : null;

  /// Получить plan_id для plan approval
  String? get planId =>
      type == ApprovalType.plan ? data['plan_id'] as String? : null;

  /// Получить plan_summary для plan approval
  Map<String, dynamic>? get planSummary => type == ApprovalType.plan
      ? data['plan_summary'] as Map<String, dynamic>?
      : null;
}
