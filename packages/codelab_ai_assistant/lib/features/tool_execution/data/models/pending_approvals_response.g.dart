// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_approvals_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingApprovalsResponse _$PendingApprovalsResponseFromJson(
  Map<String, dynamic> json,
) => _PendingApprovalsResponse(
  sessionId: json['session_id'] as String,
  pendingApprovals: (json['pending_approvals'] as List<dynamic>)
      .map((e) => PendingApprovalData.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$PendingApprovalsResponseToJson(
  _PendingApprovalsResponse instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'pending_approvals': instance.pendingApprovals,
  'count': instance.count,
};

_PendingApprovalData _$PendingApprovalDataFromJson(Map<String, dynamic> json) =>
    _PendingApprovalData(
      callId: json['call_id'] as String,
      toolName: json['tool_name'] as String,
      arguments: json['arguments'] as Map<String, dynamic>,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$PendingApprovalDataToJson(
  _PendingApprovalData instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'tool_name': instance.toolName,
  'arguments': instance.arguments,
  'reason': instance.reason,
  'created_at': instance.createdAt,
};
