import 'package:fluent_ui/fluent_ui.dart';

class MainHeader extends StatelessWidget {
  final bool bottomPanelVisible;
  final VoidCallback onToggleBottomPanel;
  const MainHeader({
    super.key,
    required this.bottomPanelVisible,
    required this.onToggleBottomPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Codelab IDE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        IconButton(icon: const Icon(FluentIcons.save), onPressed: () {}),
        IconButton(icon: const Icon(FluentIcons.play), onPressed: () {}),
        IconButton(icon: const Icon(FluentIcons.settings), onPressed: () {}),
        IconButton(
          icon: Icon(
            semanticLabel: bottomPanelVisible
                ? 'Hide bottom panel'
                : 'Show bottom panel',
            bottomPanelVisible
                ? FluentIcons.chevron_down
                : FluentIcons.chevron_up,
          ),
          onPressed: onToggleBottomPanel,
        ),
      ],
    );
  }
}
