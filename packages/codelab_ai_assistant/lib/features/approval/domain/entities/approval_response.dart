import 'package:freezed_annotation/freezed_annotation.dart';
import 'approval_decision.dart';
import 'approval_type.dart';

part 'approval_response.freezed.dart';

/// Ответ на запрос подтверждения
///
/// Содержит решение пользователя и метаданные о времени принятия решения.
@freezed
abstract class ApprovalResponse with _$ApprovalResponse {
  const factory ApprovalResponse({
    /// ID запроса на подтверждение
    required String approvalRequestId,

    /// Тип подтверждения
    required ApprovalType type,

    /// Решение пользователя
    required ApprovalDecision decision,

    /// Время ответа
    required DateTime respondedAt,

    /// Время принятия решения в миллисекундах
    required int decisionTimeMs,
  }) = _ApprovalResponse;

  const ApprovalResponse._();
}
