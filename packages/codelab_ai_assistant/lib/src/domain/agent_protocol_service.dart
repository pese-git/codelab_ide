// lib/ai_agent/domain/agent_protocol_service.dart

import '../models/ws_message.dart';
import '../data/websocket_agent_repository.dart';

/// Абстракция сервиса протокола общения с AI Agent.
abstract class AgentProtocolService {
  Stream<WSMessage> get messages;
  void sendUserMessage(String content, {String role = 'user'});
  void sendSwitchAgent(String agentType, String content);
  void sendToolResult({
    required String callId,
    String? toolName,
    Map<String, dynamic>? result,
    String? error,
  });
  void sendHITLDecision({
    required String callId,
    required String decision,
    Map<String, dynamic>? modifiedArguments,
    String? feedback,
  });
  void connect();
  Future<void> disconnect();
}

/// Базовая реализация на репозитории (WebSocketAgentRepository)
class AgentProtocolServiceImpl implements AgentProtocolService {
  final WebSocketAgentRepository _repo;
  AgentProtocolServiceImpl(this._repo);

  @override
  Stream<WSMessage> get messages => _repo.messages;

  @override
  void sendUserMessage(String content, {String role = 'user'}) {
    _repo.send(WSMessage.userMessage(content: content, role: role));
  }

  @override
  void sendSwitchAgent(String agentType, String content) {
    // Отправляем switch_agent сообщение через WebSocket
    _repo.sendRaw({
      'type': 'switch_agent',
      'agent_type': agentType,
      'content': content,
    });
  }

  @override
  void sendToolResult({
    required String callId,
    String? toolName,
    Map<String, dynamic>? result,
    String? error,
  }) {
    _repo.send(WSMessage.toolResult(
      callId: callId,
      toolName: toolName,
      result: result,
      error: error,
    ));
  }

  @override
  void sendHITLDecision({
    required String callId,
    required String decision,
    Map<String, dynamic>? modifiedArguments,
    String? feedback,
  }) {
    _repo.send(WSMessage.hitlDecision(
      callId: callId,
      decision: decision,
      modifiedArguments: modifiedArguments,
      feedback: feedback,
    ));
  }

  @override
  void connect() => _repo.connect();

  @override
  Future<void> disconnect() => _repo.disconnect();
}
