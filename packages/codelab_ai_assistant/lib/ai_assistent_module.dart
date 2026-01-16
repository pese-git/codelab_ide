// Dependency Injection контейнер для Clean Architecture
import 'package:cherrypick/cherrypick.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'core/bloc/app_bloc_observer.dart';

// API
import 'features/agent_chat/data/datasources/gateway_api.dart';

// Server Settings
import 'features/server_settings/server_settings.dart';

// Authentication
import 'features/authentication/data/datasources/auth_remote_datasource.dart';
import 'features/authentication/data/datasources/auth_local_datasource.dart';
import 'features/authentication/data/datasources/auth_memory_datasource.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/data/services/auth_interceptor.dart';

// Session Management
import 'features/session_management/data/datasources/session_remote_datasource.dart';
import 'features/session_management/data/datasources/session_local_datasource.dart';
import 'features/session_management/data/repositories/session_repository_impl.dart';
import 'features/session_management/domain/repositories/session_repository.dart';
import 'features/session_management/domain/usecases/create_session.dart';
import 'features/session_management/domain/usecases/load_session.dart';
import 'features/session_management/domain/usecases/list_sessions.dart';
import 'features/session_management/domain/usecases/delete_session.dart';

// Tool Execution
import 'features/tool_execution/data/datasources/tool_executor_datasource.dart';
import 'features/tool_execution/data/datasources/file_system_datasource.dart';
import 'features/tool_execution/data/repositories/tool_repository_impl.dart';
import 'features/tool_execution/domain/repositories/tool_repository.dart';
import 'features/tool_execution/domain/usecases/execute_tool.dart';
import 'features/tool_execution/domain/usecases/request_approval.dart';
import 'features/tool_execution/domain/usecases/validate_safety.dart';
import 'features/tool_execution/data/services/approval_sync_service.dart';

// Agent Chat
import 'features/agent_chat/data/datasources/agent_remote_datasource.dart';
import 'features/agent_chat/data/repositories/agent_repository_impl.dart';
import 'features/agent_chat/domain/repositories/agent_repository.dart';
import 'features/agent_chat/domain/usecases/send_message.dart';
import 'features/agent_chat/domain/usecases/send_tool_result.dart';
import 'features/agent_chat/domain/usecases/receive_messages.dart';
import 'features/agent_chat/domain/usecases/switch_agent.dart';
import 'features/agent_chat/domain/usecases/load_history.dart';
import 'features/agent_chat/domain/usecases/connect.dart';
import 'features/agent_chat/domain/usecases/approve_plan.dart';
import 'features/agent_chat/domain/usecases/reject_plan.dart';
import 'features/agent_chat/domain/usecases/get_active_plan.dart';
import 'features/agent_chat/domain/usecases/watch_plan_updates.dart';

// Presentation
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/session_management/presentation/bloc/session_manager_bloc.dart';
import 'features/agent_chat/presentation/bloc/agent_chat_bloc.dart';
import 'features/tool_execution/presentation/bloc/tool_approval_bloc.dart';

// Services
import 'features/tool_execution/data/services/tool_approval_service_impl.dart';

/// Модуль DI для AI Assistant с Clean Architecture
///
/// Регистрирует все зависимости в правильном порядке:
/// 1. External dependencies (Dio, SharedPreferences, Logger)
/// 2. Data Sources
/// 3. Repositories
/// 4. Use Cases
/// 5. BLoCs (в будущем)
class AiAssistantModule extends Module {
  final String baseUrl;
  final SharedPreferences? sharedPreferences;

  AiAssistantModule({
    this.baseUrl = 'http://localhost',
    this.sharedPreferences,
  });

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
    // External Dependencies
    // ========================================================================

    // Logger
    bind<Logger>()
        .toProvide(
          () => Logger(
            printer: PrettyPrinter(
              methodCount: 0,
              errorMethodCount: 5,
              lineLength: 80,
              colors: true,
              printEmojis: true,
            ),
          ),
        )
        .singleton();

    // BlocObserver для трейсинга состояний всех Bloc'ов
    bind<AppBlocObserver>()
        .toProvide(
          () => AppBlocObserver(logger: currentScope.resolve<Logger>()),
        )
        .singleton();

    // ========================================================================
    // Authentication Feature - Data Sources (создаем ДО AuthInterceptor)
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
        .singleton(); // Автоматически вызовет dispose() при уничтожении scope

    // AuthRemoteDataSource - всегда создаем
    bind<AuthRemoteDataSource>().toProvide(() {
      // Создаем отдельный Dio для auth запросов (без interceptor'ов)
      final authDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return AuthRemoteDataSourceImpl(
        dio: authDio,
        authServiceUrl: currentScope.resolve<String>(named: 'authServiceUrl'),
      );
    }).singleton();

    // AuthInterceptor - всегда включен для JWT авторизации
    bind<AuthInterceptor>().toProvide(() {
      return AuthInterceptor(
        localDataSource: currentScope.resolve<AuthLocalDataSource>(),
        remoteDataSource: currentScope.resolve<AuthRemoteDataSource>(),
        logger: currentScope.resolve<Logger>(),
      );
    }).singleton();

    // Dio HTTP client
    bind<Dio>().toProvide(() {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Добавляем AuthInterceptor для JWT авторизации (всегда включен)
      final authInterceptor = currentScope.resolve<AuthInterceptor>();
      authInterceptor.setDio(dio); // Устанавливаем ссылку на Dio
      dio.interceptors.add(authInterceptor);

      return dio;
    }).singleton();

    // SharedPreferences
    if (sharedPreferences != null) {
      bind<SharedPreferences>().toProvide(() => sharedPreferences!).singleton();
    }

    // GatewayApi
    bind<GatewayApi>()
        .toProvide(
          () => GatewayApi(
            dio: currentScope.resolve<Dio>(),
            baseUrl: currentScope.resolve<String>(named: 'gatewayBaseUrl'),
          ),
        )
        .singleton();

    // ========================================================================
    // Server Settings Feature
    // ========================================================================

    // Data sources
    bind<ServerSettingsLocalDataSource>().toProvide(
      () => ServerSettingsLocalDataSourceImpl(
        currentScope.resolve<SharedPreferences>(),
      ),
    ).singleton();

    bind<ServerSettingsRemoteDataSource>().toProvide(
      () => ServerSettingsRemoteDataSourceImpl(
        dio: currentScope.resolve<Dio>(),
        logger: currentScope.resolve<Logger>(),
      ),
    ).singleton();

    // Repository
    bind<ServerSettingsRepository>().toProvide(
      () => ServerSettingsRepositoryImpl(
        localDataSource: currentScope.resolve<ServerSettingsLocalDataSource>(),
        remoteDataSource: currentScope.resolve<ServerSettingsRemoteDataSource>(),
        logger: currentScope.resolve<Logger>(),
      ),
    ).singleton();

    // Use cases
    bind<LoadSettingsUseCase>().toProvide(
      () => LoadSettingsUseCase(
        currentScope.resolve<ServerSettingsRepository>(),
      ),
    ).singleton();

    bind<SaveSettingsUseCase>().toProvide(
      () => SaveSettingsUseCase(
        currentScope.resolve<ServerSettingsRepository>(),
      ),
    ).singleton();

    bind<TestConnectionUseCase>().toProvide(
      () => TestConnectionUseCase(
        currentScope.resolve<ServerSettingsRepository>(),
      ),
    ).singleton();

    bind<ClearSettingsUseCase>().toProvide(
      () => ClearSettingsUseCase(
        currentScope.resolve<ServerSettingsRepository>(),
      ),
    ).singleton();

    // BLoC
    bind<ServerSettingsBloc>().toProvide(
      () => ServerSettingsBloc(
        loadSettings: currentScope.resolve<LoadSettingsUseCase>(),
        saveSettings: currentScope.resolve<SaveSettingsUseCase>(),
        testConnection: currentScope.resolve<TestConnectionUseCase>(),
        clearSettings: currentScope.resolve<ClearSettingsUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );

    // ========================================================================
    // Authentication Feature - Repository
    // ========================================================================

    // Repository (использует data sources, созданные выше)
    bind<AuthRepository>()
        .toProvide(
          () => AuthRepositoryImpl(
            remoteDataSource: currentScope.resolve<AuthRemoteDataSource>(),
            localDataSource: currentScope.resolve<AuthLocalDataSource>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Session Management Feature
    // ========================================================================

    // Data Sources
    bind<SessionRemoteDataSource>()
        .toProvide(
          () => SessionRemoteDataSourceImpl(
            dio: currentScope.resolve<Dio>(),
            baseUrl: currentScope.resolve<String>(named: 'gatewayBaseUrl'),
          ),
        )
        .singleton();

    if (sharedPreferences != null) {
      bind<SessionLocalDataSource>()
          .toProvide(
            () => SessionLocalDataSourceImpl(
              currentScope.resolve<SharedPreferences>(),
            ),
          )
          .singleton();
    }

    // Repository
    if (sharedPreferences != null) {
      bind<SessionRepository>()
          .toProvide(
            () => SessionRepositoryImpl(
              remoteDataSource: currentScope.resolve<SessionRemoteDataSource>(),
              localDataSource: currentScope.resolve<SessionLocalDataSource>(),
            ),
          )
          .singleton();
    }

    // Use Cases
    if (sharedPreferences != null) {
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
    }

    // ========================================================================
    // Tool Execution Feature
    // ========================================================================

    // Data Sources
    bind<FileSystemDataSource>().toProvide(() => FileSystemDataSourceImpl());

    bind<ToolExecutorDataSource>().toProvide(
      () => ToolExecutorDataSourceImpl(
        fileSystem: currentScope.resolve<FileSystemDataSource>(),
      ),
    );

    // ApprovalSyncService for restoring pending approvals
    bind<ApprovalSyncService>()
        .toProvide(
          () => ApprovalSyncService(
            api: currentScope.resolve<GatewayApi>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();

    // ToolApprovalService implementation
    bind<ToolApprovalServiceImpl>()
        .toProvide(
          () => ToolApprovalServiceImpl(
            syncService: currentScope.resolve<ApprovalSyncService>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();

    // ToolApprovalService interface for repository
    bind<ToolApprovalService>()
        .toProvide(() => currentScope.resolve<ToolApprovalServiceImpl>())
        .singleton();

    // Repository
    bind<ToolRepository>()
        .toProvide(
          () => ToolRepositoryImpl(
            executor: currentScope.resolve<ToolExecutorDataSource>(),
            approvalService: currentScope.resolve<ToolApprovalService>(),
          ),
        )
        .singleton();

    // Use Cases
    bind<ExecuteToolUseCase>().toProvide(
      () => ExecuteToolUseCase(currentScope.resolve<ToolRepository>()),
    );

    bind<RequestApprovalUseCase>().toProvide(
      () => RequestApprovalUseCase(currentScope.resolve<ToolRepository>()),
    );

    bind<ValidateSafetyUseCase>().toProvide(
      () => ValidateSafetyUseCase(currentScope.resolve<ToolRepository>()),
    );

    // ========================================================================
    // Agent Chat Feature
    // ========================================================================

    // Data Sources
    bind<AgentRemoteDataSource>()
        .toProvide(
          () => AgentRemoteDataSourceImpl(
            gatewayUrl: currentScope
                .resolve<String>(named: 'gatewayBaseUrl')
                .replaceFirst('http', 'ws'),
          ),
        )
        .singleton();

    // Repository
    bind<AgentRepository>()
        .toProvide(
          () => AgentRepositoryImpl(
            remoteDataSource: currentScope.resolve<AgentRemoteDataSource>(),
            gatewayApi: currentScope.resolve<GatewayApi>(),
          ),
        )
        .singleton();

    // Use Cases
    bind<SendMessageUseCase>().toProvide(
      () => SendMessageUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<SendToolResultUseCase>().toProvide(
      () => SendToolResultUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<ReceiveMessagesUseCase>().toProvide(
      () => ReceiveMessagesUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<SwitchAgentUseCase>().toProvide(
      () => SwitchAgentUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<LoadHistoryUseCase>().toProvide(
      () => LoadHistoryUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<ConnectUseCase>().toProvide(
      () => ConnectUseCase(currentScope.resolve<AgentRepository>()),
    );

    // Planning Use Cases
    bind<ApprovePlanUseCase>().toProvide(
      () => ApprovePlanUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<RejectPlanUseCase>().toProvide(
      () => RejectPlanUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<GetActivePlanUseCase>().toProvide(
      () => GetActivePlanUseCase(currentScope.resolve<AgentRepository>()),
    );

    bind<WatchPlanUpdatesUseCase>().toProvide(
      () => WatchPlanUpdatesUseCase(currentScope.resolve<AgentRepository>()),
    );

    // ========================================================================
    // Presentation Layer (BLoCs)
    // ========================================================================

    // AuthBloc - всегда создается для JWT авторизации
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

    // SessionManagerBloc
    if (sharedPreferences != null) {
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

    // AgentChatBloc
    bind<AgentChatBloc>().toProvide(
      () => AgentChatBloc(
        sendMessage: currentScope.resolve<SendMessageUseCase>(),
        sendToolResult: currentScope.resolve<SendToolResultUseCase>(),
        receiveMessages: currentScope.resolve<ReceiveMessagesUseCase>(),
        switchAgent: currentScope.resolve<SwitchAgentUseCase>(),
        loadHistory: currentScope.resolve<LoadHistoryUseCase>(),
        connect: currentScope.resolve<ConnectUseCase>(),
        executeTool: currentScope.resolve<ExecuteToolUseCase>(),
        approvalService: currentScope.resolve<ToolApprovalServiceImpl>(),
        approvePlan: currentScope.resolve<ApprovePlanUseCase>(),
        rejectPlan: currentScope.resolve<RejectPlanUseCase>(),
        getActivePlan: currentScope.resolve<GetActivePlanUseCase>(),
        watchPlanUpdates: currentScope.resolve<WatchPlanUpdatesUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );

    // ToolApprovalBloc
    bind<ToolApprovalBloc>().toProvide(
      () => ToolApprovalBloc(
        requestApproval: currentScope.resolve<RequestApprovalUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );
  }
}
