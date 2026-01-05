// Repository interface для работы с агентами и сообщениями
import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/message.dart';
import '../entities/agent.dart';

/// Интерфейс репозитория для работы с AI агентами и сообщениями
/// 
/// Определяет контракт для работы с чатом, не зависящий от реализации.
abstract class AgentRepository {
  /// Отправляет сообщение пользователя
  /// 
  /// Возвращает [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> sendMessage(SendMessageParams params);
  
  /// Отправляет результат выполнения tool call
  ///
  /// Возвращает [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> sendToolResult({
    required String callId,
    required String toolName,
    Map<String, dynamic>? result,
    String? error,
  });
  
  /// Получает поток входящих сообщений от агента
  /// 
  /// Возвращает Stream с Either - каждое сообщение может быть успешным или ошибкой
  StreamEither<Message> receiveMessages();
  
  /// Переключает текущего агента
  /// 
  /// Возвращает [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> switchAgent(SwitchAgentParams params);
  
  /// Загружает историю сообщений для сессии
  /// 
  /// Возвращает [Right] со списком сообщений или [Left] с ошибкой
  FutureEither<List<Message>> loadHistory(LoadHistoryParams params);
  
  /// Получает список доступных агентов
  /// 
  /// Возвращает [Right] со списком агентов или [Left] с ошибкой
  FutureEither<List<Agent>> getAvailableAgents();
  
  /// Получает текущего активного агента
  /// 
  /// Возвращает [Right] с агентом или [Left] с ошибкой
  FutureEither<Agent> getCurrentAgent();
  
  /// Подключается к WebSocket с указанной сессией
  /// 
  /// Возвращает [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> connect(String sessionId);
  
  /// Отключается от WebSocket
  /// 
  /// Возвращает [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> disconnect();
  
  /// Проверяет, подключен ли WebSocket
  bool get isConnected;
}
