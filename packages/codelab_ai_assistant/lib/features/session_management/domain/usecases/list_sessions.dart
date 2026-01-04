// Use case для получения списка сессий
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

/// Use case для получения списка всех сессий
/// 
/// Возвращает список сессий, отсортированный по дате обновления (новые первыми).
class ListSessionsUseCase implements NoParamsUseCase<List<Session>> {
  final SessionRepository _repository;

  ListSessionsUseCase(this._repository);

  @override
  FutureEither<List<Session>> call() {
    return _repository.listSessions();
  }
}
