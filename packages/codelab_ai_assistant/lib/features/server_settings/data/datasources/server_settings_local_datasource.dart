// Local data source для хранения настроек сервера
import 'package:shared_preferences/shared_preferences.dart';

/// Интерфейс для локального источника данных настроек сервера
abstract class ServerSettingsLocalDataSource {
  /// Сохранить базовый URL сервера
  Future<void> saveBaseUrl(String baseUrl);

  /// Получить сохраненный базовый URL
  Future<String?> getBaseUrl();

  /// Проверить наличие сохраненного URL
  Future<bool> hasBaseUrl();

  /// Удалить сохраненный URL
  Future<void> clearBaseUrl();
}

/// Реализация локального источника данных настроек сервера
class ServerSettingsLocalDataSourceImpl
    implements ServerSettingsLocalDataSource {
  static const String _baseUrlKey = 'server_base_url';

  final SharedPreferences _prefs;

  ServerSettingsLocalDataSourceImpl(this._prefs);

  @override
  Future<void> saveBaseUrl(String baseUrl) async {
    await _prefs.setString(_baseUrlKey, baseUrl);
  }

  @override
  Future<String?> getBaseUrl() async {
    return _prefs.getString(_baseUrlKey);
  }

  @override
  Future<bool> hasBaseUrl() async {
    return _prefs.containsKey(_baseUrlKey);
  }

  @override
  Future<void> clearBaseUrl() async {
    await _prefs.remove(_baseUrlKey);
  }
}
