// Data layer exceptions
// Эти исключения выбрасываются в data sources и конвертируются в Failures в repositories

/// Базовое исключение для data слоя
abstract class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Ошибка сервера (5xx, внутренние ошибки backend)
class ServerException extends AppException {
  const ServerException(super.message, [super.cause]);
}

/// Ошибка сети (нет соединения, timeout)
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// Ошибка кеша (локальное хранилище)
class CacheException extends AppException {
  const CacheException(super.message, [super.cause]);
}

/// Ошибка валидации данных
class ValidationException extends AppException {
  const ValidationException(super.message, [super.cause]);
}

/// Ресурс не найден (404)
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.cause]);
}

/// Ошибка авторизации (401, 403)
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, [super.cause]);
}

/// Ошибка выполнения инструмента
class ToolExecutionException extends AppException {
  final String code;

  const ToolExecutionException({
    required this.code,
    required String message,
    Object? cause,
  }) : super(message, cause);

  @override
  String toString() => 'ToolExecutionException($code): $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Ошибка парсинга данных
class ParseException extends AppException {
  const ParseException(super.message, [super.cause]);
}

/// Ошибка WebSocket соединения
class WebSocketException extends AppException {
  const WebSocketException(super.message, [super.cause]);
}
