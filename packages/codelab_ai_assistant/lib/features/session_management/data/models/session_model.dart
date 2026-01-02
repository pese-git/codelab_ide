// DTO модель для сессии (Data слой)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/session.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

/// DTO модель для сериализации/десериализации сессии
///
/// Используется в data слое для работы с JSON API и локальным хранилищем.
/// Конвертируется в domain entity через метод toEntity().
@freezed
abstract class SessionModel with _$SessionModel {
  const factory SessionModel({
    /// Уникальный идентификатор сессии
    // ignore: invalid_annotation_target
    @JsonKey(name: 'session_id') required String id,

    /// Дата и время создания сессии (ISO 8601)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Дата и время последнего обновления (ISO 8601)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'updated_at') required DateTime updatedAt,

    /// Текущий активный агент в сессии
    // ignore: invalid_annotation_target
    @JsonKey(name: 'current_agent') required String currentAgent,

    /// Количество сообщений в сессии
    // ignore: invalid_annotation_target
    @JsonKey(name: 'message_count') required int messageCount,

    /// Опциональный заголовок сессии
    String? title,

    /// Опциональное описание сессии
    String? description,
  }) = _SessionModel;

  const SessionModel._();

  /// Создает модель из JSON
  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  ///
  /// Преобразует nullable поля в Option<T> для функционального стиля
  Session toEntity() {
    return Session(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      currentAgent: currentAgent,
      messageCount: messageCount,
      title: title != null ? some(title!) : none(),
      description: description != null ? some(description!) : none(),
    );
  }

  /// Создает DTO модель из domain entity
  ///
  /// Преобразует Option<T> в nullable поля для JSON сериализации
  factory SessionModel.fromEntity(Session session) {
    return SessionModel(
      id: session.id,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      currentAgent: session.currentAgent,
      messageCount: session.messageCount,
      title: session.title.toNullable(),
      description: session.description.toNullable(),
    );
  }
}
