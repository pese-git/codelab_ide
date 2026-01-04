// Use case для подключения к WebSocket
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../repositories/agent_repository.dart';

/// Параметры для подключения
class ConnectParams {
  final String sessionId;
  
  const ConnectParams({required this.sessionId});
}

/// Use case для подключения к WebSocket с указанной сессией
class ConnectUseCase implements UseCase<Unit, ConnectParams> {
  final AgentRepository _repository;

  ConnectUseCase(this._repository);

  @override
  FutureEither<Unit> call(ConnectParams params) {
    return _repository.connect(params.sessionId);
  }
}
