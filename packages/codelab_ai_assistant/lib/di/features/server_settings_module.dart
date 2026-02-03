// Server Settings Feature Module
import 'package:cherrypick/cherrypick.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/server_settings/data/datasources/server_settings_local_datasource.dart';
import '../../features/server_settings/data/datasources/server_settings_remote_datasource.dart';
import '../../features/server_settings/data/repositories/server_settings_repository_impl.dart';
import '../../features/server_settings/domain/repositories/server_settings_repository.dart';
import '../../features/server_settings/domain/usecases/clear_settings.dart';
import '../../features/server_settings/domain/usecases/load_settings.dart';
import '../../features/server_settings/domain/usecases/save_settings.dart';
import '../../features/server_settings/domain/usecases/test_connection.dart';
import '../../features/server_settings/presentation/bloc/server_settings_bloc.dart';

/// Модуль для регистрации зависимостей Server Settings feature
///
/// Включает:
/// - ServerSettingsLocalDataSource (SharedPreferences)
/// - ServerSettingsRemoteDataSource (REST API)
/// - ServerSettingsRepository
/// - Use Cases (load, save, test connection, clear)
/// - ServerSettingsBloc
///
/// Зависимости:
/// - Logger (из CoreModule)
/// - Dio (из NetworkModule)
/// - SharedPreferences (обязательно)
class ServerSettingsModule extends Module {
  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Data Sources
    // ========================================================================

    bind<ServerSettingsLocalDataSource>()
        .toProvide(
          () => ServerSettingsLocalDataSourceImpl(
            currentScope.resolve<SharedPreferences>(),
          ),
        )
        .singleton();

    bind<ServerSettingsRemoteDataSource>()
        .toProvide(
          () => ServerSettingsRemoteDataSourceImpl(
            dio: currentScope.resolve<Dio>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Repository
    // ========================================================================

    bind<ServerSettingsRepository>()
        .toProvide(
          () => ServerSettingsRepositoryImpl(
            localDataSource:
                currentScope.resolve<ServerSettingsLocalDataSource>(),
            remoteDataSource:
                currentScope.resolve<ServerSettingsRemoteDataSource>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Use Cases
    // ========================================================================

    bind<LoadSettingsUseCase>()
        .toProvide(
          () => LoadSettingsUseCase(
            currentScope.resolve<ServerSettingsRepository>(),
          ),
        )
        .singleton();

    bind<SaveSettingsUseCase>()
        .toProvide(
          () => SaveSettingsUseCase(
            currentScope.resolve<ServerSettingsRepository>(),
          ),
        )
        .singleton();

    bind<TestConnectionUseCase>()
        .toProvide(
          () => TestConnectionUseCase(
            currentScope.resolve<ServerSettingsRepository>(),
          ),
        )
        .singleton();

    bind<ClearSettingsUseCase>()
        .toProvide(
          () => ClearSettingsUseCase(
            currentScope.resolve<ServerSettingsRepository>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Presentation (BLoC)
    // ========================================================================

    bind<ServerSettingsBloc>().toProvide(
      () => ServerSettingsBloc(
        loadSettings: currentScope.resolve<LoadSettingsUseCase>(),
        saveSettings: currentScope.resolve<SaveSettingsUseCase>(),
        testConnection: currentScope.resolve<TestConnectionUseCase>(),
        clearSettings: currentScope.resolve<ClearSettingsUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );
  }
}
