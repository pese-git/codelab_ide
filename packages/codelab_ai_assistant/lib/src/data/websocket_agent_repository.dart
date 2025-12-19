// lib/ai_agent/data/websocket_agent_repository.dart

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ws_message.dart';

/// Репозиторий для взаимодействия с AI Agent через WebSocket.
class WebSocketAgentRepository {
  final String wsUrl;
  WebSocketChannel? _channel;

  WebSocketAgentRepository({required this.wsUrl});

  Stream<WSMessage> get messages => _channel!.stream
      .map((event) => WSMessage.fromJson(jsonDecode(event as String)));

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  void send(WSMessage message) {
    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
  }
}
