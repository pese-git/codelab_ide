# Руководство по миграции UI компонентов

## Текущая ситуация

Clean Architecture полностью реализована, но UI компоненты используют старую структуру state.

## Проблема

**Старый AiAgentBloc:**
```dart
@freezed
class AiAgentState with _$AiAgentState {
  const factory AiAgentState.chat({
    required List<WSMessage> history,
    bool waitingResponse,
    ToolApprovalRequest? pendingApproval,
    String currentAgent,
  }) = ChatState;
}
```

**Новый AgentChatBloc:**
```dart
@freezed
class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,  // Не WSMessage!
    required bool isLoading,
    required bool isConnected,
    required String currentAgent,
    required Option<String> error,
  }) = _AgentChatState;
}
```

## Решение

### 1. Создать маппер Message → WSMessage

Файл: `lib/src/utils/message_mapper.dart`

```dart
import '../models/ws_message.dart';
import '../../features/agent_chat/domain/entities/message.dart';

class MessageMapper {
  static WSMessage toWSMessage(Message message) {
    return message.content.when(
      text: (text, isFinal) => message.isUser
          ? WSMessage.userMessage(content: text, role: 'user')
          : WSMessage.assistantMessage(content: text, isFinal: isFinal),
      
      toolCall: (callId, toolName, arguments) => WSMessage.toolCall(
        callId: callId,
        toolName: toolName,
        arguments: arguments,
        requiresApproval: false,
      ),
      
      toolResult: (callId, toolName, result, error) => WSMessage.toolResult(
        callId: callId,
        toolName: toolName,
        result: result?.toNullable(),
        error: error?.toNullable(),
      ),
      
      agentSwitch: (fromAgent, toAgent, reason) => WSMessage.agentSwitched(
        content: 'Agent switched',
        fromAgent: fromAgent,
        toAgent: toAgent,
        reason: reason?.toNullable(),
        confidence: null,
      ),
      
      error: (message) => WSMessage.error(content: message),
    );
  }
  
  static List<WSMessage> toWSMessageList(List<Message> messages) {
    return messages.map(toWSMessage).toList();
  }
}
```

### 2. Обновить chat_view.dart

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<AgentChatBloc, AgentChatState>(
    bloc: widget.bloc,
    builder: (context, state) {
      // Маппинг новых entities в старый формат для UI
      final waiting = state.isLoading;
      final pendingApproval = null; // TODO: Добавить в AgentChatState
      final List<WSMessage> history = MessageMapper.toWSMessageList(state.messages);
      final currentAgent = AgentType.fromString(state.currentAgent);
      
      // Остальной код без изменений
      return Column(...);
    },
  );
}
```

### 3. Обновить session_list_view.dart

```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<SessionManagerBloc, SessionManagerState>(
    bloc: sessionManagerBloc,
    builder: (context, state) {
      // Новый state - простая структура
      if (state.isLoading) {
        return const Center(child: ProgressRing());
      }
      
      state.error.fold(
        () {}, // No error
        (errorMsg) => _showError(context, errorMsg),
      );
      
      if (state.sessions.isEmpty) {
        return _buildEmptyState(context);
      }
      
      return _buildSessionList(context, state.sessions);
    },
  );
}
```

### 4. Обновить события

**Старые события:**
```dart
AiAgentEvent.sendUserMessage(text)
AiAgentEvent.loadHistory(history)
SessionManagerEvent.createNewSession()
SessionManagerEvent.switchToSession(id)
```

**Новые события:**
```dart
AgentChatEvent.sendMessage(text)
AgentChatEvent.loadHistory(sessionId)
SessionManagerEvent.createSession()
SessionManagerEvent.selectSession(sessionId)
```

## Оценка времени

- Создать MessageMapper: 30 минут
- Обновить chat_view.dart: 1-2 часа
- Обновить session_list_view.dart: 1 час
- Обновить session_manager_widget.dart: 1 час
- Обновить ai_assistant_panel.dart: 30 минут
- Тестирование: 1-2 часа

**Итого: 4-6 часов**

## Следующие шаги

1. Создать MessageMapper
2. Обновить chat_view.dart
3. Обновить session_list_view.dart
4. Обновить session_manager_widget.dart
5. Тестировать функционал
6. Исправить ошибки
7. Коммит
