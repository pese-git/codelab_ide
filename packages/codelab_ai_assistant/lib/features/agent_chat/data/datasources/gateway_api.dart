import 'package:dio/dio.dart';
import '../../../session_management/data/models/session_models.dart';
import '../../../tool_execution/data/models/pending_approvals_response.dart';

/// API клиент для Gateway Service (только Dio, без Retrofit)
///
/// Все запросы идут через Gateway (порт 8000), который проксирует их к Agent Runtime.
/// Gateway автоматически добавляет X-Internal-Auth заголовок.
class GatewayApi {
  final Dio _dio;
  final String baseUrl;

  GatewayApi({required Dio dio, this.baseUrl = 'http://localhost:8000/api/v1'})
      : _dio = dio;

  /// Получить историю сессии
  ///
  /// GET /api/v1/sessions/{sessionId}/history
  Future<SessionHistory> getSessionHistory(String sessionId) async {
    final response = await _dio.get(
      '$baseUrl/sessions/$sessionId/history',
    );
    return SessionHistory.fromJson(response.data);
  }

  /// Получить список всех сессий
  ///
  /// GET /sessions
  Future<SessionListResponse> listSessions() async {
    final response = await _dio.get('$baseUrl/sessions');
    return SessionListResponse.fromJson(response.data);
  }

  /// Получить список доступных агентов
  ///
  /// GET /agents
  Future<List<AgentInfo>> listAgents() async {
    final response = await _dio.get('$baseUrl/agents');
    return (response.data as List)
        .map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Получить текущего агента для сессии
  ///
  /// GET /agents/{sessionId}/current
  Future<CurrentAgentInfo> getCurrentAgent(String sessionId) async {
    final response = await _dio.get('$baseUrl/agents/$sessionId/current');
    return CurrentAgentInfo.fromJson(response.data);
  }

  /// DEPRECATED: Создать новую сессию
  ///
  /// POST /sessions - ОТКЛЮЧЕН на сервере (возвращает 405)
  ///
  /// В новом протоколе сессии создаются автоматически при первом сообщении.
  /// Сервер отправляет session_info чанк с ID созданной сессии.
  ///
  /// Этот метод оставлен для совместимости, но больше не используется.
  @Deprecated('Use auto-create via /agent/message/stream without session_id')
  Future<Map<String, dynamic>> createSession() async {
    throw UnimplementedError(
      'POST /sessions is disabled. Sessions are now created automatically '
      'when sending the first message without session_id.',
    );
    // final response = await _dio.post('$baseUrl/sessions');
    // return response.data as Map<String, dynamic>;
  }

  /// Получить ожидающие подтверждения для сессии
  ///
  /// GET /sessions/{sessionId}/pending-approvals
  Future<PendingApprovalsResponse> getPendingApprovals(String sessionId) async {
    final response = await _dio.get(
      '$baseUrl/sessions/$sessionId/pending-approvals',
    );
    return PendingApprovalsResponse.fromJson(
        response.data as Map<String, dynamic>);
  }
}
