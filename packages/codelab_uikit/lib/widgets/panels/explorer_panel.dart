import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    as material
    show Material, Colors, BorderRadius, BoxDecoration;
import '../../models/file_node.dart';

class ExplorerPanel extends StatefulWidget {
  final List<FileNode> files;
  final void Function(FileNode) onFileOpen;
  const ExplorerPanel({
    super.key,
    required this.files,
    required this.onFileOpen,
  });

  @override
  State<ExplorerPanel> createState() => ExplorerPanelState();
}

class ExplorerPanelState extends State<ExplorerPanel> {
  final Set<String> expandedDirs = {};

  void _toggleDir(FileNode node) {
    setState(() {
      if (expandedDirs.contains(node.path)) {
        expandedDirs.remove(node.path);
      } else {
        expandedDirs.add(node.path);
      }
    });
  }

  List<TreeViewItem> _buildTree(List<FileNode> nodes) {
    return nodes.map((node) {
      if (node.isDirectory) {
        return TreeViewItem(
          leading: const Icon(FluentIcons.folder_horizontal),
          content: GestureDetector(
            onTap: () => _toggleDir(node),
            child: Text(node.name),
          ),
          expanded: expandedDirs.contains(node.path),
          children: _buildTree(node.children),
        );
      } else {
        return TreeViewItem(
          leading: const Icon(FluentIcons.page),
          content: Draggable<FileNode>(
            data: node,
            feedback: material.Material(
              color: material.Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: material.BoxDecoration(
                  color: material.Colors.grey[200],
                  borderRadius: material.BorderRadius.circular(2),
                ),
                child: Text(
                  node.name,
                  style: const TextStyle(
                    color: material.Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.4, child: Text(node.name)),
            child: GestureDetector(
              onTap: () => widget.onFileOpen(node),
              child: Text(node.name),
            ),
          ),
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[20],
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'EXPLORER',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: TreeView(items: _buildTree(widget.files))),
        ],
      ),
    );
  }
}
