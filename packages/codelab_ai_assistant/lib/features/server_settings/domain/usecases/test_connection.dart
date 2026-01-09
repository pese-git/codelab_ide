// Use case для тестирования соединения с сервером
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../repositories/server_settings_repository.dart';

/// Параметры для тестирования соединения
class TestConnectionParams {
  final String baseUrl;

  const TestConnectionParams({required this.baseUrl});
}

/// Use case для тестирования соединения с сервером
///
/// Проверяет доступность сервера по указанному URL
/// Возвращает true если сервер доступен и отвечает на health check
class TestConnectionUseCase implements UseCase<bool, TestConnectionParams> {
  final ServerSettingsRepository _repository;

  TestConnectionUseCase(this._repository);

  @override
  FutureEither<bool> call(TestConnectionParams params) async {
    return await _repository.testConnection(params.baseUrl);
  }
}
