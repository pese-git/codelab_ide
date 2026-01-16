// Use case для подписки на обновления планов
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/execution_plan.dart';
import '../repositories/agent_repository.dart';

/// Use case для подписки на обновления планов выполнения
/// 
/// Возвращает поток обновлений плана (plan_notification, plan_progress).
/// Клиент может использовать этот поток для отслеживания прогресса.
class WatchPlanUpdatesUseCase implements StreamUseCase<ExecutionPlan, NoParams> {
  final AgentRepository _repository;
  
  const WatchPlanUpdatesUseCase(this._repository);
  
  @override
  StreamEither<ExecutionPlan> call(NoParams params) {
    return _repository.watchPlanUpdates();
  }
}
