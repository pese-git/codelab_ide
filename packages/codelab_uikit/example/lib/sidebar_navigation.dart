import 'package:fluent_ui/fluent_ui.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      color: Colors.grey[10],
      child: Column(
        children: [
          _SidebarIcon(
            icon: FluentIcons.open_folder_horizontal,
            index: 0,
            selected: selectedIndex == 0,
            tooltip: 'Explorer',
            onTap: () => onSelected(0),
          ),
          _SidebarIcon(
            icon: FluentIcons.search,
            index: 1,
            selected: selectedIndex == 1,
            tooltip: 'Search',
            onTap: () => onSelected(1),
          ),
          _SidebarIcon(
            icon: FluentIcons.git_graph,
            index: 2,
            selected: selectedIndex == 2,
            tooltip: 'Git',
            onTap: () => onSelected(2),
          ),
          _SidebarIcon(
            icon: FluentIcons.play,
            index: 3,
            selected: selectedIndex == 3,
            tooltip: 'Run',
            onTap: () => onSelected(3),
          ),
          _SidebarIcon(
            icon: FluentIcons.plug,
            index: 4,
            selected: selectedIndex == 4,
            tooltip: 'Extensions',
            onTap: () => onSelected(4),
          ),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _SidebarIcon({
    required this.icon,
    required this.index,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, color: selected ? Colors.blue : Colors.grey[100]),
          onPressed: onTap,
        ),
      ),
    );
  }
}
