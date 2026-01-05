// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_call_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ToolCallModel _$ToolCallModelFromJson(Map<String, dynamic> json) =>
    _ToolCallModel(
      callId: json['call_id'] as String,
      toolName: json['tool_name'] as String,
      arguments: json['arguments'] as Map<String, dynamic>,
      requiresApproval: json['requires_approval'] as bool? ?? false,
    );

Map<String, dynamic> _$ToolCallModelToJson(_ToolCallModel instance) =>
    <String, dynamic>{
      'call_id': instance.callId,
      'tool_name': instance.toolName,
      'arguments': instance.arguments,
      'requires_approval': instance.requiresApproval,
    };
