// Типизированные ошибки для UI
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// Типизированная ошибка для отображения в UI
///
/// Преимущества перед String:
/// - Типобезопасность
/// - Exhaustive pattern matching
/// - Дополнительные данные (код, retryable, поля)
/// - Легко локализовать
@freezed
abstract class AppError with _$AppError {
  /// Сетевая ошибка
  const factory AppError.network({
    required String message,
    String? code,
    @Default(true) bool isRetryable,
    Object? originalError,
  }) = NetworkError;

  /// Ошибка авторизации
  const factory AppError.authentication({
    required String message,
    String? code,
    @Default(false) bool isTokenExpired,
  }) = AuthenticationError;

  /// Ошибка валидации
  const factory AppError.validation({
    required String message,
    @Default({}) Map<String, String> fieldErrors,
  }) = ValidationError;

  /// Ошибка сервера
  const factory AppError.server({
    required String message,
    String? code,
    int? statusCode,
  }) = ServerError;

  /// Неизвестная ошибка
  const factory AppError.unknown({
    required String message,
    Object? originalError,
    StackTrace? stackTrace,
  }) = UnknownError;

  const AppError._();

  /// Получить локализованное сообщение
  String getLocalizedMessage() {
    return when(
      network: (msg, code, retryable, original) => 'Ошибка сети: $msg',
      authentication: (msg, code, expired) => expired
          ? 'Сессия истекла. Войдите снова.'
          : 'Ошибка авторизации: $msg',
      validation: (msg, fields) => 'Ошибка валидации: $msg',
      server: (msg, code, status) =>
          'Ошибка сервера${status != null ? " ($status)" : ""}: $msg',
      unknown: (msg, original, stack) => 'Неизвестная ошибка: $msg',
    );
  }

  /// Можно ли повторить операцию
  bool get isRetryable {
    return when(
      network: (msg, code, retryable, original) => retryable,
      authentication: (msg, code, expired) => false,
      validation: (msg, fields) => false,
      server: (msg, code, status) => status != null && status >= 500,
      unknown: (msg, original, stack) => false,
    );
  }
}
