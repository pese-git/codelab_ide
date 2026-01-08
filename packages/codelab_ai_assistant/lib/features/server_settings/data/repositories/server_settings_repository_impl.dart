// Реализация репозитория настроек сервера
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/server_settings.dart';
import '../../domain/repositories/server_settings_repository.dart';
import '../datasources/server_settings_local_datasource.dart';
import '../datasources/server_settings_remote_datasource.dart';

/// Реализация репозитория настроек сервера
///
/// Координирует работу между remote и local data sources
class ServerSettingsRepositoryImpl implements ServerSettingsRepository {
  final ServerSettingsLocalDataSource _localDataSource;
  final ServerSettingsRemoteDataSource _remoteDataSource;
  final Logger _logger;

  ServerSettingsRepositoryImpl({
    required ServerSettingsLocalDataSource localDataSource,
    required ServerSettingsRemoteDataSource remoteDataSource,
    required Logger logger,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _logger = logger;

  @override
  Future<Either<Failure, Option<ServerSettings>>> getSettings() async {
    try {
      _logger.d('[ServerSettingsRepository] Getting settings...');
      
      final baseUrl = await _localDataSource.getBaseUrl();
      
      if (baseUrl == null || baseUrl.isEmpty) {
        _logger.d('[ServerSettingsRepository] No settings found');
        return right(none());
      }

      final settings = ServerSettings(baseUrl: baseUrl);
      _logger.i('[ServerSettingsRepository] ✅ Settings loaded: $baseUrl');
      
      return right(some(settings));
    } catch (e) {
      _logger.e('[ServerSettingsRepository] ❌ Failed to get settings: $e');
      return left(Failure.cache('Failed to get settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(ServerSettings settings) async {
    try {
      _logger.d('[ServerSettingsRepository] Saving settings: ${settings.baseUrl}');
      
      await _localDataSource.saveBaseUrl(settings.baseUrl);
      
      _logger.i('[ServerSettingsRepository] ✅ Settings saved successfully');
      return right(unit);
    } catch (e) {
      _logger.e('[ServerSettingsRepository] ❌ Failed to save settings: $e');
      return left(Failure.cache('Failed to save settings: $e'));
    }
  }

  @override
  Future<bool> hasSettings() async {
    try {
      final hasUrl = await _localDataSource.hasBaseUrl();
      _logger.d('[ServerSettingsRepository] Has settings: $hasUrl');
      return hasUrl;
    } catch (e) {
      _logger.e('[ServerSettingsRepository] ❌ Failed to check settings: $e');
      return false;
    }
  }

  @override
  Future<Either<Failure, bool>> testConnection(String baseUrl) async {
    try {
      _logger.d('[ServerSettingsRepository] Testing connection to: $baseUrl');
      
      // Валидация URL
      if (baseUrl.isEmpty) {
        return left(const Failure.validation('Base URL cannot be empty'));
      }

      // Проверка формата URL
      final uri = Uri.tryParse(baseUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        return left(const Failure.validation('Invalid URL format'));
      }

      // Тестирование соединения
      final isConnected = await _remoteDataSource.testConnection(baseUrl);
      
      if (isConnected) {
        _logger.i('[ServerSettingsRepository] ✅ Connection test successful');
        return right(true);
      } else {
        _logger.w('[ServerSettingsRepository] ⚠️ Connection test failed');
        return left(const Failure.network('Server is not reachable'));
      }
    } catch (e) {
      _logger.e('[ServerSettingsRepository] ❌ Connection test error: $e');
      return left(Failure.network('Connection test failed: $e'));
    }
  }
}
