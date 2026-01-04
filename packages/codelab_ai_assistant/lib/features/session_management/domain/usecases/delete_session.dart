// Use case для удаления сессии
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Use case для удаления сессии
/// 
/// Удаляет сессию как из удаленного хранилища, так и из локального кеша.
class DeleteSessionUseCase implements UseCase<Unit, DeleteSessionParams> {
  final SessionRepository _repository;

  DeleteSessionUseCase(this._repository);

  @override
  FutureEither<Unit> call(DeleteSessionParams params) {
    return _repository.deleteSession(params);
  }
}
