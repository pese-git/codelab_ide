// Repository interface для работы с агентами и сообщениями
import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/message.dart';
import '../entities/agent.dart';
import '../entities/execution_plan.dart';

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
  
  // ===== Методы для работы с планами =====
  
  /// Подтверждает план выполнения
  ///
  /// Отправляет plan_approval с decision="approve" на сервер.
  /// После подтверждения начинается выполнение подзадач.
  ///
  /// Args:
  ///   planId: ID плана для подтверждения
  ///   feedback: Опциональная обратная связь от пользователя
  ///
  /// Returns:
  ///   [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> approvePlan({
    required String planId,
    Option<String> feedback = const None(),
  });
  
  /// Отклоняет план выполнения
  ///
  /// Отправляет plan_approval с decision="reject" на сервер.
  /// После отклонения Orchestrator может предложить альтернативный подход.
  ///
  /// Args:
  ///   planId: ID плана для отклонения
  ///   reason: Причина отклонения
  ///
  /// Returns:
  ///   [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> rejectPlan({
    required String planId,
    required String reason,
  });
  
  /// Получает активный план выполнения (если есть)
  ///
  /// Returns:
  ///   [Right] с Option<ExecutionPlan> - Some если план активен, None если нет
  ///   [Left] с ошибкой при проблемах получения
  FutureEither<Option<ExecutionPlan>> getActivePlan();
  
  /// Подписывается на обновления плана
  ///
  /// Возвращает поток обновлений плана (plan_update, plan_progress).
  /// Клиент может использовать этот поток для отслеживания прогресса.
  ///
  /// Returns:
  ///   Stream с Either - каждое обновление может быть успешным или ошибкой
  StreamEither<ExecutionPlan> watchPlanUpdates();
}
