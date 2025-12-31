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
      content: json['content'] as String?,
      isFinal: json['is_final'] as bool? ?? false,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$WSAssistantMessageToJson(WSAssistantMessage instance) =>
    <String, dynamic>{
      'content': instance.content,
      'is_final': instance.isFinal,
      'type': instance.$type,
    };

WSToolCall _$WSToolCallFromJson(Map<String, dynamic> json) => WSToolCall(
  callId: json['call_id'] as String,
  toolName: json['tool_name'] as String,
  arguments: json['arguments'] as Map<String, dynamic>,
  requiresApproval: json['requires_approval'] as bool? ?? false,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WSToolCallToJson(WSToolCall instance) =>
    <String, dynamic>{
      'call_id': instance.callId,
      'tool_name': instance.toolName,
      'arguments': instance.arguments,
      'requires_approval': instance.requiresApproval,
      'type': instance.$type,
    };

WSToolResult _$WSToolResultFromJson(Map<String, dynamic> json) => WSToolResult(
  callId: json['call_id'] as String,
  toolName: json['tool_name'] as String?,
  result: json['result'] as Map<String, dynamic>?,
  error: json['error'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WSToolResultToJson(WSToolResult instance) =>
    <String, dynamic>{
      'call_id': instance.callId,
      'tool_name': instance.toolName,
      'result': instance.result,
      'error': instance.error,
      'type': instance.$type,
    };

WSAgentSwitchedMessage _$WSAgentSwitchedMessageFromJson(
  Map<String, dynamic> json,
) => WSAgentSwitchedMessage(
  content: json['content'] as String?,
  fromAgent: _readFromAgent(json, 'from_agent') as String?,
  toAgent: _readToAgent(json, 'to_agent') as String?,
  reason: _readReason(json, 'reason') as String?,
  confidence: _readConfidence(json, 'confidence') as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WSAgentSwitchedMessageToJson(
  WSAgentSwitchedMessage instance,
) => <String, dynamic>{
  'content': instance.content,
  'from_agent': instance.fromAgent,
  'to_agent': instance.toAgent,
  'reason': instance.reason,
  'confidence': instance.confidence,
  'type': instance.$type,
};

WSError _$WSErrorFromJson(Map<String, dynamic> json) => WSError(
  content: json['content'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WSErrorToJson(WSError instance) => <String, dynamic>{
  'content': instance.content,
  'type': instance.$type,
};

WSHITLDecision _$WSHITLDecisionFromJson(Map<String, dynamic> json) =>
    WSHITLDecision(
      callId: json['call_id'] as String,
      decision: json['decision'] as String,
      modifiedArguments: json['modified_arguments'] as Map<String, dynamic>?,
      feedback: json['feedback'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$WSHITLDecisionToJson(WSHITLDecision instance) =>
    <String, dynamic>{
      'call_id': instance.callId,
      'decision': instance.decision,
      'modified_arguments': instance.modifiedArguments,
      'feedback': instance.feedback,
      'type': instance.$type,
    };
