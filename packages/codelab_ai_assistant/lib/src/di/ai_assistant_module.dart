// lib/ai_agent/di/ai_agent_module.dart

import 'package:cherrypick/cherrypick.dart';
import 'package:flutter/material.dart';
import 'package:codelab_core/codelab_core.dart';
import '../data/websocket_agent_repository.dart';
import '../domain/agent_protocol_service.dart';
import '../bloc/ai_agent_bloc.dart';
import '../integration/tool_api.dart';
import '../services/tool_executor.dart';
import '../services/tool_approval_service.dart';

class AiAssistantModule extends Module {
  final String wsUrl;
  final bool useMockApi;
  final GlobalKey<NavigatorState>? navigatorKey;
  
  AiAssistantModule({
    required this.wsUrl,
    this.navigatorKey,
    this.useMockApi = false,
  });

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

    // PathValidator — factory
    // Создается динамически с текущим workspace root из ProjectManagerService
    // Это позволяет поддерживать смену проекта без перезапуска приложения
    bind<PathValidator>().toProvide(() {
      // Пытаемся получить ProjectManagerService из scope
      // Если не найден, используем fallback значение
      try {
        final projectManager = currentScope.resolve<ProjectManagerService>();
        final project = projectManager.currentProject;
        if (project != null) {
          return PathValidator(workspaceRoot: project.path);
        }
      } catch (e) {
        // ProjectManagerService не зарегистрирован или проект не выбран
      }
      
      // Fallback: используем временную директорию
      // В production это должно вызывать ошибку, но для разработки допустимо
      return PathValidator(workspaceRoot: '/tmp');
    });

    // ToolExecutor — factory
    // Создается с новым PathValidator при каждом вызове
    // Это гарантирует актуальность workspace root
    bind<ToolExecutor>()
        .toProvide(() => ToolExecutor(
              pathValidator: currentScope.resolve<PathValidator>(),
            ));

    // ToolApprovalService — singleton
    // Обрабатывает запросы на подтверждение HITL операций
    bind<ToolApprovalService>()
        .toProvide(() => ToolApprovalServiceImpl())
        .singleton();

    // ToolApi — factory
    // Создается с новым ToolExecutor при каждом вызове
    // Это обеспечивает актуальность workspace root
    bind<ToolApi>()
        .toProvide(() {
          if (useMockApi) {
            return ToolApiMock();
          }
          return ToolApiImpl(
            toolExecutor: currentScope.resolve<ToolExecutor>(),
            approvalService: currentScope.resolve<ToolApprovalService>(),
          );
        });

    // Bloc — factory: на каждый новый чат отдельный экземпляр блока
    bind<AiAgentBloc>().toProvide(
      () => AiAgentBloc(
        protocol: currentScope.resolve<AgentProtocolService>(),
        toolApi: currentScope.resolve<ToolApi>(),
      ),
    );
  }
}
