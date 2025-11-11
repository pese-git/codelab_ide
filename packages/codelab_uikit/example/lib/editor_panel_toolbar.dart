import 'package:fluent_ui/fluent_ui.dart';

class EditorPanelToolbar extends StatelessWidget {
  final String label;
  final VoidCallback onAddTab;
  final VoidCallback onSaveTabs;
  final VoidCallback? onSplit;
  final bool isSplitActive;
  final bool canSplit;

  const EditorPanelToolbar({
    super.key,
    required this.label,
    required this.onAddTab,
    required this.onSaveTabs,
    this.onSplit,
    this.isSplitActive = false,
    this.canSplit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[10],
        border: Border(bottom: BorderSide(color: Colors.grey[30])),
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
          Tooltip(
            message: isSplitActive
                ? 'Split editor is active'
                : 'Split editor right',
            child: IconButton(
              icon: Icon(
                FluentIcons.split,
                size: 16,
                color: canSplit
                    ? (isSplitActive ? Colors.orange : null)
                    : Colors.grey[110],
              ),
              onPressed: canSplit ? onSplit : null,
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
              ),
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
