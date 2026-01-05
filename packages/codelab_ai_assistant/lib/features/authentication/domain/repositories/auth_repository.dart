// Repository интерфейс для авторизации
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_token.dart';

/// Repository для работы с авторизацией
///
/// Определяет контракт для работы с OAuth2 токенами
abstract class AuthRepository {
  /// Авторизация с использованием пароля (Password Grant)
  ///
  /// Возвращает Either с Failure или AuthToken
  Future<Either<Failure, AuthToken>> loginWithPassword(
    PasswordGrantParams params,
  );

  /// Обновление токена с использованием refresh token
  ///
  /// Возвращает Either с Failure или новый AuthToken
  Future<Either<Failure, AuthToken>> refreshToken(
    RefreshTokenParams params,
  );

  /// Сохранение токена в локальное хранилище
  ///
  /// Возвращает Either с Failure или Unit при успехе
  Future<Either<Failure, Unit>> saveToken(AuthToken token);

  /// Получение сохраненного токена из локального хранилища
  ///
  /// Возвращает Either с Failure или Option<AuthToken>
  Future<Either<Failure, Option<AuthToken>>> getStoredToken();

  /// Удаление токена из локального хранилища (logout)
  ///
  /// Возвращает Either с Failure или Unit при успехе
  Future<Either<Failure, Unit>> clearToken();

  /// Проверка, авторизован ли пользователь
  ///
  /// Возвращает true если есть валидный токен
  Future<bool> isAuthenticated();
}
