# 🔄 Анализ Loader в форме чата

## Когда включается loader (`isLoading: true`)

### В AgentChatBloc

Loader включается в 4 случаях:

#### 1. Отправка сообщения (`_onSendMessage`)
```dart
// Строка 265
emit(state.copyWith(
  messages: [...state.messages, userMessage],
  isLoading: true,  // ✅ Loader включается
  error: none(),
));

// Отключается после получения ответа от сервера
emit(state.copyWith(isLoading: false));
```

**Триггер:** Пользователь отправляет сообщение  
**Длительность:** До получения ответа от сервера  
**UI эффект:** Кнопка отправки показывает ProgressRing, поле ввода disabled

#### 2. Переключение агента (`_onSwitchAgent`)
```dart
// Строка 392
emit(state.copyWith(isLoading: true, error: none()));

// Отключается после успешного переключения
emit(state.copyWith(isLoading: false, currentAgent: event.agentType));
```

**Триггер:** Пользователь выбирает другого агента  
**Длительность:** До подтверждения от сервера  
**UI эффект:** Весь чат в состоянии loading

#### 3. Загрузка истории (`_onLoadHistory`)
```dart
// Строка 418
emit(state.copyWith(isLoading: true, error: none()));

// Отключается после загрузки сообщений
emit(state.copyWith(messages: messages, isLoading: false, error: none()));
```

**Триггер:** Открытие существующей сессии  
**Длительность:** До загрузки всех сообщений  
**UI эффект:** Весь чат в состоянии loading

#### 4. Подключение к WebSocket (`_onConnect`)
```dart
// Строка 442
emit(state.copyWith(isLoading: true, error: none()));

// Отключается после успешного подключения
emit(state.copyWith(isConnected: true, isLoading: false));
```

**Триггер:** Подключение к новой или существующей сессии  
**Длительность:** До установки WebSocket соединения  
**UI эффект:** Весь чат в состоянии loading

---

## Проблема: Глобальный loader

### Текущая реализация

```dart
@freezed
abstract class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required bool isLoading,  // ❌ Один флаг для всех операций
    // ...
  }) = _AgentChatState;
}
```

**Проблемы:**
- Один `isLoading` блокирует весь UI
- Нельзя показать loading для конкретной операции
- Нельзя делать несколько операций параллельно
- Плохой UX - пользователь не понимает, что происходит

### В UI (ChatView/ChatPage)

```dart
final waiting = state.isLoading;

// Поле ввода disabled при любом loading
TextBox(
  enabled: !waiting && !hasApproval,
)

// Кнопка отправки показывает loader при любом loading
FilledButton(
  onPressed: (waiting || hasApproval) ? null : _send,
  child: waiting
      ? const ProgressRing()  // ❌ Показывается для ВСЕХ операций
      : const Icon(FluentIcons.send),
)
```

---

## Решение: Множественные loading операции

### Улучшенная реализация (из BLOC_REFACTORING_RECOMMENDATIONS.md)

```dart
@freezed
class AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required Set<LoadingOperation> loadingOperations,  // ✅ Множество операций
    // ...
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
  bool get isConnecting => loadingOperations.contains(
    LoadingOperation.connecting,
  );
}

enum LoadingOperation {
  sendingMessage,
  loadingHistory,
  switchingAgent,
  connecting,
  executingTool,
}
```

### В BLoC

```dart
// Отправка сообщения
Future<void> _onSendMessage(...) async {
  // Добавляем конкретную операцию
  emit(state.copyWith(
    messages: [...state.messages, userMessage],
    loadingOperations: {
      ...state.loadingOperations,
      LoadingOperation.sendingMessage,  // ✅ Конкретная операция
    },
  ));
  
  final result = await _sendMessage(...);
  
  // Убираем конкретную операцию
  emit(state.copyWith(
    loadingOperations: state.loadingOperations
        .where((op) => op != LoadingOperation.sendingMessage)
        .toSet(),
  ));
}

// Загрузка истории
Future<void> _onLoadHistory(...) async {
  emit(state.copyWith(
    loadingOperations: {
      ...state.loadingOperations,
      LoadingOperation.loadingHistory,  // ✅ Другая операция
    },
  ));
  
  // ...
  
  emit(state.copyWith(
    messages: messages,
    loadingOperations: state.loadingOperations
        .where((op) => op != LoadingOperation.loadingHistory)
        .toSet(),
  ));
}
```

### В UI

```dart
// Показываем loader только для отправки сообщения
ChatInputBar(
  controller: _controller,
  onSend: _send,
  isLoading: state.isSendingMessage,  // ✅ Конкретный loader
  enabled: !state.isLoading,  // Disabled если любая операция
)

// Показываем loader для загрузки истории
if (state.isLoadingHistory) {
  return Center(child: ProgressRing());
}

// Показываем loader для подключения
if (state.isConnecting) {
  return Center(
    child: Column(
      children: [
        ProgressRing(),
        Text('Connecting to session...'),
      ],
    ),
  );
}
```

---

## Преимущества улучшенного подхода

### До (текущая реализация)

```
Отправка сообщения → isLoading: true → ВСЁ заблокировано
Загрузка истории → isLoading: true → ВСЁ заблокировано
Переключение агента → isLoading: true → ВСЁ заблокировано
Подключение → isLoading: true → ВСЁ заблокировано
```

**Проблемы:**
- ❌ Пользователь не понимает, что происходит
- ❌ Нельзя делать несколько действий
- ❌ Плохой UX

### После (рекомендуемая реализация)

```
Отправка сообщения → isSendingMessage: true → Только кнопка отправки
Загрузка истории → isLoadingHistory: true → Показываем скелетон
Переключение агента → isSwitchingAgent: true → Показываем индикатор
Подключение → isConnecting: true → Показываем "Connecting..."
```

**Преимущества:**
- ✅ Понятно, что именно загружается
- ✅ Можно делать несколько операций
- ✅ Лучший UX
- ✅ Более отзывчивый интерфейс

---

## Текущее поведение (что нужно знать)

### Loader включается когда:

1. **Отправляете сообщение** - до получения ответа
2. **Переключаете агента** - до подтверждения
3. **Открываете сессию** - до загрузки истории
4. **Подключаетесь к WebSocket** - до установки соединения

### Loader НЕ включается когда:

- Получаете сообщения от агента (streaming)
- Выполняются tool calls (автоматически)
- Показывается pending approval

### Как избежать бесконечного loader:

1. **Убедитесь что сервер отвечает** - проверьте логи
2. **Проверьте WebSocket соединение** - должно быть установлено
3. **Проверьте авторизацию** - 401 ошибки блокируют операции
4. **Добавьте timeout** - для операций

---

## Рекомендации

### Краткосрочные (для текущего кода)

1. **Добавить timeout для операций:**
```dart
Future<void> _onConnect(...) async {
  emit(state.copyWith(isLoading: true));
  
  try {
    final result = await _connect(...)
        .timeout(const Duration(seconds: 10));  // ✅ Timeout
    
    // ...
  } on TimeoutException {
    emit(state.copyWith(
      isLoading: false,
      error: some('Connection timeout'),
    ));
  }
}
```

2. **Добавить индикатор конкретной операции:**
```dart
// В UI показывать, что именно загружается
if (state.isLoading) {
  return Center(
    child: Column(
      children: [
        ProgressRing(),
        Text(_getLoadingMessage(state)),  // "Sending message...", "Loading history..."
      ],
    ),
  );
}
```

### Долгосрочные (рефакторинг BLoC)

Применить рекомендации из [`BLOC_REFACTORING_RECOMMENDATIONS.md`](BLOC_REFACTORING_RECOMMENDATIONS.md):
- Множественные loading операции
- Типизированные ошибки
- Timeout handling
- Retry механизмы

---

## Заключение

**Loader включается при:**
1. Отправке сообщения
2. Переключении агента
3. Загрузке истории
4. Подключении к WebSocket

**Для улучшения UX:**
- Используйте множественные loading операции
- Добавьте timeout
- Показывайте конкретное сообщение о загрузке
- Добавьте retry кнопки

См. [`BLOC_REFACTORING_RECOMMENDATIONS.md`](BLOC_REFACTORING_RECOMMENDATIONS.md) для деталей.
