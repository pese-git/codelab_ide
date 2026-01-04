// Use case для запроса подтверждения выполнения инструмента
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/tool_call.dart';
import '../entities/tool_approval.dart';
import '../repositories/tool_repository.dart';

/// Use case для запроса подтверждения пользователя (HITL)
/// 
/// Показывает пользователю диалог с информацией об операции
/// и ожидает его решения (approve/reject/modify/cancel).
class RequestApprovalUseCase implements UseCase<ApprovalDecision, RequestApprovalParams> {
  final ToolRepository _repository;

  RequestApprovalUseCase(this._repository);

  @override
  FutureEither<ApprovalDecision> call(RequestApprovalParams params) {
    return _repository.requestApproval(params);
  }
}
