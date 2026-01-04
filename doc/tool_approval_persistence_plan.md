# План: Персистентность запросов на подтверждение инструментов

## Проблема

Текущая реализация использует `Completer<ApprovalDecision>` без таймаута, что правильно для ожидания решения пользователя. Однако:

1. **При перезапуске IDE:** `Completer` теряется (существует только в памяти)
2. **При переустановке IDE:** Локальное состояние полностью теряется
3. **Состояние на сервере:** `HITLPendingState` хранится в `AgentContext.metadata` (в памяти)
4. **Результат:** Пользователь не видит ожидающие подтверждения после перезапуска/переустановки

## Требования

- ✅ Ожидание подтверждения должно быть бесконечным (без таймаута)
- ✅ Запросы должны сохраняться при перезапуске IDE
- ✅ **Запросы должны сохраняться при переустановке IDE**
- ✅ После перезапуска/переустановки пользователь должен видеть все ожидающие подтверждения
- ✅ Сессия агента должна корректно восстанавливаться

## Текущая архитектура

### Серверная сторона (Python)

1. **HITLManager** ([`hitl_manager.py`](codelab-ai-service/agent-runtime/app/services/hitl_manager.py:35))
   - Хранит `HITLPendingState` в `AgentContext.metadata['hitl_pending_calls']`
   - Методы: `add_pending()`, `get_pending()`, `get_all_pending()`, `remove_pending()`
   - **Проблема:** Хранение только в памяти

2. **Обработка решений** ([`endpoints.py`](codelab-ai-service/agent-runtime/app/api/v1/endpoints.py:69))
   - Получает `hitl_decision` через SSE endpoint `/agent/message/stream`
   - Формат: `{"type": "hitl_decision", "call_id": "...", "decision": "approve|edit|reject"}`
   - Обрабатывает решение и продолжает выполнение агента

3. **Модели** ([`hitl_models.py`](codelab-ai-service/agent-runtime/app/models/hitl_models.py:139))
   - `HITLPendingState` - состояние ожидающего подтверждения
   - `HITLUserDecision` - решение пользователя
   - `HITLDecision` - enum (APPROVE, EDIT, REJECT)

### Клиентская сторона (Dart/Flutter)

1. **ToolApprovalServiceImpl** ([`tool_approval_service_impl.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/services/tool_approval_service_impl.dart:33))
   - Создает `Completer<ApprovalDecision>` для каждого запроса
   - Эмитирует запрос через `StreamController`
   - **Проблема:** `Completer` существует только в памяти

2. **AgentChatBloc** ([`agent_chat_bloc.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/agent_chat/presentation/bloc/agent_chat_bloc.dart:354))
   - Подписывается на `approvalRequests` stream
   - Хранит `pendingApproval` в состоянии
   - Отправляет решение через `SendToolResultUseCase`
   - **Проблема:** Состояние теряется при перезапуске

3. **Отправка решений**
   - Решения отправляются через WebSocket как `tool_result`
   - Используется `SendToolResultUseCase`

## Архитектурное решение

### Ключевое решение: База данных на сервере

**Источник истины - база данных на сервере**, а не память. Это решает все проблемы с перезапуском и переустановкой.

### 1. SQLAlchemy модель для хранения ожидающих подтверждений

```python
# agent-runtime/app/models/db_models.py

from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class PendingApproval(Base):
    """SQLAlchemy модель для ожидающих подтверждений"""
    __tablename__ = 'pending_approvals'
    
    approval_id = Column(String(255), primary_key=True)
    session_id = Column(String(255), ForeignKey('sessions.session_id', ondelete='CASCADE'), nullable=False)
    call_id = Column(String(255), nullable=False)
    tool_name = Column(String(255), nullable=False)
    arguments = Column(JSONB, nullable=False)
    reason = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    status = Column(String(50), nullable=False, default='pending')
    
    __table_args__ = (
        Index('idx_pending_approvals_session_id', 'session_id'),
        Index('idx_pending_approvals_status', 'status'),
        Index('idx_pending_approvals_created_at', 'created_at'),
    )
```

### 2. Модификация HITLManager (сервер)

Добавить персистентность в базу данных:

```python
# agent-runtime/app/services/hitl_manager.py

class HITLManager:
    def __init__(self, db: Database):
        self.db = db
    
    async def add_pending(
        self,
        session_id: str,
        call_id: str,
        tool_name: str,
        arguments: Dict,
        reason: Optional[str] = None
    ) -> HITLPendingState:
        """
        Добавить запрос на подтверждение.
        Сохраняет в БД И в AgentContext.metadata для обратной совместимости.
        """
        # Создаем состояние
        pending_state = HITLPendingState(
            call_id=call_id,
            tool_name=tool_name,
            arguments=arguments,
            reason=reason
        )
        
        # Сохраняем в БД (источник истины)
        await self.db.save_pending_approval(
            session_id=session_id,
            call_id=call_id,
            tool_name=tool_name,
            arguments=arguments,
            reason=reason
        )
        
        # Также сохраняем в AgentContext для быстрого доступа
        context = _get_agent_context_manager().get_or_create(session_id)
        if HITL_PENDING_KEY not in context.metadata:
            context.metadata[HITL_PENDING_KEY] = {}
        context.metadata[HITL_PENDING_KEY][call_id] = pending_state.model_dump()
        
        logger.info(f"Added pending approval to DB: session={session_id}, call_id={call_id}")
        
        return pending_state
    
    async def get_all_pending(self, session_id: str) -> List[HITLPendingState]:
        """
        Получить все ожидающие подтверждения из БД.
        """
        # Загружаем из БД (источник истины)
        pending_list = await self.db.get_pending_approvals(session_id)
        
        return [
            HITLPendingState(
                call_id=p['call_id'],
                tool_name=p['tool_name'],
                arguments=p['arguments'],
                reason=p.get('reason'),
                created_at=p['created_at']
            )
            for p in pending_list
        ]
    
    async def remove_pending(self, session_id: str, call_id: str) -> bool:
        """
        Удалить запрос после обработки.
        Удаляет из БД И из AgentContext.
        """
        # Удаляем из БД
        await self.db.delete_pending_approval(call_id)
        
        # Удаляем из AgentContext
        context = _get_agent_context_manager().get(session_id)
        if context:
            pending_calls = context.metadata.get(HITL_PENDING_KEY, {})
            if call_id in pending_calls:
                del pending_calls[call_id]
        
        logger.info(f"Removed pending approval from DB: call_id={call_id}")
        return True
```

### 3. Добавление методов в Database с использованием SQLAlchemy (сервер)

```python
# agent-runtime/app/services/database.py

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, delete
from app.models.db_models import PendingApproval
import json

class Database:
    def __init__(self, database_url: str):
        self.engine = create_async_engine(database_url, echo=True)
        self.async_session = sessionmaker(
            self.engine, class_=AsyncSession, expire_on_commit=False
        )
    
    async def save_pending_approval(
        self,
        session_id: str,
        call_id: str,
        tool_name: str,
        arguments: Dict,
        reason: Optional[str] = None
    ):
        """Сохранить ожидающее подтверждение в БД используя SQLAlchemy"""
        async with self.async_session() as session:
            pending_approval = PendingApproval(
                approval_id=call_id,  # approval_id = call_id
                session_id=session_id,
                call_id=call_id,
                tool_name=tool_name,
                arguments=arguments,  # SQLAlchemy автоматически сериализует JSONB
                reason=reason,
                status='pending'
            )
            session.add(pending_approval)
            await session.commit()
    
    async def get_pending_approvals(self, session_id: str) -> List[Dict]:
        """Получить все ожидающие подтверждения для сессии используя SQLAlchemy"""
        async with self.async_session() as session:
            stmt = select(PendingApproval).where(
                PendingApproval.session_id == session_id,
                PendingApproval.status == 'pending'
            ).order_by(PendingApproval.created_at.asc())
            
            result = await session.execute(stmt)
            rows = result.scalars().all()
            
            return [
                {
                    'call_id': row.call_id,
                    'tool_name': row.tool_name,
                    'arguments': row.arguments,  # JSONB автоматически десериализуется
                    'reason': row.reason,
                    'created_at': row.created_at
                }
                for row in rows
            ]
    
    async def delete_pending_approval(self, call_id: str):
        """Удалить ожидающее подтверждение используя SQLAlchemy"""
        async with self.async_session() as session:
            stmt = delete(PendingApproval).where(PendingApproval.call_id == call_id)
            await session.execute(stmt)
            await session.commit()
```

### 4. REST API для получения ожидающих подтверждений

```python
# agent-runtime/app/api/v1/endpoints.py

@router.get("/sessions/{session_id}/pending-approvals")
async def get_pending_approvals(session_id: str):
    """
    Получить все ожидающие подтверждения для сессии.
    Используется при восстановлении после перезапуска IDE.
    """
    logger.debug(f"Getting pending approvals for session {session_id}")
    
    # Проверяем существование сессии
    if not session_manager.exists(session_id):
        return JSONResponse(
            content={"error": f"Session {session_id} not found"},
            status_code=404
        )
    
    # Получаем из БД
    pending_approvals = await hitl_manager.get_all_pending(session_id)
    
    return {
        "session_id": session_id,
        "pending_approvals": [
            {
                "call_id": p.call_id,
                "tool_name": p.tool_name,
                "arguments": p.arguments,
                "reason": p.reason,
                "created_at": p.created_at.isoformat()
            }
            for p in pending_approvals
        ],
        "count": len(pending_approvals)
    }
```

### 8. Gateway проксирование запроса

Gateway должен проксировать REST запрос к Agent-Runtime:

```python
# gateway/app/api/v1/endpoints.py

@router.get("/sessions/{session_id}/pending-approvals")
async def get_pending_approvals_proxy(session_id: str):
    """
    Проксировать запрос на получение ожидающих подтверждений к Agent-Runtime.
    
    Client → Gateway → Agent-Runtime
    """
    logger.debug(f"Proxying pending-approvals request for session {session_id}")
    
    try:
        # Проксируем запрос к Agent-Runtime
        agent_runtime_url = f"{AGENT_RUNTIME_BASE_URL}/sessions/{session_id}/pending-approvals"
        
        async with httpx.AsyncClient() as client:
            response = await client.get(agent_runtime_url, timeout=10.0)
            
            if response.status_code == 404:
                return JSONResponse(
                    content={"error": f"Session {session_id} not found"},
                    status_code=404
                )
            
            response.raise_for_status()
            return response.json()
            
    except httpx.HTTPError as e:
        logger.error(f"Failed to proxy pending-approvals request: {e}")
        return JSONResponse(
            content={"error": "Failed to fetch pending approvals"},
            status_code=500
        )
```

### 5. Клиентский сервис для синхронизации

```dart
// lib/features/tool_execution/data/services/approval_sync_service.dart

class ApprovalSyncService {
  final GatewayApi _api;
  
  ApprovalSyncService(this._api);
  
  /// Получить все ожидающие подтверждения с сервера (REST API)
  Future<List<ToolApprovalRequest>> fetchPendingApprovals(String sessionId) async {
    try {
      final response = await _api.get('/sessions/$sessionId/pending-approvals');
      
      final List<dynamic> approvals = response['pending_approvals'] ?? [];
      
      return approvals.map((json) {
        return ToolApprovalRequest(
          requestId: json['call_id'],
          toolCall: ToolCall(
            id: json['call_id'],
            toolName: json['tool_name'],
            arguments: Map<String, dynamic>.from(json['arguments']),
            requiresApproval: true,
            createdAt: DateTime.parse(json['created_at']),
          ),
          requestedAt: DateTime.parse(json['created_at']),
        );
      }).toList();
    } catch (e) {
      logger.e('Failed to fetch pending approvals: $e');
      return [];
    }
  }
}
```

### 6. Модификация ToolApprovalServiceImpl (клиент)

```dart
// lib/features/tool_execution/data/services/tool_approval_service_impl.dart

class ToolApprovalServiceImpl implements ToolApprovalService {
  final StreamController<ApprovalRequestWithCompleter> _approvalController =
      StreamController<ApprovalRequestWithCompleter>.broadcast();
  final ApprovalSyncService _syncService;
  
  // Храним активные completers для восстановления
  final Map<String, Completer<ApprovalDecision>> _activeCompleters = {};

  Stream<ApprovalRequestWithCompleter> get approvalRequests =>
      _approvalController.stream;

  @override
  Future<ApprovalDecision> requestApproval(ToolCall toolCall) async {
    final completer = Completer<ApprovalDecision>();
    
    // Сохраняем completer для возможного восстановления
    _activeCompleters[toolCall.id] = completer;
    
    final domainRequest = ToolApprovalRequest(
      requestId: toolCall.id,
      toolCall: toolCall,
      requestedAt: DateTime.now(),
    );
    
    final requestWithCompleter = ApprovalRequestWithCompleter(domainRequest, completer);
    
    // Эмитируем запрос в stream
    _approvalController.add(requestWithCompleter);
    
    // Ожидаем решения (БЕЗ ТАЙМАУТА - это правильно!)
    final decision = await completer.future;
    
    // Удаляем completer после получения решения
    _activeCompleters.remove(toolCall.id);
    
    return decision;
  }
  
  /// Восстановить ожидающие подтверждения с сервера
  Future<void> restorePendingApprovals(String sessionId) async {
    logger.i('Restoring pending approvals for session: $sessionId');
    
    // Получаем все ожидающие подтверждения с сервера
    final pending = await _syncService.fetchPendingApprovals(sessionId);
    
    logger.i('Found ${pending.length} pending approvals to restore');
    
    for (final request in pending) {
      // Проверяем, нет ли уже активного completer
      if (_activeCompleters.containsKey(request.toolCall.id)) {
        logger.d('Completer already exists for ${request.toolCall.id}, skipping');
        continue;
      }
      
      // Создаем новый completer
      final completer = Completer<ApprovalDecision>();
      _activeCompleters[request.toolCall.id] = completer;
      
      final requestWithCompleter = ApprovalRequestWithCompleter(request, completer);
      
      // Эмитируем в stream для отображения в UI
      _approvalController.add(requestWithCompleter);
      
      // Запускаем асинхронное ожидание решения
      _waitForDecision(request.toolCall.id, completer);
    }
  }
  
  Future<void> _waitForDecision(String callId, Completer<ApprovalDecision> completer) async {
    try {
      // Ждем решения (без таймаута)
      await completer.future;
      _activeCompleters.remove(callId);
    } catch (e) {
      logger.e('Error waiting for decision: $e');
      _activeCompleters.remove(callId);
    }
  }

  void dispose() {
    _approvalController.close();
  }
}
```

### 7. Модификация AgentChatBloc (клиент)

```dart
// lib/features/agent_chat/presentation/bloc/agent_chat_bloc.dart

Future<void> _onConnect(
  ConnectEvent event,
  Emitter<AgentChatState> emit,
) async {
  emit(state.copyWith(isLoading: true, error: none()));

  // Подключаемся к WebSocket
  final connectResult = await _connect(ConnectParams(sessionId: event.sessionId));
  
  connectResult.fold(
    (failure) {
      _logger.e('Failed to connect: ${failure.message}');
      emit(state.copyWith(isLoading: false, error: some(failure.message)));
      return;
    },
    (_) async {
      _logger.i('Connected to WebSocket: ${event.sessionId}');
      
      // Подписываемся на поток сообщений
      _messageSubscription?.cancel();
      _messageSubscription = _receiveMessages(const NoParams()).listen((either) {
        either.fold(
          (failure) => add(AgentChatEvent.error(failure)),
          (message) => add(AgentChatEvent.messageReceived(message)),
        );
      });

      // ВАЖНО: Восстанавливаем ожидающие подтверждения с сервера
      await _approvalService.restorePendingApprovals(event.sessionId);

      emit(state.copyWith(isConnected: true, isLoading: false));
    },
  );
}
```

## Последовательность работы

### Сценарий 1: Нормальный flow (без перезапуска)

```
1. Agent → Gateway: tool_call (requires_approval=true)
2. Gateway → Agent-Runtime: SSE stream
3. Agent-Runtime: HITLManager.add_pending() → сохраняет в БД
4. Agent-Runtime → Gateway: tool_call chunk
5. Gateway → Client (WS): tool_call message
6. Client: ToolApprovalService.requestApproval() → создает Completer
7. Client: UI показывает диалог подтверждения
8. User: принимает/отклоняет
9. Client → Gateway (WS): tool_result с решением
10. Gateway → Agent-Runtime (SSE): hitl_decision
11. Agent-Runtime: HITLManager.remove_pending() → удаляет из БД
12. Agent-Runtime: продолжает выполнение
```

### Сценарий 2: Перезапуск IDE

```
1. [IDE перезапущена, Completer потерян]
2. User: открывает IDE, подключается к сессии
3. Client → Agent-Runtime (REST): GET /sessions/{id}/pending-approvals
4. Agent-Runtime: загружает из БД
5. Agent-Runtime → Client: список ожидающих подтверждений
6. Client: ToolApprovalService.restorePendingApprovals()
7. Client: создает новые Completers для каждого запроса
8. Client: UI показывает все ожидающие диалоги
9. User: принимает/отклоняет
10. Client → Gateway (WS): tool_result с решением
11. [продолжение как в сценарии 1]
```

### Сценарий 3: Переустановка IDE

```
1. [IDE переустановлена, все локальные данные потеряны]
2. User: устанавливает IDE, вводит URL сервера
3. Client → Agent-Runtime (REST): GET /sessions (получить список сессий)
4. User: выбирает активную сессию
5. Client → Gateway (WS): подключается к сессии
6. Client → Agent-Runtime (REST): GET /sessions/{id}/pending-approvals
7. [далее как в сценарии 2]
```

### Сценарий 4: Работа с нескольких устройств

```
1. User: открывает IDE на компьютере A
2. Agent: запрашивает подтверждение
3. User: закрывает компьютер A, открывает компьютер B
4. Client B → Agent-Runtime: GET /sessions/{id}/pending-approvals
5. Client B: показывает ожидающие подтверждения
6. User: принимает решение на компьютере B
7. Client B → Gateway: отправляет решение
8. Agent: продолжает выполнение
9. [Если компьютер A снова подключится, он получит обновленное состояние]
```

## Преимущества решения

✅ **Запросы не теряются при перезапуске IDE** - хранятся в БД  
✅ **Запросы не теряются при переустановке IDE** - хранятся на сервере  
✅ **Ожидание остается бесконечным** - нет таймаутов на клиенте  
✅ **Работа с нескольких устройств** - единый источник истины  
✅ **Простая синхронизация** - REST API для получения, WebSocket для отправки  
✅ **Обратная совместимость** - сохраняем в AgentContext для быстрого доступа  
✅ **Аудит** - все запросы логируются в БД  

## Ключевые моменты

1. **БД - источник истины** для ожидающих подтверждений
2. **REST API** используется только для получения списка при восстановлении
3. **WebSocket** используется для отправки решений (через `tool_result`)
4. **Без таймаутов** - ожидание бесконечное, пока пользователь не примет решение
5. **AgentContext.metadata** сохраняется для быстрого доступа и обратной совместимости

## Файлы для изменения

### Сервер (Python)

1. `agent-runtime/app/models/db_models.py` - **новый** - SQLAlchemy модель PendingApproval
2. `agent-runtime/app/services/database.py` - добавить методы для pending_approvals с SQLAlchemy
3. `agent-runtime/app/services/hitl_manager.py` - добавить персистентность в БД
4. `agent-runtime/app/api/v1/endpoints.py` - добавить GET /sessions/{id}/pending-approvals
5. `agent-runtime/migrations/` - создать Alembic миграцию для таблицы pending_approvals
6. `gateway/app/api/v1/endpoints.py` - добавить проксирование GET /sessions/{id}/pending-approvals

### Клиент (Dart/Flutter)

7. `lib/features/tool_execution/data/services/approval_sync_service.dart` - **новый**
8. `lib/features/tool_execution/data/services/tool_approval_service_impl.dart` - добавить restorePendingApprovals()
9. `lib/features/agent_chat/presentation/bloc/agent_chat_bloc.dart` - вызывать восстановление при подключении
10. `lib/features/agent_chat/data/datasources/gateway_api.dart` - добавить метод для GET pending-approvals

## Миграция базы данных (Alembic)

```python
# agent-runtime/migrations/versions/003_add_pending_approvals.py

"""add pending approvals table

Revision ID: 003
Revises: 002
Create Date: 2026-01-04 07:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade():
    """Create pending_approvals table"""
    op.create_table(
        'pending_approvals',
        sa.Column('approval_id', sa.String(length=255), nullable=False),
        sa.Column('session_id', sa.String(length=255), nullable=False),
        sa.Column('call_id', sa.String(length=255), nullable=False),
        sa.Column('tool_name', sa.String(length=255), nullable=False),
        sa.Column('arguments', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='pending'),
        sa.ForeignKeyConstraint(['session_id'], ['sessions.session_id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('approval_id')
    )
    
    # Create indexes
    op.create_index('idx_pending_approvals_session_id', 'pending_approvals', ['session_id'])
    op.create_index('idx_pending_approvals_status', 'pending_approvals', ['status'])
    op.create_index('idx_pending_approvals_created_at', 'pending_approvals', ['created_at'])


def downgrade():
    """Drop pending_approvals table"""
    op.drop_index('idx_pending_approvals_created_at', table_name='pending_approvals')
    op.drop_index('idx_pending_approvals_status', table_name='pending_approvals')
    op.drop_index('idx_pending_approvals_session_id', table_name='pending_approvals')
    op.drop_table('pending_approvals')
```

### Применение миграции

```bash
# В директории agent-runtime
alembic upgrade head
```

## Технические детали

### Использование SQLAlchemy

- **Async SQLAlchemy** для асинхронных операций с БД
- **Автоматическая сериализация JSONB** - SQLAlchemy автоматически конвертирует Python dict ↔ JSONB
- **Type safety** - модели SQLAlchemy обеспечивают типобезопасность
- **Миграции через Alembic** - версионирование схемы БД

### Gateway как прокси

- Gateway проксирует REST запросы к Agent-Runtime
- Client → Gateway → Agent-Runtime
- Gateway не хранит состояние, только проксирует
- Упрощает архитектуру - клиент работает только с Gateway

### Архитектурные преимущества

1. **Разделение ответственности:**
   - Agent-Runtime: бизнес-логика + БД
   - Gateway: проксирование + WebSocket
   - Client: UI + локальное состояние

2. **Масштабируемость:**
   - БД может быть отдельным сервисом
   - Agent-Runtime может иметь несколько инстансов
   - Gateway может балансировать нагрузку

3. **Надежность:**
   - БД - единственный источник истины
   - Автоматическое восстановление при сбоях
   - Транзакционность операций через SQLAlchemy

## Заключение

Это решение обеспечивает полную персистентность запросов на подтверждение при сохранении требования о бесконечном ожидании. База данных на сервере с использованием SQLAlchemy является единственным источником истины, что решает все проблемы с перезапуском, переустановкой и работой с нескольких устройств. Gateway проксирует запросы, обеспечивая единую точку входа для клиента.
