// Tool Execution Feature Module
import 'package:cherrypick/cherrypick.dart';
import 'package:logger/logger.dart';

import '../../features/tool_execution/data/datasources/file_system_datasource.dart';
import '../../features/tool_execution/data/datasources/tool_executor_datasource.dart';
import '../../features/tool_execution/data/repositories/tool_repository_impl.dart';
import '../../features/tool_execution/domain/repositories/tool_repository.dart';
import '../../features/tool_execution/domain/usecases/execute_tool.dart';
import '../../features/tool_execution/domain/usecases/request_approval.dart';
import '../../features/tool_execution/domain/usecases/validate_safety.dart';
import '../../features/tool_execution/presentation/bloc/tool_approval_bloc.dart';
import '../../features/approval/domain/services/approval_service.dart';

/// Модуль для регистрации зависимостей Tool Execution feature
///
/// Включает:
/// - FileSystemDataSource (локальная файловая система)
/// - ToolExecutorDataSource (выполнение инструментов)
/// - ToolRepository
/// - Use Cases (execute, request approval, validate safety)
/// - ToolApprovalBloc
///
/// Зависимости:
/// - Logger (из CoreModule)
/// - ApprovalService (из ApprovalModule) - UNIFIED
class ToolModule extends Module {
  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Data Sources
    // ========================================================================

    bind<FileSystemDataSource>().toProvide(() => FileSystemDataSourceImpl());

    bind<ToolExecutorDataSource>().toProvide(
      () => ToolExecutorDataSourceImpl(
        fileSystem: currentScope.resolve<FileSystemDataSource>(),
      ),
    );

    // ========================================================================
    // Repository
    // ========================================================================

    bind<ToolRepository>()
        .toProvide(
          () => ToolRepositoryImpl(
            executor: currentScope.resolve<ToolExecutorDataSource>(),
            approvalService: currentScope.resolve<ApprovalService>(),
          ),
        )
        .singleton();

    // ========================================================================
    // Use Cases
    // ========================================================================

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
    // Presentation (BLoC)
    // ========================================================================

    bind<ToolApprovalBloc>().toProvide(
      () => ToolApprovalBloc(
        requestApproval: currentScope.resolve<RequestApprovalUseCase>(),
        logger: currentScope.resolve<Logger>(),
      ),
    );
  }
}
