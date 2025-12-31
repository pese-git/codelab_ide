// lib/ai_agent/models/ws_message.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ws_message.freezed.dart';
part 'ws_message.g.dart';

// Helper functions to read values from metadata if not present at top level
Object? _readFromAgent(Map json, String key) {
  return json['from_agent'] ?? json['metadata']?['from_agent'];
}

Object? _readToAgent(Map json, String key) {
  return json['to_agent'] ?? json['metadata']?['to_agent'];
}

Object? _readReason(Map json, String key) {
  return json['reason'] ?? json['metadata']?['reason'];
}

Object? _readConfidence(Map json, String key) {
  return json['confidence'] ?? json['metadata']?['confidence'];
}

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class WSMessage with _$WSMessage {
  const factory WSMessage.userMessage({
    required String content,
    required String role,
  }) = WSUserMessage;

  const factory WSMessage.assistantMessage({
    String? content,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'is_final', defaultValue: false) required bool isFinal,
  }) = WSAssistantMessage;

  const factory WSMessage.toolCall({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'call_id') required String callId,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'tool_name') required String toolName,
    required Map<String, dynamic> arguments,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'requires_approval', defaultValue: false)
    @Default(false)
    bool requiresApproval,
  }) = WSToolCall;

  const factory WSMessage.toolResult({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'call_id') required String callId,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'tool_name') String? toolName,
    Map<String, dynamic>? result,
    String? error,
  }) = WSToolResult;

  const factory WSMessage.agentSwitched({
    String? content,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'from_agent', readValue: _readFromAgent) String? fromAgent,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'to_agent', readValue: _readToAgent) String? toAgent,
    // ignore: invalid_annotation_target
    @JsonKey(readValue: _readReason) String? reason,
    // ignore: invalid_annotation_target
    @JsonKey(readValue: _readConfidence) String? confidence,
  }) = WSAgentSwitchedMessage;

  const factory WSMessage.error({String? content}) = WSError;

  const factory WSMessage.switchAgent({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'agent_type') required String agentType,
    required String content,
    String? reason,
  }) = WSSwitchAgent;

  const factory WSMessage.hitlDecision({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'call_id') required String callId,
    required String decision, // "approve", "edit", "reject"
    // ignore: invalid_annotation_target
    @JsonKey(name: 'modified_arguments') Map<String, dynamic>? modifiedArguments,
    String? feedback,
  }) = WSHITLDecision;

  factory WSMessage.fromJson(Map<String, dynamic> json) =>
      _$WSMessageFromJson(json);
}
