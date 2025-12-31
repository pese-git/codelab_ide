import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logger/logger.dart';
import '../models/session_models.dart';
import '../services/session_restore_service.dart';

part 'session_manager_bloc.freezed.dart';

/// Events для управления сессиями
@freezed
class SessionManagerEvent with _$SessionManagerEvent {
  const factory SessionManagerEvent.loadSessions() = LoadSessions;
  const factory SessionManagerEvent.createNewSession() = CreateNewSession;
  const factory SessionManagerEvent.switchToSession(String sessionId) = SwitchToSession;
  const factory SessionManagerEvent.deleteSession(String sessionId) = DeleteSession;
  const factory SessionManagerEvent.refreshCurrentSession() = RefreshCurrentSession;
}

/// States для управления сессиями
@freezed
class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState.initial() = _Initial;
  
  const factory SessionManagerState.loading() = _Loading;
  
  const factory SessionManagerState.loaded({
    required List<SessionInfo> sessions,
    required String? currentSessionId,
    String? currentAgent,
  }) = _Loaded;
  
  const factory SessionManagerState.error(String message) = _Error;
  
  const factory SessionManagerState.sessionSwitched({
    required String sessionId,
    required SessionHistory history,
  }) = _SessionSwitched;
}

/// BLoC для управления сессиями
class SessionManagerBloc extends Bloc<SessionManagerEvent, SessionManagerState> {
  final SessionRestoreService _sessionService;
  final Logger _logger;

  SessionManagerBloc({
    required SessionRestoreService sessionService,
    required Logger logger,
  })  : _sessionService = sessionService,
        _logger = logger,
        super(const SessionManagerState.initial()) {
    on<LoadSessions>(_onLoadSessions);
    on<CreateNewSession>(_onCreateNewSession);
    on<SwitchToSession>(_onSwitchToSession);
    on<DeleteSession>(_onDeleteSession);
    on<RefreshCurrentSession>(_onRefreshCurrentSession);
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<SessionManagerState> emit,
  ) async {
    emit(const SessionManagerState.loading());

    try {
      _logger.d('Loading sessions list');
      final response = await _sessionService.listAllSessions();
      
      emit(SessionManagerState.loaded(
        sessions: response.sessions,
        currentSessionId: _sessionService.currentSessionId,
        currentAgent: _sessionService.currentAgent,
      ));
      
      _logger.i('Loaded ${response.sessions.length} sessions');
    } catch (e) {
      _logger.e('Error loading sessions', error: e);
      emit(SessionManagerState.error(e.toString()));
    }
  }

  Future<void> _onCreateNewSession(
    CreateNewSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    try {
      _logger.i('Creating new session');
      await _sessionService.resetSession();
      
      // Перезагрузить список сессий
      add(const SessionManagerEvent.loadSessions());
      
      _logger.i('New session created: ${_sessionService.currentSessionId}');
    } catch (e) {
      _logger.e('Error creating new session', error: e);
      emit(SessionManagerState.error(e.toString()));
    }
  }

  Future<void> _onSwitchToSession(
    SwitchToSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    try {
      _logger.i('Switching to session: ${event.sessionId}');
      
      final history = await _sessionService.switchToSession(event.sessionId);
      
      if (history != null) {
        emit(SessionManagerState.sessionSwitched(
          sessionId: event.sessionId,
          history: history,
        ));
        
        _logger.i('Switched to session: ${event.sessionId}, ${history.messageCount} messages');
        
        // Перезагрузить список сессий
        add(const SessionManagerEvent.loadSessions());
      } else {
        throw Exception('Failed to load session history');
      }
    } catch (e) {
      _logger.e('Error switching session', error: e);
      emit(SessionManagerState.error(e.toString()));
    }
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    try {
      _logger.i('Deleting session: ${event.sessionId}');
      
      // TODO: Добавить DELETE endpoint в Gateway API
      _logger.w('Delete session not implemented yet');
      
      // Перезагрузить список сессий
      add(const SessionManagerEvent.loadSessions());
    } catch (e) {
      _logger.e('Error deleting session', error: e);
      emit(SessionManagerState.error(e.toString()));
    }
  }

  Future<void> _onRefreshCurrentSession(
    RefreshCurrentSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    try {
      _logger.d('Refreshing current session info');
      
      final agentInfo = await _sessionService.getCurrentAgentInfo();
      
      if (agentInfo != null) {
        _logger.i('Current agent: ${agentInfo.currentAgent}');
      }
      
      // Перезагрузить список сессий
      add(const SessionManagerEvent.loadSessions());
    } catch (e) {
      _logger.e('Error refreshing current session', error: e);
      emit(SessionManagerState.error(e.toString()));
    }
  }
}
