// Use case для отправки сообщения
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/message.dart';
import '../repositories/agent_repository.dart';

/// Use case для отправки сообщения пользователя агенту
/// 
/// Инкапсулирует бизнес-логику отправки сообщения через WebSocket.
class SendMessageUseCase implements UseCase<Unit, SendMessageParams> {
  final AgentRepository _repository;

  SendMessageUseCase(this._repository);

  @override
  FutureEither<Unit> call(SendMessageParams params) {
    return _repository.sendMessage(params);
  }
}
