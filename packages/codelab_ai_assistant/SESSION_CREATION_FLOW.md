# Session Creation Flow - Server-Side Implementation

## Обзор

Реализован полный цикл создания сессий на сервере (Agent Runtime) вместо локального создания на клиенте.

## Архитектура

### Backend (Python)

#### Agent Runtime
**Endpoint:** `POST /sessions`
- **Файл:** [`agent-runtime/app/api/v1/endpoints.py:458`](../../../codelab-ai-service/agent-runtime/app/api/v1/endpoints.py:458)
- **Функция:** Создает новую сессию в базе данных
- **Возвращает:** `session_id`, `message_count`, `current_agent`, `created_at`
- **Логика:**
  - Генерирует уникальный `session_id` через `uuid.uuid4()`
  - Создает сессию через `session_manager.get_or_create()`
  - Инициализирует с агентом `orchestrator`
  - Сохраняет в базе данных SQLite

#### Gateway
**Endpoint:** `POST /sessions`
- **Файл:** [`gateway/app/api/v1/endpoints.py:150`](../../../codelab-ai-service/gateway/app/api/v1/endpoints.py:150)
- **Функция:** Проксирует запрос к Agent Runtime
- **Добавляет:** `X-Internal-Auth` заголовок для внутренней аутентификации

### Frontend (Dart/Flutter)

#### 1. GatewayApi
**Метод:** `createSession()`
- **Файл:** [`lib/src/api/gateway_api.dart:60`](lib/src/api/gateway_api.dart:60)
- **Функция:** HTTP клиент для вызова `POST /sessions`
- **Возвращает:** `Map<String, dynamic>` с данными сессии

#### 2. GatewayService
**Метод:** `createSession()`
- **Файл:** [`lib/src/services/gateway_service.dart:122`](lib/src/services/gateway_service.dart:122)
- **Функция:** Обертка над GatewayApi с обработкой ошибок
- **Возвращает:** `String` - session_id
- **Обработка ошибок:** Бросает `GatewayException` при сбоях

#### 3. SessionRestoreService
**Метод:** `createNewSession()`
- **Файл:** [`lib/src/services/session_restore_service.dart:89`](lib/src/services/session_restore_service.dart:89)
- **Функция:** Создает сессию через API с fallback на локальное создание
- **Логика:**
  - Вызывает `gatewayService.createSession()`
  - Сохраняет `session_id` в `SharedPreferences`
  - При ошибке - fallback на локальную генерацию ID

#### 4. SessionManagerBloc
**Event:** `createNewSession`
- **Файл:** [`lib/src/bloc/session_manager_bloc.dart:85`](lib/src/bloc/session_manager_bloc.dart:85)
- **Функция:** Обрабатывает создание новой сессии через UI
- **Использует:** `SessionRestoreService.resetSession()` → `createNewSession()`

#### 5. WebSocket Connection
**Динамическое подключение:**
- **Репозиторий:** [`lib/src/data/websocket_agent_repository.dart:8`](lib/src/data/websocket_agent_repository.dart:8)
- **Изменения:**
  - Параметр `wsUrl` заменен на `gatewayUrl`
  - Метод `connect({String? sessionId})` - подключение с session_id
  - Метод `reconnect(String sessionId)` - переподключение с новым session_id
  - URL формируется динамически: `ws://gateway/ws/{session_id}`

#### 6. AgentProtocolService
**Методы:**
- **Файл:** [`lib/src/domain/agent_protocol_service.dart:7`](lib/src/domain/agent_protocol_service.dart:7)
- `connect({String? sessionId})` - подключение с опциональным session_id
- `reconnect(String sessionId)` - переподключение с новым session_id

#### 7. AiAgentBloc
**Изменения:**
- **Файл:** [`lib/src/bloc/ai_agent_bloc.dart:48`](lib/src/bloc/ai_agent_bloc.dart:48)
- Убрано автоматическое подключение в конструкторе
- Подключение происходит при `loadHistory` с конкретным `session_id`
- Метод `_ensureConnected()` - гарантирует подписку на сообщения

## Поток создания новой сессии

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. User clicks "New Session" in SessionListView                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. SessionManagerBloc.createNewSession event                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. SessionRestoreService.createNewSession()                     │
│    → GatewayService.createSession()                             │
│    → GatewayApi POST /sessions                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. Gateway proxies to Agent Runtime                             │
│    → POST http://agent-runtime:8001/sessions                    │
│    → Headers: X-Internal-Auth: secret-key                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. Agent Runtime creates session                                │
│    → session_id = "session_" + uuid.uuid4().hex[:16]            │
│    → session_manager.get_or_create(session_id)                  │
│    → Saves to SQLite database                                   │
│    → Returns: {session_id, message_count, current_agent, ...}   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. IDE receives session_id                                      │
│    → Saves to SharedPreferences                                 │
│    → Emits newSessionCreated state                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. UI transitions to ChatView                                   │
│    → AiAgentBloc.loadHistory(empty history with session_id)     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 8. WebSocket connects with session_id                           │
│    → protocol.reconnect(session_id)                             │
│    → ws://localhost:8000/ws/{session_id}                        │
│    → _ensureConnected() subscribes to messages                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 9. Ready to chat!                                               │
│    User can send messages through WebSocket                     │
└─────────────────────────────────────────────────────────────────┘
```

## Поток переключения между сессиями

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. User clicks on existing session in SessionListView          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. SessionManagerBloc.switchToSession(session_id)               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. SessionRestoreService.switchToSession(session_id)            │
│    → GatewayService.getSessionHistory(session_id)               │
│    → GET /sessions/{session_id}/history                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. Gateway proxies to Agent Runtime                             │
│    → GET http://agent-runtime:8001/sessions/{id}/history        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. Agent Runtime returns session history                        │
│    → {session_id, messages[], message_count, current_agent}     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 6. IDE receives history                                         │
│    → Saves session_id to SharedPreferences                      │
│    → Emits sessionSwitched state                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 7. UI transitions to ChatView                                   │
│    → AiAgentBloc.loadHistory(history)                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 8. WebSocket reconnects with new session_id                     │
│    → protocol.reconnect(session_id)                             │
│    → Closes old connection                                      │
│    → Opens new: ws://localhost:8000/ws/{new_session_id}         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 9. Chat loaded with history                                     │
│    User can continue conversation                               │
└─────────────────────────────────────────────────────────────────┘
```

## Ключевые изменения

### 1. WebSocket URL теперь динамический
**Было:**
```dart
// Фиксированный URL в main.dart
wsUrl: 'ws://localhost:8000/ws/ide-session'
```

**Стало:**
```dart
// Динамический URL формируется из gatewayUrl + session_id
gatewayUrl: 'ws://localhost:8000'
// Реальный URL: ws://localhost:8000/ws/{session_id}
```

### 2. Создание сессии на сервере
**Было:**
```dart
// Локальная генерация ID
String _generateSessionId() {
  return 'session_${DateTime.now().millisecondsSinceEpoch}';
}
```

**Стало:**
```dart
// Запрос к серверу
final sessionId = await gatewayService.createSession();
// Server generates: session_uuid4().hex[:16]
```

### 3. WebSocket подключение отложенное
**Было:**
```dart
// Подключение в конструкторе AiAgentBloc
protocol.connect();
```

**Стало:**
```dart
// Подключение при loadHistory с session_id
protocol.reconnect(event.history.sessionId);
_ensureConnected();
```

## Преимущества новой архитектуры

1. **Централизованное управление сессиями** - все сессии хранятся в БД Agent Runtime
2. **Уникальность session_id** - гарантируется сервером через UUID
3. **Персистентность** - сессии сохраняются между перезапусками IDE
4. **Масштабируемость** - можно добавить синхронизацию между несколькими клиентами
5. **Аудит** - все сессии логируются на сервере
6. **Восстановление** - можно восстановить сессию на любом клиенте по session_id

## Обратная совместимость

- Если сервер недоступен, используется fallback на локальное создание ID
- WebSocket URL формируется с fallback на `ide-session` если session_id не указан
- Существующий код не требует изменений

## Тестирование

### 1. Создание новой сессии
```bash
# Запустить сервисы
cd codelab-ai-service
docker-compose up

# В IDE:
# 1. Открыть AI Assistant панель
# 2. Нажать "New Session"
# 3. Проверить в логах Agent Runtime создание сессии
# 4. Проверить WebSocket подключение с новым session_id
```

### 2. Переключение между сессиями
```bash
# В IDE:
# 1. Создать несколько сессий
# 2. Отправить сообщения в каждую
# 3. Вернуться к списку сессий
# 4. Переключиться на другую сессию
# 5. Проверить что история загружена
# 6. Проверить WebSocket переподключился с новым session_id
```

### 3. Проверка логов
```bash
# Agent Runtime logs
docker logs codelab-ai-service-agent-runtime-1 -f | grep "session"

# Gateway logs  
docker logs codelab-ai-service-gateway-1 -f | grep "session"

# Должны видеть:
# - "Creating new session"
# - "Created new session: session_xxxxx"
# - "WebSocket connected" с правильным session_id
```

## Файлы изменений

### Backend
- ✅ `codelab-ai-service/agent-runtime/app/api/v1/endpoints.py` - добавлен POST /sessions
- ✅ `codelab-ai-service/gateway/app/api/v1/endpoints.py` - добавлен POST /sessions proxy

### Frontend
- ✅ `lib/src/api/gateway_api.dart` - добавлен метод createSession()
- ✅ `lib/src/services/gateway_service.dart` - добавлен метод createSession()
- ✅ `lib/src/services/session_restore_service.dart` - обновлен createNewSession()
- ✅ `lib/src/data/websocket_agent_repository.dart` - динамический session_id в URL
- ✅ `lib/src/domain/agent_protocol_service.dart` - добавлен reconnect()
- ✅ `lib/src/bloc/ai_agent_bloc.dart` - отложенное подключение WebSocket
- ✅ `lib/src/di/ai_assistant_module.dart` - убран параметр wsUrl
- ✅ `apps/codelab_ide/lib/main.dart` - убран параметр wsUrl

### UI
- ✅ `lib/src/ui/session_list_view.dart` - новый виджет списка сессий
- ✅ `lib/src/ui/chat_view.dart` - новый виджет чата
- ✅ `lib/src/ui/ai_assistant_panel.dart` - переработан для навигации

## Известные ограничения

1. **Fallback на локальное создание** - если сервер недоступен, session_id генерируется локально
2. **Нет валидации session_id** - клиент может подключиться к любому session_id
3. **Нет аутентификации пользователей** - любой может получить доступ к любой сессии
4. **Удаление сессий** - пока не реализовано на backend

## Будущие улучшения

1. **DELETE /sessions/{id}** - endpoint для удаления сессий
2. **PATCH /sessions/{id}** - переименование сессий
3. **User authentication** - привязка сессий к пользователям
4. **Session sharing** - возможность делиться сессиями
5. **Session export** - экспорт истории в файл
6. **Session search** - поиск по содержимому сессий
