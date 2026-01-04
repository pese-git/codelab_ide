# Миграция на Clean Architecture - План удаления legacy кода

## Статус: Готово к миграции

Новая архитектура полностью реализована и готова к использованию.

## Текущая ситуация

### ✅ Новая архитектура (100%)
Все слои реализованы:
- Core infrastructure
- Domain layers для 3 фич
- Data layers для 3 фич
- Presentation layers (3 BLoCs)
- DI container

### ⚠️ Legacy код (требует удаления)
Старые файлы в `lib/src/`:
- `bloc/` - старые BLoCs
- `data/` - старый WebSocketAgentRepository
- `domain/` - старый AgentProtocolService
- `services/` - старые сервисы
- `models/` - старые модели (частично используются)
- `integration/` - старый ToolApi
- `api/` - старый GatewayApi (частично используется)
- `ui/` - старые UI компоненты (требуют обновления)
- `widgets/` - старые виджеты (требуют обновления)

## План миграции

### Этап 1: Обновить экспорты (КРИТИЧНО)

Обновить [`lib/codelab_ai_assistant.dart`](lib/codelab_ai_assistant.dart):

```dart
/// Clean Architecture AI Assistant
library;

// Core
export 'core/error/failures.dart';
export 'core/error/exceptions.dart';
export 'core/usecases/usecase.dart';
export 'core/utils/type_defs.dart';

// Session Management
export 'features/session_management/domain/entities/session.dart';
export 'features/session_management/domain/usecases/create_session.dart';
export 'features/session_management/domain/usecases/load_session.dart';
export 'features/session_management/domain/usecases/list_sessions.dart';
export 'features/session_management/domain/usecases/delete_session.dart';
export 'features/session_management/presentation/bloc/session_manager_bloc.dart';

// Tool Execution
export 'features/tool_execution/domain/entities/tool_call.dart';
export 'features/tool_execution/domain/entities/tool_result.dart';
export 'features/tool_execution/domain/entities/tool_approval.dart';
export 'features/tool_execution/domain/usecases/execute_tool.dart';
export 'features/tool_execution/domain/usecases/request_approval.dart';
export 'features/tool_execution/domain/usecases/validate_safety.dart';
export 'features/tool_execution/presentation/bloc/tool_approval_bloc.dart';

// Agent Chat
export 'features/agent_chat/domain/entities/message.dart';
export 'features/agent_chat/domain/entities/agent.dart';
export 'features/agent_chat/domain/usecases/send_message.dart';
export 'features/agent_chat/domain/usecases/receive_messages.dart';
export 'features/agent_chat/domain/usecases/switch_agent.dart';
export 'features/agent_chat/domain/usecases/load_history.dart';
export 'features/agent_chat/presentation/bloc/agent_chat_bloc.dart';

// DI
export 'injection_container.dart';

// UI (временно, пока не мигрированы)
export 'src/ui/ai_assistant_panel.dart';
export 'src/ui/chat_view.dart';
export 'src/ui/session_list_view.dart';
```

### Этап 2: Удалить старые BLoCs

Удалить файлы:
- `lib/src/bloc/ai_agent_bloc.dart`
- `lib/src/bloc/session_manager_bloc.dart`

Эти BLoCs заменены на:
- `lib/features/agent_chat/presentation/bloc/agent_chat_bloc.dart`
- `lib/features/session_management/presentation/bloc/session_manager_bloc.dart`

### Этап 3: Удалить старые сервисы

Удалить файлы:
- `lib/src/domain/agent_protocol_service.dart` → заменен на AgentRepository
- `lib/src/data/websocket_agent_repository.dart` → заменен на AgentRemoteDataSource
- `lib/src/integration/tool_api.dart` → заменен на ToolRepository
- `lib/src/services/tool_executor.dart` → заменен на ToolExecutorDataSource
- `lib/src/services/gateway_service.dart` → заменен на SessionRemoteDataSource
- `lib/src/services/session_restore_service.dart` → функционал в SessionRepository

### Этап 4: Обновить старые модели

Файлы для удаления:
- `lib/src/models/ws_message.dart` → заменен на MessageModel
- `lib/src/models/tool_models.dart` → заменен на ToolCallModel, ToolResultModel
- `lib/src/models/session_models.dart` → заменен на SessionModel

**НО**: Сначала нужно убедиться, что они не используются в UI компонентах.

### Этап 5: Обновить UI компоненты

Файлы требующие обновления:
- `lib/src/ui/ai_assistant_panel.dart` → использовать новый AgentChatBloc
- `lib/src/ui/chat_view.dart` → использовать новые entities
- `lib/src/ui/session_list_view.dart` → использовать новый SessionManagerBloc
- `lib/src/widgets/tool_approval_dialog.dart` → использовать новый ToolApprovalBloc

### Этап 6: Удалить старый DI модуль

Удалить:
- `lib/src/di/ai_assistant_module.dart` → заменен на `lib/injection_container.dart`

### Этап 7: Очистка utils

Проверить и возможно удалить:
- `lib/src/utils/websocket_error_mapper.dart` → функционал в repositories

### Этап 8: Обновить API клиенты

Оставить (используются в новой архитектуре):
- `lib/src/api/gateway_api.dart` → используется в SessionRemoteDataSource

## Порядок выполнения (безопасный)

1. ✅ Создать новую архитектуру (ЗАВЕРШЕНО)
2. ⏳ Обновить UI компоненты для использования новых BLoCs
3. ⏳ Обновить экспорты в главном файле
4. ⏳ Удалить старые BLoCs
5. ⏳ Удалить старые сервисы
6. ⏳ Удалить старые модели
7. ⏳ Удалить старый DI модуль
8. ⏳ Запустить тесты
9. ⏳ Создать коммит с удалением legacy кода

## Риски

### Риск 1: UI компоненты могут сломаться
**Митигация**: Обновлять UI постепенно, тестировать каждый компонент

### Риск 2: Внешние зависимости на старые экспорты
**Митигация**: Проверить использование модуля в других частях проекта

### Риск 3: Тесты могут сломаться
**Митигация**: Обновить тесты вместе с кодом

## Оценка времени

- Обновление UI компонентов: 2-3 часа
- Обновление экспортов: 30 минут
- Удаление legacy кода: 1 час
- Тестирование: 2 часа
- Исправление проблем: 1-2 часа

**Итого**: 6-8 часов

## Следующий шаг

Начать с обновления UI компонентов для использования новых BLoCs.
