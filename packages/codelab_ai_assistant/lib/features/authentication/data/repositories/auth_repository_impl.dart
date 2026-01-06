// Реализация репозитория авторизации
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_token_model.dart';

/// Реализация репозитория авторизации
///
/// Координирует работу между remote и local data sources
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, AuthToken>> loginWithPassword(
    PasswordGrantParams params,
  ) async {
    try {
      // Создаем запрос
      final request = PasswordGrantRequest.fromParams(params);

      // Выполняем авторизацию
      final tokenModel = await _remoteDataSource.loginWithPassword(request);

      // Конвертируем в entity
      final token = tokenModel.toEntity();

      // Сохраняем токен локально
      await _localDataSource.saveToken(tokenModel);

      return right(token);
    } on AuthenticationException catch (e) {
      return left(Failure.unauthorized(e.message));
    } on UnauthorizedException catch (e) {
      return left(Failure.unauthorized(e.message));
    } catch (e) {
      return left(Failure.server('Login failed: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthToken>> refreshToken(
    RefreshTokenParams params,
  ) async {
    try {
      // Создаем запрос
      final request = RefreshTokenRequest.fromParams(params);

      // Обновляем токен
      final tokenModel = await _remoteDataSource.refreshToken(request);

      // Конвертируем в entity
      final token = tokenModel.toEntity();

      // Сохраняем новый токен локально
      await _localDataSource.saveToken(tokenModel);

      return right(token);
    } on AuthenticationException catch (e) {
      // При ошибке обновления токена, удаляем старый
      await _localDataSource.clearToken();
      return left(Failure.unauthorized(e.message));
    } on UnauthorizedException catch (e) {
      await _localDataSource.clearToken();
      return left(Failure.unauthorized(e.message));
    } catch (e) {
      return left(Failure.server('Token refresh failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveToken(AuthToken token) async {
    try {
      final tokenModel = AuthTokenModel.fromEntity(token);
      await _localDataSource.saveToken(tokenModel);
      return right(unit);
    } catch (e) {
      return left(Failure.cache('Failed to save token: $e'));
    }
  }

  @override
  Future<Either<Failure, Option<AuthToken>>> getStoredToken() async {
    try {
      final tokenModel = await _localDataSource.getToken();
      if (tokenModel == null) {
        return right(none());
      }

      final token = tokenModel.toEntity();

      // Проверяем, не истек ли токен
      if (token.isExpired) {
        // Токен истек, удаляем его
        await _localDataSource.clearToken();
        return right(none());
      }

      return right(some(token));
    } catch (e) {
      return left(Failure.cache('Failed to get stored token: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearToken() async {
    try {
      await _localDataSource.clearToken();
      return right(unit);
    } catch (e) {
      return left(Failure.cache('Failed to clear token: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final tokenModel = await _localDataSource.getToken();
      if (tokenModel == null) {
        return false;
      }

      final token = tokenModel.toEntity();
      return !token.isExpired;
    } catch (e) {
      return false;
    }
  }
}
