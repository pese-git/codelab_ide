// DTO модель для tool call (Data слой)
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/tool_call.dart';

part 'tool_call_model.freezed.dart';
part 'tool_call_model.g.dart';

/// DTO модель для сериализации/десериализации tool call
///
/// Используется в data слое для работы с JSON WebSocket сообщениями.
@freezed
abstract class ToolCallModel with _$ToolCallModel {
  const factory ToolCallModel({
    /// Уникальный идентификатор вызова
    // ignore: invalid_annotation_target
    @JsonKey(name: 'call_id') required String callId,

    /// Имя инструмента для выполнения
    // ignore: invalid_annotation_target
    @JsonKey(name: 'tool_name') required String toolName,

    /// Аргументы для инструмента
    required Map<String, dynamic> arguments,

    /// Требуется ли подтверждение пользователя
    // ignore: invalid_annotation_target
    @JsonKey(name: 'requires_approval', defaultValue: false)
    @Default(false)
    bool requiresApproval,
  }) = _ToolCallModel;

  const ToolCallModel._();

  /// Создает модель из JSON
  factory ToolCallModel.fromJson(Map<String, dynamic> json) =>
      _$ToolCallModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  ToolCall toEntity() {
    return ToolCall(
      id: callId,
      toolName: toolName,
      arguments: arguments,
      requiresApproval: requiresApproval,
      createdAt: DateTime.now(),
    );
  }

  /// Создает DTO модель из domain entity
  factory ToolCallModel.fromEntity(ToolCall entity) {
    return ToolCallModel(
      callId: entity.id,
      toolName: entity.toolName,
      arguments: entity.arguments,
      requiresApproval: entity.requiresApproval,
    );
  }
}
