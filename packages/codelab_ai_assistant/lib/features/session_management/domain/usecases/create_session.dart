// Use case для создания новой сессии
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Use case для создания новой сессии чата
/// 
/// Инкапсулирует бизнес-логику создания сессии.
/// Использует [SessionRepository] для выполнения операции.
class CreateSessionUseCase implements UseCase<Session, CreateSessionParams> {
  final SessionRepository _repository;

  CreateSessionUseCase(this._repository);

  @override
  FutureEither<Session> call(CreateSessionParams params) {
    return _repository.createSession(params);
  }
}
