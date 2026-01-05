// Domain entity для токена авторизации
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'auth_token.freezed.dart';

/// Domain entity представляющая токен авторизации OAuth2
///
/// Это чистая бизнес-модель, не зависящая от источника данных
@freezed
abstract class AuthToken with _$AuthToken {
  const factory AuthToken({
    /// Access токен для авторизации запросов
    required String accessToken,

    /// Refresh токен для обновления access токена
    required String refreshToken,

    /// Тип токена (обычно "bearer")
    required String tokenType,

    /// Время жизни access токена в секундах
    required int expiresIn,

    /// Опциональные scope (разрешения)
    required Option<String> scope,

    /// Время выдачи токена
    required DateTime issuedAt,
  }) = _AuthToken;

  const AuthToken._();

  /// Проверяет, истек ли токен
  bool get isExpired {
    final expirationTime = issuedAt.add(Duration(seconds: expiresIn));
    return DateTime.now().isAfter(expirationTime);
  }

  /// Проверяет, нужно ли обновить токен (за 5 минут до истечения)
  bool get needsRefresh {
    final refreshTime = issuedAt.add(Duration(seconds: expiresIn - 300));
    return DateTime.now().isAfter(refreshTime);
  }

  /// Время истечения токена
  DateTime get expiresAt {
    return issuedAt.add(Duration(seconds: expiresIn));
  }

  /// Возвращает Authorization заголовок для HTTP запросов
  String get authorizationHeader {
    // Всегда используем "Bearer" с заглавной буквы согласно RFC 6750
    return 'Bearer $accessToken';
  }

  /// Возвращает scope или дефолтное значение
  String get displayScope => scope.getOrElse(() => 'default');
}

/// Параметры для авторизации с паролем (Password Grant)
@freezed
abstract class PasswordGrantParams with _$PasswordGrantParams {
  const factory PasswordGrantParams({
    /// Имя пользователя или email
    required String username,

    /// Пароль пользователя
    required String password,

    /// ID OAuth клиента
    required String clientId,

    /// Опциональные scope (разрешения)
    Option<String>? scope,
  }) = _PasswordGrantParams;

  const PasswordGrantParams._();

  /// Создает параметры с дефолтным clientId
  factory PasswordGrantParams.withDefaults({
    required String username,
    required String password,
    String clientId = 'codelab-flutter-app',
  }) =>
      PasswordGrantParams(
        username: username,
        password: password,
        clientId: clientId,
        scope: none(),
      );
}

/// Параметры для обновления токена (Refresh Token Grant)
@freezed
abstract class RefreshTokenParams with _$RefreshTokenParams {
  const factory RefreshTokenParams({
    /// Refresh токен
    required String refreshToken,

    /// ID OAuth клиента
    required String clientId,
  }) = _RefreshTokenParams;

  const RefreshTokenParams._();

  /// Создает параметры с дефолтным clientId
  factory RefreshTokenParams.withDefaults({
    required String refreshToken,
    String clientId = 'codelab-flutter-app',
  }) =>
      RefreshTokenParams(
        refreshToken: refreshToken,
        clientId: clientId,
      );
}
