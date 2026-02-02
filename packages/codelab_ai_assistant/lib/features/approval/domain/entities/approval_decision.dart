import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'approval_decision.freezed.dart';

/// Решение пользователя по запросу на подтверждение
///
/// Унифицированное представление всех возможных решений.
@freezed
sealed class ApprovalDecision with _$ApprovalDecision {
  /// Операция одобрена без изменений
  const factory ApprovalDecision.approved() = ApprovalApproved;

  /// Операция отклонена
  ///
  /// [feedback] - опциональная причина отклонения
  const factory ApprovalDecision.rejected({
    Option<String>? feedback,
  }) = ApprovalRejected;

  /// Операция одобрена с модификациями
  ///
  /// [modifiedData] - измененные данные (например, аргументы tool)
  /// [feedback] - комментарий пользователя
  const factory ApprovalDecision.modified({
    required Map<String, dynamic> modifiedData,
    required String feedback,
  }) = ApprovalModified;

  /// Операция отменена (таймаут или явная отмена)
  const factory ApprovalDecision.cancelled() = ApprovalCancelled;
}

/// Расширение для удобной работы с ApprovalDecision
extension ApprovalDecisionExtension on ApprovalDecision {
  /// Проверка, одобрена ли операция
  bool get isApproved => this is ApprovalApproved;

  /// Проверка, отклонена ли операция
  bool get isRejected => this is ApprovalRejected;

  /// Проверка, модифицирована ли операция
  bool get isModified => this is ApprovalModified;

  /// Проверка, отменена ли операция
  bool get isCancelled => this is ApprovalCancelled;

  /// Получить feedback если есть
  Option<String> getFeedback() {
    return when(
      approved: () => none(),
      rejected: (feedback) => feedback ?? none(),
      modified: (_, feedback) => some(feedback),
      cancelled: () => none(),
    );
  }

  /// Преобразовать в строковое представление для API
  String toDecisionString() {
    return when(
      approved: () => 'approved',
      rejected: (_) => 'rejected',
      modified: (_, __) => 'modified',
      cancelled: () => 'cancelled',
    );
  }

  /// Создать ApprovalDecision из строки
  static ApprovalDecision fromString(
    String decision, {
    Map<String, dynamic>? modifiedData,
    String? feedback,
  }) {
    switch (decision) {
      case 'approved':
        return const ApprovalDecision.approved();
      case 'rejected':
        return ApprovalDecision.rejected(
          feedback: feedback != null ? some(feedback) : none(),
        );
      case 'modified':
        if (modifiedData == null) {
          throw ArgumentError('modifiedData is required for modified decision');
        }
        return ApprovalDecision.modified(
          modifiedData: modifiedData,
          feedback: feedback ?? '',
        );
      case 'cancelled':
        return const ApprovalDecision.cancelled();
      default:
        throw ArgumentError('Unknown decision: $decision');
    }
  }
}
