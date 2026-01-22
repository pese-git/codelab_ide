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
    @JsonKey(name: 'id') required String id,

    /// Дата и время создания сессии (ISO 8601)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// Дата и время последнего обновления (ISO 8601)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'updated_at') DateTime? updatedAt,

    /// Дата последней активности (ISO 8601) - используется если created_at/updated_at отсутствуют
    // ignore: invalid_annotation_target
    @JsonKey(name: 'last_activity') DateTime? lastActivity,

    /// Текущий активный агент в сессии
    // ignore: invalid_annotation_target
    @JsonKey(name: 'current_agent') String? currentAgent,

    /// Количество сообщений в сессии
    // ignore: invalid_annotation_target
    @JsonKey(name: 'message_count') required int messageCount,

    /// Опциональный заголовок сессии
    String? title,

    /// Опциональное описание сессии
    String? description,

    /// Флаг активности сессии
    // ignore: invalid_annotation_target
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _SessionModel;

  const SessionModel._();

  /// Создает модель из JSON
  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  ///
  /// Преобразует nullable поля в Option<T> для функционального стиля
  Session toEntity() {
    // Используем lastActivity если created_at/updated_at отсутствуют
    final effectiveCreatedAt = createdAt ?? lastActivity ?? DateTime.now();
    final effectiveUpdatedAt = updatedAt ?? lastActivity ?? DateTime.now();

    return Session(
      id: id,
      createdAt: effectiveCreatedAt,
      updatedAt: effectiveUpdatedAt,
      currentAgent:
          currentAgent ?? 'orchestrator', // Default to orchestrator if null
      messageCount: messageCount,
      title: title != null ? some(title!) : none(),
      description: description != null ? some(description!) : none(),
      isActive: isActive ?? true, // Default to true if null
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
      isActive: session.isActive,
    );
  }
}
