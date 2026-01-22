// Domain entity для сессии чата
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'session.freezed.dart';

/// Domain entity представляющая сессию чата с AI агентом
///
/// Это чистая бизнес-модель, не зависящая от источника данных
@freezed
abstract class Session with _$Session {
  const factory Session({
    /// Уникальный идентификатор сессии
    required String id,

    /// Дата и время создания сессии
    required DateTime createdAt,

    /// Дата и время последнего обновления
    required DateTime updatedAt,

    /// Текущий активный агент в сессии
    required String currentAgent,

    /// Количество сообщений в сессии
    required int messageCount,

    /// Опциональный заголовок сессии
    required Option<String> title,

    /// Опциональное описание сессии
    required Option<String> description,

    /// Флаг активности сессии (true - активна, false - неактивна)
    @Default(true) bool isActive,
  }) = _Session;

  const Session._();

  /// Проверяет, является ли сессия пустой (без сообщений)
  bool get isEmpty => messageCount == 0;

  /// Проверяет, есть ли в сессии сообщения
  bool get isNotEmpty => messageCount > 0;

  /// Возвращает заголовок или дефолтное значение
  String get displayTitle => title.getOrElse(() => 'Сессия $id');

  /// Проверяет, была ли сессия обновлена недавно (в течение последнего часа)
  bool get isRecentlyUpdated {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inHours < 1;
  }

  /// Возвращает форматированную дату создания
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    }
  }
}

/// Параметры для создания новой сессии
@freezed
abstract class CreateSessionParams with _$CreateSessionParams {
  const factory CreateSessionParams({
    /// Опциональный заголовок для новой сессии
    Option<String>? title,

    /// Опциональное описание для новой сессии
    Option<String>? description,

    /// Начальный агент (по умолчанию 'orchestrator')
    @Default('orchestrator') String initialAgent,
  }) = _CreateSessionParams;

  const CreateSessionParams._();

  /// Создает параметры по умолчанию
  factory CreateSessionParams.defaults() => CreateSessionParams(
    title: none(),
    description: none(),
    initialAgent: 'orchestrator',
  );
}

/// Параметры для загрузки сессии
@freezed
abstract class LoadSessionParams with _$LoadSessionParams {
  const factory LoadSessionParams({
    /// ID сессии для загрузки
    required String sessionId,
  }) = _LoadSessionParams;
}

/// Параметры для удаления сессии
@freezed
abstract class DeleteSessionParams with _$DeleteSessionParams {
  const factory DeleteSessionParams({
    /// ID сессии для удаления
    required String sessionId,
  }) = _DeleteSessionParams;
}
