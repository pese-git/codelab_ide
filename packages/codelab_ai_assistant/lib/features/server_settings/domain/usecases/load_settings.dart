// Use case для загрузки настроек сервера
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/server_settings.dart';
import '../repositories/server_settings_repository.dart';

/// Use case для загрузки настроек сервера
///
/// Получает сохраненные настройки из репозитория
/// Возвращает Option<ServerSettings> т.к. настройки могут отсутствовать при первом запуске
class LoadSettingsUseCase implements NoParamsUseCase<Option<ServerSettings>> {
  final ServerSettingsRepository _repository;

  LoadSettingsUseCase(this._repository);

  @override
  FutureEither<Option<ServerSettings>> call() async {
    return await _repository.getSettings();
  }
}
