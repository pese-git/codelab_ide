// Use case для очистки настроек сервера
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/type_defs.dart';
import '../repositories/server_settings_repository.dart';

/// Use case для очистки настроек сервера
///
/// Удаляет сохраненные настройки из локального хранилища
class ClearSettingsUseCase implements NoParamsUseCase<Unit> {
  final ServerSettingsRepository _repository;

  ClearSettingsUseCase(this._repository);

  @override
  FutureEither<Unit> call() async {
    return await _repository.clearSettings();
  }
}
