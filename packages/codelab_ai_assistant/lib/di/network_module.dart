// Network Module - HTTP и WebSocket клиенты
import 'dart:io';

import 'package:cherrypick/cherrypick.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/authentication/data/datasources/auth_local_datasource.dart';
import '../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../features/authentication/data/services/auth_interceptor.dart';
import '../features/agent_chat/data/datasources/gateway_api.dart';

/// Модуль для регистрации сетевых зависимостей
///
/// Включает:
/// - Dio HTTP client с interceptors
/// - AuthInterceptor для JWT авторизации
/// - GatewayApi для REST запросов
/// - Конфигурация SSL и proxy
class NetworkModule extends Module {
  final String baseUrl;

  NetworkModule({this.baseUrl = 'http://localhost'});

  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Configuration - URL endpoints
    // ========================================================================

    // Gateway API URL (базовый URL + /api/v1)
    bind<String>()
        .withName('gatewayBaseUrl')
        .toProvide(() => '$baseUrl/api/v1')
        .singleton();

    // Auth Service URL (базовый URL, OAuth эндпоинт: /oauth/token)
    bind<String>()
        .withName('authServiceUrl')
        .toProvide(() => baseUrl)
        .singleton();

    // ========================================================================
    // Auth Dio (отдельный для auth запросов без interceptors)
    // ========================================================================

    bind<Dio>()
        .withName('authDio')
        .toProvide(() {
          final authDio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

          // Логи
          authDio.interceptors.add(
            LogInterceptor(
              request: true,
              requestBody: true,
              responseBody: true,
              error: true,
            ),
          );

          // SSL configuration (только для разработки)
          authDio.httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () {
              final client = HttpClient();
              client.badCertificateCallback =
                  (X509Certificate cert, String host, int port) => true;
              return client;
            },
          );

          return authDio;
        })
        .singleton();

    // ========================================================================
    // AuthInterceptor
    // ========================================================================

    bind<AuthInterceptor>().toProvide(() {
      return AuthInterceptor(
        localDataSource: currentScope.resolve<AuthLocalDataSource>(),
        remoteDataSource: currentScope.resolve<AuthRemoteDataSource>(),
        logger: currentScope.resolve<Logger>(),
      );
    }).singleton();

    // ========================================================================
    // Main Dio (с AuthInterceptor)
    // ========================================================================

    bind<Dio>().toProvide(() {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Логи
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );

      // Добавляем AuthInterceptor для JWT авторизации
      final authInterceptor = currentScope.resolve<AuthInterceptor>();
      authInterceptor.setDio(dio);
      dio.interceptors.add(authInterceptor);

      // SSL configuration (только для разработки)
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );

      return dio;
    }).singleton();

    // ========================================================================
    // GatewayApi
    // ========================================================================

    bind<GatewayApi>()
        .toProvide(
          () => GatewayApi(
            dio: currentScope.resolve<Dio>(),
            baseUrl: currentScope.resolve<String>(named: 'gatewayBaseUrl'),
          ),
        )
        .singleton();
  }
}
