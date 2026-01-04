// Domain entity для вызова инструмента
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_call.freezed.dart';

/// Domain entity представляющая вызов инструмента
///
/// Это чистая бизнес-модель, не зависящая от источника данных
@freezed
abstract class ToolCall with _$ToolCall {
  const factory ToolCall({
    /// Уникальный идентификатор вызова
    required String id,

    /// Имя инструмента для выполнения
    required String toolName,

    /// Аргументы для инструмента
    required Map<String, dynamic> arguments,

    /// Требуется ли подтверждение пользователя (HITL)
    required bool requiresApproval,

    /// Timestamp создания вызова
    required DateTime createdAt,
  }) = _ToolCall;

  const ToolCall._();

  /// Проверяет, является ли инструмент безопасным (не требует HITL)
  bool get isSafe => !requiresApproval;

  /// Проверяет, является ли это файловая операция
  bool get isFileOperation {
    return toolName == 'read_file' ||
        toolName == 'write_file' ||
        toolName == 'list_files' ||
        toolName == 'create_directory';
  }

  /// Проверяет, является ли это команда
  bool get isCommand => toolName == 'run_command';

  /// Проверяет, является ли это поиск в коде
  bool get isSearch => toolName == 'search_in_code';

  /// Получает путь из аргументов (если есть)
  String? get path {
    final pathArg = arguments['path'];
    return pathArg is String ? pathArg : null;
  }

  /// Получает команду из аргументов (для run_command)
  String? get command {
    final cmdArg = arguments['command'];
    return cmdArg is String ? cmdArg : null;
  }
}

/// Параметры для выполнения инструмента
@freezed
abstract class ExecuteToolParams with _$ExecuteToolParams {
  const factory ExecuteToolParams({
    /// Tool call для выполнения
    required ToolCall toolCall,
  }) = _ExecuteToolParams;
}

/// Параметры для запроса подтверждения
@freezed
abstract class RequestApprovalParams with _$RequestApprovalParams {
  const factory RequestApprovalParams({
    /// Tool call требующий подтверждения
    required ToolCall toolCall,
  }) = _RequestApprovalParams;
}

/// Параметры для валидации безопасности
@freezed
abstract class ValidateSafetyParams with _$ValidateSafetyParams {
  const factory ValidateSafetyParams({
    /// Tool call для проверки
    required ToolCall toolCall,
  }) = _ValidateSafetyParams;
}
