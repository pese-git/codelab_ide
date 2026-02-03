// Authentication Feature Module
import 'package:cherrypick/cherrypick.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/authentication/data/datasources/auth_local_datasource.dart';
import '../../features/authentication/data/datasources/auth_memory_datasource.dart';
import '../../features/authentication/data/datasources/auth_remote_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';

/// Модуль для регистрации зависимостей Authentication feature
///
/// Включает:
/// - AuthLocalDataSource (SharedPreferences или Memory)
/// - AuthRemoteDataSource (OAuth API)
/// - AuthRepository
/// - AuthBloc
///
/// Зависимости:
/// - Logger (из CoreModule)
/// - Dio с именем 'authDio' (из NetworkModule)
/// - String с именем 'authServiceUrl' (из NetworkModule)
/// - SharedPreferences (опционально)
class AuthModule extends Module {
  final SharedPreferences? sharedPreferences;

  AuthModule({this.sharedPreferences});

  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Data Sources
    // ========================================================================

    // AuthLocalDataSource - используем SharedPreferences если доступен, иначе память
    bind<AuthLocalDataSource>()
        .toProvide(
          () => sharedPreferences != null
              ? AuthLocalDataSourceImpl(
                  currentScope.resolve<SharedPreferences>(),
                )
              : AuthMemoryDataSourceImpl(),
        )
        .singleton();

    // AuthRemoteDataSource - использует отдельный Dio без interceptors
    bind<AuthRemoteDataSource>().toProvide(() {
      return AuthRemoteDataSourceImpl(
        dio: currentScope.resolve<Dio>(named: 'authDio'),
        authServiceUrl: currentScope.resolve<String>(named: 'authServiceUrl'),
      );
    }).singleton();

    // ========================================================================
    // Repository
    // ========================================================================

    bind<AuthRepository>()
        .toProvide(
          () => AuthRepositoryImpl(
            remoteDataSource: currentScope.resolve<AuthRemoteDataSource>(),
            localDataSource: currentScope.resolve<AuthLocalDataSource>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Presentation (BLoC)
    // ========================================================================

    bind<AuthBloc>().toProvide(() {
      final authBloc = AuthBloc(
        authRepository: currentScope.resolve<AuthRepository>(),
        logger: currentScope.resolve<Logger>(),
        tokenExpiredStream: currentScope
            .resolve<AuthLocalDataSource>()
            .tokenExpiredStream,
      );
      return authBloc;
    });
  }
}
