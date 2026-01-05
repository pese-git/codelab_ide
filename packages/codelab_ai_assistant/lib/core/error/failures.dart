// Domain layer failures
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Базовый класс для всех ошибок в domain слое
/// Использует sealed class для exhaustive pattern matching
@freezed
sealed class Failure with _$Failure {
  /// Ошибка сервера (5xx, внутренние ошибки backend)
  const factory Failure.server(String message) = ServerFailure;

  /// Ошибка сети (нет соединения, timeout)
  const factory Failure.network(String message) = NetworkFailure;

  /// Ошибка кеша (локальное хранилище)
  const factory Failure.cache(String message) = CacheFailure;

  /// Ошибка валидации (некорректные данные)
  const factory Failure.validation(String message) = ValidationFailure;

  /// Ресурс не найден (404)
  const factory Failure.notFound(String message) = NotFoundFailure;

  /// Ошибка авторизации (401, 403)
  const factory Failure.unauthorized(String message) = UnauthorizedFailure;

  /// Ошибка выполнения инструмента
  const factory Failure.toolExecution({
    required String code,
    required String message,
  }) = ToolExecutionFailure;

  /// Пользователь отклонил операцию
  const factory Failure.userRejected(String operation) = UserRejectedFailure;

  /// Неизвестная ошибка
  const factory Failure.unknown(String message) = UnknownFailure;
}

/// Extension для получения человекочитаемого сообщения
extension FailureX on Failure {
  String get message => when(
        server: (msg) => 'Ошибка сервера: $msg',
        network: (msg) => 'Ошибка сети: $msg',
        cache: (msg) => 'Ошибка кеша: $msg',
        validation: (msg) => 'Ошибка валидации: $msg',
        notFound: (msg) => 'Не найдено: $msg',
        unauthorized: (msg) => 'Ошибка авторизации: $msg',
        toolExecution: (code, msg) => 'Ошибка выполнения [$code]: $msg',
        userRejected: (op) => 'Операция отклонена: $op',
        unknown: (msg) => 'Неизвестная ошибка: $msg',
      );
}
