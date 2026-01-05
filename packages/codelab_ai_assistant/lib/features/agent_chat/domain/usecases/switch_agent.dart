// Use case для переключения агента
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/message.dart';
import '../repositories/agent_repository.dart';

/// Use case для переключения текущего агента
/// 
/// Отправляет запрос на переключение агента через WebSocket.
class SwitchAgentUseCase implements UseCase<Unit, SwitchAgentParams> {
  final AgentRepository _repository;

  SwitchAgentUseCase(this._repository);

  @override
  FutureEither<Unit> call(SwitchAgentParams params) {
    return _repository.switchAgent(params);
  }
}
