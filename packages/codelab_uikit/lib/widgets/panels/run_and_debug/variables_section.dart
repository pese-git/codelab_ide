import 'package:fluent_ui/fluent_ui.dart';
import '../expander_with_flexible_height.dart';

class VariablesSection extends StatelessWidget {
  final bool expanded;
  final double height;
  final double minHeaderHeight;
  final ValueChanged<bool>? onExpandedChanged;

  const VariablesSection({
    super.key,
    required this.expanded,
    required this.height,
    this.minHeaderHeight = 40,
    this.onExpandedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpanderWithFlexibleHeight(
      expanded: expanded,
      expandedHeight: height,
      minHeaderHeight: minHeaderHeight,
      child: Expander(
        leading: const Icon(FluentIcons.variable_group),
        header: const Text(
          'VARIABLES',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: expanded,
        onStateChanged: onExpandedChanged,
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SingleChildScrollView(
            child: Text(
              'No variables to show',
              style: TextStyle(color: Colors.grey[100]),
            ),
          ),
        ),
      ),
    );
  }
}
