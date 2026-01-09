// Use case для сохранения настроек сервера
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/server_settings.dart';
import '../repositories/server_settings_repository.dart';

/// Параметры для сохранения настроек
class SaveSettingsParams {
  final ServerSettings settings;

  const SaveSettingsParams({required this.settings});
}

/// Use case для сохранения настроек сервера
///
/// Сохраняет настройки в локальное хранилище
class SaveSettingsUseCase implements UseCase<Unit, SaveSettingsParams> {
  final ServerSettingsRepository _repository;

  SaveSettingsUseCase(this._repository);

  @override
  FutureEither<Unit> call(SaveSettingsParams params) async {
    return await _repository.saveSettings(params.settings);
  }
}
