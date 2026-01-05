// Use Case для отправки результата выполнения инструмента
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../repositories/agent_repository.dart';

/// Параметры для отправки результата tool call
class SendToolResultParams {
  final String callId;
  final String toolName;
  final Map<String, dynamic>? result;
  final String? error;

  const SendToolResultParams({
    required this.callId,
    required this.toolName,
    this.result,
    this.error,
  });
}

/// Use Case для отправки результата выполнения инструмента
///
/// Отправляет результат (успешный или с ошибкой) выполнения tool call
/// обратно на сервер для продолжения диалога с LLM.
///
/// Пример использования:
/// ```dart
/// final result = await sendToolResult(SendToolResultParams(
///   callId: 'call_123',
///   toolName: 'read_file',
///   result: {'content': 'file content'},
/// ));
///
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (_) => print('Tool result sent'),
/// );
/// ```
class SendToolResultUseCase implements UseCase<Unit, SendToolResultParams> {
  final AgentRepository _repository;

  SendToolResultUseCase(this._repository);

  @override
  FutureEither<Unit> call(SendToolResultParams params) {
    return _repository.sendToolResult(
      callId: params.callId,
      toolName: params.toolName,
      result: params.result,
      error: params.error,
    );
  }
}
