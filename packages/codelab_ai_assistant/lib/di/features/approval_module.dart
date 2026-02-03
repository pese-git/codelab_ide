// Approval Feature Module - Unified Approval System
import 'package:cherrypick/cherrypick.dart';
import 'package:logger/logger.dart';

import '../../core/config/feature_flags.dart';
import '../../features/approval/data/datasources/approval_api_datasource.dart';
import '../../features/approval/data/datasources/approval_api_datasource_impl.dart';
import '../../features/approval/data/services/unified_approval_service_impl.dart';
import '../../features/approval/domain/services/approval_service.dart';
import '../../features/agent_chat/data/datasources/agent_remote_datasource.dart';
import '../../features/agent_chat/data/datasources/gateway_api.dart';

// Legacy imports (будут удалены в Фазе 2.3)
import '../../features/tool_execution/data/services/approval_sync_service.dart';
import '../../features/tool_execution/data/services/tool_approval_service_impl.dart';
import '../../features/approval/data/services/tool_approval_service_adapter.dart';

/// Модуль для регистрации зависимостей Approval System
///
/// Поддерживает два режима работы (через FeatureFlags):
/// 1. Legacy mode (useUnifiedApproval = false):
///    - ToolApprovalService (старая реализация)
///    - ApprovalSyncService
///    - ToolApprovalServiceAdapter
///
/// 2. Unified mode (useUnifiedApproval = true):
///    - ApprovalService (новая унифицированная система)
///    - ApprovalApiDataSource
///
/// Зависимости:
/// - Logger (из CoreModule)
/// - GatewayApi (из NetworkModule)
/// - AgentRemoteDataSource (из AgentChatModule)
class ApprovalModule extends Module {
  @override
  void builder(Scope currentScope) {
    if (FeatureFlags.useUnifiedApproval) {
      _registerUnifiedApprovalSystem(currentScope);
    } else {
      _registerLegacyApprovalSystem(currentScope);
    }
  }

  /// Регистрация новой унифицированной системы approvals
  void _registerUnifiedApprovalSystem(Scope currentScope) {
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

    // Для обратной совместимости с AgentChatBloc
    // TODO: Удалить после миграции AgentChatBloc на ApprovalService
    bind<ToolApprovalService>()
        .toProvide(
          () => ToolApprovalServiceAdapter(
            unifiedService: currentScope.resolve<ApprovalService>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();
  }

  /// Регистрация legacy системы approvals (будет удалена в Фазе 2.3)
  void _registerLegacyApprovalSystem(Scope currentScope) {
    // ========================================================================
    // Legacy Approval System (deprecated)
    // ========================================================================

    // ApprovalSyncService for restoring pending approvals
    bind<ApprovalSyncService>()
        .toProvide(
          () => ApprovalSyncService(
            api: currentScope.resolve<GatewayApi>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();

    // ToolApprovalServiceImpl - legacy implementation
    bind<ToolApprovalService>()
        .toProvide(
          () => ToolApprovalServiceImpl(
            syncService: currentScope.resolve<ApprovalSyncService>(),
            logger: currentScope.resolve<Logger>(),
          ),
        )
        .singleton();
  }
}
