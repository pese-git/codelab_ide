// Use case для отправки решения по плану
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/message.dart';
import '../repositories/agent_repository.dart';

/// Use case для отправки решения пользователя по плану выполнения
/// 
/// Инкапсулирует бизнес-логику отправки решения (approve/reject/modify)
/// через WebSocket на backend.
class SendPlanDecisionUseCase implements UseCase<Unit, SendPlanDecisionParams> {
  final AgentRepository _repository;

  SendPlanDecisionUseCase(this._repository);

  @override
  FutureEither<Unit> call(SendPlanDecisionParams params) {
    return _repository.sendPlanDecision(params);
  }
}
