# План рефакторинга codelab_ai_assistant по Clean Architecture

## Анализ текущей структуры

### Текущие проблемы:
1. **Смешение ответственности**: BLoC напрямую работает с WebSocket репозиторием
2. **Отсутствие четкого Domain слоя**: Бизнес-логика размазана по BLoC и сервисам
3. **Модели данных используются как entities**: WSMessage, ToolCall - это DTO, а не domain entities
4. **Нет Use Cases**: Бизнес-логика находится в BLoC
5. **Прямая зависимость от внешних источников**: BLoC знает о WebSocket деталях
6. **Сложное тестирование**: Из-за тесной связанности компонентов

### Текущая структура:
```
lib/src/
├── api/                    # REST API клиенты
├── bloc/                   # BLoC (Presentation + частично Domain)
├── data/                   # Репозитории (частично)
├── di/                     # Dependency Injection
├── domain/                 # Сервисы (не настоящий Domain)
├── integration/            # Tool API
├── models/                 # DTO модели
├── services/               # Различные сервисы
├── ui/                     # UI компоненты
├── utils/                  # Утилиты
└── widgets/                # Виджеты
```

## Целевая Clean Architecture структура

### Принципы:
1. **Независимость от фреймворков**: Domain не зависит от Flutter/Dart специфики
2. **Тестируемость**: Каждый слой тестируется независимо
3. **Независимость от UI**: Бизнес-логика не знает о UI
4. **Независимость от БД/API**: Domain не знает откуда приходят данные
5. **Dependency Rule**: Зависимости направлены внутрь (к Domain)
6. **Функциональное программирование**: Используем fpdart (Either, Option, Task)

### Новая структура:

```
lib/
├── core/                           # Общие компоненты
│   ├── error/                      # Обработка ошибок
│   │   ├── failures.dart           # Domain failures (sealed class)
│   │   └── exceptions.dart         # Data exceptions
│   ├── usecases/                   # Базовые use case интерфейсы
│   │   └── usecase.dart            # UseCase<Failure, Type, Params>
│   └── utils/                      # Утилиты
│       └── type_defs.dart          # FutureEither, StreamEither и т.д.
│
├── features/                       # Фичи приложения
│   ├── agent_chat/                 # Фича: Чат с AI агентом
│   │   ├── domain/
│   │   │   ├── entities/           # Бизнес-объекты (immutable)
│   │   │   │   ├── message.dart
│   │   │   │   ├── agent.dart
│   │   │   │   └── chat_session.dart
│   │   │   ├── repositories/       # Интерфейсы репозиториев
│   │   │   │   ├── agent_repository.dart
│   │   │   │   └── message_repository.dart
│   │   │   └── usecases/           # Бизнес-логика
│   │   │       ├── send_message.dart
│   │   │       ├── receive_messages.dart
│   │   │       ├── switch_agent.dart
│   │   │       └── load_chat_history.dart
│   │   ├── data/
│   │   │   ├── models/             # DTO модели (с JSON)
│   │   │   │   ├── ws_message_model.dart
│   │   │   │   └── agent_model.dart
│   │   │   ├── datasources/        # Источники данных
│   │   │   │   ├── agent_remote_datasource.dart
│   │   │   │   └── agent_local_datasource.dart
│   │   │   ├── repositories/       # Реализации репозиториев
│   │   │   │   └── agent_repository_impl.dart
│   │   │   └── mappers/            # Маппинг DTO <-> Entity
│   │   │       └── message_mapper.dart
│   │   └── presentation/
│   │       ├── bloc/               # BLoC (только UI логика)
│   │       │   ├── agent_chat_bloc.dart
│   │       │   ├── agent_chat_event.dart
│   │       │   └── agent_chat_state.dart
│   │       ├── pages/              # Страницы
│   │       │   └── chat_page.dart
│   │       └── widgets/            # Виджеты
│   │           ├── chat_view.dart
│   │           └── message_bubble.dart
│   │
│   ├── tool_execution/             # Фича: Выполнение инструментов
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── tool_call.dart
│   │   │   │   ├── tool_result.dart
│   │   │   │   └── tool_approval.dart
│   │   │   ├── repositories/
│   │   │   │   └── tool_repository.dart
│   │   │   └── usecases/
│   │   │       ├── execute_tool.dart
│   │   │       ├── request_tool_approval.dart
│   │   │       └── validate_tool_safety.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── tool_call_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── tool_executor_datasource.dart
│   │   │   │   └── file_system_datasource.dart
│   │   │   └── repositories/
│   │   │       └── tool_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── tool_approval_bloc.dart
│   │       └── widgets/
│   │           └── tool_approval_dialog.dart
│   │
│   └── session_management/         # Фича: Управление сессиями
│       ├── domain/
│       │   ├── entities/
│       │   │   └── session.dart
│       │   ├── repositories/
│       │   │   └── session_repository.dart
│       │   └── usecases/
│       │       ├── create_session.dart
│       │       ├── load_session.dart
│       │       └── list_sessions.dart
│       ├── data/
│       │   ├── models/
│       │   │   └── session_model.dart
│       │   ├── datasources/
│       │   │   ├── session_remote_datasource.dart
│       │   │   └── session_local_datasource.dart
│       │   └── repositories/
│       │       └── session_repository_impl.dart
│       └── presentation/
│           ├── bloc/
│           │   └── session_manager_bloc.dart
│           └── widgets/
│               └── session_list_view.dart
│
└── injection_container.dart        # DI setup
```

## Использование fpdart

### Type Definitions (core/utils/type_defs.dart)
```dart
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

// Either для асинхронных операций
typedef FutureEither<T> = Future<Either<Failure, T>>;

// Either для синхронных операций
typedef SyncEither<T> = Either<Failure, T>;

// Stream с Either
typedef StreamEither<T> = Stream<Either<Failure, T>>;

// Task для ленивых вычислений
typedef FutureTask<T> = Task<Either<Failure, T>>;
```

### Failures (core/error/failures.dart)
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.server(String message) = ServerFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.notFound(String message) = NotFoundFailure;
  const factory Failure.unauthorized(String message) = UnauthorizedFailure;
  const factory Failure.toolExecution(String code, String message) = ToolExecutionFailure;
  const factory Failure.userRejected(String operation) = UserRejectedFailure;
}
```

### UseCase базовый класс (core/usecases/usecase.dart)
```dart
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';
import '../utils/type_defs.dart';

/// Базовый интерфейс для всех Use Cases
/// 
/// [Type] - тип возвращаемого значения
/// [Params] - тип параметров
abstract class UseCase<Type, Params> {
  FutureEither<Type> call(Params params);
}

/// Use Case без параметров
abstract class NoParamsUseCase<Type> {
  FutureEither<Type> call();
}

/// Use Case возвращающий Stream
abstract class StreamUseCase<Type, Params> {
  StreamEither<Type> call(Params params);
}

/// Класс для use cases без параметров
class NoParams {
  const NoParams();
}
```

## Детальный план рефакторинга

### Этап 1: Core слой

#### 1.1 Создать type definitions с fpdart
```dart
// core/utils/type_defs.dart
typedef FutureEither<T> = Future<Either<Failure, T>>;
typedef StreamEither<T> = Stream<Either<Failure, T>>;
```

#### 1.2 Создать Failures (sealed class с freezed)
```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.server(String message) = ServerFailure;
  const factory Failure.network(String message) = NetworkFailure;
  // ...
}
```

#### 1.3 Создать базовый UseCase
```dart
abstract class UseCase<Type, Params> {
  FutureEither<Type> call(Params params);
}
```

### Этап 2: Domain слой (agent_chat)

#### 2.1 Entities (с freezed, immutable)
```dart
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required MessageContent content,
    required MessageRole role,
    required DateTime timestamp,
  }) = _Message;
}

@freezed
sealed class MessageContent with _$MessageContent {
  const factory MessageContent.text(String text) = TextContent;
  const factory MessageContent.toolCall(ToolCallData data) = ToolCallContent;
  const factory MessageContent.toolResult(ToolResultData data) = ToolResultContent;
}
```

#### 2.2 Repository Interfaces (возвращают Either)
```dart
abstract class AgentRepository {
  FutureEither<Unit> sendMessage(Message message);
  StreamEither<Message> receiveMessages();
  FutureEither<Unit> switchAgent(String agentType, String content);
  FutureEither<ChatSession> loadHistory(String sessionId);
}
```

#### 2.3 Use Cases (используют Either)
```dart
class SendMessageUseCase implements UseCase<Unit, SendMessageParams> {
  final AgentRepository repository;
  
  SendMessageUseCase(this.repository);
  
  @override
  FutureEither<Unit> call(SendMessageParams params) {
    return repository.sendMessage(params.message);
  }
}
```

### Этап 3: Data слой (agent_chat)

#### 3.1 Models (DTO с JSON)
```dart
@JsonSerializable()
class WSMessageModel {
  final String type;
  final String? content;
  // ...
  
  // Маппинг в Entity
  Message toEntity() {
    return Message(
      id: generateId(),
      content: _mapContent(),
      role: _mapRole(),
      timestamp: DateTime.now(),
    );
  }
}
```

#### 3.2 Data Sources (выбрасывают Exceptions)
```dart
abstract class AgentRemoteDataSource {
  Future<void> sendMessage(WSMessageModel message);
  Stream<WSMessageModel> receiveMessages();
  Future<void> connect(String sessionId);
}

class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  final WebSocketChannel channel;
  
  @override
  Future<void> sendMessage(WSMessageModel message) async {
    try {
      channel.sink.add(jsonEncode(message.toJson()));
    } catch (e) {
      throw ServerException('Failed to send message: $e');
    }
  }
}
```

#### 3.3 Repository Implementation (конвертирует Exceptions в Failures)
```dart
class AgentRepositoryImpl implements AgentRepository {
  final AgentRemoteDataSource remoteDataSource;
  final AgentLocalDataSource localDataSource;
  
  @override
  FutureEither<Unit> sendMessage(Message message) async {
    try {
      final model = MessageMapper.toModel(message);
      await remoteDataSource.sendMessage(model);
      return right(unit);
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.server('Unexpected error: $e'));
    }
  }
  
  @override
  StreamEither<Message> receiveMessages() {
    return remoteDataSource.receiveMessages()
      .map((model) => right<Failure, Message>(model.toEntity()))
      .handleError((error) {
        if (error is ServerException) {
          return left<Failure, Message>(Failure.server(error.message));
        }
        return left<Failure, Message>(Failure.server('Unexpected error: $error'));
      });
  }
}
```

### Этап 4: Domain слой (tool_execution)

#### 4.1 Entities
```dart
@freezed
class ToolCall with _$ToolCall {
  const factory ToolCall({
    required String id,
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool requiresApproval,
  }) = _ToolCall;
}

@freezed
sealed class ToolResult with _$ToolResult {
  const factory ToolResult.success(Map<String, dynamic> data) = ToolSuccess;
  const factory ToolResult.failure(String error) = ToolFailure;
}
```

#### 4.2 Repository Interface
```dart
abstract class ToolRepository {
  FutureEither<ToolResult> executeToolCall(ToolCall toolCall);
  FutureEither<bool> requestApproval(ToolCall toolCall);
  SyncEither<Unit> validateSafety(ToolCall toolCall);
}
```

#### 4.3 Use Cases
```dart
class ExecuteToolUseCase implements UseCase<ToolResult, ExecuteToolParams> {
  final ToolRepository repository;
  
  ExecuteToolUseCase(this.repository);
  
  @override
  FutureEither<ToolResult> call(ExecuteToolParams params) async {
    // 1. Validate safety
    final validationResult = repository.validateSafety(params.toolCall);
    
    return validationResult.fold(
      (failure) => left(failure),
      (_) async {
        // 2. Request approval if needed
        if (params.toolCall.requiresApproval) {
          final approvalResult = await repository.requestApproval(params.toolCall);
          return approvalResult.fold(
            (failure) => left(failure),
            (approved) {
              if (!approved) {
                return left(Failure.userRejected(params.toolCall.toolName));
              }
              // 3. Execute tool
              return repository.executeToolCall(params.toolCall);
            },
          );
        }
        
        // 3. Execute tool directly
        return repository.executeToolCall(params.toolCall);
      },
    );
  }
}
```

### Этап 5: Data слой (tool_execution)

#### 5.1 Data Sources
```dart
abstract class ToolExecutorDataSource {
  Future<Map<String, dynamic>> executeReadFile(Map<String, dynamic> args);
  Future<Map<String, dynamic>> executeWriteFile(Map<String, dynamic> args);
  Future<Map<String, dynamic>> executeListFiles(Map<String, dynamic> args);
  // ...
}

class ToolExecutorDataSourceImpl implements ToolExecutorDataSource {
  final FileSystemDataSource fileSystem;
  
  @override
  Future<Map<String, dynamic>> executeReadFile(Map<String, dynamic> args) async {
    try {
      final path = args['path'] as String;
      final content = await fileSystem.readFile(path);
      return {'success': true, 'content': content};
    } catch (e) {
      throw ToolExecutionException('Failed to read file: $e');
    }
  }
}
```

#### 5.2 Repository Implementation
```dart
class ToolRepositoryImpl implements ToolRepository {
  final ToolExecutorDataSource executor;
  final ToolApprovalService approvalService;
  
  @override
  FutureEither<ToolResult> executeToolCall(ToolCall toolCall) async {
    try {
      final result = await _executeByToolName(toolCall);
      return right(ToolResult.success(result));
    } on ToolExecutionException catch (e) {
      return left(Failure.toolExecution(e.code, e.message));
    } catch (e) {
      return left(Failure.server('Unexpected error: $e'));
    }
  }
  
  @override
  FutureEither<bool> requestApproval(ToolCall toolCall) async {
    try {
      final result = await approvalService.requestApproval(
        ToolCallModel.fromEntity(toolCall),
      );
      return right(result == ToolApprovalResult.approved);
    } catch (e) {
      return left(Failure.server('Approval request failed: $e'));
    }
  }
  
  @override
  SyncEither<Unit> validateSafety(ToolCall toolCall) {
    try {
      // Validation logic
      if (_isDangerous(toolCall)) {
        return left(Failure.validation('Dangerous operation detected'));
      }
      return right(unit);
    } catch (e) {
      return left(Failure.validation('Validation failed: $e'));
    }
  }
}
```

### Этап 6: Domain слой (session_management)

#### 6.1 Entities
```dart
@freezed
class Session with _$Session {
  const factory Session({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String currentAgent,
    required int messageCount,
    Option<String> title,
  }) = _Session;
}
```

#### 6.2 Repository Interface
```dart
abstract class SessionRepository {
  FutureEither<Session> createSession();
  FutureEither<Session> loadSession(String sessionId);
  FutureEither<List<Session>> listSessions();
  FutureEither<Unit> deleteSession(String sessionId);
}
```

#### 6.3 Use Cases
```dart
class CreateSessionUseCase implements NoParamsUseCase<Session> {
  final SessionRepository repository;
  
  CreateSessionUseCase(this.repository);
  
  @override
  FutureEither<Session> call() {
    return repository.createSession();
  }
}
```

### Этап 7: Data слой (session_management)

#### 7.1 Data Sources
```dart
abstract class SessionRemoteDataSource {
  Future<SessionModel> createSession();
  Future<SessionModel> getSession(String sessionId);
  Future<List<SessionModel>> listSessions();
}

abstract class SessionLocalDataSource {
  Future<void> cacheSession(SessionModel session);
  Future<SessionModel?> getLastSession();
  Future<void> clearCache();
}
```

#### 7.2 Repository Implementation
```dart
class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource remoteDataSource;
  final SessionLocalDataSource localDataSource;
  
  @override
  FutureEither<Session> createSession() async {
    try {
      final model = await remoteDataSource.createSession();
      await localDataSource.cacheSession(model);
      return right(model.toEntity());
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.server('Unexpected error: $e'));
    }
  }
}
```

### Этап 8: Presentation слой

#### 8.1 Рефакторинг BLoC (использует Use Cases)
```dart
class AgentChatBloc extends Bloc<AgentChatEvent, AgentChatState> {
  final SendMessageUseCase sendMessage;
  final ReceiveMessagesUseCase receiveMessages;
  final SwitchAgentUseCase switchAgent;
  final LoadChatHistoryUseCase loadHistory;
  
  AgentChatBloc({
    required this.sendMessage,
    required this.receiveMessages,
    required this.switchAgent,
    required this.loadHistory,
  }) : super(const AgentChatState.initial()) {
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<SwitchAgent>(_onSwitchAgent);
    on<LoadHistory>(_onLoadHistory);
    
    // Подписка на сообщения
    _subscribeToMessages();
  }
  
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AgentChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    
    final result = await sendMessage(SendMessageParams(
      message: Message(
        id: generateId(),
        content: MessageContent.text(event.text),
        role: MessageRole.user,
        timestamp: DateTime.now(),
      ),
    ));
    
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.when(
          server: (msg) => msg,
          network: (msg) => msg,
          // ...
        ),
      )),
      (_) => emit(state.copyWith(isLoading: false)),
    );
  }
  
  void _subscribeToMessages() {
    receiveMessages(NoParams()).listen((either) {
      either.fold(
        (failure) => add(AgentChatEvent.error(failure)),
        (message) => add(AgentChatEvent.messageReceived(message)),
      );
    });
  }
}
```

#### 8.2 State с freezed
```dart
@freezed
class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required bool isLoading,
    required String currentAgent,
    Option<String> error,
    Option<ToolApprovalRequest> pendingApproval,
  }) = _AgentChatState;
  
  factory AgentChatState.initial() => AgentChatState(
    messages: const [],
    isLoading: false,
    currentAgent: 'orchestrator',
    error: none(),
    pendingApproval: none(),
  );
}
```

### Этап 9: Dependency Injection

#### 9.1 Обновить DI контейнер
```dart
class AiAssistantModule extends Module {
  @override
  void builder(Scope currentScope) {
    // Core
    bind<Logger>().toProvide(() => Logger()).singleton();
    
    // Data Sources
    bind<AgentRemoteDataSource>()
      .toProvide(() => AgentRemoteDataSourceImpl(
        channel: WebSocketChannel.connect(Uri.parse(wsUrl)),
      ))
      .singleton();
    
    bind<AgentLocalDataSource>()
      .toProvide(() => AgentLocalDataSourceImpl(
        prefs: currentScope.resolve<SharedPreferences>(),
      ))
      .singleton();
    
    bind<ToolExecutorDataSource>()
      .toProvide(() => ToolExecutorDataSourceImpl(
        fileSystem: currentScope.resolve<FileSystemDataSource>(),
      ));
    
    // Repositories
    bind<AgentRepository>()
      .toProvide(() => AgentRepositoryImpl(
        remoteDataSource: currentScope.resolve<AgentRemoteDataSource>(),
        localDataSource: currentScope.resolve<AgentLocalDataSource>(),
      ))
      .singleton();
    
    bind<ToolRepository>()
      .toProvide(() => ToolRepositoryImpl(
        executor: currentScope.resolve<ToolExecutorDataSource>(),
        approvalService: currentScope.resolve<ToolApprovalService>(),
      ))
      .singleton();
    
    bind<SessionRepository>()
      .toProvide(() => SessionRepositoryImpl(
        remoteDataSource: currentScope.resolve<SessionRemoteDataSource>(),
        localDataSource: currentScope.resolve<SessionLocalDataSource>(),
      ))
      .singleton();
    
    // Use Cases
    bind<SendMessageUseCase>()
      .toProvide(() => SendMessageUseCase(
        currentScope.resolve<AgentRepository>(),
      ));
    
    bind<ReceiveMessagesUseCase>()
      .toProvide(() => ReceiveMessagesUseCase(
        currentScope.resolve<AgentRepository>(),
      ));
    
    bind<ExecuteToolUseCase>()
      .toProvide(() => ExecuteToolUseCase(
        currentScope.resolve<ToolRepository>(),
      ));
    
    bind<CreateSessionUseCase>()
      .toProvide(() => CreateSessionUseCase(
        currentScope.resolve<SessionRepository>(),
      ));
    
    // BLoCs
    bind<AgentChatBloc>()
      .toProvide(() => AgentChatBloc(
        sendMessage: currentScope.resolve<SendMessageUseCase>(),
        receiveMessages: currentScope.resolve<ReceiveMessagesUseCase>(),
        switchAgent: currentScope.resolve<SwitchAgentUseCase>(),
        loadHistory: currentScope.resolve<LoadChatHistoryUseCase>(),
      ));
  }
}
```

### Этап 10: Тестирование

#### 10.1 Unit тесты Use Cases
```dart
void main() {
  late SendMessageUseCase useCase;
  late MockAgentRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAgentRepository();
    useCase = SendMessageUseCase(mockRepository);
  });
  
  test('should send message successfully', () async {
    // Arrange
    final message = Message(
      id: '1',
      content: MessageContent.text('Hello'),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    when(() => mockRepository.sendMessage(message))
      .thenAnswer((_) async => right(unit));
    
    // Act
    final result = await useCase(SendMessageParams(message: message));
    
    // Assert
    expect(result, right(unit));
    verify(() => mockRepository.sendMessage(message)).called(1);
  });
  
  test('should return failure when repository fails', () async {
    // Arrange
    final message = Message(
      id: '1',
      content: MessageContent.text('Hello'),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    when(() => mockRepository.sendMessage(message))
      .thenAnswer((_) async => left(Failure.network('Connection failed')));
    
    // Act
    final result = await useCase(SendMessageParams(message: message));
    
    // Assert
    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('Should return failure'),
    );
  });
}
```

## Преимущества использования fpdart

### 1. Явная обработка ошибок
```dart
// Вместо try-catch
final result = await useCase(params);
result.fold(
  (failure) => handleError(failure),
  (success) => handleSuccess(success),
);
```

### 2. Композиция операций
```dart
// Цепочка операций с Either
final result = await validateInput(input)
  .flatMap((valid) => repository.save(valid))
  .flatMap((saved) => notifyUser(saved));
```

### 3. Option для nullable значений
```dart
// Вместо String?
Option<String> title = some('My Title');
Option<String> empty = none();

title.fold(
  () => 'No title',
  (t) => t,
);
```

### 4. Task для ленивых вычислений
```dart
// Ленивое выполнение
final task = Task(() => expensiveOperation());
// Выполняется только при вызове run()
final result = await task.run();
```

## Миграционная стратегия

### Подход: Постепенная миграция

1. **Создать Core слой**
   - Failures, UseCase, type definitions
   - Не ломает существующий код

2. **Мигрировать session_management** (самая простая фича)
   - Создать domain/data/presentation
   - Обновить DI
   - Протестировать

3. **Мигрировать tool_execution**
   - Создать domain/data/presentation
   - Обновить DI
   - Протестировать

4. **Мигрировать agent_chat** (самая сложная)
   - Создать domain/data/presentation
   - Обновить DI
   - Протестировать

5. **Удалить старый код**
   - После полной миграции
   - Обновить экспорты

## Порядок выполнения

1. ✅ Анализ текущей структуры
2. ✅ Проектирование новой архитектуры
3. ⏳ Создание Core слоя (failures, usecases, type_defs)
4. ⏳ Миграция session_management (domain -> data -> presentation)
5. ⏳ Миграция tool_execution (domain -> data -> presentation)
6. ⏳ Миграция agent_chat (domain -> data -> presentation)
7. ⏳ Обновление DI
8. ⏳ Написание тестов
9. ⏳ Удаление старого кода
10. ⏳ Документация

## Оценка времени

- Core слой: 1 час
- session_management: 3 часа
- tool_execution: 4 часа
- agent_chat: 5 часов
- DI обновление: 1 час
- Тестирование: 4 часа
- Удаление старого кода: 1 час
- Документация: 1 час

**Итого: ~20 часов работы**
