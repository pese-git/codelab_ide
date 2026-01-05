// BLoC для управления состоянием авторизации
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_bloc.freezed.dart';

/// События авторизации
@freezed
class AuthEvent with _$AuthEvent {
  /// Проверить статус авторизации
  const factory AuthEvent.checkAuthStatus() = CheckAuthStatus;

  /// Авторизоваться с паролем
  const factory AuthEvent.login({
    required String username,
    required String password,
  }) = Login;

  /// Выйти из системы
  const factory AuthEvent.logout() = Logout;

  /// Обновить токен
  const factory AuthEvent.refreshToken() = RefreshTokenEvent;
}

/// Состояния авторизации
@freezed
class AuthState with _$AuthState {
  /// Начальное состояние
  const factory AuthState.initial() = AuthInitial;

  /// Проверка авторизации
  const factory AuthState.checking() = AuthChecking;

  /// Пользователь авторизован
  const factory AuthState.authenticated({
    required AuthToken token,
  }) = Authenticated;

  /// Пользователь не авторизован
  const factory AuthState.unauthenticated() = Unauthenticated;

  /// Процесс авторизации
  const factory AuthState.authenticating() = Authenticating;

  /// Ошибка авторизации
  const factory AuthState.error({
    required String message,
  }) = AuthError;
}

/// BLoC для управления авторизацией
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final Logger _logger;
  StreamSubscription<void>? _tokenExpiredSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required Logger logger,
    Stream<void>? tokenExpiredStream,
  })  : _authRepository = authRepository,
        _logger = logger,
        super(const AuthState.initial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<Login>(_onLogin);
    on<Logout>(_onLogout);
    on<RefreshTokenEvent>(_onRefreshToken);

    // Подписываемся на события истечения токена
    if (tokenExpiredStream != null) {
      _tokenExpiredSubscription = tokenExpiredStream.listen((_) {
        _logger.w('[AuthBloc] Token expired, checking auth status');
        add(const AuthEvent.checkAuthStatus());
      });
    }
  }

  @override
  Future<void> close() {
    _tokenExpiredSubscription?.cancel();
    return super.close();
  }

  /// Проверить статус авторизации
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    _logger.d('[AuthBloc] Checking auth status...');
    emit(const AuthState.checking());

    try {
      final isAuth = await _authRepository.isAuthenticated();

      if (isAuth) {
        // Получаем токен
        final result = await _authRepository.getStoredToken();

        result.fold(
          (failure) {
            _logger.w('[AuthBloc] Failed to get stored token: ${failure.message}');
            emit(const AuthState.unauthenticated());
          },
          (tokenOption) {
            tokenOption.fold(
              () {
                _logger.d('[AuthBloc] No token found');
                emit(const AuthState.unauthenticated());
              },
              (token) {
                _logger.i('[AuthBloc] User is authenticated');
                emit(AuthState.authenticated(token: token));
              },
            );
          },
        );
      } else {
        _logger.d('[AuthBloc] User is not authenticated');
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      _logger.e('[AuthBloc] Error checking auth status: $e');
      emit(const AuthState.unauthenticated());
    }
  }

  /// Авторизоваться
  Future<void> _onLogin(
    Login event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('[AuthBloc] Logging in user: ${event.username}');
    emit(const AuthState.authenticating());

    final params = PasswordGrantParams.withDefaults(
      username: event.username,
      password: event.password,
    );

    final result = await _authRepository.loginWithPassword(params);

    result.fold(
      (failure) {
        _logger.e('[AuthBloc] Login failed: ${failure.message}');
        emit(AuthState.error(message: failure.message));
        // Возвращаемся в unauthenticated после ошибки
        Future.delayed(const Duration(seconds: 3), () {
          if (!isClosed) {
            emit(const AuthState.unauthenticated());
          }
        });
      },
      (token) {
        _logger.i('[AuthBloc] Login successful');
        emit(AuthState.authenticated(token: token));
      },
    );
  }

  /// Выйти из системы
  Future<void> _onLogout(
    Logout event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('[AuthBloc] Logging out...');

    final result = await _authRepository.clearToken();

    result.fold(
      (failure) {
        _logger.e('[AuthBloc] Logout failed: ${failure.message}');
        // Все равно переходим в unauthenticated
        emit(const AuthState.unauthenticated());
      },
      (_) {
        _logger.i('[AuthBloc] Logout successful');
        emit(const AuthState.unauthenticated());
      },
    );
  }

  /// Обновить токен
  Future<void> _onRefreshToken(
    RefreshTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    _logger.d('[AuthBloc] Refreshing token...');

    // Получаем текущий токен
    final tokenResult = await _authRepository.getStoredToken();

    await tokenResult.fold(
      (failure) async {
        _logger.e('[AuthBloc] Failed to get token for refresh: ${failure.message}');
        emit(const AuthState.unauthenticated());
      },
      (tokenOption) async {
        await tokenOption.fold(
          () async {
            _logger.w('[AuthBloc] No token to refresh');
            emit(const AuthState.unauthenticated());
          },
          (token) async {
            final params = RefreshTokenParams.withDefaults(
              refreshToken: token.refreshToken,
            );

            final result = await _authRepository.refreshToken(params);

            result.fold(
              (failure) {
                _logger.e('[AuthBloc] Token refresh failed: ${failure.message}');
                emit(const AuthState.unauthenticated());
              },
              (newToken) {
                _logger.i('[AuthBloc] Token refreshed successfully');
                emit(AuthState.authenticated(token: newToken));
              },
            );
          },
        );
      },
    );
  }
}
