import 'package:dio/dio.dart';
import '../models/session_models.dart';

/// API клиент для Gateway Service (только Dio, без Retrofit)
/// 
/// Все запросы идут через Gateway (порт 8000), который проксирует их к Agent Runtime.
/// Gateway автоматически добавляет X-Internal-Auth заголовок.
class GatewayApi {
  final Dio _dio;
  final String baseUrl;

  GatewayApi({
    required Dio dio,
    this.baseUrl = 'http://localhost:8000',
  }) : _dio = dio;

  /// Получить историю сессии
  /// 
  /// GET /sessions/{sessionId}/history
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
    final response = await _dio.get(
      '$baseUrl/sessions',
    );
    return SessionListResponse.fromJson(response.data);
  }

  /// Получить список доступных агентов
  /// 
  /// GET /agents
  Future<List<AgentInfo>> listAgents() async {
    final response = await _dio.get(
      '$baseUrl/agents',
    );
    return (response.data as List)
        .map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Получить текущего агента для сессии
  ///
  /// GET /agents/{sessionId}/current
  Future<CurrentAgentInfo> getCurrentAgent(String sessionId) async {
    final response = await _dio.get(
      '$baseUrl/agents/$sessionId/current',
    );
    return CurrentAgentInfo.fromJson(response.data);
  }

  /// Создать новую сессию
  ///
  /// POST /sessions
  Future<Map<String, dynamic>> createSession() async {
    final response = await _dio.post(
      '$baseUrl/sessions',
    );
    return response.data as Map<String, dynamic>;
  }
}
