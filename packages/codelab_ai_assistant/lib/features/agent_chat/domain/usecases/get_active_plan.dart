// Use case для получения активного плана выполнения
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/execution_plan.dart';
import '../repositories/agent_repository.dart';

/// Use case для получения активного плана выполнения
/// 
/// Возвращает текущий активный план, если он существует.
/// Используется для отображения прогресса выполнения плана в UI.
class GetActivePlanUseCase implements UseCase<Option<ExecutionPlan>, NoParams> {
  final AgentRepository _repository;
  
  const GetActivePlanUseCase(this._repository);
  
  @override
  Future<Either<Failure, Option<ExecutionPlan>>> call(NoParams params) async {
    return _repository.getActivePlan();
  }
}
