// Approval Feature Module - Unified Approval System
import 'package:cherrypick/cherrypick.dart';
import 'package:logger/logger.dart';

import '../../features/approval/data/datasources/approval_api_datasource.dart';
import '../../features/approval/data/datasources/approval_api_datasource_impl.dart';
import '../../features/approval/data/services/unified_approval_service_impl.dart';
import '../../features/approval/domain/services/approval_service.dart';
import '../../features/agent_chat/data/datasources/agent_remote_datasource.dart';
import '../../features/agent_chat/data/datasources/gateway_api.dart';

/// Модуль для регистрации зависимостей Unified Approval System
///
/// Предоставляет единую систему для всех типов подтверждений:
/// - Tool approval (подтверждение выполнения инструментов)
/// - Plan approval (подтверждение планов)
/// - Будущие типы (file operations, dangerous commands, etc.)
///
/// Зависимости:
/// - Logger (из CoreModule)
/// - GatewayApi (из NetworkModule)
/// - AgentRemoteDataSource (из AgentChatModule)
class ApprovalModule extends Module {
  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Unified Approval System
    // ========================================================================

    // ApprovalApiDataSource - unified data source for all approval types
    bind<ApprovalApiDataSource>()
        .toProvide(
          () => ApprovalApiDataSourceImpl(
            gatewayApi: currentScope.resolve<GatewayApi>(),
            remoteDataSource: currentScope.resolve<AgentRemoteDataSource>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();

    // ApprovalService - domain service for all approval types
    bind<ApprovalService>()
        .toProvide(
          () => UnifiedApprovalServiceImpl(
            apiDataSource: currentScope.resolve<ApprovalApiDataSource>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();
  }
}
