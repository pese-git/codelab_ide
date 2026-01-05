// Use case для загрузки истории сообщений
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/message.dart';
import '../repositories/agent_repository.dart';

/// Use case для загрузки истории сообщений сессии
/// 
/// Загружает все сообщения для указанной сессии.
class LoadHistoryUseCase implements UseCase<List<Message>, LoadHistoryParams> {
  final AgentRepository _repository;

  LoadHistoryUseCase(this._repository);

  @override
  FutureEither<List<Message>> call(LoadHistoryParams params) {
    return _repository.loadHistory(params);
  }
}
