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
  Future<Either<Failure, Session>> createSession(
    CreateSessionParams params,
  ) async {
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
    print('[SessionRepository] Loading session: ${params.sessionId}');
    try {
      // Загружаем с сервера
      print('[SessionRepository] Trying to load from server...');
      final model = await _remoteDataSource.getSession(params.sessionId);

      print('[SessionRepository] Session loaded from server: ${model.id}');
      // Кешируем локально
      await _localDataSource.cacheSession(model);

      // Конвертируем в entity и возвращаем
      return right(model.toEntity());
    } on NotFoundException {
      print(
        '[SessionRepository] Session not found on server (404), trying session list...',
      );
      // Если сессия не найдена на сервере, пытаемся найти её в списке сессий
      // Это может произойти если endpoint /sessions/{id} не реализован,
      // но сессия существует в списке
      return _loadFromSessionList(params.sessionId);
    } on ServerException catch (e) {
      print('[SessionRepository] Server error: ${e.message}');
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      print('[SessionRepository] Network error: ${e.message}');
      // При ошибке сети пытаемся загрузить из кеша
      return _loadFromCache(params.sessionId);
    } on CacheException catch (e) {
      print('[SessionRepository] Cache error: ${e.message}');
      return left(Failure.cache(e.message));
    } catch (e) {
      print('[SessionRepository] Unexpected error: $e');
      return left(Failure.unknown('Unexpected error loading session: $e'));
    }
  }

  /// Вспомогательный метод для загрузки сессии из списка сессий
  Future<Either<Failure, Session>> _loadFromSessionList(
    String sessionId,
  ) async {
    try {
      print('[SessionRepository] Loading sessions list...');
      // Пытаемся найти сессию в списке
      final sessions = await _remoteDataSource.listSessions();
      print('[SessionRepository] Got ${sessions.length} sessions from server');
      print('[SessionRepository] Looking for session: $sessionId');

      // Выводим все ID сессий для отладки
      for (var s in sessions) {
        print('[SessionRepository]   - Session ID: ${s.id}');
      }

      final session = sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () =>
            throw NotFoundException('Session not found in list', null),
      );

      print('[SessionRepository] Found session in list: ${session.id}');
      // Кешируем
      await _localDataSource.cacheSession(session);

      return right(session.toEntity());
    } on NotFoundException catch (e) {
      print('[SessionRepository] Session not found in list: ${e.message}');
      return left(Failure.notFound(e.message));
    } catch (e) {
      print('[SessionRepository] Error loading from list: $e');
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
      print('[SessionRepository] Listing sessions...');
      
      // Всегда загружаем с сервера для синхронизации
      final models = await _remoteDataSource.listSessions();
      print('[SessionRepository] Got ${models.length} sessions from server');
      
      // Синхронизируем кеш: удаляем устаревшие сессии
      final cachedOption = await _localDataSource.getCachedSessionList();
      await cachedOption.fold(
        () async {
          // Нет кеша, просто кешируем новые данные
          print('[SessionRepository] No cache, caching new sessions');
        },
        (cachedModels) async {
          // Есть кеш, проверяем какие сессии устарели
          final serverIds = models.map((m) => m.id).toSet();
          final cachedIds = cachedModels.map((m) => m.id).toSet();
          final removedIds = cachedIds.difference(serverIds);
          
          if (removedIds.isNotEmpty) {
            print('[SessionRepository] Found ${removedIds.length} stale sessions in cache: $removedIds');
            // Если последняя сессия была удалена, очищаем кеш
            final lastSessionOption = await _localDataSource.getLastSession();
            await lastSessionOption.fold(
              () async {},
              (lastSession) async {
                if (removedIds.contains(lastSession.id)) {
                  print('[SessionRepository] Last session was removed, clearing cache');
                  await _localDataSource.clearCache();
                }
              },
            );
          }
        },
      );
      
      // Кешируем актуальный список
      await _localDataSource.cacheSessionList(models);
      
      // Конвертируем в entities
      final sessions = models.map((m) => m.toEntity()).toList();
      print('[SessionRepository] Returning ${sessions.length} sessions');
      return right(sessions);
    } on ServerException catch (e) {
      print('[SessionRepository] Server error while listing: ${e.message}');
      // При ошибке сервера пытаемся вернуть кеш
      return _listFromCache(e);
    } on NetworkException catch (e) {
      print('[SessionRepository] Network error while listing: ${e.message}');
      // При ошибке сети пытаемся вернуть кеш
      return _listFromCache(e);
    } on CacheException catch (e) {
      print('[SessionRepository] Cache error: ${e.message}');
      return left(Failure.cache(e.message));
    } catch (e) {
      print('[SessionRepository] Unexpected error listing sessions: $e');
      return left(Failure.unknown('Unexpected error listing sessions: $e'));
    }
  }

  /// Вспомогательный метод для загрузки списка из кеша
  Future<Either<Failure, List<Session>>> _listFromCache(
    AppException originalError,
  ) async {
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
  Future<Either<Failure, Unit>> deleteSession(
    DeleteSessionParams params,
  ) async {
    try {
      // Удаляем на сервере
      await _remoteDataSource.deleteSession(params.sessionId);

      // Очищаем кеш (если это была последняя сессия)
      final lastSessionOption = await _localDataSource.getLastSession();

      await lastSessionOption.fold(() async => unit, (model) async {
        if (model.id == params.sessionId) {
          await _localDataSource.clearCache();
        }
        return unit;
      });

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
      final model = await _remoteDataSource.updateSessionTitle(
        sessionId,
        title,
      );

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
      return left(
        Failure.unknown('Unexpected error updating session title: $e'),
      );
    }
  }
}
