// Dependency Injection контейнер для Clean Architecture
import 'package:cherrypick/cherrypick.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// API
import 'src/api/gateway_api.dart';

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

// Agent Chat
import 'features/agent_chat/data/datasources/agent_remote_datasource.dart';
import 'features/agent_chat/data/repositories/agent_repository_impl.dart';
import 'features/agent_chat/domain/repositories/agent_repository.dart';
import 'features/agent_chat/domain/usecases/send_message.dart';
import 'features/agent_chat/domain/usecases/receive_messages.dart';
import 'features/agent_chat/domain/usecases/switch_agent.dart';
import 'features/agent_chat/domain/usecases/load_history.dart';
import 'features/agent_chat/domain/usecases/connect.dart';
import 'features/tool_execution/domain/entities/tool_approval.dart';
import 'features/tool_execution/domain/entities/tool_call.dart';

// Presentation
import 'features/session_management/presentation/bloc/session_manager_bloc.dart';
import 'features/agent_chat/presentation/bloc/agent_chat_bloc.dart';
import 'features/tool_execution/presentation/bloc/tool_approval_bloc.dart';

// Adapters
import 'features/tool_execution/data/adapters/tool_approval_service_adapter.dart';

// Legacy services (для адаптеров)
import 'src/services/tool_approval_service.dart' as legacy;

/// Модуль DI для AI Assistant с Clean Architecture
///
/// Регистрирует все зависимости в правильном порядке:
/// 1. External dependencies (Dio, SharedPreferences, Logger)
/// 2. Data Sources
/// 3. Repositories
/// 4. Use Cases
/// 5. BLoCs (в будущем)
class AiAssistantCleanModule extends Module {
  final String gatewayBaseUrl;
  final String internalApiKey;
  final SharedPreferences? sharedPreferences;

  AiAssistantCleanModule({
    this.gatewayBaseUrl = 'http://localhost:8000',
    this.internalApiKey = 'change-me-internal-key',
    this.sharedPreferences,
  });

  @override
  void builder(Scope currentScope) {
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

    // Dio HTTP client
    bind<Dio>().toProvide(() {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Internal auth interceptor
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['X-Internal-Auth'] = internalApiKey;
            return handler.next(options);
          },
        ),
      );

      return dio;
    }).singleton();

    // SharedPreferences
    if (sharedPreferences != null) {
      bind<SharedPreferences>().toProvide(() => sharedPreferences!).singleton();
    }
    
    // GatewayApi
    bind<GatewayApi>()
        .toProvide(() => GatewayApi(
              dio: currentScope.resolve<Dio>(),
              baseUrl: gatewayBaseUrl,
            ))
        .singleton();

    // ========================================================================
    // Session Management Feature
    // ========================================================================

    // Data Sources
    bind<SessionRemoteDataSource>()
        .toProvide(
          () => SessionRemoteDataSourceImpl(
            dio: currentScope.resolve<Dio>(),
            baseUrl: gatewayBaseUrl,
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

    // Legacy ToolApprovalService (для адаптера)
    bind<legacy.ToolApprovalService>()
        .toProvide(() => legacy.ToolApprovalServiceImpl())
        .singleton();

    // ToolApprovalService adapter
    bind<ToolApprovalService>()
        .toProvide(
          () => ToolApprovalServiceFactory.createAdapter(
            currentScope.resolve<legacy.ToolApprovalService>(),
          ),
        )
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
            gatewayUrl: gatewayBaseUrl.replaceFirst('http', 'ws') + '/api/v1',
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

    // ========================================================================
    // Presentation Layer (BLoCs)
    // ========================================================================

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
        receiveMessages: currentScope.resolve<ReceiveMessagesUseCase>(),
        switchAgent: currentScope.resolve<SwitchAgentUseCase>(),
        loadHistory: currentScope.resolve<LoadHistoryUseCase>(),
        connect: currentScope.resolve<ConnectUseCase>(),
        executeTool: currentScope.resolve<ExecuteToolUseCase>(),
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
