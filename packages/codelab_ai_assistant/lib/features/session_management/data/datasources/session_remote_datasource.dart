// Remote data source для работы с сессиями через REST API
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/session_model.dart';

/// Интерфейс для удаленного источника данных сессий
/// 
/// Определяет методы для работы с REST API Gateway
abstract class SessionRemoteDataSource {
  /// Создает новую сессию на сервере
  Future<SessionModel> createSession();
  
  /// Получает сессию по ID
  Future<SessionModel> getSession(String sessionId);
  
  /// Получает список всех сессий
  Future<List<SessionModel>> listSessions();
  
  /// Удаляет сессию по ID
  Future<void> deleteSession(String sessionId);
  
  /// Обновляет заголовок сессии
  Future<SessionModel> updateSessionTitle(String sessionId, String title);
}

/// Реализация удаленного источника данных через Dio HTTP клиент
class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;

  SessionRemoteDataSourceImpl({required Dio dio, required String baseUrl})
    : _dio = dio,
      _baseUrl = baseUrl;

  @override
  Future<SessionModel> createSession() async {
    try {
      final response = await _dio.post('$_baseUrl/sessions');
      return SessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create session');
    } catch (e) {
      throw ServerException('Unexpected error creating session: $e');
    }
  }

  @override
  Future<SessionModel> getSession(String sessionId) async {
    try {
      final response = await _dio.get('$_baseUrl/sessions/$sessionId');
      return SessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get session');
    } catch (e) {
      throw ServerException('Unexpected error getting session: $e');
    }
  }

  @override
  Future<List<SessionModel>> listSessions() async {
    try {
      final response = await _dio.get('$_baseUrl/sessions');
      final data = response.data as Map<String, dynamic>;
      final sessionsList = data['sessions'] as List<dynamic>;

      return sessionsList
          .map((json) => SessionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to list sessions');
    } catch (e) {
      throw ServerException('Unexpected error listing sessions: $e');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _dio.delete('$_baseUrl/sessions/$sessionId');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete session');
    } catch (e) {
      throw ServerException('Unexpected error deleting session: $e');
    }
  }

  @override
  Future<SessionModel> updateSessionTitle(
    String sessionId,
    String title,
  ) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/sessions/$sessionId',
        data: {'title': title},
      );
      return SessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update session title');
    } catch (e) {
      throw ServerException('Unexpected error updating session title: $e');
    }
  }

  /// Обрабатывает ошибки Dio и конвертирует их в domain exceptions
  AppException _handleDioError(DioException e, String context) {
    // Timeout errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException('$context: Connection timeout', e);
    }

    // Connection errors
    if (e.type == DioExceptionType.connectionError) {
      return NetworkException('$context: Connection error', e);
    }

    // HTTP status code errors
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 404:
          return NotFoundException('$context: Resource not found', e);
        case 401:
        case 403:
          return UnauthorizedException('$context: Unauthorized', e);
        case 400:
          return ValidationException('$context: Bad request', e);
        case 500:
        case 502:
        case 503:
          return ServerException('$context: Server error', e);
        default:
          return ServerException('$context: HTTP $statusCode', e);
      }
    }

    // Other errors
    return ServerException('$context: ${e.message}', e);
  }
}
