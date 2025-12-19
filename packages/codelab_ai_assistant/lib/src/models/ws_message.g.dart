// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WSUserMessage _$WSUserMessageFromJson(Map<String, dynamic> json) =>
    WSUserMessage(
      content: json['content'] as String,
      role: json['role'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$WSUserMessageToJson(WSUserMessage instance) =>
    <String, dynamic>{
      'content': instance.content,
      'role': instance.role,
      'type': instance.$type,
    };

WSAssistantMessage _$WSAssistantMessageFromJson(Map<String, dynamic> json) =>
    WSAssistantMessage(
      token: json['token'] as String,
      isFinal: json['is_final'] as bool? ?? false,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$WSAssistantMessageToJson(WSAssistantMessage instance) =>
    <String, dynamic>{
      'token': instance.token,
      'is_final': instance.isFinal,
      'type': instance.$type,
    };

WSToolCall _$WSToolCallFromJson(Map<String, dynamic> json) => WSToolCall(
  callId: json['callId'] as String,
  toolName: json['toolName'] as String,
  arguments: json['arguments'] as Map<String, dynamic>,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WSToolCallToJson(WSToolCall instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'toolName': instance.toolName,
      'arguments': instance.arguments,
      'type': instance.$type,
    };

WSToolResult _$WSToolResultFromJson(Map<String, dynamic> json) => WSToolResult(
  callId: json['callId'] as String,
  result: json['result'] as Map<String, dynamic>?,
  error: json['error'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WSToolResultToJson(WSToolResult instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'result': instance.result,
      'error': instance.error,
      'type': instance.$type,
    };

WSError _$WSErrorFromJson(Map<String, dynamic> json) =>
    WSError(content: json['content'] as String, $type: json['type'] as String?);

Map<String, dynamic> _$WSErrorToJson(WSError instance) => <String, dynamic>{
  'content': instance.content,
  'type': instance.$type,
};
