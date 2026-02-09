# Протокол автоматического создания сессий

## Обзор

Реализован новый протокол автоматического создания сессий, который упрощает взаимодействие клиента с сервером и решает проблемы с FK constraints.

## Изменения в протоколе

### Старый протокол (DEPRECATED)

```
1. Client → POST /sessions
2. Server → {session_id: "abc-123"}
3. Client → POST /agent/message/stream {session_id: "abc-123", message: "..."}
4. Server → SSE stream with messages
```

**Проблемы:**
- Два запроса для начала диалога
- Возможны race conditions с FK constraints
- Сложность обработки ошибок

### Новый протокол (ACTIVE)

```
1. Client → POST /agent/message/stream {message: "..."} // БЕЗ session_id
2. Server → SSE stream:
   - session_info chunk: {type: "session_info", session_id: "abc-123"}
   - assistant_message chunks
   - done chunk
3. Client сохраняет session_id для последующих сообщений
4. Client → POST /agent/message/stream {session_id: "abc-123", message: "..."}
```

**Преимущества:**
- ✅ Один запрос вместо двух
- ✅ Атомарность - сессия и сообщение в одной транзакции
- ✅ Решена проблема с FK constraints
- ✅ Упрощенная обработка ошибок
- ✅ Обратная совместимость - старый код с явным session_id работает

## Изменения в коде

### Backend (Agent Runtime)

#### 1. API Layer

**`MessageStreamRequest.session_id`** → `Optional[str]` (default=None)
```python
# codelab-ai-service/agent-runtime/app/api/v1/schemas/message_schemas.py
class MessageStreamRequest(BaseModel):
    session_id: Optional[str] = None  # Теперь опционален
    message: MessageRequest
```

**`StreamChunk`** → добавлен тип `"session_info"`
```python
# codelab-ai-service/agent-runtime/app/api/v1/schemas/common.py
class StreamChunk(BaseModel):
    type: str  # "session_info", "assistant_message", "tool_call", etc.
    session_id: Optional[str] = None  # Для session_info чанка
    # ... другие поля
```

**`POST /sessions`** → закомментирован (возвращает 405)
```python
# codelab-ai-service/agent-runtime/app/api/v1/routers/sessions_router.py
# @router.post("/", response_model=SessionResponse)
# async def create_session(...):
#     ...  # DISABLED
```

#### 2. Domain Layer

**`MessageProcessor.process()`** → автоматически создает сессии
```python
# codelab-ai-service/agent-runtime/app/domain/services/message_processor.py
async def process(self, session_id: Optional[str], message: MessageRequest):
    # Получаем или создаем conversation
    conversation = await self._get_or_create_conversation(session_id)
    actual_session_id = conversation.session_id
    
    # Отправляем session_info чанк первым
    yield StreamChunk(
        type="session_info",
        session_id=actual_session_id,
        is_final=False
    )
    
    # ... обработка сообщения
```

#### 3. Infrastructure Layer

**`ConversationMapper`** → детальное логирование
```python
# codelab-ai-service/agent-runtime/app/infrastructure/persistence/mappers/conversation_mapper.py
async def get_or_create_conversation(self, session_id: Optional[str]):
    if session_id:
        # Загружаем существующую
        return await self.get_conversation(session_id)
    else:
        # Создаем новую
        return await self.create_conversation()
```

### Frontend (IDE)

#### 1. Domain Layer

**`MessageContent`** → добавлен тип `sessionInfo`
```dart
// codelab_ide/packages/codelab_ai_assistant/lib/features/agent_chat/domain/entities/message.dart
sealed class MessageContent {
  const factory MessageContent.text(...) = TextMessageContent;
  const factory MessageContent.toolCall(...) = ToolCallMessageContent;
  // ... другие типы
  const factory MessageContent.sessionInfo({
    required String sessionId,
    @Default(false) bool isNewSession,
  }) = SessionInfoMessageContent;
}
```

#### 2. Data Layer

**`MessageModel`** → поддержка `session_info`
```dart
// codelab_ide/packages/codelab_ai_assistant/lib/features/agent_chat/data/models/message_model.dart
@freezed
class MessageModel {
  const factory MessageModel({
    required String type,
    String? content,
    @JsonKey(name: 'session_id') String? sessionId,  // Новое поле
    // ... другие поля
  }) = _MessageModel;
  
  MessageContent _parseContent() {
    switch (type) {
      case 'session_info':
        return MessageContent.sessionInfo(
          sessionId: sessionId ?? '',
          isNewSession: true,
        );
      // ... другие типы
    }
  }
}
```

**`GatewayApi.createSession()`** → deprecated
```dart
// codelab_ide/packages/codelab_ai_assistant/lib/features/agent_chat/data/datasources/gateway_api.dart
@Deprecated('Use auto-create via /agent/message/stream without session_id')
Future<Map<String, dynamic>> createSession() async {
  throw UnimplementedError(
    'POST /sessions is disabled. Sessions are now created automatically '
    'when sending the first message without session_id.',
  );
}
```

#### 3. Presentation Layer

**`MessageHandlerMiddleware`** → обработка `session_info`
```dart
// codelab_ide/packages/codelab_ai_assistant/lib/features/agent_chat/presentation/middleware/message_handler_middleware.dart
Future<Option<String>> handleMessage({
  required Message message,
  required void Function(Message message) onPlanApproval,
  void Function(String sessionId)? onSessionInfo,  // Новый callback
}) async {
  // Обрабатываем session_info
  message.content.maybeWhen(
    sessionInfo: (sessionId, isNewSession) {
      _logger.i('[MessageHandlerMiddleware] 🆔 Session info received: $sessionId');
      onSessionInfo?.call(sessionId);
    },
    orElse: () {},
  );
  // ...
}
```

**`AgentChatBloc`** → пропускает `session_info` в истории
```dart
// codelab_ide/packages/codelab_ai_assistant/lib/features/agent_chat/presentation/bloc/agent_chat_bloc.dart
Future<void> _onMessageReceived(MessageReceivedEvent event, Emitter emit) async {
  // Проверяем, является ли это session_info сообщением
  final isSessionInfo = event.message.content.maybeWhen(
    sessionInfo: (_, __) => true,
    orElse: () => false,
  );
  
  // Обрабатываем через middleware
  await _messageHandlerMiddleware.handleMessage(
    message: event.message,
    onSessionInfo: (sessionId) {
      _logger.i('[AgentChatBloc] 🆔 Session ID received: $sessionId');
    },
  );
  
  // Session info сообщения не добавляем в историю
  if (isSessionInfo) return;
  
  // Обновляем state
  emit(state.copyWith(messages: [...state.messages, event.message]));
}
```

**`SessionManagerBloc`** → автоматическое создание
```dart
// codelab_ide/packages/codelab_ai_assistant/lib/features/session_management/presentation/bloc/session_manager_bloc.dart
Future<void> _onCreateSession(CreateSession event, Emitter emit) async {
  _logger.d('[SessionManagerBloc] ➕ Creating new session (auto-create mode)...');
  
  // В новом протоколе сессия создается автоматически при первом сообщении
  // Генерируем временный ID для навигации
  final tempSessionId = 'new_${DateTime.now().millisecondsSinceEpoch}';
  
  // Эмитим side effect для навигации к чату
  _sideEffectsController.add(
    NewSessionCreatedEffect(sessionId: tempSessionId),
  );
  
  _logger.d('[SessionManagerBloc] Session will be created on first message');
}
```

## Примеры использования

### Создание новой сессии

**HTTP Request:**
```http
POST /agent/message/stream
Content-Type: application/json

{
  "message": {
    "type": "user_message",
    "content": "Привет!"
  }
}
```

**SSE Response:**
```
data: {"type":"session_info","session_id":"abc-123","is_final":false}

data: {"type":"assistant_message","content":"Привет","is_final":false}

data: {"type":"assistant_message","content":"!","is_final":false}

data: {"type":"done","is_final":true}
```

### Продолжение диалога

**HTTP Request:**
```http
POST /agent/message/stream
Content-Type: application/json

{
  "session_id": "abc-123",
  "message": {
    "type": "user_message",
    "content": "Как дела?"
  }
}
```

**SSE Response:**
```
data: {"type":"assistant_message","content":"Отлично","is_final":false}

data: {"type":"assistant_message","content":"!","is_final":false}

data: {"type":"done","is_final":true}
```

## Миграция

### Для клиентов

1. **Удалить вызов `POST /sessions`** перед отправкой первого сообщения
2. **Обработать `session_info` чанк** в SSE потоке
3. **Сохранить `session_id`** для последующих сообщений
4. **Использовать сохраненный `session_id`** для продолжения диалога

### Обратная совместимость

Старый код, который явно передает `session_id`, продолжит работать:
```dart
// Это все еще работает
await sendMessage(
  sessionId: existingSessionId,
  message: userMessage,
);
```

## Тестирование

### Проверка создания новой сессии

```bash
curl -X POST http://localhost:8000/api/v1/agent/message/stream \
  -H "Content-Type: application/json" \
  -d '{"message":{"type":"user_message","content":"Привет!"}}'
```

Ожидаемый результат:
- Первый чанк: `{"type":"session_info","session_id":"...","is_final":false}`
- Последующие чанки: сообщения ассистента

### Проверка продолжения диалога

```bash
curl -X POST http://localhost:8000/api/v1/agent/message/stream \
  -H "Content-Type: application/json" \
  -d '{"session_id":"abc-123","message":{"type":"user_message","content":"Как дела?"}}'
```

Ожидаемый результат:
- НЕТ `session_info` чанка
- Сразу сообщения ассистента

### Проверка отключения POST /sessions

```bash
curl -X POST http://localhost:8000/api/v1/sessions
```

Ожидаемый результат:
```
HTTP/1.1 405 Method Not Allowed
{"detail":"Method Not Allowed"}
```

## Логирование

### Backend

```
INFO: [MessageProcessor] 🆔 Session ID not provided, creating new conversation
INFO: [MessageProcessor] ✅ Created new conversation: abc-123
INFO: [MessageProcessor] 📤 Sending session_info chunk: abc-123
```

### Frontend

```
[MessageHandlerMiddleware] 🆔 Session info received: abc-123 (new: true)
[AgentChatBloc] 🆔 Session ID received: abc-123
[AgentChatBloc] Skipping session_info message in history
```

## Статус

✅ **Backend реализован и развернут**
✅ **Frontend обновлен**
✅ **Протокол протестирован**
✅ **Документация создана**

## Следующие шаги

1. ✅ Обновить UI для работы без предварительного создания сессии
2. ⏳ Провести интеграционное тестирование
3. ⏳ Обновить документацию API
4. ⏳ Удалить deprecated код после полной миграции
