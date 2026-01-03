/// Clean Architecture AI Assistant
/// 
/// Модуль для работы с AI агентами, построенный по принципам Clean Architecture.
/// Использует функциональное программирование (fpdart) для явной обработки ошибок.
library;

// ============================================================================
// Core
// ============================================================================

export 'core/error/failures.dart';
export 'core/error/exceptions.dart';
export 'core/usecases/usecase.dart';
export 'core/utils/type_defs.dart';

// ============================================================================
// Session Management Feature
// ============================================================================

// Domain
export 'features/session_management/domain/entities/session.dart';
export 'features/session_management/domain/repositories/session_repository.dart';
export 'features/session_management/domain/usecases/create_session.dart';
export 'features/session_management/domain/usecases/load_session.dart';
export 'features/session_management/domain/usecases/list_sessions.dart';
export 'features/session_management/domain/usecases/delete_session.dart';

// Presentation
export 'features/session_management/presentation/bloc/session_manager_bloc.dart'
    hide InitialState, LoadingState, ErrorState, $ErrorStateCopyWith;

// ============================================================================
// Tool Execution Feature
// ============================================================================

// Domain
export 'features/tool_execution/domain/entities/tool_call.dart';
export 'features/tool_execution/domain/entities/tool_result.dart';
export 'features/tool_execution/domain/entities/tool_approval.dart';
export 'features/tool_execution/domain/repositories/tool_repository.dart';
export 'features/tool_execution/domain/usecases/execute_tool.dart';
export 'features/tool_execution/domain/usecases/request_approval.dart';
export 'features/tool_execution/domain/usecases/validate_safety.dart';

// Presentation
export 'features/tool_execution/presentation/bloc/tool_approval_bloc.dart' hide InitialState, ErrorState;

// ============================================================================
// Agent Chat Feature
// ============================================================================

// Domain
export 'features/agent_chat/domain/entities/message.dart';
export 'features/agent_chat/domain/entities/agent.dart';
export 'features/agent_chat/domain/repositories/agent_repository.dart';
export 'features/agent_chat/domain/usecases/send_message.dart';
export 'features/agent_chat/domain/usecases/send_tool_result.dart';
export 'features/agent_chat/domain/usecases/receive_messages.dart';
export 'features/agent_chat/domain/usecases/switch_agent.dart';
export 'features/agent_chat/domain/usecases/load_history.dart';

// Presentation
export 'features/agent_chat/presentation/bloc/agent_chat_bloc.dart';
export 'features/agent_chat/presentation/widgets/ai_assistant_panel.dart';
export 'features/agent_chat/presentation/widgets/chat_view.dart';

// ============================================================================
// Session Management Widgets
// ============================================================================

export 'features/session_management/presentation/widgets/session_list_view.dart';
export 'features/session_management/presentation/widgets/session_manager_widget.dart';

// ============================================================================
// Tool Execution Widgets
// ============================================================================

export 'features/tool_execution/presentation/widgets/tool_approval_dialog.dart';

// ============================================================================
// Dependency Injection
// ============================================================================

export 'injection_container.dart';
