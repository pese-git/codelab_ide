// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  role: json['role'] as String,
  content: json['content'] as String,
  name: json['name'] as String?,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
      'name': instance.name,
    };

_AgentSwitch _$AgentSwitchFromJson(Map<String, dynamic> json) => _AgentSwitch(
  from: json['from'] as String,
  to: json['to'] as String,
  reason: json['reason'] as String,
  timestamp: json['timestamp'] as String,
);

Map<String, dynamic> _$AgentSwitchToJson(_AgentSwitch instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'reason': instance.reason,
      'timestamp': instance.timestamp,
    };

_SessionHistory _$SessionHistoryFromJson(Map<String, dynamic> json) =>
    _SessionHistory(
      sessionId: json['session_id'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      messageCount: (json['message_count'] as num).toInt(),
      lastActivity: json['last_activity'] as String?,
      currentAgent: json['current_agent'] as String?,
      agentHistory:
          (json['agent_history'] as List<dynamic>?)
              ?.map((e) => AgentSwitch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SessionHistoryToJson(_SessionHistory instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'messages': instance.messages,
      'message_count': instance.messageCount,
      'last_activity': instance.lastActivity,
      'current_agent': instance.currentAgent,
      'agent_history': instance.agentHistory,
    };

_SessionInfo _$SessionInfoFromJson(Map<String, dynamic> json) => _SessionInfo(
  sessionId: json['session_id'] as String,
  messageCount: (json['message_count'] as num).toInt(),
  lastActivity: json['last_activity'] as String,
  currentAgent: json['current_agent'] as String?,
);

Map<String, dynamic> _$SessionInfoToJson(_SessionInfo instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'message_count': instance.messageCount,
      'last_activity': instance.lastActivity,
      'current_agent': instance.currentAgent,
    };

_SessionListResponse _$SessionListResponseFromJson(Map<String, dynamic> json) =>
    _SessionListResponse(
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$SessionListResponseToJson(
  _SessionListResponse instance,
) => <String, dynamic>{'sessions': instance.sessions, 'total': instance.total};

_AgentInfo _$AgentInfoFromJson(Map<String, dynamic> json) => _AgentInfo(
  type: json['type'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  allowedTools: (json['allowed_tools'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  hasFileRestrictions: json['has_file_restrictions'] as bool,
);

Map<String, dynamic> _$AgentInfoToJson(_AgentInfo instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'description': instance.description,
      'allowed_tools': instance.allowedTools,
      'has_file_restrictions': instance.hasFileRestrictions,
    };

_CurrentAgentInfo _$CurrentAgentInfoFromJson(Map<String, dynamic> json) =>
    _CurrentAgentInfo(
      sessionId: json['session_id'] as String,
      currentAgent: json['current_agent'] as String,
      agentHistory: (json['agent_history'] as List<dynamic>)
          .map((e) => AgentSwitch.fromJson(e as Map<String, dynamic>))
          .toList(),
      switchCount: (json['switch_count'] as num).toInt(),
    );

Map<String, dynamic> _$CurrentAgentInfoToJson(_CurrentAgentInfo instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'current_agent': instance.currentAgent,
      'agent_history': instance.agentHistory,
      'switch_count': instance.switchCount,
    };
