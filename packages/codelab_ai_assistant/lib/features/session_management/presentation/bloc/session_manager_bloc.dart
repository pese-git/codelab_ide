// BLoC для управления сессиями (Presentation слой)
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/session.dart';
import '../../domain/usecases/create_session.dart';
import '../../domain/usecases/load_session.dart';
import '../../domain/usecases/list_sessions.dart';
import '../../domain/usecases/delete_session.dart';

part 'session_manager_bloc.freezed.dart';

/// События для SessionManagerBloc
@freezed
class SessionManagerEvent with _$SessionManagerEvent {
  const factory SessionManagerEvent.loadSessions() = LoadSessions;
  const factory SessionManagerEvent.createSession() = CreateSession;
  const factory SessionManagerEvent.selectSession(String sessionId) =
      SelectSession;
  const factory SessionManagerEvent.deleteSession(String sessionId) =
      DeleteSession;
  const factory SessionManagerEvent.refreshSessions() = RefreshSessions;
}

/// Состояния для SessionManagerBloc
@freezed
sealed class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState.initial() = InitialState;
  const factory SessionManagerState.loading() = LoadingState;
  const factory SessionManagerState.error(String message) = ErrorState;
  const factory SessionManagerState.loaded({
    required List<Session> sessions,
    String? currentSessionId,
    String? currentAgent,
  }) = LoadedState;
  const factory SessionManagerState.sessionSwitched(
    String sessionId,
    Session session,
  ) = SessionSwitchedState;
  const factory SessionManagerState.newSessionCreated(String sessionId) = NewSessionCreatedState;
}

/// BLoC для управления сессиями с использованием Use Cases
///
/// Этот BLoC использует Clean Architecture подход:
/// - Не содержит бизнес-логики (она в Use Cases)
/// - Работает только с domain entities
/// - Обрабатывает Either<Failure, T> из use cases
class SessionManagerBloc
    extends Bloc<SessionManagerEvent, SessionManagerState> {
  final CreateSessionUseCase _createSession;
  final LoadSessionUseCase _loadSession;
  final ListSessionsUseCase _listSessions;
  final DeleteSessionUseCase _deleteSession;
  final Logger _logger;

  SessionManagerBloc({
    required CreateSessionUseCase createSession,
    required LoadSessionUseCase loadSession,
    required ListSessionsUseCase listSessions,
    required DeleteSessionUseCase deleteSession,
    required Logger logger,
  }) : _createSession = createSession,
       _loadSession = loadSession,
       _listSessions = listSessions,
       _deleteSession = deleteSession,
       _logger = logger,
       super(SessionManagerState.initial()) {
    on<LoadSessions>(_onLoadSessions);
    on<CreateSession>(_onCreateSession);
    on<SelectSession>(_onSelectSession);
    on<DeleteSession>(_onDeleteSession);
    on<RefreshSessions>(_onRefreshSessions);
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<SessionManagerState> emit,
  ) async {
    _logger.d('[SessionManagerBloc] 📋 Loading sessions...');
    emit(const SessionManagerState.loading());

    final result = await _listSessions();

    result.fold(
      (failure) {
        _logger.e('[SessionManagerBloc] ❌ Failed to load sessions: ${failure.message}');
        emit(SessionManagerState.error(failure.message));
      },
      (sessions) {
        _logger.i('[SessionManagerBloc] ✅ Loaded ${sessions.length} sessions');
        emit(SessionManagerState.loaded(
          sessions: sessions,
          currentSessionId: null,
          currentAgent: null,
        ));
      },
    );
  }

  Future<void> _onCreateSession(
    CreateSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    _logger.d('[SessionManagerBloc] ➕ Creating new session...');
    emit(const SessionManagerState.loading());

    final result = await _createSession(CreateSessionParams.defaults());

    result.fold(
      (failure) {
        _logger.e('[SessionManagerBloc] ❌ Failed to create session: ${failure.message}');
        emit(SessionManagerState.error(failure.message));
      },
      (session) {
        _logger.i('[SessionManagerBloc] ✅ Created session: ${session.id}');
        // ✅ Эмитим событийное состояние для listener
        emit(SessionManagerState.newSessionCreated(session.id));
        
        // ✅ Сразу перезагружаем список, чтобы вернуться в состояние loaded
        // Это предотвращает застревание UI в состоянии newSessionCreated при resize
        _logger.d('[SessionManagerBloc] 🔄 Reloading sessions after creation');
        add(const SessionManagerEvent.loadSessions());
      },
    );
  }

  Future<void> _onSelectSession(
    SelectSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    _logger.d('[SessionManagerBloc] 🔍 Selecting session: ${event.sessionId}');
    emit(const SessionManagerState.loading());

    final result = await _loadSession(
      LoadSessionParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) {
        _logger.e('[SessionManagerBloc] ❌ Failed to load session: ${failure.message}');
        emit(SessionManagerState.error(failure.message));
      },
      (session) {
        _logger.i('[SessionManagerBloc] ✅ Selected session: ${session.id}');
        // ✅ Эмитим событийное состояние для listener
        emit(SessionManagerState.sessionSwitched(session.id, session));
        
        // ✅ Сразу перезагружаем список, чтобы вернуться в состояние loaded
        // Это предотвращает застревание UI в состоянии sessionSwitched при resize
        _logger.d('[SessionManagerBloc] 🔄 Reloading sessions after selection');
        add(const SessionManagerEvent.loadSessions());
      },
    );
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    _logger.d('[SessionManagerBloc] 🗑️ Deleting session: ${event.sessionId}');
    emit(const SessionManagerState.loading());

    final result = await _deleteSession(
      DeleteSessionParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) {
        _logger.e('[SessionManagerBloc] ❌ Failed to delete session: ${failure.message}');
        emit(SessionManagerState.error(failure.message));
      },
      (_) {
        _logger.i('[SessionManagerBloc] ✅ Deleted session: ${event.sessionId}');
        // Перезагружаем список после удаления
        _logger.d('[SessionManagerBloc] 🔄 Reloading sessions after deletion');
        add(const SessionManagerEvent.loadSessions());
      },
    );
  }

  Future<void> _onRefreshSessions(
    RefreshSessions event,
    Emitter<SessionManagerState> emit,
  ) async {
    _logger.d('[SessionManagerBloc] 🔄 Refreshing sessions...');
    emit(const SessionManagerState.loading());

    final result = await _listSessions();

    result.fold(
      (failure) {
        _logger.e('[SessionManagerBloc] ❌ Failed to refresh sessions: ${failure.message}');
        emit(SessionManagerState.error(failure.message));
      },
      (sessions) {
        _logger.i('[SessionManagerBloc] ✅ Refreshed ${sessions.length} sessions');
        emit(SessionManagerState.loaded(
          sessions: sessions,
          currentSessionId: null,
          currentAgent: null,
        ));
      },
    );
  }
}
