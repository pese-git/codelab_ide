// lib/ai_agent/models/ws_message.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ws_message.freezed.dart';
part 'ws_message.g.dart';

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
    @JsonKey(name: 'requires_approval', defaultValue: false) @Default(false) bool requiresApproval,
  }) = WSToolCall;

  const factory WSMessage.toolResult({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'call_id') required String callId,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'tool_name') String? toolName,
    Map<String, dynamic>? result,
    String? error,
  }) = WSToolResult;

  const factory WSMessage.error({String? content}) = WSError;

  factory WSMessage.fromJson(Map<String, dynamic> json) =>
      _$WSMessageFromJson(json);
}
