import 'package:fluent_ui/fluent_ui.dart';
import '../../models/agent_info.dart';
import 'agent_selector.dart';

/// Верхний бар AI ассистента с индикатором текущего агента
class AIAssistantHeader extends StatelessWidget {
  final VoidCallback? onClear;
  final String title;
  final AgentType currentAgent;
  final Function(AgentType)? onAgentSelected;
  
  const AIAssistantHeader({
    super.key,
    this.onClear,
    this.title = 'AI Assistant',
    this.currentAgent = AgentType.orchestrator,
    this.onAgentSelected,
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
          // Индикатор текущего агента
          if (onAgentSelected != null)
            AgentSelector(
              currentAgent: currentAgent,
              onAgentSelected: onAgentSelected!,
            ),
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
