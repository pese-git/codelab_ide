import 'package:flutter/material.dart'
    show SizedBox, StatelessWidget, BuildContext, Widget;
import 'explorer_panel.dart';
import 'sidebar_placeholder.dart';

class SidebarPanel extends StatelessWidget {
  final int selectedIndex;
  const SidebarPanel({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return const ExplorerPanel();
      case 1:
        return const SidebarPlaceholder('Search');
      case 2:
        return const SidebarPlaceholder('Source Control');
      case 3:
        return const SidebarPlaceholder('Run/Debug');
      case 4:
        return const SidebarPlaceholder('Extensions');
      default:
        return const SizedBox(width: 200);
    }
  }
}
