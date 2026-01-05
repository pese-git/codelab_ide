// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(Map<String, dynamic> json) =>
    _MessageModel(
      type: json['type'] as String,
      content: json['content'] as String?,
      role: json['role'] as String?,
      isFinal: json['is_final'] as bool?,
      callId: json['call_id'] as String?,
      toolName: json['tool_name'] as String?,
      arguments: json['arguments'] as Map<String, dynamic>?,
      requiresApproval: json['requires_approval'] as bool?,
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      agentType: json['agent_type'] as String?,
      fromAgent: json['from_agent'] as String?,
      toAgent: json['to_agent'] as String?,
      reason: json['reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'content': instance.content,
      'role': instance.role,
      'is_final': instance.isFinal,
      'call_id': instance.callId,
      'tool_name': instance.toolName,
      'arguments': instance.arguments,
      'requires_approval': instance.requiresApproval,
      'result': instance.result,
      'error': instance.error,
      'agent_type': instance.agentType,
      'from_agent': instance.fromAgent,
      'to_agent': instance.toAgent,
      'reason': instance.reason,
      'metadata': instance.metadata,
    };
