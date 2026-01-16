// Use case для отклонения плана выполнения
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/agent_repository.dart';

/// Параметры для отклонения плана
class RejectPlanParams {
  /// ID плана для отклонения
  final String planId;
  
  /// Причина отклонения
  final String reason;
  
  const RejectPlanParams({
    required this.planId,
    required this.reason,
  });
}

/// Use case для отклонения плана выполнения
/// 
/// Отправляет отклонение плана на сервер.
/// После отклонения Orchestrator может предложить альтернативный подход.
class RejectPlanUseCase implements UseCase<void, RejectPlanParams> {
  final AgentRepository _repository;
  
  const RejectPlanUseCase(this._repository);
  
  @override
  Future<Either<Failure, void>> call(RejectPlanParams params) async {
    return _repository.rejectPlan(
      planId: params.planId,
      reason: params.reason,
    );
  }
}
