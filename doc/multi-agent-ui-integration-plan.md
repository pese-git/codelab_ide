# План интеграции мультиагентной системы в IDE UI

## Цель

Добавить визуальную поддержку мультиагентной системы в IDE:
- Индикатор текущего активного агента
- Кнопки для переключения между агентами
- История переключений агентов
- Цветовая кодировка сообщений

## Компоненты для создания/обновления

### 1. Модели данных

**Файл:** `packages/codelab_core/lib/models/agent_info.dart`

```dart
enum AgentType {
  orchestrator,
  coder,
  architect,
  debug,
  ask;
  
  String get displayName {
    switch (this) {
      case AgentType.orchestrator:
        return 'Orchestrator';
      case AgentType.coder:
        return 'Coder';
      case AgentType.architect:
        return 'Architect';
      case AgentType.debug:
        return 'Debug';
      case AgentType.ask:
        return 'Ask';
    }
  }
  
  String get icon {
    switch (this) {
      case AgentType.orchestrator:
        return '🎭';
      case AgentType.coder:
        return '💻';
      case AgentType.architect:
        return '🏗️';
      case AgentType.debug:
        return '🐛';
      case AgentType.ask:
        return '💬';
    }
  }
  
  Color get color {
    switch (this) {
      case AgentType.orchestrator:
        return Colors.red.lighter;
      case AgentType.coder:
        return Colors.blue.lighter;
      case AgentType.architect:
        return Colors.green.lighter;
      case AgentType.debug:
        return Colors.orange.lighter;
      case AgentType.ask:
        return Colors.purple.lighter;
    }
  }
}

class AgentSwitchEvent {
  final AgentType fromAgent;
  final AgentType toAgent;
  final String reason;
  final String? confidence;
  final DateTime timestamp;
  
  AgentSwitchEvent({
    required this.fromAgent,
    required this.toAgent,
    required this.reason,
    this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
```

### 2. Виджет индикатора агента

**Файл:** `packages/codelab_uikit/lib/widgets/ai_assistant_ui/agent_indicator.dart`

```dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:codelab_core/models/agent_info.dart';

class AgentIndicator extends StatelessWidget {
  final AgentType currentAgent;
  final VoidCallback? onTap;
  
  const AgentIndicator({
    super.key,
    required this.currentAgent,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: currentAgent.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: currentAgent.color.darker,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentAgent.icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              currentAgent.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: currentAgent.color.darkest,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                FluentIcons.chevron_down,
                size: 12,
                color: currentAgent.color.darkest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 3. Виджет выбора агента

**Файл:** `packages/codelab_uikit/lib/widgets/ai_assistant_ui/agent_selector.dart`

```dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:codelab_core/models/agent_info.dart';

class AgentSelector extends StatelessWidget {
  final AgentType currentAgent;
  final Function(AgentType) onAgentSelected;
  
  const AgentSelector({
    super.key,
    required this.currentAgent,
    required this.onAgentSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Flyout(
      content: (context) => FlyoutContent(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Agent',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            ...AgentType.values.map((agent) => _buildAgentOption(
              context,
              agent,
              isSelected: agent == currentAgent,
            )),
          ],
        ),
      ),
      child: AgentIndicator(
        currentAgent: currentAgent,
        onTap: () {},
      ),
    );
  }
  
  Widget _buildAgentOption(
    BuildContext context,
    AgentType agent,
    {required bool isSelected}
  ) {
    return ListTile(
      leading: Text(agent.icon, style: const TextStyle(fontSize: 20)),
      title: Text(agent.displayName),
      subtitle: Text(_getAgentDescription(agent)),
      selected: isSelected,
      onPressed: () {
        onAgentSelected(agent);
        Navigator.of(context).pop();
      },
      tileColor: WidgetStateProperty.resolveWith((states) {
        if (states.isHovered) return agent.color.withOpacity(0.1);
        if (isSelected) return agent.color.withOpacity(0.2);
        return Colors.transparent;
      }),
    );
  }
  
  String _getAgentDescription(AgentType agent) {
    switch (agent) {
      case AgentType.orchestrator:
        return 'Coordinates and routes tasks';
      case AgentType.coder:
        return 'Writes and modifies code';
      case AgentType.architect:
        return 'Designs and plans architecture';
      case AgentType.debug:
        return 'Investigates errors and bugs';
      case AgentType.ask:
        return 'Answers questions and explains';
    }
  }
}
```

### 4. Обновление AI Assistant Header

**Файл:** `packages/codelab_uikit/lib/widgets/ai_assistant_ui/ai_assistant_header.dart`

Добавить индикатор агента:

```dart
class AIAssistantHeader extends StatelessWidget {
  final VoidCallback? onClear;
  final String title;
  final AgentType currentAgent;  // NEW
  final Function(AgentType)? onAgentSelected;  // NEW
  
  const AIAssistantHeader({
    super.key,
    this.onClear,
    this.title = 'AI Assistant',
    this.currentAgent = AgentType.orchestrator,  // NEW
    this.onAgentSelected,  // NEW
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.lighter,
            child: Icon(FluentIcons.chat, size: 20),
          ),
          const SizedBox(width: 10),
          Text(title, style: FluentTheme.of(context).typography.title),
          const SizedBox(width: 12),
          // NEW: Agent indicator
          if (onAgentSelected != null)
            AgentSelector(
              currentAgent: currentAgent,
              onAgentSelected: onAgentSelected!,
            )
          else
            AgentIndicator(currentAgent: currentAgent),
          const Spacer(),
          IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: onClear,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 5. Обновление Message Bubble

**Файл:** `packages/codelab_uikit/lib/widgets/ai_assistant_ui/ai_assistant_message_bubble.dart`

Добавить цветовую кодировку по агентам:

```dart
class AIAssistantMessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final AgentType? agentType;  // NEW
  
  const AIAssistantMessageBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.agentType,  // NEW
  });
  
  @override
  Widget build(BuildContext context) {
    final bgColor = isUser
        ? Colors.blue.lighter
        : (agentType?.color ?? Colors.grey.lighter);  // NEW: цвет по агенту
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEW: показать агента для assistant сообщений
          if (!isUser && agentType != null) ...[
            Row(
              children: [
                Text(agentType!.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  agentType!.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: agentType!.color.darkest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(content),
        ],
      ),
    );
  }
}
```

### 6. Виджет истории переключений

**Файл:** `packages/codelab_uikit/lib/widgets/ai_assistant_ui/agent_history_panel.dart`

```dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:codelab_core/models/agent_info.dart';

class AgentHistoryPanel extends StatelessWidget {
  final List<AgentSwitchEvent> history;
  
  const AgentHistoryPanel({
    super.key,
    required this.history,
  });
  
  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text('No agent switches yet'),
      );
    }
    
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final event = history[index];
        return ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.fromAgent.icon),
              const Icon(FluentIcons.forward, size: 12),
              Text(event.toAgent.icon),
            ],
          ),
          title: Text(
            '${event.fromAgent.displayName} → ${event.toAgent.displayName}'
          ),
          subtitle: Text(event.reason),
          trailing: Text(
            _formatTime(event.timestamp),
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
```

## План реализации

### Этап 1: Модели данных (30 мин)
1. Создать `agent_info.dart` с enum и моделями
2. Добавить в exports

### Этап 2: UI компоненты (1-2 часа)
1. Создать `agent_indicator.dart`
2. Создать `agent_selector.dart`
3. Создать `agent_history_panel.dart`
4. Обновить `ai_assistant_header.dart`
5. Обновить `ai_assistant_message_bubble.dart`

### Этап 3: Интеграция с BLoC (1-2 часа)
1. Добавить состояние текущего агента в BLoC
2. Добавить историю переключений
3. Обработка `agent_switched` событий из WebSocket
4. Отправка `switch_agent` запросов

### Этап 4: Тестирование (30 мин)
1. Проверить отображение индикатора
2. Проверить переключение агентов
3. Проверить историю
4. Проверить цветовую кодировку

## Следующие шаги

1. Создать модели данных
2. Создать UI компоненты
3. Интегрировать с существующим BLoC
4. Протестировать работу

Хотите начать реализацию?
