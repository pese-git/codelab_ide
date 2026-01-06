// Dio interceptor для автоматической авторизации и обновления токенов
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_token_model.dart';

/// Interceptor для автоматического добавления токена и его обновления
///
/// Добавляет Authorization заголовок к запросам и автоматически
/// обновляет токен при получении 401 ошибки
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;
  final Logger _logger;
  final String _clientId;
  Dio? _dio; // Ссылка на Dio instance для повторных запросов

  // Флаг для предотвращения циклических обновлений
  bool _isRefreshing = false;
  // Очередь запросов, ожидающих обновления токена
  final List<_RequestOptions> _requestQueue = [];

  AuthInterceptor({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
    required Logger logger,
    String clientId = 'codelab-flutter-app',
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _logger = logger,
        _clientId = clientId;

  /// Установить ссылку на Dio instance
  void setDio(Dio dio) {
    _dio = dio;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Пропускаем OAuth эндпоинты
    if (_isOAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    try {
      // Получаем токен из хранилища
      final tokenModel = await _localDataSource.getToken();

      if (tokenModel != null) {
        final token = tokenModel.toEntity();

        // Проверяем, нужно ли обновить токен
        if (token.needsRefresh && !_isRefreshing) {
          _logger.d('[AuthInterceptor] Token needs refresh, refreshing...');
          await _refreshToken(tokenModel);
          // Получаем обновленный токен
          final newTokenModel = await _localDataSource.getToken();
          if (newTokenModel != null) {
            final newToken = newTokenModel.toEntity();
            options.headers['Authorization'] = newToken.authorizationHeader;
          }
        } else if (!token.isExpired) {
          // Токен еще валиден, добавляем его
          options.headers['Authorization'] = token.authorizationHeader;
        } else {
          _logger.w('[AuthInterceptor] Token expired and not refreshed');
        }
      } else {
        _logger.d('[AuthInterceptor] No token found in storage');
      }
    } catch (e) {
      _logger.e('[AuthInterceptor] Error in onRequest: $e');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Обрабатываем только 401 ошибки
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Пропускаем OAuth эндпоинты
    if (_isOAuthEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    _logger.w('[AuthInterceptor] Received 401, attempting token refresh');

    try {
      // Получаем текущий токен
      final tokenModel = await _localDataSource.getToken();
      if (tokenModel == null) {
        _logger.w('[AuthInterceptor] No token to refresh');
        return handler.next(err);
      }

      // Если уже идет обновление, добавляем запрос в очередь
      if (_isRefreshing) {
        _logger.d('[AuthInterceptor] Refresh in progress, queueing request');
        final completer = _RequestOptions(err.requestOptions, handler);
        _requestQueue.add(completer);
        return;
      }

      // Обновляем токен
      final newTokenModel = await _refreshToken(tokenModel);

      if (newTokenModel != null) {
        // Повторяем оригинальный запрос с новым токеном
        final newToken = newTokenModel.toEntity();
        final options = err.requestOptions;
        options.headers['Authorization'] = newToken.authorizationHeader;

        _logger.d('[AuthInterceptor] Retrying request with new token');
        _logger.d('[AuthInterceptor] New token: ${newToken.accessToken.substring(0, 20)}...');
        _logger.d('[AuthInterceptor] Request URL: ${options.uri}');
        _logger.d('[AuthInterceptor] Request headers: ${options.headers}');

        // Создаем новый Dio БЕЗ AuthInterceptor для избежания цикла
        // но копируем базовые настройки
        final retryDio = Dio(_dio?.options ?? BaseOptions());
        
        // Копируем все interceptor'ы КРОМЕ AuthInterceptor
        if (_dio != null) {
          for (final interceptor in _dio!.interceptors) {
            if (interceptor != this) {
              retryDio.interceptors.add(interceptor);
            }
          }
        }

        try {
          final response = await retryDio.fetch(options);
          // Обрабатываем очередь запросов
          _processQueue(newToken.authorizationHeader);
          return handler.resolve(response);
        } catch (e) {
          _logger.e('[AuthInterceptor] Retry failed: $e');
          _clearQueue(err);
          return handler.next(err);
        }
      } else {
        _logger.e('[AuthInterceptor] Token refresh failed');
        // Очищаем очередь с ошибкой
        _clearQueue(err);
        return handler.next(err);
      }
    } catch (e) {
      _logger.e('[AuthInterceptor] Error during token refresh: $e');
      _clearQueue(err);
      return handler.next(err);
    }
  }

  /// Обновляет токен
  Future<AuthTokenModel?> _refreshToken(AuthTokenModel oldToken) async {
    if (_isRefreshing) {
      _logger.d('[AuthInterceptor] Refresh already in progress');
      return null;
    }

    _isRefreshing = true;

    try {
      _logger.i('[AuthInterceptor] Refreshing token...');

      final request = RefreshTokenRequest(
        refreshToken: oldToken.refreshToken,
        clientId: _clientId,
      );

      final newTokenModel = await _remoteDataSource.refreshToken(request);

      // Сохраняем новый токен
      await _localDataSource.saveToken(newTokenModel);

      _logger.i('[AuthInterceptor] Token refreshed successfully');

      return newTokenModel;
    } catch (e) {
      _logger.e('[AuthInterceptor] Token refresh failed: $e');
      // При ошибке обновления удаляем старый токен
      // clearToken() автоматически уведомит об истечении токена через stream
      await _localDataSource.clearToken();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Обрабатывает очередь запросов после успешного обновления токена
  void _processQueue(String authHeader) {
    _logger.d('[AuthInterceptor] Processing ${_requestQueue.length} queued requests');

    if (_dio == null) {
      _logger.e('[AuthInterceptor] Cannot process queue: Dio instance not set');
      _requestQueue.clear();
      return;
    }

    // Создаем Dio БЕЗ AuthInterceptor для избежания цикла
    final retryDio = Dio(_dio!.options);
    for (final interceptor in _dio!.interceptors) {
      if (interceptor != this) {
        retryDio.interceptors.add(interceptor);
      }
    }

    for (final item in _requestQueue) {
      item.options.headers['Authorization'] = authHeader;
      retryDio.fetch(item.options).then((response) {
        item.handler.resolve(response);
      }).catchError((error) {
        item.handler.next(error as DioException);
      });
    }

    _requestQueue.clear();
  }

  /// Очищает очередь запросов с ошибкой
  void _clearQueue(DioException error) {
    _logger.d('[AuthInterceptor] Clearing ${_requestQueue.length} queued requests with error');

    for (final item in _requestQueue) {
      item.handler.next(error);
    }

    _requestQueue.clear();
  }

  /// Проверяет, является ли путь OAuth эндпоинтом
  bool _isOAuthEndpoint(String path) {
    return path.contains('/oauth/token') || path.contains('/auth/oauth');
  }
}

/// Вспомогательный класс для хранения запросов в очереди
class _RequestOptions {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _RequestOptions(this.options, this.handler);
}
