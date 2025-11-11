import 'package:fluent_ui/fluent_ui.dart';

class EditorPanelToolbar extends StatelessWidget {
  final String label;
  final VoidCallback onAddTab;
  final VoidCallback onSaveTabs;

  const EditorPanelToolbar({
    super.key,
    required this.label,
    required this.onAddTab,
    required this.onSaveTabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[10],
        border: Border(
          bottom: BorderSide(color: Colors.grey[30]),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[100],
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(FluentIcons.add, size: 16),
            onPressed: onAddTab,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(FluentIcons.save, size: 16),
            onPressed: onSaveTabs,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            ),
          ),
        ],
      ),
    );
  }
}
