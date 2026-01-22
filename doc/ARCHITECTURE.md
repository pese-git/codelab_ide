# Архитектура CodeLab IDE

Документ описывает архитектуру проекта CodeLab IDE, включая структуру пакетов, паттерны проектирования и взаимодействие компонентов.

**Версия**: 1.0.0  
**Дата обновления**: 21 января 2026

## 📋 Содержание

- [Обзор](#обзор)
- [Монорепозиторная структура](#монорепозиторная-структура)
- [Пакеты](#пакеты)
- [Архитектурные паттерны](#архитектурные-паттерны)
- [Потоки данных](#потоки-данных)
- [Интеграция компонентов](#интеграция-компонентов)

## Обзор

CodeLab IDE построена на основе **монорепозиторной архитектуры** с использованием Melos для управления зависимостями. Проект следует принципам **Clean Architecture** и использует **BLoC pattern** для управления состоянием.

### Ключевые принципы

1. **Модульность** - Каждый пакет независим и может разрабатываться отдельно
2. **Разделение ответственности** - Четкое разделение на слои (Presentation, Domain, Data)
3. **Тестируемость** - Все компоненты покрыты unit и integration тестами
4. **Переиспользуемость** - UI компоненты и бизнес-логика переиспользуются
5. **Расширяемость** - Легко добавлять новые функции и пакеты

## Монорепозиторная структура

```
codelab_ide/
├── apps/
│   └── codelab_ide/              # Основное приложение
│       ├── lib/
│       │   ├── main.dart         # Точка входа
│       │   ├── codelab_app.dart  # Корневой виджет с DI
│       │   ├── di/               # Dependency Injection
│       │   ├── pages/            # Страницы приложения
│       │   └── widgets/          # Специфичные виджеты
│       └── pubspec.yaml
├── packages/
│   ├── codelab_core/             # Основные сервисы
│   ├── codelab_engine/           # Движок редактора
│   ├── codelab_ai_assistant/     # AI интеграция
│   ├── codelab_terminal/         # Терминал
│   ├── codelab_uikit/            # UI компоненты
│   └── codelab_version_control/  # Git интеграция
├── doc/                          # Документация
├── pubspec.yaml                  # Workspace конфигурация
└── melos.yaml                    # Melos конфигурация
```

### Управление зависимостями

```yaml
# pubspec.yaml (workspace)
workspace:
  - apps/codelab_ide
  - packages/*

# Локальные зависимости
dependencies:
  codelab_core: any
  codelab_uikit: any
  # ...
```

## Пакеты

### 1. codelab_core

**Назначение**: Основные сервисы и модели данных

**Ответственность**:
- Работа с файловой системой (FileService)
- Управление проектами (ProjectService)
- Выполнение команд (RunService)
- Базовые модели данных (FileNode, ProjectConfig)
- Обработка ошибок (AppError, FileError)

**Зависимости**:
- `file`, `path` - файловая система
- `process_run` - выполнение команд
- `fpdart` - функциональное программирование

### 2. codelab_engine

**Назначение**: Движок редактора кода

**Ответственность**:
- Управление редактором (EditorManagerService)
- Синхронизация файлов (FileSyncService)
- LSP интеграция (LSPService) - в разработке
- Определение языков (LanguageDetector)

**Зависимости**:
- `codelab_core` - базовые сервисы
- `flutter_bloc` - управление состоянием

### 3. codelab_ai_assistant

**Назначение**: Интеграция AI ассистента

**Ответственность**:
- WebSocket коммуникация с AI Service
- Мультиагентная система (5 агентов)
- Human-in-the-Loop (HITL)
- Выполнение инструментов локально
- Управление сессиями
- Настройки сервера

**Архитектура**: Clean Architecture

```
features/
├── agent_chat/
│   ├── domain/           # Бизнес-логика
│   │   ├── entities/     # Message, Agent
│   │   ├── repositories/ # Интерфейсы
│   │   └── usecases/     # Use cases
│   ├── data/             # Реализация
│   │   ├── models/       # DTO
│   │   ├── repositories/ # Реализация репозиториев
│   │   └── datasources/  # WebSocket
│   └── presentation/     # UI
│       ├── bloc/         # BLoC
│       └── widgets/      # UI компоненты
├── session_management/
├── server_settings/
└── tool_execution/
```

**Зависимости**:
- `codelab_core` - базовые сервисы
- `codelab_uikit` - UI компоненты
- `web_socket_channel` - WebSocket
- `shared_preferences` - локальное хранилище

### 4. codelab_terminal

**Назначение**: Эмулятор терминала

**Ответственность**:
- Эмуляция терминала (xterm)
- PTY поддержка (flutter_pty)
- Управление сессиями терминала
- История команд

**Зависимости**:
- `xterm` - эмулятор терминала
- `flutter_pty` - PTY поддержка
- `flutter_bloc` - управление состоянием

### 5. codelab_uikit

**Назначение**: Переиспользуемые UI компоненты

**Ответственность**:
- Основной layout (IDELayout)
- Панели (ExplorerPanel, SidebarPanel)
- AI Assistant UI (AIAssistantUI, AgentIndicator)
- Диалоги (ToolApprovalDialog)
- Splitters (HorizontalSplitter, VerticalSplitter)
- Модели UI (AgentInfo, EditorTab, FileNode)

**Зависимости**:
- `fluent_ui` - UI framework

### 6. codelab_version_control

**Назначение**: Интеграция с системами контроля версий

**Ответственность**:
- Git операции (базовые)
- История коммитов
- Diff просмотр

**Статус**: Базовая реализация

## Архитектурные паттерны

### Clean Architecture

Применяется в `codelab_ai_assistant` и планируется для других пакетов.

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (BLoC, Widgets, UI State)         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          Domain Layer               │
│  (Entities, Use Cases, Repositories)│
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│           Data Layer                │
│  (Models, Repositories Impl,        │
│   Data Sources)                     │
└─────────────────────────────────────┘
```

**Преимущества**:
- Независимость от фреймворков
- Тестируемость
- Независимость от UI
- Независимость от БД

### BLoC Pattern

Используется для управления состоянием во всех пакетах.

```dart
// События
sealed class MyEvent {
  const factory MyEvent.action() = ActionEvent;
}

// Состояния
sealed class MyState {
  const factory MyState.initial() = Initial;
  const factory MyState.loading() = Loading;
  const factory MyState.success(Data data) = Success;
  const factory MyState.error(String message) = Error;
}

// BLoC
class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc() : super(MyState.initial()) {
    on<ActionEvent>(_onAction);
  }
}
```

**Преимущества**:
- Предсказуемые переходы состояний
- Легко тестировать
- Разделение бизнес-логики и UI
- Reactive programming

### Dependency Injection

Используется CherryPick для DI.

```dart
@CherryPick()
abstract class AppDiModule {
  @Singleton()
  FileService fileService();
  
  @Factory()
  AgentChatBloc agentChatBloc(
    SendMessageUseCase sendMessage,
    ReceiveMessagesUseCase receiveMessages,
  );
}
```

### Functional Programming

Используется FPDart для обработки ошибок.

```dart
// Either для результатов с ошибками
Future<Either<Failure, String>> readFile(String path) async {
  try {
    final content = await file.readAsString();
    return right(content);
  } catch (e) {
    return left(FileError(message: e.toString()));
  }
}

// Option для nullable значений
Option<String> findUser(String id) {
  final user = users[id];
  return user != null ? some(user) : none();
}

// TaskEither для асинхронных операций
final task = TaskEither<Failure, Data>.tryCatch(
  () => fetchData(),
  (error, stack) => NetworkFailure(error.toString()),
);
```

## Потоки данных

### 1. Отправка сообщения AI агенту

```
User Input
    │
    ▼
AgentChatBloc.sendMessage()
    │
    ▼
SendMessageUseCase
    │
    ▼
AgentChatRepository
    │
    ▼
WebSocketDataSource
    │
    ▼
AI Service (Gateway)
```

### 2. Получение ответа от агента

```
AI Service (Gateway)
    │
    ▼
WebSocketDataSource
    │
    ▼
Stream<Message>
    │
    ▼
AgentChatBloc (подписан на stream)
    │
    ▼
messageReceived event
    │
    ▼
State обновляется
    │
    ▼
UI перерисовывается
```

### 3. Tool execution с HITL

```
Agent отправляет tool_call
    │
    ▼
AgentChatBloc получает сообщение
    │
    ▼
ExecuteToolUseCase
    │
    ▼
ToolApprovalService.requestApproval()
    │
    ▼
Stream approval requests
    │
    ▼
AgentChatBloc (подписан)
    │
    ▼
approvalRequested event
    │
    ▼
UI показывает диалог
    │
    ▼
User approve/reject
    │
    ▼
Completer завершается
    │
    ▼
Tool выполняется или отклоняется
    │
    ▼
Результат отправляется на сервер
```

### 4. Работа с файлами

```
User открывает файл
    │
    ▼
EditorManagerService.openFile()
    │
    ▼
FileService.readFile()
    │
    ▼
Файл загружается в редактор
    │
    ▼
User редактирует
    │
    ▼
FileSyncService отслеживает изменения
    │
    ▼
User сохраняет (Ctrl+S)
    │
    ▼
EditorManagerService.saveFile()
    │
    ▼
FileService.writeFile()
```

## Интеграция компонентов

### Главное приложение (apps/codelab_ide)

```dart
// main.dart
void main() {
  // Инициализация DI
  final diModule = AppDiModule();
  
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => diModule.fileService()),
        RepositoryProvider(create: (_) => diModule.projectService()),
        // ...
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => diModule.agentChatBloc()),
          BlocProvider(create: (context) => diModule.sessionManagerBloc()),
          // ...
        ],
        child: CodelabApp(),
      ),
    ),
  );
}
```

### Взаимодействие пакетов

```
┌─────────────────┐
│  codelab_ide    │ (main app)
└────────┬────────┘
         │
         ├──────────────────────────────┐
         │                              │
         ▼                              ▼
┌────────────────┐            ┌─────────────────┐
│ codelab_uikit  │            │ codelab_core    │
└────────────────┘            └────────┬────────┘
                                       │
         ┌─────────────────────────────┼─────────────────┐
         │                             │                 │
         ▼                             ▼                 ▼
┌──────────────────┐      ┌────────────────┐  ┌─────────────────┐
│ codelab_ai_      │      │ codelab_engine │  │ codelab_terminal│
│ assistant        │      └────────────────┘  └─────────────────┘
└──────────────────┘
         │
         ▼
┌──────────────────┐
│ codelab_version_ │
│ control          │
└──────────────────┘
```

## Коммуникация между компонентами

### Event Bus (опционально)

Для слабосвязанной коммуникации между компонентами можно использовать event bus:

```dart
// События
sealed class AppEvent {
  const factory AppEvent.fileOpened(String path) = FileOpenedEvent;
  const factory AppEvent.fileSaved(String path) = FileSavedEvent;
  const factory AppEvent.projectLoaded(String path) = ProjectLoadedEvent;
}

// Event Bus
class EventBus {
  final _controller = StreamController<AppEvent>.broadcast();
  
  Stream<AppEvent> get events => _controller.stream;
  
  void emit(AppEvent event) => _controller.add(event);
}
```

### Shared State

Для глобального состояния используется Provider:

```dart
class AppState extends ChangeNotifier {
  String? _currentProject;
  String? _activeFile;
  
  String? get currentProject => _currentProject;
  String? get activeFile => _activeFile;
  
  void setCurrentProject(String path) {
    _currentProject = path;
    notifyListeners();
  }
}
```

## Тестирование

### Unit Tests

```dart
test('should read file successfully', () async {
  // Arrange
  final fileService = FileService();
  
  // Act
  final result = await fileService.readFile('test.txt');
  
  // Assert
  expect(result.isRight(), true);
});
```

### Widget Tests

```dart
testWidgets('should display message bubble', (tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(
      home: MessageBubble(
        content: 'Hello',
        isUser: true,
      ),
    ),
  );
  
  // Assert
  expect(find.text('Hello'), findsOneWidget);
});
```

### Integration Tests

```dart
testWidgets('should send message and receive response', (tester) async {
  // Arrange
  await tester.pumpWidget(MyApp());
  
  // Act
  await tester.enterText(find.byType(TextField), 'Hello');
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.text('Hello'), findsOneWidget);
});
```

## Производительность

### Оптимизации

1. **Lazy loading** - Загрузка компонентов по требованию
2. **Caching** - Кэширование часто используемых данных
3. **Debouncing** - Ограничение частоты вызовов
4. **Pagination** - Постраничная загрузка больших списков
5. **Virtual scrolling** - Виртуализация длинных списков

### Мониторинг

```dart
// Логирование производительности
final stopwatch = Stopwatch()..start();
await heavyOperation();
stopwatch.stop();
logger.i('Operation took ${stopwatch.elapsedMilliseconds}ms');
```

## Безопасность

### HITL (Human-in-the-Loop)

Критичные операции требуют подтверждения пользователя:
- Запись файлов
- Выполнение команд
- Удаление данных
- Изменение конфигурации

### Валидация

```dart
// Валидация путей
class PathValidator {
  static bool isValid(String path) {
    // Проверка на path traversal
    if (path.contains('..')) return false;
    
    // Проверка на абсолютный путь
    if (!path.startsWith('/')) return false;
    
    return true;
  }
}
```

## Расширяемость

### Добавление нового пакета

1. Создать директорию в `packages/`
2. Инициализировать `pubspec.yaml`
3. Добавить в `workspace` в корневом `pubspec.yaml`
4. Запустить `melos bootstrap`

### Добавление нового агента

1. Обновить `AgentType` enum в `codelab_uikit`
2. Добавить обработку в `AgentChatBloc`
3. Обновить UI компоненты

### Добавление нового инструмента

1. Создать реализацию в `tool_execution/data/tools/`
2. Зарегистрировать в `ToolRepository`
3. Добавить тесты

## Заключение

Архитектура CodeLab IDE построена на принципах модульности, тестируемости и расширяемости. Использование Clean Architecture и BLoC pattern обеспечивает четкое разделение ответственности и упрощает поддержку проекта.

## Дополнительные ресурсы

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Melos](https://melos.invertase.dev/)
- [FPDart](https://pub.dev/packages/fpdart)
