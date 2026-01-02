import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../api/gateway_api.dart';
import '../models/session_models.dart';

/// Сервис для работы с Gateway REST API
/// 
/// Предоставляет методы для:
/// - Получения истории сессий
/// - Управления сессиями
/// - Получения информации об агентах
class GatewayService {
  final GatewayApi _api;
  final Logger _logger;

  GatewayService({
    required GatewayApi api,
    required Logger logger,
  })  : _api = api,
        _logger = logger;

  /// Получить историю сессии
  /// 
  /// Throws:
  /// - [SessionNotFoundException] если сессия не найдена
  /// - [GatewayException] при других ошибках
  Future<SessionHistory> getSessionHistory(String sessionId) async {
    try {
      _logger.d('Getting session history for: $sessionId');
      final history = await _api.getSessionHistory(sessionId);
      _logger.i('Session history loaded: ${history.messageCount} messages');
      return history;
    } on DioException catch (e) {
      _logger.e('Failed to get session history', error: e);
      
      if (e.response?.statusCode == 404) {
        throw SessionNotFoundException('Session not found: $sessionId');
      }
      
      throw GatewayException(
        'Failed to get session history: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.e('Unexpected error getting session history', error: e);
      throw GatewayException('Unexpected error: $e');
    }
  }

  /// Получить список всех сессий
  /// 
  /// Throws:
  /// - [GatewayException] при ошибках
  Future<SessionListResponse> listSessions() async {
    try {
      _logger.d('Listing all sessions');
      final response = await _api.listSessions();
      _logger.i('Sessions loaded: ${response.total} total');
      return response;
    } on DioException catch (e) {
      _logger.e('Failed to list sessions', error: e);
      throw GatewayException(
        'Failed to list sessions: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.e('Unexpected error listing sessions', error: e);
      throw GatewayException('Unexpected error: $e');
    }
  }

  /// Получить список доступных агентов
  /// 
  /// Throws:
  /// - [GatewayException] при ошибках
  Future<List<AgentInfo>> listAgents() async {
    try {
      _logger.d('Listing available agents');
      final agents = await _api.listAgents();
      _logger.i('Agents loaded: ${agents.length} agents');
      return agents;
    } on DioException catch (e) {
      _logger.e('Failed to list agents', error: e);
      throw GatewayException(
        'Failed to list agents: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.e('Unexpected error listing agents', error: e);
      throw GatewayException('Unexpected error: $e');
    }
  }

  /// Получить текущего агента для сессии
  ///
  /// Throws:
  /// - [SessionNotFoundException] если сессия не найдена
  /// - [GatewayException] при других ошибках
  Future<CurrentAgentInfo> getCurrentAgent(String sessionId) async {
    try {
      _logger.d('Getting current agent for session: $sessionId');
      final agentInfo = await _api.getCurrentAgent(sessionId);
      _logger.i('Current agent: ${agentInfo.currentAgent}');
      return agentInfo;
    } on DioException catch (e) {
      _logger.e('Failed to get current agent', error: e);
      
      if (e.response?.statusCode == 404) {
        throw SessionNotFoundException('Session not found: $sessionId');
      }
      
      throw GatewayException(
        'Failed to get current agent: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.e('Unexpected error getting current agent', error: e);
      throw GatewayException('Unexpected error: $e');
    }
  }

  /// Создать новую сессию на сервере
  ///
  /// Returns: session_id созданной сессии
  ///
  /// Throws:
  /// - [GatewayException] при ошибках
  Future<String> createSession() async {
    try {
      _logger.i('Creating new session on server');
      final response = await _api.createSession();
      final sessionId = response['session_id'] as String;
      _logger.i('Session created: $sessionId');
      return sessionId;
    } on DioException catch (e) {
      _logger.e('Failed to create session', error: e);
      throw GatewayException(
        'Failed to create session: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.e('Unexpected error creating session', error: e);
      throw GatewayException('Unexpected error: $e');
    }
  }
}

/// Исключение при работе с Gateway API
class GatewayException implements Exception {
  final String message;
  final int? statusCode;

  GatewayException(this.message, {this.statusCode});

  @override
  String toString() => 'GatewayException: $message (status: $statusCode)';
}

/// Исключение когда сессия не найдена
class SessionNotFoundException implements Exception {
  final String message;

  SessionNotFoundException(this.message);

  @override
  String toString() => 'SessionNotFoundException: $message';
}
