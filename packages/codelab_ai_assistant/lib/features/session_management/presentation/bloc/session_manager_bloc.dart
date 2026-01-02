// BLoC для управления сессиями (Presentation слой)
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/usecases/usecase.dart';
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
abstract class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState({
    required List<Session> sessions,
    required bool isLoading,
    required bool isRefreshing,
    required Option<Session> selectedSession,
    required Option<String> error,
  }) = _SessionManagerState;

  factory SessionManagerState.initial() => SessionManagerState(
    sessions: const [],
    isLoading: false,
    isRefreshing: false,
    selectedSession: none(),
    error: none(),
  );
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
    emit(state.copyWith(isLoading: true, error: none()));

    final result = await _listSessions();

    result.fold(
      (failure) {
        _logger.e('Failed to load sessions: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (sessions) {
        _logger.i('Loaded ${sessions.length} sessions');
        emit(
          state.copyWith(sessions: sessions, isLoading: false, error: none()),
        );
      },
    );
  }

  Future<void> _onCreateSession(
    CreateSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: none()));

    final result = await _createSession(CreateSessionParams.defaults());

    result.fold(
      (failure) {
        _logger.e('Failed to create session: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (session) {
        _logger.i('Created session: ${session.id}');

        // Добавляем новую сессию в список
        final updatedSessions = [session, ...state.sessions];

        emit(
          state.copyWith(
            sessions: updatedSessions,
            selectedSession: some(session),
            isLoading: false,
            error: none(),
          ),
        );
      },
    );
  }

  Future<void> _onSelectSession(
    SelectSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: none()));

    final result = await _loadSession(
      LoadSessionParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) {
        _logger.e('Failed to load session: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (session) {
        _logger.i('Selected session: ${session.id}');
        emit(
          state.copyWith(
            selectedSession: some(session),
            isLoading: false,
            error: none(),
          ),
        );
      },
    );
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<SessionManagerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: none()));

    final result = await _deleteSession(
      DeleteSessionParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) {
        _logger.e('Failed to delete session: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) {
        _logger.i('Deleted session: ${event.sessionId}');

        // Удаляем сессию из списка
        final updatedSessions = state.sessions
            .where((s) => s.id != event.sessionId)
            .toList();

        // Сбрасываем выбранную сессию если она была удалена
        final updatedSelected = state.selectedSession.fold(
          () => none<Session>(),
          (selected) =>
              selected.id == event.sessionId ? none<Session>() : some(selected),
        );

        emit(
          state.copyWith(
            sessions: updatedSessions,
            selectedSession: updatedSelected,
            isLoading: false,
            error: none(),
          ),
        );
      },
    );
  }

  Future<void> _onRefreshSessions(
    RefreshSessions event,
    Emitter<SessionManagerState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, error: none()));

    final result = await _listSessions();

    result.fold(
      (failure) {
        _logger.e('Failed to refresh sessions: ${failure.message}');
        emit(state.copyWith(isRefreshing: false, error: some(failure.message)));
      },
      (sessions) {
        _logger.i('Refreshed ${sessions.length} sessions');
        emit(
          state.copyWith(
            sessions: sessions,
            isRefreshing: false,
            error: none(),
          ),
        );
      },
    );
  }
}
