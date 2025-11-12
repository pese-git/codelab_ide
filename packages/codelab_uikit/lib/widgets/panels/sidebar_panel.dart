import 'package:flutter/material.dart' show SizedBox, StatelessWidget, BuildContext, Widget;
import 'explorer_panel.dart';
import '../placeholder/sidebar_placeholder.dart';
import '../../models/file_node.dart';

class SidebarPanel extends StatelessWidget {
  final int selectedIndex;
  final List<FileNode> files;
  final void Function(FileNode) onFileOpen;
  const SidebarPanel({
    super.key,
    required this.selectedIndex,
    required this.files,
    required this.onFileOpen,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return ExplorerPanel(files: files, onFileOpen: onFileOpen);
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
