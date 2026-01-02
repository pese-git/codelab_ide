// lib/ai_agent/di/ai_agent_module.dart

import 'package:cherrypick/cherrypick.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:codelab_core/codelab_core.dart';
import '../data/websocket_agent_repository.dart';
import '../domain/agent_protocol_service.dart';
import '../bloc/ai_agent_bloc.dart';
import '../integration/tool_api.dart';
import '../services/tool_executor.dart';
import '../services/tool_approval_service.dart';
import '../services/gateway_service.dart';
import '../services/session_restore_service.dart';
import '../api/gateway_api.dart';
import '../bloc/session_manager_bloc.dart';

class AiAssistantModule extends Module {
  final String gatewayBaseUrl;
  final String internalApiKey;
  final bool useMockApi;
  final GlobalKey<NavigatorState>? navigatorKey;
  final SharedPreferences? sharedPreferences;
  
  AiAssistantModule({
    this.gatewayBaseUrl = 'http://localhost:8000',
    this.internalApiKey = 'change-me-internal-key',
    this.navigatorKey,
    this.useMockApi = false,
    this.sharedPreferences,
  });

  @override
  void builder(Scope currentScope) {
    // SharedPreferences — singleton (передается извне или создается)
    if (sharedPreferences != null) {
      bind<SharedPreferences>()
          .toProvide(() => sharedPreferences!)
          .singleton();
    }

    // Logger — singleton
    bind<Logger>()
        .toProvide(() => Logger(
              printer: PrettyPrinter(
                methodCount: 0,
                errorMethodCount: 5,
                lineLength: 80,
                colors: true,
                printEmojis: true,
              ),
            ))
        .singleton();

    // Dio HTTP client — singleton
    bind<Dio>()
        .toProvide(() {
          final dio = Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ));
          
          // Добавить интерцептор для внутренней аутентификации
          dio.interceptors.add(InterceptorsWrapper(
            onRequest: (options, handler) {
              // Добавить X-Internal-Auth заголовок ко всем запросам
              options.headers['X-Internal-Auth'] = internalApiKey;
              return handler.next(options);
            },
          ));
          
          // Добавить логирование запросов (опционально)
          dio.interceptors.add(LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (obj) => currentScope.resolve<Logger>().d(obj),
          ));
          
          return dio;
        })
        .singleton();

    // Gateway API — singleton
    bind<GatewayApi>()
        .toProvide(() => GatewayApi(
              dio: currentScope.resolve<Dio>(),
              baseUrl: gatewayBaseUrl,
            ))
        .singleton();

    // Gateway Service — singleton
    bind<GatewayService>()
        .toProvide(() => GatewayService(
              api: currentScope.resolve<GatewayApi>(),
              logger: currentScope.resolve<Logger>(),
            ))
        .singleton();

    // Session Restore Service — singleton
    // Требует SharedPreferences, который должен быть передан в конструктор модуля
    if (sharedPreferences != null) {
      bind<SessionRestoreService>()
          .toProvide(() => SessionRestoreService(
                gatewayService: currentScope.resolve<GatewayService>(),
                prefs: currentScope.resolve<SharedPreferences>(),
                logger: currentScope.resolve<Logger>(),
              ))
          .singleton();
    }

    // WebSocket-репозиторий — singleton
    // Теперь использует gatewayUrl вместо полного wsUrl
    bind<WebSocketAgentRepository>()
        .toProvide(() => WebSocketAgentRepository(
              gatewayUrl: gatewayBaseUrl.replaceFirst('http', 'ws'),
            ))
        .singleton();

    // Протокол-сервис (AgentProtocolService) — singleton
    bind<AgentProtocolService>()
        .toProvide(
          () => AgentProtocolServiceImpl(
            currentScope.resolve<WebSocketAgentRepository>(),
          ),
        )
        .singleton();

    // ToolExecutor — factory
    // Создается при каждом вызове и динамически получает workspace root
    // из ProjectManagerService при выполнении каждого tool call
    bind<ToolExecutor>().toProvide(() => ToolExecutor());

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
        approvalService: currentScope.resolve<ToolApprovalService>(),
      ),
    );

    // Session Manager Bloc — factory
    // Создается для каждого открытия диалога управления сессиями
    if (sharedPreferences != null) {
      bind<SessionManagerBloc>().toProvide(
        () => SessionManagerBloc(
          sessionService: currentScope.resolve<SessionRestoreService>(),
          logger: currentScope.resolve<Logger>(),
        ),
      );
    }
  }
}
