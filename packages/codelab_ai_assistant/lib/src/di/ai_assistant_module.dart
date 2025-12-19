// lib/ai_agent/di/ai_agent_module.dart

import 'package:cherrypick/cherrypick.dart';
import '../data/websocket_agent_repository.dart';
import '../domain/agent_protocol_service.dart';
import '../bloc/ai_agent_bloc.dart';
import '../integration/tool_api.dart';

class AiAssistantModule extends Module {
  final String wsUrl;
  final bool useMockApi;
  AiAssistantModule({required this.wsUrl, this.useMockApi = false});

  @override
  void builder(Scope currentScope) {
    // WebSocket-репозиторий — singleton
    bind<WebSocketAgentRepository>()
        .toProvide(() => WebSocketAgentRepository(wsUrl: wsUrl))
        .singleton();

    // Протокол-сервис (AgentProtocolService) — singleton
    bind<AgentProtocolService>()
        .toProvide(
          () => AgentProtocolServiceImpl(
            currentScope.resolve<WebSocketAgentRepository>(),
          ),
        )
        .singleton();

    // ToolApi — singleton, можно подменить на mock реализацию
    bind<ToolApi>()
        .toProvide(() => useMockApi ? ToolApiMock() : ToolApiImpl())
        .singleton();

    // Bloc — factory: на каждый новый чат отдельный экземпляр блока
    bind<AiAgentBloc>().toProvide(
      () => AiAgentBloc(
        protocol: currentScope.resolve<AgentProtocolService>(),
        toolApi: currentScope.resolve<ToolApi>(),
      ),
    );
  }
}
