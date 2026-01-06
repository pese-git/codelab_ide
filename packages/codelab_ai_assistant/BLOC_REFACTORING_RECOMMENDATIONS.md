# Рекомендации по улучшению BLoC Event/State

## Анализ текущего состояния

### Что уже хорошо ✅

1. **Использование Freezed** - immutable events и states
2. **Clean Architecture** - BLoC работает с use cases
3. **Sealed classes** - exhaustive pattern matching
4. **Логирование** - Logger для отладки
5. **Обработка ошибок** - Either<Failure, T> из use cases

### Что можно улучшить 🔧

## 1. Проблема: Множественные состояния для одного сценария

### Текущая реализация (SessionManagerBloc)

```dart
@freezed
sealed class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState.initial() = InitialState;
  const factory SessionManagerState.loading() = LoadingState;
  const factory SessionManagerState.error(String message) = ErrorState;
  const factory SessionManagerState.loaded({
    required List<Session> sessions,
    String? currentSessionId,
    String? currentAgent,
  }) = LoadedState;
  const factory SessionManagerState.sessionSwitched(
    String sessionId,
    Session session,
  ) = SessionSwitchedState; // ❌ Проблема: одноразовое состояние
  const factory SessionManagerState.newSessionCreated(String sessionId) = 
      NewSessionCreatedState; // ❌ Проблема: одноразовое состояние
}
```

**Проблемы:**
- `sessionSwitched` и `newSessionCreated` - одноразовые состояния
- Используются только в listener, не в builder
- Сложно отследить текущее состояние данных
- После перехода состояние теряется

### Улучшенная реализация

```dart
@freezed
class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState({
    required List<Session> sessions,
    required bool isLoading,
    required Option<String> error,
    required Option<String> currentSessionId,
    required Option<String> currentAgent,
    // Side effects как отдельные поля
    required Option<SessionSideEffect> sideEffect,
  }) = _SessionManagerState;

  factory SessionManagerState.initial() => SessionManagerState(
    sessions: const [],
    isLoading: false,
    error: none(),
    currentSessionId: none(),
    currentAgent: none(),
    sideEffect: none(),
  );
}

/// Side effects для одноразовых событий
@freezed
class SessionSideEffect with _$SessionSideEffect {
  const factory SessionSideEffect.sessionSwitched(Session session) = 
      SessionSwitched;
  const factory SessionSideEffect.sessionCreated(String sessionId) = 
      SessionCreated;
  const factory SessionSideEffect.sessionDeleted(String sessionId) = 
      SessionDeleted;
}
```

**Преимущества:**
- ✅ Всегда знаем текущее состояние данных
- ✅ Side effects отделены от основного состояния
- ✅ Можно обработать side effect и очистить его
- ✅ Легче тестировать

### Использование

```dart
// В BLoC
emit(state.copyWith(
  sessions: newSessions,
  isLoading: false,
  sideEffect: some(SessionSideEffect.sessionCreated(sessionId)),
));

// В UI
BlocConsumer<SessionManagerBloc, SessionManagerState>(
  listener: (context, state) {
    state.sideEffect.fold(
      () {},
      (effect) {
        effect.when(
          sessionSwitched: (session) => _navigateToChat(session),
          sessionCreated: (id) => _navigateToNewChat(id),
          sessionDeleted: (id) => context.showSuccess('Deleted'),
        );
        // Очищаем side effect после обработки
        bloc.add(const SessionManagerEvent.clearSideEffect());
      },
    );
  },
  builder: (context, state) {
    // Всегда имеем доступ к данным
    if (state.isLoading) return ProgressRing();
    if (state.error.isSome()) return ErrorWidget(state.error);
    return SessionList(sessions: state.sessions);
  },
);
```

## 2. Проблема: Смешение UI и бизнес-логики в State

### Текущая реализация (AgentChatBloc)

```dart
@freezed
abstract class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required bool isLoading,
    required bool isConnected,
    required String currentAgent,
    required Option<String> error,
    required Option<ApprovalRequestWithCompleter> pendingApproval, // ❌ Completer в State
  }) = _AgentChatState;
}
```

**Проблемы:**
- `ApprovalRequestWithCompleter` содержит Completer - не serializable
- Сложно тестировать
- Нарушает принцип immutability (Completer - mutable)

### Улучшенная реализация

```dart
@freezed
class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required bool isLoading,
    required bool isConnected,
    required String currentAgent,
    required Option<String> error,
    // Только данные для UI, без Completer
    required Option<PendingApprovalData> pendingApproval,
  }) = _AgentChatState;
}

/// Данные для отображения pending approval (без Completer)
@freezed
class PendingApprovalData with _$PendingApprovalData {
  const factory PendingApprovalData({
    required String callId,
    required String toolName,
    required Map<String, dynamic> arguments,
    Option<String>? reason,
  }) = _PendingApprovalData;
}

// Completer хранится отдельно в BLoC
class AgentChatBloc extends Bloc<AgentChatEvent, AgentChatState> {
  // Храним completer'ы отдельно от state
  final Map<String, Completer<ApprovalDecision>> _pendingCompleters = {};
  
  Future<void> _onApprovalRequested(
    ApprovalRequestedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    final request = event.request;
    
    // Сохраняем completer отдельно
    _pendingCompleters[request.toolCall.id] = request.completer;
    
    // В state только данные для UI
    emit(state.copyWith(
      pendingApproval: some(PendingApprovalData(
        callId: request.toolCall.id,
        toolName: request.toolCall.toolName,
        arguments: request.toolCall.arguments,
        reason: request.reason,
      )),
    ));
  }
  
  Future<void> _onApproveToolCall(
    ApproveToolCallEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    state.pendingApproval.fold(
      () => _logger.w('No pending approval'),
      (approval) {
        final completer = _pendingCompleters.remove(approval.callId);
        completer?.complete(const ApprovalDecision.approved());
        emit(state.copyWith(pendingApproval: none()));
      },
    );
  }
}
```

**Преимущества:**
- ✅ State полностью immutable и serializable
- ✅ Легче тестировать
- ✅ Можно сохранить state в storage
- ✅ Четкое разделение: данные в state, логика в BLoC

## 3. Проблема: Отсутствие типизации для ошибок

### Текущая реализация

```dart
const factory SessionManagerState.error(String message) = ErrorState;
```

**Проблемы:**
- Только текст ошибки, нет типа
- Сложно обрабатывать разные типы ошибок по-разному
- Нет кода ошибки для локализации

### Улучшенная реализация

```dart
@freezed
class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState({
    required List<Session> sessions,
    required bool isLoading,
    required Option<AppError> error, // ✅ Типизированная ошибка
    // ...
  }) = _SessionManagerState;
}

/// Типизированная ошибка для UI
@freezed
class AppError with _$AppError {
  const factory AppError.network({
    required String message,
    String? code,
    bool? isRetryable,
  }) = NetworkError;
  
  const factory AppError.authentication({
    required String message,
    String? code,
  }) = AuthenticationError;
  
  const factory AppError.validation({
    required String message,
    required Map<String, String> fieldErrors,
  }) = ValidationError;
  
  const factory AppError.unknown({
    required String message,
    Object? originalError,
  }) = UnknownError;
}
```

**Использование:**

```dart
// В BLoC
result.fold(
  (failure) {
    final error = failure.when(
      network: (msg) => AppError.network(
        message: msg,
        isRetryable: true,
      ),
      authentication: (msg) => AppError.authentication(message: msg),
      validation: (msg, fields) => AppError.validation(
        message: msg,
        fieldErrors: fields,
      ),
      unknown: (msg) => AppError.unknown(message: msg),
    );
    emit(state.copyWith(error: some(error)));
  },
  // ...
);

// В UI
state.error.fold(
  () => Container(),
  (error) => error.when(
    network: (msg, code, retryable) => NetworkErrorWidget(
      message: msg,
      onRetry: retryable == true ? _retry : null,
    ),
    authentication: (msg, code) => AuthErrorWidget(message: msg),
    validation: (msg, fields) => ValidationErrorWidget(
      message: msg,
      fieldErrors: fields,
    ),
    unknown: (msg, original) => GenericErrorWidget(message: msg),
  ),
);
```

## 4. Проблема: Отсутствие состояния для частичных обновлений

### Текущая реализация (AgentChatBloc)

```dart
const factory AgentChatState({
  required List<Message> messages,
  required bool isLoading, // ❌ Глобальный loading
  // ...
}) = _AgentChatState;
```

**Проблемы:**
- `isLoading` блокирует весь UI
- Нельзя показать loading для конкретного действия
- Нельзя делать несколько действий параллельно

### Улучшенная реализация

```dart
@freezed
class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required Set<LoadingOperation> loadingOperations, // ✅ Множество операций
    required bool isConnected,
    required String currentAgent,
    required Option<String> error,
    required Option<PendingApprovalData> pendingApproval,
  }) = _AgentChatState;
  
  const AgentChatState._();
  
  // Удобные геттеры
  bool get isLoading => loadingOperations.isNotEmpty;
  bool get isSendingMessage => loadingOperations.contains(
    LoadingOperation.sendingMessage,
  );
  bool get isLoadingHistory => loadingOperations.contains(
    LoadingOperation.loadingHistory,
  );
  bool get isSwitchingAgent => loadingOperations.contains(
    LoadingOperation.switchingAgent,
  );
}

/// Типы операций загрузки
enum LoadingOperation {
  sendingMessage,
  loadingHistory,
  switchingAgent,
  executingTool,
  connecting,
}
```

**Использование:**

```dart
// В BLoC - добавляем конкретную операцию
emit(state.copyWith(
  loadingOperations: {...state.loadingOperations, LoadingOperation.sendingMessage},
));

// После завершения - убираем
emit(state.copyWith(
  loadingOperations: state.loadingOperations
      .where((op) => op != LoadingOperation.sendingMessage)
      .toSet(),
));

// В UI - показываем loading только для нужной части
ChatInputBar(
  isLoading: state.isSendingMessage, // ✅ Конкретный loading
  enabled: !state.isLoading,
)
```

## 5. Улучшение: Добавление метаданных в Events

### Текущая реализация

```dart
const factory AgentChatEvent.sendMessage(String text) = SendMessageEvent;
```

**Проблемы:**
- Нет контекста откуда пришло событие
- Сложно отследить в логах
- Нет возможности добавить metadata

### Улучшенная реализация

```dart
@freezed
class AgentChatEvent with _$AgentChatEvent {
  const factory AgentChatEvent.sendMessage({
    required String text,
    @Default(none()) Option<Map<String, dynamic>> metadata,
    @Default(none()) Option<String> correlationId, // Для трейсинга
  }) = SendMessageEvent;
  
  const factory AgentChatEvent.messageReceived({
    required Message message,
    @Default(none()) Option<String> correlationId,
  }) = MessageReceivedEvent;
}
```

**Использование:**

```dart
// Отправка с метаданными
bloc.add(AgentChatEvent.sendMessage(
  text: 'Hello',
  metadata: some({'source': 'quick_action', 'template': 'greeting'}),
  correlationId: some(uuid.v4()),
));

// В BLoC - логирование с контекстом
Future<void> _onSendMessage(
  SendMessageEvent event,
  Emitter<AgentChatState> emit,
) async {
  _logger.i(
    'Sending message',
    event.correlationId.fold(() => null, (id) => id),
  );
  // ...
}
```

## 6. Улучшение: Разделение State на Data и UI State

### Текущая реализация

```dart
@freezed
abstract class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages, // Data
    required bool isLoading, // UI state
    required bool isConnected, // Data
    required String currentAgent, // Data
    required Option<String> error, // UI state
    required Option<ApprovalRequestWithCompleter> pendingApproval, // Mixed
  }) = _AgentChatState;
}
```

**Проблема:** Смешаны данные и UI состояние

### Улучшенная реализация

```dart
@freezed
class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    // Data state
    required ChatData data,
    // UI state
    required ChatUIState uiState,
  }) = _AgentChatState;
  
  factory AgentChatState.initial() => AgentChatState(
    data: ChatData.initial(),
    uiState: ChatUIState.initial(),
  );
}

/// Данные чата (domain)
@freezed
class ChatData with _$ChatData {
  const factory ChatData({
    required List<Message> messages,
    required bool isConnected,
    required String currentAgent,
    required Option<PendingApprovalData> pendingApproval,
  }) = _ChatData;
  
  factory ChatData.initial() => ChatData(
    messages: const [],
    isConnected: false,
    currentAgent: 'orchestrator',
    pendingApproval: none(),
  );
}

/// UI состояние (presentation)
@freezed
class ChatUIState with _$ChatUIState {
  const factory ChatUIState({
    required Set<LoadingOperation> loadingOperations,
    required Option<AppError> error,
    required Option<SessionSideEffect> sideEffect,
  }) = _ChatUIState;
  
  factory ChatUIState.initial() => ChatUIState(
    loadingOperations: const {},
    error: none(),
    sideEffect: none(),
  );
  
  const ChatUIState._();
  
  bool get isLoading => loadingOperations.isNotEmpty;
}
```

**Преимущества:**
- ✅ Четкое разделение данных и UI состояния
- ✅ Легче тестировать (можно тестировать отдельно)
- ✅ Можно сохранить только data в storage
- ✅ UI state можно сбросить без потери данных

## 7. Улучшение: Добавление Debounce для Events

### Проблема

```dart
// Пользователь быстро кликает кнопку
onPressed: () {
  bloc.add(const SessionManagerEvent.loadSessions());
  bloc.add(const SessionManagerEvent.loadSessions());
  bloc.add(const SessionManagerEvent.loadSessions());
}
```

### Решение

```dart
class SessionManagerBloc extends Bloc<SessionManagerEvent, SessionManagerState> {
  SessionManagerBloc({...}) : super(...) {
    // Debounce для loadSessions
    on<LoadSessions>(
      _onLoadSessions,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
    
    // Throttle для refresh
    on<RefreshSessions>(
      _onRefreshSessions,
      transformer: throttle(const Duration(seconds: 1)),
    );
  }
}

// Transformer helpers
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
}

EventTransformer<E> throttle<E>(Duration duration) {
  return (events, mapper) => events.throttleTime(duration).flatMap(mapper);
}
```

## 8. Улучшение: Добавление Undo/Redo

### Реализация

```dart
@freezed
class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required ChatData data,
    required ChatUIState uiState,
    required List<ChatData> history, // ✅ История для undo
    required int historyIndex, // ✅ Текущая позиция
  }) = _AgentChatState;
  
  const AgentChatState._();
  
  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < history.length - 1;
}

// Events
@freezed
class AgentChatEvent with _$AgentChatEvent {
  // ... существующие events
  const factory AgentChatEvent.undo() = UndoEvent;
  const factory AgentChatEvent.redo() = RedoEvent;
}

// В BLoC
Future<void> _onSendMessage(
  SendMessageEvent event,
  Emitter<AgentChatState> emit,
) async {
  // Сохраняем текущее состояние в историю
  final newHistory = [
    ...state.history.take(state.historyIndex + 1),
    state.data,
  ];
  
  // Обновляем данные
  final newData = state.data.copyWith(
    messages: [...state.data.messages, userMessage],
  );
  
  emit(state.copyWith(
    data: newData,
    history: newHistory,
    historyIndex: newHistory.length - 1,
  ));
}

Future<void> _onUndo(
  UndoEvent event,
  Emitter<AgentChatState> emit,
) async {
  if (state.canUndo) {
    emit(state.copyWith(
      data: state.history[state.historyIndex - 1],
      historyIndex: state.historyIndex - 1,
    ));
  }
}
```

## 9. Улучшение: Добавление Optimistic Updates

### Текущая реализация

```dart
Future<void> _onSendMessage(...) async {
  // Добавляем сообщение
  emit(state.copyWith(
    messages: [...state.messages, userMessage],
    isLoading: true,
  ));
  
  // Отправляем на сервер
  final result = await _sendMessage(...);
  
  result.fold(
    (failure) {
      // ❌ Проблема: сообщение уже в списке, но отправка failed
      emit(state.copyWith(isLoading: false, error: some(failure.message)));
    },
    (_) {
      emit(state.copyWith(isLoading: false));
    },
  );
}
```

### Улучшенная реализация

```dart
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required MessageRole role,
    required MessageContent content,
    required DateTime timestamp,
    required MessageStatus status, // ✅ Статус сообщения
    Option<Map<String, dynamic>>? metadata,
  }) = _Message;
}

enum MessageStatus {
  pending,    // Отправляется
  sent,       // Отправлено
  delivered,  // Доставлено
  failed,     // Ошибка
}

Future<void> _onSendMessage(...) async {
  // Добавляем с статусом pending
  final userMessage = Message(
    id: tempId,
    role: MessageRole.user,
    content: MessageContent.text(text: event.text, isFinal: true),
    timestamp: DateTime.now(),
    status: MessageStatus.pending, // ✅ Optimistic
    metadata: none(),
  );
  
  emit(state.copyWith(
    data: state.data.copyWith(
      messages: [...state.data.messages, userMessage],
    ),
  ));
  
  // Отправляем
  final result = await _sendMessage(...);
  
  result.fold(
    (failure) {
      // Обновляем статус на failed
      final updatedMessages = state.data.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();
      
      emit(state.copyWith(
        data: state.data.copyWith(messages: updatedMessages),
        uiState: state.uiState.copyWith(
          error: some(AppError.network(message: failure.message)),
        ),
      ));
    },
    (realId) {
      // Обновляем на реальный ID и статус sent
      final updatedMessages = state.data.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(id: realId, status: MessageStatus.sent);
        }
        return m;
      }).toList();
      
      emit(state.copyWith(
        data: state.data.copyWith(messages: updatedMessages),
      ));
    },
  );
}
```

## 10. Улучшение: Добавление Pagination State

### Для больших списков

```dart
@freezed
class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState({
    required List<Session> sessions,
    required PaginationState pagination, // ✅ Состояние пагинации
    required bool isLoading,
    required Option<AppError> error,
  }) = _SessionManagerState;
}

@freezed
class PaginationState with _$PaginationState {
  const factory PaginationState({
    required int currentPage,
    required int totalPages,
    required int pageSize,
    required bool hasMore,
    required bool isLoadingMore,
  }) = _PaginationState;
  
  factory PaginationState.initial() => const PaginationState(
    currentPage: 1,
    totalPages: 1,
    pageSize: 20,
    hasMore: false,
    isLoadingMore: false,
  );
}

// Events
@freezed
class SessionManagerEvent with _$SessionManagerEvent {
  const factory SessionManagerEvent.loadSessions() = LoadSessions;
  const factory SessionManagerEvent.loadMoreSessions() = LoadMoreSessions; // ✅
}
```

## Итоговые рекомендации

### Приоритет 1: Критичные улучшения

1. **Разделить State на Data и UI State** - улучшит архитектуру
2. **Убрать Completer из State** - сделает state serializable
3. **Использовать типизированные ошибки** - улучшит UX

### Приоритет 2: Желательные улучшения

4. **Side effects вместо одноразовых состояний** - упростит логику
5. **Множественные loading операции** - улучшит UX
6. **Optimistic updates** - сделает UI отзывчивым

### Приоритет 3: Опциональные улучшения

7. **Debounce/Throttle** - оптимизация
8. **Undo/Redo** - расширенная функциональность
9. **Pagination** - для больших списков

## Пример полного улучшенного BLoC

```dart
// Улучшенный SessionManagerBloc
@freezed
class SessionManagerState with _$SessionManagerState {
  const factory SessionManagerState({
    // Data
    required List<Session> sessions,
    required Option<String> currentSessionId,
    required PaginationState pagination,
    
    // UI State
    required Set<LoadingOperation> loadingOperations,
    required Option<AppError> error,
    required Option<SessionSideEffect> sideEffect,
  }) = _SessionManagerState;
  
  factory SessionManagerState.initial() => SessionManagerState(
    sessions: const [],
    currentSessionId: none(),
    pagination: PaginationState.initial(),
    loadingOperations: const {},
    error: none(),
    sideEffect: none(),
  );
  
  const SessionManagerState._();
  
  bool get isLoading => loadingOperations.isNotEmpty;
  bool get isLoadingSessions => loadingOperations.contains(
    LoadingOperation.loadingSessions,
  );
}

class SessionManagerBloc extends Bloc<SessionManagerEvent, SessionManagerState> {
  SessionManagerBloc({...}) : super(SessionManagerState.initial()) {
    on<LoadSessions>(
      _onLoadSessions,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
    on<CreateSession>(_onCreateSession);
    on<DeleteSession>(_onDeleteSession);
    on<ClearSideEffect>(_onClearSideEffect);
  }
  
  Future<void> _onLoadSessions(...) async {
    // Добавляем loading операцию
    emit(state.copyWith(
      loadingOperations: {
        ...state.loadingOperations,
        LoadingOperation.loadingSessions,
      },
    ));
    
    final result = await _listSessions();
    
    result.fold(
      (failure) {
        emit(state.copyWith(
          loadingOperations: state.loadingOperations
              .where((op) => op != LoadingOperation.loadingSessions)
              .toSet(),
          error: some(AppError.network(
            message: failure.message,
            isRetryable: true,
          )),
        ));
      },
      (sessions) {
        emit(state.copyWith(
          sessions: sessions,
          loadingOperations: state.loadingOperations
              .where((op) => op != LoadingOperation.loadingSessions)
              .toSet(),
          error: none(),
        ));
      },
    );
  }
  
  Future<void> _onClearSideEffect(...) async {
    emit(state.copyWith(sideEffect: none()));
  }
}
```

## Заключение

Применение этих улучшений приведет к:
- ✅ Более чистой архитектуре BLoC
- ✅ Лучшей тестируемости
- ✅ Улучшенному UX (optimistic updates, конкретные loading)
- ✅ Легкой отладке (типизированные ошибки, метаданные)
- ✅ Возможности сохранения состояния (serializable state)
