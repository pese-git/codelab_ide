# План интеграции HITL в CodeLab IDE

## Текущее состояние

✅ Backend полностью реализован и работает
✅ IDE уже отображает диалог approve/reject (базовая функциональность)

## Что нужно доработать в IDE

### 1. Модели данных (Dart)

**Файл:** [`ws_message.dart`](../packages/codelab_ai_assistant/lib/src/models/ws_message.dart:1)

Добавить новый тип сообщения `hitlDecision`:

```dart
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class WSMessage with _$WSMessage {
  // ... существующие типы ...
  
  // Новый тип для HITL решений
  const factory WSMessage.hitlDecision({
    @JsonKey(name: 'call_id') required String callId,
    required String decision, // "approve", "edit", "reject"
    @JsonKey(name: 'modified_arguments') Map<String, dynamic>? modifiedArguments,
    String? feedback,
  }) = WSHITLDecision;
}
```

### 2. Protocol Service

**Файл:** [`agent_protocol_service.dart`](../packages/codelab_ai_assistant/lib/src/domain/agent_protocol_service.dart:1)

Добавить метод для отправки HITL решений:

```dart
abstract class AgentProtocolService {
  // ... существующие методы ...
  
  void sendHITLDecision({
    required String callId,
    required String decision,
    Map<String, dynamic>? modifiedArguments,
    String? feedback,
  });
}

class AgentProtocolServiceImpl implements AgentProtocolService {
  // ... существующие методы ...
  
  @override
  void sendHITLDecision({
    required String callId,
    required String decision,
    Map<String, dynamic>? modifiedArguments,
    String? feedback,
  }) {
    _repo.send(WSMessage.hitlDecision(
      callId: callId,
      decision: decision,
      modifiedArguments: modifiedArguments,
      feedback: feedback,
    ));
  }
}
```

### 3. BLoC State Management

**Файл:** [`ai_agent_bloc.dart`](../packages/codelab_ai_assistant/lib/src/bloc/ai_agent_bloc.dart:1)

Добавить состояния и события для HITL:

```dart
// События
sealed class AiAgentEvent {
  // ... существующие события ...
  
  const factory AiAgentEvent.approveToolCall(String callId) = ApproveToolCall;
  const factory AiAgentEvent.editToolCall(
    String callId,
    Map<String, dynamic> modifiedArguments,
  ) = EditToolCall;
  const factory AiAgentEvent.rejectToolCall(
    String callId,
    String feedback,
  ) = RejectToolCall;
}

// Состояния
sealed class AiAgentState {
  // ... существующие состояния ...
  
  const factory AiAgentState.toolCallPendingApproval({
    required String callId,
    required String toolName,
    required Map<String, dynamic> arguments,
    String? reason,
  }) = ToolCallPendingApproval;
}

// Обработчики
class AiAgentBloc extends Bloc<AiAgentEvent, AiAgentState> {
  // ... существующий код ...
  
  void _onApproveToolCall(ApproveToolCall event, Emitter<AiAgentState> emit) {
    _protocolService.sendHITLDecision(
      callId: event.callId,
      decision: 'approve',
    );
    emit(const AiAgentState.processing());
  }
  
  void _onEditToolCall(EditToolCall event, Emitter<AiAgentState> emit) {
    _protocolService.sendHITLDecision(
      callId: event.callId,
      decision: 'edit',
      modifiedArguments: event.modifiedArguments,
    );
    emit(const AiAgentState.processing());
  }
  
  void _onRejectToolCall(RejectToolCall event, Emitter<AiAgentState> emit) {
    _protocolService.sendHITLDecision(
      callId: event.callId,
      decision: 'reject',
      feedback: event.feedback,
    );
    emit(const AiAgentState.processing());
  }
  
  // Обработка входящего tool_call с requires_approval
  void _handleToolCall(WSToolCall toolCall) {
    if (toolCall.requiresApproval) {
      // Показать диалог одобрения
      emit(AiAgentState.toolCallPendingApproval(
        callId: toolCall.callId,
        toolName: toolCall.toolName,
        arguments: toolCall.arguments,
        reason: _getApprovalReason(toolCall.toolName),
      ));
    } else {
      // Выполнить автоматически
      _executeToolCall(toolCall);
    }
  }
}
```

### 4. UI Компоненты

**Новый файл:** `packages/codelab_ai_assistant/lib/src/widgets/tool_approval_dialog.dart`

Создать диалог для одобрения tool calls:

```dart
class ToolApprovalDialog extends StatefulWidget {
  final String callId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final String? reason;
  final Function(String decision, {Map<String, dynamic>? modifiedArgs, String? feedback}) onDecision;
  
  // ... implementation
}
```

Функциональность диалога:
- Отображение деталей операции (tool name, arguments)
- Причина требования одобрения
- Кнопки: Approve, Edit, Reject
- Для Edit - возможность редактировать JSON аргументы
- Для Reject - поле для feedback

### 5. Интеграция в AI Assistant Panel

**Файл:** [`ai_assistant_panel.dart`](../packages/codelab_ai_assistant/lib/src/ui/ai_assistant_panel.dart:1)

Обновить обработку состояний:

```dart
BlocBuilder<AiAgentBloc, AiAgentState>(
  builder: (context, state) {
    return state.when(
      // ... существующие состояния ...
      
      toolCallPendingApproval: (callId, toolName, arguments, reason) {
        // Показать диалог одобрения
        return ToolApprovalDialog(
          callId: callId,
          toolName: toolName,
          arguments: arguments,
          reason: reason,
          onDecision: (decision, {modifiedArgs, feedback}) {
            if (decision == 'approve') {
              context.read<AiAgentBloc>().add(
                AiAgentEvent.approveToolCall(callId)
              );
            } else if (decision == 'edit') {
              context.read<AiAgentBloc>().add(
                AiAgentEvent.editToolCall(callId, modifiedArgs!)
              );
            } else if (decision == 'reject') {
              context.read<AiAgentBloc>().add(
                AiAgentEvent.rejectToolCall(callId, feedback!)
              );
            }
          },
        );
      },
    );
  },
)
```

### 6. Визуализация pending состояний

**Новый виджет:** `PendingToolCallsWidget`

Показывать список ожидающих одобрения операций:
- Количество pending tool calls
- Детали каждого вызова
- Возможность быстрого approve/reject

### 7. Настройки HITL

**Новый файл:** `packages/codelab_ai_assistant/lib/src/settings/hitl_settings.dart`

Настройки для пользователя:
- Включить/выключить HITL глобально
- Настроить какие операции требуют одобрения
- Автоматическое одобрение для доверенных операций
- Timeout для pending состояний

### 8. Уведомления

Добавить уведомления для:
- Новый tool call требует одобрения
- Timeout pending состояния
- Успешное выполнение после одобрения

## Приоритеты реализации

### Высокий приоритет (MVP)
1. ✅ Добавить `WSHITLDecision` в модели (уже есть базовый диалог)
2. ✅ Добавить `sendHITLDecision()` в protocol service
3. ✅ Обработка `requiresApproval` в BLoC
4. ✅ Базовый диалог одобрения (уже работает!)

### Средний приоритет
5. Улучшить UI диалога одобрения
6. Добавить возможность редактирования параметров (Edit)
7. Добавить поле feedback для Reject
8. Визуализация pending состояний

### Низкий приоритет
9. Настройки HITL в UI
10. Уведомления
11. История HITL решений
12. Статистика одобрений/отклонений

## Текущая реализация в IDE

Судя по feedback, IDE уже имеет:
- ✅ Обработку `requiresApproval` флага
- ✅ Отображение диалога approve/reject
- ✅ Базовую отправку решений

## Что точно нужно добавить

1. **Модель `WSHITLDecision`** в [`ws_message.dart`](../packages/codelab_ai_assistant/lib/src/models/ws_message.dart:1)
2. **Метод `sendHITLDecision()`** в [`agent_protocol_service.dart`](../packages/codelab_ai_assistant/lib/src/domain/agent_protocol_service.dart:1)
3. **Поддержка Edit** - редактирование параметров перед одобрением
4. **Поддержка Feedback** - причина отклонения

## Проверка текущей реализации

Нужно проверить:
- Как сейчас реализован диалог approve/reject?
- Отправляется ли корректное сообщение `hitl_decision`?
- Обрабатывается ли ответ от backend после решения?

## Рекомендации

1. Использовать существующий паттерн с Freezed для `WSHITLDecision`
2. Интегрировать в существующий BLoC flow
3. Переиспользовать UI компоненты из `codelab_uikit`
4. Добавить тесты для HITL flow
