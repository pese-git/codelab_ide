// Модель ответа для списка ожидающих подтверждений
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_approvals_response.freezed.dart';
part 'pending_approvals_response.g.dart';

/// Ответ сервера со списком ожидающих подтверждений
@freezed
abstract class PendingApprovalsResponse with _$PendingApprovalsResponse {
  const factory PendingApprovalsResponse({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'pending_approvals') required List<PendingApprovalData> pendingApprovals,
    required int count,
  }) = _PendingApprovalsResponse;

  factory PendingApprovalsResponse.fromJson(Map<String, dynamic> json) =>
      _$PendingApprovalsResponseFromJson(json);
}

/// Данные одного ожидающего подтверждения
@freezed
abstract class PendingApprovalData with _$PendingApprovalData {
  const factory PendingApprovalData({
    @JsonKey(name: 'call_id') required String callId,
    @JsonKey(name: 'tool_name') required String toolName,
    required Map<String, dynamic> arguments,
    String? reason,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _PendingApprovalData;

  factory PendingApprovalData.fromJson(Map<String, dynamic> json) =>
      _$PendingApprovalDataFromJson(json);
}
