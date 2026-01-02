// Use case для загрузки сессии
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Use case для загрузки существующей сессии по ID
/// 
/// Загружает сессию из удаленного источника и кеширует локально.
class LoadSessionUseCase implements UseCase<Session, LoadSessionParams> {
  final SessionRepository _repository;

  LoadSessionUseCase(this._repository);

  @override
  FutureEither<Session> call(LoadSessionParams params) {
    return _repository.loadSession(params);
  }
}
