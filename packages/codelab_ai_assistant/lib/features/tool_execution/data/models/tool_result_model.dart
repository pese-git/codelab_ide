// DTO модель для tool result (Data слой)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/tool_result.dart';

part 'tool_result_model.freezed.dart';
part 'tool_result_model.g.dart';

/// DTO модель для сериализации/десериализации результата выполнения инструмента
@freezed
abstract class ToolResultModel with _$ToolResultModel {
  const factory ToolResultModel({
    /// ID вызова инструмента
    // ignore: invalid_annotation_target
    @JsonKey(name: 'call_id') required String callId,

    /// Имя инструмента
    // ignore: invalid_annotation_target
    @JsonKey(name: 'tool_name') required String toolName,

    /// Успешность выполнения
    required bool success,

    /// Данные результата (если успешно)
    Map<String, dynamic>? result,

    /// Код ошибки (если неуспешно)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'error_code') String? errorCode,

    /// Сообщение об ошибке (если неуспешно)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'error_message') String? errorMessage,

    /// Дополнительные детали ошибки
    Map<String, dynamic>? details,

    /// Время выполнения в миллисекундах
    // ignore: invalid_annotation_target
    @JsonKey(name: 'duration_ms') int? durationMs,
  }) = _ToolResultModel;

  const ToolResultModel._();

  /// Создает модель из JSON
  factory ToolResultModel.fromJson(Map<String, dynamic> json) =>
      _$ToolResultModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  ToolResult toEntity() {
    if (success && result != null) {
      return ToolResult.success(
        callId: callId,
        toolName: toolName,
        data: result!,
        durationMs: durationMs ?? 0,
        completedAt: DateTime.now(),
      );
    } else {
      return ToolResult.failure(
        callId: callId,
        toolName: toolName,
        errorCode: errorCode ?? 'unknown_error',
        errorMessage: errorMessage ?? 'Unknown error occurred',
        details: details != null ? some(details!) : none(),
        failedAt: DateTime.now(),
      );
    }
  }

  /// Создает DTO модель из domain entity
  factory ToolResultModel.fromEntity(ToolResult entity) {
    return entity.when(
      success: (callId, toolName, data, durationMs, completedAt) {
        return ToolResultModel(
          callId: callId,
          toolName: toolName,
          success: true,
          result: data,
          durationMs: durationMs,
        );
      },
      failure: (callId, toolName, errorCode, errorMessage, details, failedAt) {
        return ToolResultModel(
          callId: callId,
          toolName: toolName,
          success: false,
          errorCode: errorCode,
          errorMessage: errorMessage,
          details: details?.toNullable(),
        );
      },
    );
  }
}
