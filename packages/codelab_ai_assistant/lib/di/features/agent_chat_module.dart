// Agent Chat Feature Module
import 'package:cherrypick/cherrypick.dart';
import 'package:logger/logger.dart';

import '../../features/agent_chat/data/datasources/agent_remote_datasource.dart';
import '../../features/agent_chat/data/datasources/gateway_api.dart';
import '../../features/agent_chat/data/repositories/agent_repository_impl.dart';
import '../../features/agent_chat/domain/repositories/agent_repository.dart';
import '../../features/agent_chat/domain/usecases/connect.dart';
import '../../features/agent_chat/domain/usecases/load_history.dart';
import '../../features/agent_chat/domain/usecases/receive_messages.dart';
import '../../features/agent_chat/domain/usecases/send_message.dart';
import '../../features/agent_chat/domain/usecases/send_plan_decision.dart';
import '../../features/agent_chat/domain/usecases/send_tool_result.dart';
import '../../features/agent_chat/domain/usecases/switch_agent.dart';
import '../../features/agent_chat/presentation/bloc/agent_chat_bloc.dart';
import '../../features/agent_chat/presentation/middleware/connection_middleware.dart';
import '../../features/agent_chat/presentation/middleware/message_handler_middleware.dart';
import '../../features/agent_chat/presentation/middleware/approval_middleware.dart';
import '../../features/approval/domain/services/approval_service.dart';
import '../../features/tool_execution/domain/usecases/execute_tool.dart';

/// Модуль для регистрации зависимостей Agent Chat feature
///
/// Включает:
/// - AgentRemoteDataSource (WebSocket)
/// - AgentRepository
/// - Use Cases (send, receive, switch, connect, etc.)
/// - Middleware (connection, message handler, approval)
/// - AgentChatBloc
///
/// Зависимости:
/// - Logger (из CoreModule)
/// - GatewayApi (из NetworkModule)
/// - String с именем 'gatewayBaseUrl' (из NetworkModule)
/// - ApprovalService (из ApprovalModule) - UNIFIED
/// - ExecuteToolUseCase (из ToolModule)
class AgentChatModule extends Module {
  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Data Sources
    // ========================================================================

    bind<AgentRemoteDataSource>()
        .toProvide(
          () => AgentRemoteDataSourceImpl(
            gatewayUrl: currentScope
                .resolve<String>(named: 'gatewayBaseUrl')
                .replaceFirst('http', 'ws'),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Repository
    // ========================================================================

    bind<AgentRepository>()
        .toProvide(
          () => AgentRepositoryImpl(
            remoteDataSource: currentScope.resolve<AgentRemoteDataSource>(),
            gatewayApi: currentScope.resolve<GatewayApi>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Use Cases
    // ========================================================================

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

    bind<SendPlanDecisionUseCase>().toProvide(
      () => SendPlanDecisionUseCase(currentScope.resolve<AgentRepository>()),
    );

    // ========================================================================
    // Middleware
    // ========================================================================

    bind<ConnectionMiddleware>().toProvide(
      () => ConnectionMiddleware(
        connect: currentScope.resolve<ConnectUseCase>(),
        receiveMessages: currentScope.resolve<ReceiveMessagesUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );

    bind<MessageHandlerMiddleware>().toProvide(
      () => MessageHandlerMiddleware(
        executeTool: currentScope.resolve<ExecuteToolUseCase>(),
        sendToolResult: currentScope.resolve<SendToolResultUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );

    bind<ApprovalMiddleware>().toProvide(
      () => ApprovalMiddleware(
        approvalService: currentScope.resolve<ApprovalService>(),
        executeTool: currentScope.resolve<ExecuteToolUseCase>(),
        sendToolResult: currentScope.resolve<SendToolResultUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );

    // ========================================================================
    // Presentation (BLoC)
    // ========================================================================

    bind<AgentChatBloc>().toProvide(
      () => AgentChatBloc(
        connectionMiddleware: currentScope.resolve<ConnectionMiddleware>(),
        messageHandlerMiddleware: currentScope.resolve<MessageHandlerMiddleware>(),
        approvalMiddleware: currentScope.resolve<ApprovalMiddleware>(),
        sendMessage: currentScope.resolve<SendMessageUseCase>(),
        switchAgent: currentScope.resolve<SwitchAgentUseCase>(),
        loadHistory: currentScope.resolve<LoadHistoryUseCase>(),
        sendPlanDecision: currentScope.resolve<SendPlanDecisionUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );
  }
}
