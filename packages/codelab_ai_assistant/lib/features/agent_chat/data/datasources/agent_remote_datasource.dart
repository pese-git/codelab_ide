// Remote data source для работы с агентами через WebSocket
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/error/exceptions.dart';
import '../models/message_model.dart';

/// Интерфейс для удаленного источника данных агентов
abstract class AgentRemoteDataSource {
  /// Подключается к WebSocket с указанной сессией
  Future<void> connect(String sessionId);
  
  /// Отключается от WebSocket
  Future<void> disconnect();
  
  /// Отправляет сообщение через WebSocket
  Future<void> sendMessage(MessageModel message);
  
  /// Получает поток входящих сообщений
  Stream<MessageModel> receiveMessages();
  
  /// Проверяет, подключен ли WebSocket
  bool get isConnected;
  
  /// Получает текущий session ID
  String? get currentSessionId;
}

/// Реализация удаленного источника данных через WebSocket
class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  final String gatewayUrl;
  WebSocketChannel? _channel;
  String? _currentSessionId;
  
  AgentRemoteDataSourceImpl({
    required this.gatewayUrl,
  });
  
  @override
  bool get isConnected => _channel != null;
  
  @override
  String? get currentSessionId => _currentSessionId;
  
  @override
  Future<void> connect(String sessionId) async {
    try {
      // Закрыть предыдущее соединение если есть
      if (_channel != null) {
        await disconnect();
      }
      
      _currentSessionId = sessionId;
      final wsUrl = '$gatewayUrl/ws/$sessionId';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Ждем подключения
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      throw WebSocketException('Failed to connect to WebSocket: $e', e);
    }
  }
  
  @override
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
      _channel = null;
      _currentSessionId = null;
    } catch (e) {
      throw WebSocketException('Failed to disconnect from WebSocket: $e', e);
    }
  }
  
  @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      if (_channel == null) {
        throw WebSocketException('WebSocket not connected');
      }
      
      final jsonString = jsonEncode(message.toJson());
      _channel!.sink.add(jsonString);
    } catch (e) {
      if (e is WebSocketException) rethrow;
      throw WebSocketException('Failed to send message: $e', e);
    }
  }
  
  @override
  Stream<MessageModel> receiveMessages() {
    if (_channel == null) {
      throw WebSocketException('WebSocket not connected');
    }
    
    return _channel!.stream.map((event) {
      try {
        final json = jsonDecode(event as String) as Map<String, dynamic>;
        return MessageModel.fromJson(json);
      } on FormatException catch (e) {
        throw ParseException('Invalid JSON from WebSocket: $e', e);
      } catch (e) {
        throw ParseException('Failed to parse message: $e', e);
      }
    }).handleError((error) {
      if (error is ParseException) throw error;
      throw WebSocketException('WebSocket stream error: $error', error);
    });
  }
}
