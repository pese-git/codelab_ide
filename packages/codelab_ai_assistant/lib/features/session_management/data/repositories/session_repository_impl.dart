// Реализация SessionRepository (Data слой)
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_datasource.dart';
import '../datasources/session_local_datasource.dart';

/// Реализация репозитория сессий
/// 
/// Координирует работу между remote и local data sources.
/// Конвертирует exceptions в failures и возвращает Either<Failure, T>.
class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _remoteDataSource;
  final SessionLocalDataSource _localDataSource;
  
  SessionRepositoryImpl({
    required SessionRemoteDataSource remoteDataSource,
    required SessionLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  
  @override
  Future<Either<Failure, Session>> createSession(CreateSessionParams params) async {
    try {
      // Создаем сессию на сервере
      final model = await _remoteDataSource.createSession();
      
      // Кешируем локально
      await _localDataSource.cacheSession(model);
      
      // Конвертируем в entity и возвращаем
      return right(model.toEntity());
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } on CacheException catch (e) {
      // Кеш не критичен, логируем но возвращаем успех если сервер ответил
      print('[SessionRepository] Cache error: ${e.message}');
      return left(Failure.cache(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error creating session: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Session>> loadSession(LoadSessionParams params) async {
    try {
      // Загружаем с сервера
      final model = await _remoteDataSource.getSession(params.sessionId);
      
      // Кешируем локально
      await _localDataSource.cacheSession(model);
      
      // Конвертируем в entity и возвращаем
      return right(model.toEntity());
    } on NotFoundException catch (e) {
      // Если сессия не найдена на сервере, пытаемся найти её в списке сессий
      // Это может произойти если endpoint /sessions/{id} не реализован,
      // но сессия существует в списке
      return _loadFromSessionList(params.sessionId);
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      // При ошибке сети пытаемся загрузить из кеша
      return _loadFromCache(params.sessionId);
    } on CacheException catch (e) {
      print('[SessionRepository] Cache error: ${e.message}');
      return left(Failure.cache(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error loading session: $e'));
    }
  }
  
  /// Вспомогательный метод для загрузки сессии из списка сессий
  Future<Either<Failure, Session>> _loadFromSessionList(String sessionId) async {
    try {
      // Пытаемся найти сессию в списке
      final sessions = await _remoteDataSource.listSessions();
      final session = sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw NotFoundException('Session not found in list', null),
      );
      
      // Кешируем
      await _localDataSource.cacheSession(session);
      
      return right(session.toEntity());
    } on NotFoundException catch (e) {
      return left(Failure.notFound(e.message));
    } catch (e) {
      return left(Failure.server('Failed to load session from list: $e'));
    }
  }
  
  /// Вспомогательный метод для загрузки из кеша
  Future<Either<Failure, Session>> _loadFromCache(String sessionId) async {
    try {
      final cachedOption = await _localDataSource.getLastSession();
      
      return cachedOption.fold(
        () => left(Failure.network('No network and no cached data')),
        (model) {
          // Проверяем что это нужная сессия
          if (model.id == sessionId) {
            return right(model.toEntity());
          }
          return left(Failure.network('No network and wrong session in cache'));
        },
      );
    } on CacheException catch (e) {
      return left(Failure.cache(e.message));
    }
  }
  
  @override
  Future<Either<Failure, List<Session>>> listSessions() async {
    try {
      // Проверяем свежесть кеша
      final isCacheStale = await _localDataSource.isCacheStale();
      
      // Если кеш свежий, пытаемся загрузить из него
      if (!isCacheStale) {
        final cachedOption = await _localDataSource.getCachedSessionList();
        
        final cached = cachedOption.fold(
          () => null,
          (models) => models,
        );
        
        if (cached != null && cached.isNotEmpty) {
          final sessions = cached.map((m) => m.toEntity()).toList();
          return right(sessions);
        }
      }
      
      // Загружаем с сервера
      final models = await _remoteDataSource.listSessions();
      
      // Кешируем
      await _localDataSource.cacheSessionList(models);
      
      // Конвертируем в entities
      final sessions = models.map((m) => m.toEntity()).toList();
      return right(sessions);
    } on ServerException catch (e) {
      // При ошибке сервера пытаемся вернуть кеш
      return _listFromCache(e);
    } on NetworkException catch (e) {
      // При ошибке сети пытаемся вернуть кеш
      return _listFromCache(e);
    } on CacheException catch (e) {
      print('[SessionRepository] Cache error: ${e.message}');
      return left(Failure.cache(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error listing sessions: $e'));
    }
  }
  
  /// Вспомогательный метод для загрузки списка из кеша
  Future<Either<Failure, List<Session>>> _listFromCache(AppException originalError) async {
    try {
      final cachedOption = await _localDataSource.getCachedSessionList();
      
      return cachedOption.fold(
        () {
          // Нет кеша, возвращаем оригинальную ошибку
          if (originalError is ServerException) {
            return left(Failure.server(originalError.message));
          }
          return left(Failure.network(originalError.message));
        },
        (models) {
          // Есть кеш, возвращаем его
          final sessions = models.map((m) => m.toEntity()).toList();
          return right(sessions);
        },
      );
    } on CacheException catch (e) {
      return left(Failure.cache(e.message));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> deleteSession(DeleteSessionParams params) async {
    try {
      // Удаляем на сервере
      await _remoteDataSource.deleteSession(params.sessionId);
      
      // Очищаем кеш (если это была последняя сессия)
      final lastSessionOption = await _localDataSource.getLastSession();
      
      await lastSessionOption.fold(
        () async => unit,
        (model) async {
          if (model.id == params.sessionId) {
            await _localDataSource.clearCache();
          }
          return unit;
        },
      );
      
      return right(unit);
    } on NotFoundException catch (e) {
      return left(Failure.notFound(e.message));
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } on CacheException catch (e) {
      print('[SessionRepository] Cache error: ${e.message}');
      // Удаление на сервере прошло успешно, ошибка кеша не критична
      return right(unit);
    } catch (e) {
      return left(Failure.unknown('Unexpected error deleting session: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Option<Session>>> getLastSession() async {
    try {
      final modelOption = await _localDataSource.getLastSession();
      
      return right(modelOption.map((model) => model.toEntity()));
    } on CacheException catch (e) {
      return left(Failure.cache(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error getting last session: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Session>> updateSessionTitle(
    String sessionId,
    String title,
  ) async {
    try {
      // Обновляем на сервере
      final model = await _remoteDataSource.updateSessionTitle(sessionId, title);
      
      // Обновляем кеш
      await _localDataSource.cacheSession(model);
      
      return right(model.toEntity());
    } on NotFoundException catch (e) {
      return left(Failure.notFound(e.message));
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } on CacheException catch (e) {
      print('[SessionRepository] Cache error: ${e.message}');
      return left(Failure.cache(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error updating session title: $e'));
    }
  }
}
