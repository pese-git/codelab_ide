// Repository interface для выполнения инструментов
import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/tool_call.dart';
import '../entities/tool_result.dart';
import '../entities/tool_approval.dart';

/// Интерфейс репозитория для выполнения инструментов
/// 
/// Определяет контракт для работы с инструментами, не зависящий от реализации.
/// Реализация находится в data слое.
abstract class ToolRepository {
  /// Выполняет tool call
  /// 
  /// Возвращает [Right] с результатом или [Left] с ошибкой
  FutureEither<ToolResult> executeToolCall(ExecuteToolParams params);
  
  /// Запрашивает подтверждение пользователя для выполнения tool call
  /// 
  /// Возвращает [Right] с решением пользователя или [Left] с ошибкой
  FutureEither<ApprovalDecision> requestApproval(RequestApprovalParams params);
  
  /// Валидирует безопасность tool call
  /// 
  /// Возвращает [Right] с Unit при успехе или [Left] с ошибкой валидации
  SyncEither<Unit> validateSafety(ValidateSafetyParams params);
  
  /// Проверяет, требует ли инструмент подтверждения
  /// 
  /// Возвращает true если требуется HITL подтверждение
  bool requiresApproval(ToolCall toolCall);
  
  /// Получает список поддерживаемых инструментов
  /// 
  /// Возвращает [Right] со списком имен инструментов или [Left] с ошибкой
  FutureEither<List<String>> getSupportedTools();
}
