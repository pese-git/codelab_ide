// Repository интерфейс для настроек сервера
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/server_settings.dart';

/// Repository для работы с настройками сервера
///
/// Определяет контракт для работы с настройками базового URL сервера
abstract class ServerSettingsRepository {
  /// Получить текущие настройки сервера
  ///
  /// Возвращает Either с Failure или Option<ServerSettings>
  /// Option используется т.к. настройки могут отсутствовать при первом запуске
  Future<Either<Failure, Option<ServerSettings>>> getSettings();

  /// Сохранить настройки сервера
  ///
  /// Возвращает Either с Failure или Unit при успехе
  Future<Either<Failure, Unit>> saveSettings(ServerSettings settings);

  /// Проверить наличие настроек
  ///
  /// Возвращает true если настройки сохранены
  Future<bool> hasSettings();

  /// Тестировать соединение с сервером
  ///
  /// Проверяет доступность сервера по указанному URL
  /// Возвращает Either с Failure или bool (true если сервер доступен)
  Future<Either<Failure, bool>> testConnection(String baseUrl);

  /// Очистить настройки сервера
  ///
  /// Удаляет сохраненные настройки из локального хранилища
  /// Возвращает Either с Failure или Unit при успехе
  Future<Either<Failure, Unit>> clearSettings();
}
