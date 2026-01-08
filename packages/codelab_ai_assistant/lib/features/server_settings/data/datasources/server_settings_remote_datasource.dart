// Remote data source для тестирования соединения с сервером
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Интерфейс для удаленного источника данных настроек сервера
abstract class ServerSettingsRemoteDataSource {
  /// Тестировать соединение с сервером
  ///
  /// Проверяет доступность сервера по указанному URL
  /// Возвращает true если сервер доступен
  Future<bool> testConnection(String baseUrl);
}

/// Реализация удаленного источника данных настроек сервера
class ServerSettingsRemoteDataSourceImpl
    implements ServerSettingsRemoteDataSource {
  final Dio _dio;
  final Logger _logger;

  ServerSettingsRemoteDataSourceImpl({
    required Dio dio,
    required Logger logger,
  })  : _dio = dio,
        _logger = logger;

  @override
  Future<bool> testConnection(String baseUrl) async {
    try {
      _logger.d('[ServerSettingsRemoteDataSource] Testing connection to: $baseUrl');

      // Пробуем несколько вариантов health check endpoints
      final endpoints = [
        '$baseUrl/health',
        '$baseUrl/api/v1/health',
      ];

      for (final endpoint in endpoints) {
        try {
          _logger.d('[ServerSettingsRemoteDataSource] Trying endpoint: $endpoint');
          
          final response = await _dio.get(
            endpoint,
            options: Options(
              // Короткий timeout для быстрой проверки
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              // Не следуем редиректам
              followRedirects: false,
              validateStatus: (status) {
                // Считаем успешными коды 200-299 и 404 (сервер отвечает, но endpoint не найден)
                return status != null && (status >= 200 && status < 300 || status == 404);
              },
            ),
          );

          if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
            _logger.i('[ServerSettingsRemoteDataSource] ✅ Connection successful: ${response.statusCode}');
            return true;
          }
        } on DioException catch (e) {
          _logger.d('[ServerSettingsRemoteDataSource] Endpoint $endpoint failed: ${e.type}');
          // Продолжаем пробовать другие endpoints
          continue;
        }
      }

      // Если ни один endpoint не ответил успешно
      _logger.w('[ServerSettingsRemoteDataSource] ❌ All endpoints failed');
      return false;
    } on DioException catch (e) {
      _logger.e('[ServerSettingsRemoteDataSource] ❌ Connection test failed: ${e.type} - ${e.message}');
      return false;
    } catch (e) {
      _logger.e('[ServerSettingsRemoteDataSource] ❌ Unexpected error: $e');
      return false;
    }
  }
}
