// Session Management Feature Module
import 'package:cherrypick/cherrypick.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/session_management/data/datasources/session_local_datasource.dart';
import '../../features/session_management/data/datasources/session_remote_datasource.dart';
import '../../features/session_management/data/repositories/session_repository_impl.dart';
import '../../features/session_management/domain/repositories/session_repository.dart';
import '../../features/session_management/domain/usecases/create_session.dart';
import '../../features/session_management/domain/usecases/delete_session.dart';
import '../../features/session_management/domain/usecases/list_sessions.dart';
import '../../features/session_management/domain/usecases/load_session.dart';
import '../../features/session_management/presentation/bloc/session_manager_bloc.dart';

/// Модуль для регистрации зависимостей Session Management feature
///
/// Включает:
/// - SessionLocalDataSource (SharedPreferences)
/// - SessionRemoteDataSource (REST API)
/// - SessionRepository
/// - Use Cases (create, load, list, delete)
/// - SessionManagerBloc
///
/// Зависимости:
/// - Logger (из CoreModule)
/// - Dio (из NetworkModule)
/// - String с именем 'gatewayBaseUrl' (из NetworkModule)
/// - SharedPreferences (опционально)
///
/// Примечание: Если SharedPreferences не доступен, модуль не регистрирует зависимости
class SessionModule extends Module {
  final SharedPreferences? sharedPreferences;

  SessionModule({this.sharedPreferences});

  @override
  void builder(Scope currentScope) {
    // Регистрируем только если SharedPreferences доступен
    if (sharedPreferences == null) {
      return;
    }

    // ========================================================================
    // Data Sources
    // ========================================================================

    bind<SessionRemoteDataSource>()
        .toProvide(
          () => SessionRemoteDataSourceImpl(
            dio: currentScope.resolve<Dio>(),
            baseUrl: currentScope.resolve<String>(named: 'gatewayBaseUrl'),
          ),
        )
        .singleton();

    bind<SessionLocalDataSource>()
        .toProvide(
          () => SessionLocalDataSourceImpl(
            currentScope.resolve<SharedPreferences>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Repository
    // ========================================================================

    bind<SessionRepository>()
        .toProvide(
          () => SessionRepositoryImpl(
            remoteDataSource: currentScope.resolve<SessionRemoteDataSource>(),
            localDataSource: currentScope.resolve<SessionLocalDataSource>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Use Cases
    // ========================================================================

    bind<CreateSessionUseCase>().toProvide(
      () => CreateSessionUseCase(currentScope.resolve<SessionRepository>()),
    );

    bind<LoadSessionUseCase>().toProvide(
      () => LoadSessionUseCase(currentScope.resolve<SessionRepository>()),
    );

    bind<ListSessionsUseCase>().toProvide(
      () => ListSessionsUseCase(currentScope.resolve<SessionRepository>()),
    );

    bind<DeleteSessionUseCase>().toProvide(
      () => DeleteSessionUseCase(currentScope.resolve<SessionRepository>()),
    );

    // ========================================================================
    // Presentation (BLoC)
    // ========================================================================

    bind<SessionManagerBloc>().toProvide(
      () => SessionManagerBloc(
        createSession: currentScope.resolve<CreateSessionUseCase>(),
        loadSession: currentScope.resolve<LoadSessionUseCase>(),
        listSessions: currentScope.resolve<ListSessionsUseCase>(),
        deleteSession: currentScope.resolve<DeleteSessionUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );
  }
}
