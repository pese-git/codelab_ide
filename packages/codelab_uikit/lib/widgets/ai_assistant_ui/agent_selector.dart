import 'package:fluent_ui/fluent_ui.dart';
import '../../models/agent_info.dart';
import 'agent_indicator.dart';

/// Селектор для выбора агента
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
    return FlyoutTarget(
      controller: FlyoutController(),
      child: AgentIndicator(
        currentAgent: currentAgent,
        onTap: () {
          _showAgentMenu(context);
        },
      ),
    );
  }

  void _showAgentMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Select Agent'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AgentType.values.map((agent) {
              return _buildAgentOption(
                context,
                agent,
                isSelected: agent == currentAgent,
              );
            }).toList(),
          ),
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentOption(
    BuildContext context,
    AgentType agent,
    {required bool isSelected}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: agent.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              agent.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          agent.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          agent.description,
          style: const TextStyle(fontSize: 11),
        ),
        onPressed: () {
          onAgentSelected(agent);
          Navigator.of(context).pop();
        },
        tileColor: WidgetStateProperty.resolveWith((states) {
          if (states.isPressed) return agent.color.withOpacity(0.3);
          if (states.isHovered) return agent.color.withOpacity(0.1);
          if (isSelected) return agent.color.withOpacity(0.2);
          return Colors.transparent;
        }),
      ),
    );
  }
}
