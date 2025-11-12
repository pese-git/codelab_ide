import 'package:flutter/material.dart'
    show SizedBox, StatelessWidget, BuildContext, Widget;
import '../placeholder/sidebar_placeholder.dart';

class SidebarPanel extends StatelessWidget {
  final int selectedIndex;

  // Новое: кастомные слоты для каждого раздела
  final Widget? explorerSlot;
  final Widget? searchSlot;
  final Widget? sourceControlSlot;
  final Widget? runDebugSlot;
  final Widget? extensionsSlot;

  const SidebarPanel({
    super.key,
    required this.selectedIndex,
    this.explorerSlot,
    this.searchSlot,
    this.sourceControlSlot,
    this.runDebugSlot,
    this.extensionsSlot,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return explorerSlot ?? const SidebarPlaceholder('Explorer');
      case 1:
        return searchSlot ?? const SidebarPlaceholder('Search');
      case 2:
        return sourceControlSlot ?? const SidebarPlaceholder('Source Control');
      case 3:
        return runDebugSlot ?? const SidebarPlaceholder('Run/Debug');
      case 4:
        return extensionsSlot ?? const SidebarPlaceholder('Extensions');
      default:
        return const SizedBox(width: 200);
    }
  }
}
