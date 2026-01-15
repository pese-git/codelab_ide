// Use case для подтверждения плана выполнения
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/agent_repository.dart';

/// Параметры для подтверждения плана
class ApprovePlanParams {
  /// ID плана для подтверждения
  final String planId;
  
  /// Опциональная обратная связь от пользователя
  final Option<String> feedback;
  
  const ApprovePlanParams({
    required this.planId,
    this.feedback = const None(),
  });
}

/// Use case для подтверждения плана выполнения
/// 
/// Отправляет подтверждение плана на сервер, после чего
/// начинается выполнение подзадач.
class ApprovePlanUseCase implements UseCase<void, ApprovePlanParams> {
  final AgentRepository _repository;
  
  const ApprovePlanUseCase(this._repository);
  
  @override
  Future<Either<Failure, void>> call(ApprovePlanParams params) async {
    return _repository.approvePlan(
      planId: params.planId,
      feedback: params.feedback,
    );
  }
}
