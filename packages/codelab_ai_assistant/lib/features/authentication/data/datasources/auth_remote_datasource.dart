// Remote data source для авторизации
import 'package:dio/dio.dart';
import '../models/auth_token_model.dart';

/// Интерфейс для удаленного источника данных авторизации
abstract class AuthRemoteDataSource {
  /// Авторизация с паролем
  Future<AuthTokenModel> loginWithPassword(PasswordGrantRequest request);

  /// Обновление токена
  Future<AuthTokenModel> refreshToken(RefreshTokenRequest request);
}

/// Реализация удаленного источника данных авторизации
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  final String _authServiceUrl;

  AuthRemoteDataSourceImpl({
    required Dio dio,
    String authServiceUrl = 'http://localhost/auth',
  })  : _dio = dio,
        _authServiceUrl = authServiceUrl;

  @override
  Future<AuthTokenModel> loginWithPassword(
    PasswordGrantRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '$_authServiceUrl/oauth/token',
        data: request.toFormData(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // Не добавляем X-Internal-Auth для OAuth эндпоинтов
          headers: {},
        ),
      );

      return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthenticationException(
          'Invalid credentials',
          statusCode: 401,
        );
      } else if (e.response?.statusCode == 429) {
        throw AuthenticationException(
          'Too many attempts. Please try again later.',
          statusCode: 429,
        );
      }
      throw AuthenticationException(
        'Authentication failed: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthenticationException('Unexpected error: $e');
    }
  }

  @override
  Future<AuthTokenModel> refreshToken(RefreshTokenRequest request) async {
    try {
      final response = await _dio.post(
        '$_authServiceUrl/oauth/token',
        data: request.toFormData(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // Не добавляем X-Internal-Auth для OAuth эндпоинтов
          headers: {},
        ),
      );

      return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthenticationException(
          'Invalid or expired refresh token',
          statusCode: 401,
        );
      }
      throw AuthenticationException(
        'Token refresh failed: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthenticationException('Unexpected error: $e');
    }
  }
}

/// Исключение авторизации
class AuthenticationException implements Exception {
  final String message;
  final int? statusCode;

  AuthenticationException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthenticationException: $message (status: $statusCode)';
}
