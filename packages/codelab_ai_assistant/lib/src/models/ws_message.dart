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
    required String token,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'is_final', defaultValue: false) required bool isFinal,
  }) = WSAssistantMessage;

  const factory WSMessage.toolCall({
    required String callId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) = WSToolCall;

  const factory WSMessage.toolResult({
    required String callId,
    Map<String, dynamic>? result,
    String? error,
  }) = WSToolResult;

  const factory WSMessage.error({required String content}) = WSError;

  factory WSMessage.fromJson(Map<String, dynamic> json) =>
      _$WSMessageFromJson(json);
}
