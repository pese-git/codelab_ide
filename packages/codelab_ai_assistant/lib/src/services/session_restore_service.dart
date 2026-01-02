import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_models.dart';
import 'gateway_service.dart';

/// Сервис для восстановления сессий при запуске приложения
/// 
/// Использует SharedPreferences для хранения текущего session_id
/// и Gateway API для восстановления истории сообщений.
class SessionRestoreService {
  static const String _sessionIdKey = 'current_session_id';
  static const String _lastAgentKey = 'last_agent_type';

  final GatewayService _gatewayService;
  final SharedPreferences _prefs;
  final Logger _logger;

  String? _currentSessionId;
  String? _currentAgent;

  SessionRestoreService({
    required GatewayService gatewayService,
    required SharedPreferences prefs,
    required Logger logger,
  })  : _gatewayService = gatewayService,
        _prefs = prefs,
        _logger = logger;

  /// Инициализация - восстановление или создание сессии
  /// 
  /// Returns: SessionHistory если сессия восстановлена, null если создана новая
  Future<SessionHistory?> initialize() async {
    _logger.i('Initializing session restore service');
    
    _currentSessionId = _prefs.getString(_sessionIdKey);
    _currentAgent = _prefs.getString(_lastAgentKey);

    if (_currentSessionId != null) {
      _logger.d('Found saved session ID: $_currentSessionId');
      
      final restored = await restoreSession(_currentSessionId!);
      if (restored != null) {
        _logger.i('Session restored successfully: ${restored.messageCount} messages');
        return restored;
      } else {
        _logger.w('Failed to restore session, creating new one');
        await createNewSession();
        return null;
      }
    } else {
      _logger.i('No saved session found, creating new one');
      await createNewSession();
      return null;
    }
  }

  /// Восстановить сессию из базы данных через Gateway API
  /// 
  /// Returns: SessionHistory если успешно, null если сессия не найдена
  Future<SessionHistory?> restoreSession(String sessionId) async {
    try {
      _logger.d('Attempting to restore session: $sessionId');
      
      final history = await _gatewayService.getSessionHistory(sessionId);
      
      _logger.i(
        'Session restored: ${history.messageCount} messages, '
        'current agent: ${history.currentAgent ?? "N/A"}',
      );
      
      // Сохранить текущего агента
      if (history.currentAgent != null) {
        _currentAgent = history.currentAgent;
        await _prefs.setString(_lastAgentKey, history.currentAgent!);
      }
      
      return history;
    } on SessionNotFoundException catch (e) {
      _logger.w('Session not found: $e');
      return null;
    } on GatewayException catch (e) {
      _logger.e('Gateway error restoring session: $e');
      return null;
    } catch (e) {
      _logger.e('Unexpected error restoring session', error: e);
      return null;
    }
  }

  /// Создать новую сессию на сервере
  Future<void> createNewSession() async {
    try {
      // Создать сессию на сервере через Gateway API
      _currentSessionId = await _gatewayService.createSession();
      _currentAgent = 'orchestrator'; // По умолчанию начинаем с orchestrator
      
      await _prefs.setString(_sessionIdKey, _currentSessionId!);
      await _prefs.setString(_lastAgentKey, _currentAgent!);
      
      _logger.i('Created new session on server: $_currentSessionId');
    } catch (e) {
      _logger.e('Failed to create session on server, falling back to local', error: e);
      // Fallback: создать локально если сервер недоступен
      _currentSessionId = _generateSessionId();
      _currentAgent = 'orchestrator';
      
      await _prefs.setString(_sessionIdKey, _currentSessionId!);
      await _prefs.setString(_lastAgentKey, _currentAgent!);
      
      _logger.w('Created local session (fallback): $_currentSessionId');
    }
  }

  /// Получить текущий session_id
  String? get currentSessionId => _currentSessionId;

  /// Получить текущего агента
  String? get currentAgent => _currentAgent;

  /// Обновить текущего агента
  Future<void> updateCurrentAgent(String agentType) async {
    _currentAgent = agentType;
    await _prefs.setString(_lastAgentKey, agentType);
    _logger.d('Updated current agent to: $agentType');
  }

  /// Получить список всех сессий
  Future<SessionListResponse> listAllSessions() async {
    try {
      return await _gatewayService.listSessions();
    } catch (e) {
      _logger.e('Error listing sessions', error: e);
      rethrow;
    }
  }

  /// Получить полную историю текущей сессии
  Future<SessionHistory?> getCurrentSessionHistory() async {
    if (_currentSessionId == null) {
      _logger.w('No current session ID');
      return null;
    }

    try {
      return await _gatewayService.getSessionHistory(_currentSessionId!);
    } catch (e) {
      _logger.e('Error getting current session history', error: e);
      return null;
    }
  }

  /// Получить информацию о текущем агенте
  Future<CurrentAgentInfo?> getCurrentAgentInfo() async {
    if (_currentSessionId == null) {
      _logger.w('No current session ID');
      return null;
    }

    try {
      final agentInfo = await _gatewayService.getCurrentAgent(_currentSessionId!);
      
      // Обновить локальное состояние
      await updateCurrentAgent(agentInfo.currentAgent);
      
      return agentInfo;
    } catch (e) {
      _logger.e('Error getting current agent info', error: e);
      return null;
    }
  }

  /// Сбросить текущую сессию (создать новую)
  Future<void> resetSession() async {
    _logger.i('Resetting session');
    await createNewSession();
  }

  /// Переключиться на другую сессию
  Future<SessionHistory?> switchToSession(String sessionId) async {
    _logger.i('Switching to session: $sessionId');
    
    final history = await restoreSession(sessionId);
    if (history != null) {
      _currentSessionId = sessionId;
      await _prefs.setString(_sessionIdKey, sessionId);
      return history;
    }
    
    return null;
  }

  /// Генерация уникального session_id
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}
