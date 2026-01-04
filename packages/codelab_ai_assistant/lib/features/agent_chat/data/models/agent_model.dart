// DTO модель для агента (Data слой)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/agent.dart';

part 'agent_model.freezed.dart';
part 'agent_model.g.dart';

/// DTO модель для сериализации/десериализации агента
@freezed
abstract class AgentModel with _$AgentModel {
  const factory AgentModel({
    /// ID агента (тип)
    required String id,

    /// Имя агента
    required String name,

    /// Описание
    required String description,

    /// Иконка
    required String icon,

    /// Доступность
    // ignore: invalid_annotation_target
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,

    /// Возможности
    @Default([]) List<String> capabilities,

    /// Метаданные
    Map<String, dynamic>? metadata,
  }) = _AgentModel;

  const AgentModel._();

  /// Создает модель из JSON
  factory AgentModel.fromJson(Map<String, dynamic> json) =>
      _$AgentModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  Agent toEntity() {
    return Agent(
      id: id,
      name: name,
      description: description,
      icon: icon,
      isAvailable: isAvailable,
      capabilities: capabilities,
      metadata: metadata != null ? some(metadata!) : none(),
    );
  }

  /// Создает DTO модель из domain entity
  factory AgentModel.fromEntity(Agent entity) {
    return AgentModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      isAvailable: entity.isAvailable,
      capabilities: entity.capabilities,
      metadata: entity.metadata?.toNullable(),
    );
  }
}
