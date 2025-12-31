import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_models.freezed.dart';
part 'session_models.g.dart';

/// Сообщение в чате
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role,
    required String content,
    String? name,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

/// Переключение агента
@freezed
abstract class AgentSwitch with _$AgentSwitch {
  const factory AgentSwitch({
    required String from,
    required String to,
    required String reason,
    required String timestamp,
  }) = _AgentSwitch;

  factory AgentSwitch.fromJson(Map<String, dynamic> json) =>
      _$AgentSwitchFromJson(json);
}

/// История сессии
@freezed
abstract class SessionHistory with _$SessionHistory {
  const factory SessionHistory({
    @JsonKey(name: 'session_id') required String sessionId,
    required List<ChatMessage> messages,
    @JsonKey(name: 'message_count') required int messageCount,
    @JsonKey(name: 'last_activity') String? lastActivity,
    @JsonKey(name: 'current_agent') String? currentAgent,
    @JsonKey(name: 'agent_history') @Default([]) List<AgentSwitch> agentHistory,
  }) = _SessionHistory;

  factory SessionHistory.fromJson(Map<String, dynamic> json) =>
      _$SessionHistoryFromJson(json);
}

/// Информация о сессии
@freezed
abstract class SessionInfo with _$SessionInfo {
  const factory SessionInfo({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'message_count') required int messageCount,
    @JsonKey(name: 'last_activity') required String lastActivity,
    @JsonKey(name: 'current_agent') String? currentAgent,
  }) = _SessionInfo;

  factory SessionInfo.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoFromJson(json);
}

/// Список сессий
@freezed
abstract class SessionListResponse with _$SessionListResponse {
  const factory SessionListResponse({
    required List<SessionInfo> sessions,
    required int total,
  }) = _SessionListResponse;

  factory SessionListResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionListResponseFromJson(json);
}

/// Информация об агенте
@freezed
abstract class AgentInfo with _$AgentInfo {
  const factory AgentInfo({
    required String type,
    required String name,
    required String description,
    @JsonKey(name: 'allowed_tools') required List<String> allowedTools,
    @JsonKey(name: 'has_file_restrictions') required bool hasFileRestrictions,
  }) = _AgentInfo;

  factory AgentInfo.fromJson(Map<String, dynamic> json) =>
      _$AgentInfoFromJson(json);
}

/// Текущий агент сессии
@freezed
abstract class CurrentAgentInfo with _$CurrentAgentInfo {
  const factory CurrentAgentInfo({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'current_agent') required String currentAgent,
    @JsonKey(name: 'agent_history') required List<AgentSwitch> agentHistory,
    @JsonKey(name: 'switch_count') required int switchCount,
  }) = _CurrentAgentInfo;

  factory CurrentAgentInfo.fromJson(Map<String, dynamic> json) =>
      _$CurrentAgentInfoFromJson(json);
}
