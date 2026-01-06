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
export 'core/bloc/app_bloc_observer.dart';
export 'core/bloc/bloc_setup.dart';

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
export 'features/agent_chat/presentation/pages/chat_page.dart';

// ============================================================================
// Session Management Presentation
// ============================================================================

export 'features/session_management/presentation/pages/session_list_page.dart';
export 'features/session_management/presentation/molecules/session_card.dart';

// ============================================================================
// Authentication Presentation
// ============================================================================

export 'features/authentication/presentation/bloc/auth_bloc.dart';
export 'features/authentication/presentation/pages/login_page.dart';
export 'features/authentication/presentation/widgets/auth_wrapper.dart';

// ============================================================================
// Shared Presentation Components
// ============================================================================

export 'features/shared/presentation/theme/app_theme.dart';
export 'features/shared/presentation/atoms/buttons/primary_button.dart';
export 'features/shared/presentation/molecules/feedback/empty_state.dart';
export 'features/shared/presentation/molecules/cards/base_card.dart';
export 'features/shared/utils/extensions/context_extensions.dart';
export 'features/shared/utils/extensions/agent_type_extensions.dart';
export 'features/shared/utils/formatters/date_formatter.dart';
export 'features/shared/utils/formatters/agent_formatter.dart';

// ============================================================================
// Tool Execution Widgets
// ============================================================================

export 'features/tool_execution/presentation/widgets/tool_approval_dialog.dart';

// ============================================================================
// Dependency Injection
// ============================================================================

export 'ai_assistent_module.dart';
