# CodeLab AI Assistant

Пакет интеграции AI ассистента для CodeLab IDE. Предоставляет полнофункциональную мультиагентную систему с поддержкой Human-in-the-Loop (HITL), выполнения инструментов и управления сессиями.

**Версия**: 1.0.0  
**Дата обновления**: 21 января 2026

## 🎯 Возможности

### ✅ Реализованные функции

**Мультиагентная система:**
- Поддержка 5 специализированных агентов:
  - **Orchestrator** (🎭) - Координирует и маршрутизирует задачи
  - **Coder** (💻) - Пишет и модифицирует код
  - **Architect** (🏗️) - Проектирует и планирует архитектуру
  - **Debug** (🐛) - Исследует ошибки и баги
  - **Ask** (💬) - Отвечает на вопросы и объясняет
- Автоматическое и ручное переключение между агентами
- История переключений агентов с причинами

**WebSocket интеграция:**
- Подключение к AI Service через Gateway
- Streaming responses (token-by-token)
- Автоматическое переподключение при разрыве соединения
- Обработка различных типов сообщений (text, tool_call, tool_result, agent_switch)

**Human-in-the-Loop (HITL):**
- Диалоги подтверждения для опасных операций
- Поддержка approve/reject/modify решений
- Восстановление pending approvals после перезапуска IDE
- Синхронизация состояния с сервером

**Выполнение инструментов:**
- Локальное выполнение 9+ инструментов:
  - `read_file` - Чтение файлов
  - `write_file` - Запись файлов
  - `list_files` - Список файлов в директории
  - `execute_command` - Выполнение команд
  - `search_files` - Поиск по файлам
  - `apply_diff` - Применение изменений
  - И другие...
- Автоматическая отправка результатов на сервер
- Обработка ошибок выполнения

**Управление сессиями:**
- Создание новых сессий
- Загрузка списка сессий
- Удаление сессий
- Сохранение истории сообщений локально (SharedPreferences)

**Настройки сервера:**
- Конфигурация URL Gateway
- Тестирование подключения
- Сохранение настроек локально

## 🏗️ Архитектура

Пакет следует принципам **Clean Architecture** с разделением на слои:

```
lib/
├── core/                           # Общие компоненты
│   ├── error/                      # Обработка ошибок
│   │   └── failures.dart           # Типы ошибок
│   ├── usecases/                   # Базовые use cases
│   │   └── usecase.dart            # UseCase интерфейс
│   └── bloc/                       # BLoC инфраструктура
│       └── app_bloc_observer.dart  # Наблюдатель за BLoC событиями
├── features/                       # Функциональные модули
│   ├── agent_chat/                 # Чат с агентом
│   │   ├── domain/                 # Бизнес-логика
│   │   │   ├── entities/           # Сущности (Message, Agent)
│   │   │   ├── repositories/       # Интерфейсы репозиториев
│   │   │   └── usecases/           # Use cases
│   │   ├── data/                   # Реализация данных
│   │   │   ├── models/             # Модели данных (DTO)
│   │   │   ├── repositories/       # Реализация репозиториев
│   │   │   └── datasources/        # Источники данных (WebSocket)
│   │   └── presentation/           # UI слой
│   │       ├── bloc/               # BLoC для управления состоянием
│   │       └── widgets/            # UI компоненты
│   ├── session_management/         # Управление сессиями
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── server_settings/            # Настройки сервера
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   └── tool_execution/             # Выполнение инструментов
│       ├── domain/
│       │   ├── entities/           # ToolCall, ToolResult, ToolApproval
│       │   ├── repositories/
│       │   └── usecases/
│       └── data/
│           ├── repositories/
│           └── services/           # ToolApprovalService, ApprovalSyncService
└── ai_assistent_module.dart        # Модуль DI
```

## 📦 Зависимости

### Основные зависимости
```yaml
dependencies:
  # State management
  flutter_bloc: ^9.1.1
  bloc: ^9.1.0
  
  # Functional programming
  fpdart: ^1.2.0
  
  # Dependency injection
  cherrypick: ^3.0.2
  cherrypick_annotations: ^3.0.1
  
  # Code generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.8.1
  
  # WebSocket
  web_socket_channel: ^2.4.0
  
  # Local storage
  shared_preferences: ^2.2.2
  
  # Logging
  logger: ^2.6.2
  
  # UI
  codelab_uikit: any
  codelab_core: any
```

## 🚀 Использование

### Инициализация модуля

```dart
import 'package:codelab_ai_assistant/ai_assistent_module.dart';

// В main.dart
void main() {
  // Инициализация DI модуля
  final aiModule = AiAssistentModule();
  
  runApp(MyApp(aiModule: aiModule));
}
```

### Использование в UI

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/bloc/agent_chat_bloc.dart';

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<AgentChatBloc>()
        ..add(AgentChatEvent.connect(sessionId)),
      child: BlocBuilder<AgentChatBloc, AgentChatState>(
        builder: (context, state) {
          // Отображение UI на основе состояния
          return Column(
            children: [
              // Список сообщений
              Expanded(
                child: ListView.builder(
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return MessageBubble(message: message);
                  },
                ),
              ),
              
              // Pending approval dialog
              if (state.pendingApproval.isSome())
                ToolApprovalDialog(
                  request: state.pendingApproval.toNullable()!,
                  onApprove: () => context.read<AgentChatBloc>()
                    .add(AgentChatEvent.approveToolCall()),
                  onReject: (reason) => context.read<AgentChatBloc>()
                    .add(AgentChatEvent.rejectToolCall(reason)),
                ),
              
              // Поле ввода
              InputBar(
                onSend: (text) => context.read<AgentChatBloc>()
                  .add(AgentChatEvent.sendMessage(text)),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

### Отправка сообщения

```dart
// Отправить сообщение агенту
context.read<AgentChatBloc>().add(
  AgentChatEvent.sendMessage('Создай новый файл main.dart'),
);
```

### Переключение агента

```dart
// Переключиться на другого агента
context.read<AgentChatBloc>().add(
  AgentChatEvent.switchAgent('coder', 'Нужно написать код'),
);
```

### Подключение к сессии

```dart
// Подключиться к существующей сессии
context.read<AgentChatBloc>().add(
  AgentChatEvent.connect(sessionId),
);

// Загрузить историю сообщений
context.read<AgentChatBloc>().add(
  AgentChatEvent.loadHistory(sessionId),
);
```

## 🔧 Конфигурация

### Настройка сервера

```dart
import 'package:codelab_ai_assistant/features/server_settings/domain/entities/server_settings.dart';

final settings = ServerSettings(
  gatewayUrl: 'ws://localhost:8000/ws',
  apiKey: 'your-api-key',
  timeout: Duration(seconds: 30),
);

// Сохранить настройки
await context.read<ServerSettingsBloc>().add(
  ServerSettingsEvent.save(settings),
);
```

### Тестирование подключения

```dart
// Проверить подключение к серверу
context.read<ServerSettingsBloc>().add(
  ServerSettingsEvent.testConnection(),
);
```

## 🧪 Тестирование

```bash
# Запустить все тесты пакета
flutter test

# Запустить конкретный тест
flutter test test/features/agent_chat/presentation/bloc/agent_chat_bloc_test.dart

# Запустить с coverage
flutter test --coverage
```

## 📚 Документация

### Основная документация
- [`CHANGELOG.md`](CHANGELOG.md) - История изменений
- [`../../doc/HITL_IDE_INTEGRATION_PLAN.md`](../../doc/HITL_IDE_INTEGRATION_PLAN.md) - План интеграции HITL
- [`../../doc/multi-agent-ui-integration-plan.md`](../../doc/multi-agent-ui-integration-plan.md) - UI для мультиагентной системы
- [`../../doc/agent_extended_protocol.md`](../../doc/agent_extended_protocol.md) - Расширенный протокол WebSocket

### Техническая документация
- [`docs/SERVER_SETTINGS_ARCHITECTURE.md`](docs/SERVER_SETTINGS_ARCHITECTURE.md) - Архитектура настроек сервера

## 🔄 Жизненный цикл сообщений

1. **Пользователь отправляет сообщение**
   - UI → `AgentChatBloc.sendMessage()`
   - BLoC → `SendMessageUseCase`
   - UseCase → `AgentChatRepository`
   - Repository → WebSocket отправка

2. **Получение ответа от агента**
   - WebSocket → `AgentChatDataSource`
   - DataSource → Stream сообщений
   - BLoC подписан на stream → `messageReceived` event
   - State обновляется → UI перерисовывается

3. **Tool call с HITL**
   - Агент отправляет `tool_call` с `requires_approval: true`
   - BLoC → `ExecuteToolUseCase`
   - UseCase → `ToolApprovalService.requestApproval()`
   - Service → Stream approval requests
   - BLoC подписан → `approvalRequested` event
   - UI показывает диалог подтверждения
   - Пользователь approve/reject
   - Completer завершается → tool выполняется или отклоняется
   - Результат отправляется на сервер

## 🛠️ Разработка

### Добавление нового инструмента

1. Создайте реализацию в `tool_execution/data/tools/`:
```dart
class MyNewTool implements Tool {
  @override
  String get name => 'my_new_tool';
  
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    // Реализация
  }
}
```

2. Зарегистрируйте в `ToolRepository`:
```dart
final tools = {
  'my_new_tool': MyNewTool(),
  // ...
};
```

### Добавление нового типа сообщения

1. Обновите `Message` entity в `domain/entities/message.dart`
2. Обновите `WSMessage` model в `data/models/ws_message.dart`
3. Добавьте обработку в `AgentChatBloc`

## 🐛 Известные проблемы

- При разрыве WebSocket соединения требуется ручное переподключение
- Pending approvals восстанавливаются только при явном подключении к сессии

## 🗺️ Roadmap

### v1.1 (Q1 2026)
- [ ] Автоматическое переподключение WebSocket
- [ ] Offline режим с очередью сообщений
- [ ] Улучшенная обработка ошибок

### v1.2 (Q2 2026)
- [ ] Поддержка мультимодальности (изображения, файлы)
- [ ] Streaming tool execution
- [ ] Расширенная аналитика использования

## 📄 Лицензия

MIT License - см. [`../../LICENSE`](../../LICENSE)
