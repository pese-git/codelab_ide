// Use case для выполнения инструмента
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../../../../core/error/failures.dart';
import '../entities/tool_call.dart';
import '../entities/tool_result.dart';
import '../entities/tool_approval.dart';
import '../repositories/tool_repository.dart';

/// Use case для выполнения инструмента с поддержкой HITL
/// 
/// Инкапсулирует бизнес-логику выполнения инструмента:
/// 1. Валидация безопасности
/// 2. Запрос подтверждения (если требуется)
/// 3. Выполнение инструмента
class ExecuteToolUseCase implements UseCase<ToolResult, ExecuteToolParams> {
  final ToolRepository _repository;

  ExecuteToolUseCase(this._repository);

  @override
  FutureEither<ToolResult> call(ExecuteToolParams params) async {
    // 1. Валидация безопасности
    final validationResult = _repository.validateSafety(
      ValidateSafetyParams(toolCall: params.toolCall),
    );
    
    return validationResult.fold(
      // Валидация не прошла
      (failure) => Future.value(left(failure)),
      
      // Валидация прошла
      (_) async {
        // 2. Проверяем, требуется ли подтверждение
        if (params.toolCall.requiresApproval) {
          final approvalResult = await _repository.requestApproval(
            RequestApprovalParams(toolCall: params.toolCall),
          );
          
          return approvalResult.fold(
            // Ошибка при запросе подтверждения
            (failure) => left(failure),
            
            // Получили решение пользователя
            (decision) {
              // Проверяем решение
              if (decision.isRejected || decision.isCancelled) {
                return Future.value(
                  left(Failure.userRejected(params.toolCall.toolName)),
                );
              }
              
              // Если аргументы были изменены, обновляем tool call
              final finalToolCall = decision.when(
                approved: () => params.toolCall,
                rejected: (_) => params.toolCall, // Не должно попасть сюда
                modified: (modifiedArgs, _) => params.toolCall.copyWith(
                  arguments: modifiedArgs,
                ),
                cancelled: () => params.toolCall, // Не должно попасть сюда
              );
              
              // 3. Выполняем инструмент
              return _repository.executeToolCall(
                ExecuteToolParams(toolCall: finalToolCall),
              );
            },
          );
        }
        
        // 3. Выполняем инструмент без подтверждения
        return _repository.executeToolCall(params);
      },
    );
  }
}
