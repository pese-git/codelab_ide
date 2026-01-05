import 'package:fluent_ui/fluent_ui.dart';
import '../../models/agent_info.dart';

/// Индикатор текущего активного агента
class AgentIndicator extends StatelessWidget {
  final AgentType currentAgent;
  final VoidCallback? onTap;
  final bool showLabel;

  const AgentIndicator({
    super.key,
    required this.currentAgent,
    this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: currentAgent.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: currentAgent.color.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentAgent.icon,
            style: const TextStyle(fontSize: 14),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              currentAgent.displayName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              FluentIcons.chevron_down,
              size: 10,
              color: Colors.black,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: widget,
        ),
      );
    }

    return widget;
  }
}
