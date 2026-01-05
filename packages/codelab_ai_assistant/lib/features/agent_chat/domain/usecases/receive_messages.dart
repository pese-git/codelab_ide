// Use case для получения потока сообщений
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/message.dart';
import '../repositories/agent_repository.dart';

/// Use case для получения потока входящих сообщений от агента
/// 
/// Возвращает Stream с Either - каждое сообщение может быть успешным или ошибкой.
class ReceiveMessagesUseCase implements StreamUseCase<Message, NoParams> {
  final AgentRepository _repository;

  ReceiveMessagesUseCase(this._repository);

  @override
  StreamEither<Message> call(NoParams params) {
    return _repository.receiveMessages();
  }
}
