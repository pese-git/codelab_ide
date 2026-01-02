// lib/ai_agent/data/websocket_agent_repository.dart

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ws_message.dart';

/// Репозиторий для взаимодействия с AI Agent через WebSocket.
class WebSocketAgentRepository {
  final String gatewayUrl;
  String? _currentSessionId;
  WebSocketChannel? _channel;

  WebSocketAgentRepository({required this.gatewayUrl});

  Stream<WSMessage> get messages => _channel!.stream
      .map((event) => WSMessage.fromJson(jsonDecode(event as String)));

  /// Подключиться к WebSocket с указанным session_id
  void connect({String? sessionId}) {
    // Закрыть предыдущее соединение если есть
    if (_channel != null) {
      _channel!.sink.close();
    }
    
    _currentSessionId = sessionId;
    final wsUrl = sessionId != null
        ? '$gatewayUrl/ws/$sessionId'
        : '$gatewayUrl/ws/ide-session'; // fallback для обратной совместимости
    
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  /// Переподключиться с новым session_id
  void reconnect(String sessionId) {
    connect(sessionId: sessionId);
  }

  void send(WSMessage message) {
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  void sendRaw(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _currentSessionId = null;
  }
  
  String? get currentSessionId => _currentSessionId;
}
