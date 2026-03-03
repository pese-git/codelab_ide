import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/file_node.dart';

class ExplorerPanel extends StatefulWidget {
  final FileNode? initialFileTree;
  final ValueChanged<FileNode> onOpenFile;
  ExplorerPanel({super.key, this.initialFileTree, required this.onOpenFile});

  @override
  State<ExplorerPanel> createState() => ExplorerPanelState();
}

class ExplorerPanelState extends State<ExplorerPanel> {
  FileNode? _fileTree;
  Set<String> _expandedNodes = {};
  String? _selectedFile;
  String? _selectedContent;

  @override
  void initState() {
    super.initState();
    if (widget.initialFileTree != null) {
      _fileTree = widget.initialFileTree;
    }
  }

  // Рекурсивное преобразование твоей модели в TreeViewItem
  TreeViewItem _fileNodeToTreeViewItem(FileNode node) {
    final isDir = node.isDirectory;
    return TreeViewItem(
      key: ValueKey(node.path),
      leading: Icon(isDir ? FluentIcons.folder : FluentIcons.page),
      content: Text(node.name),
      expanded: _expandedNodes.contains(node.path),
      value: node.path,
      children: node.children.map(_fileNodeToTreeViewItem).toList(),
      onInvoked: (item, reason) async {
        if (!isDir && reason == TreeViewItemInvokeReason.pressed) {
          _onFileTap(node);
        }
      },
      onExpandToggle: (item, getsExpanded) async {
        setState(() {
          if (getsExpanded) {
            _expandedNodes.add(node.path);
          } else {
            _expandedNodes.remove(node.path);
          }
        });
      },
      selected: _selectedFile == node.path,
    );
  }

  /// Публичный метод для внешнего обновления дерева файлов (вызывается из блока)
  void updateFileTree(FileNode fileTree) {
    setState(() {
      _fileTree = fileTree;
      _expandedNodes = {};
      _selectedFile = null;
      _selectedContent = null;
    });
  }

  void expandNode(String path) {
    setState(() {
      _expandedNodes.add(path);
    });
  }

  void collapseNode(String path) {
    setState(() {
      _expandedNodes.remove(path);
    });
  }

  void _onFileTap(FileNode node) async {
    // Чтение содержимого файла, выделение, вызов callback...
    //setState(() => _selectedFile = node.path);
    // ...
    widget.onOpenFile.call(node);
  }

  @override
  Widget build(BuildContext context) {
    if (_fileTree == null) {
      return const Center(child: Text('No project or file tree loaded'));
    }

    return TreeView(
      items: [_fileNodeToTreeViewItem(_fileTree!)],
      selectionMode: .single,
      scrollPrimary: true,
      shrinkWrap: false,
      gesturesBuilder: (item) {
        final gestures = <Type, GestureRecognizerFactory>{};

        gestures[TapGestureRecognizer] =
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(debugOwner: this),
              (TapGestureRecognizer instance) {
                instance.onSecondaryTap = () {
                  _showDialog(context, item);
                };
              },
            );

        return gestures;
      },
    );
  }

  void _showDialog(BuildContext context, TreeViewItem item) {
    showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog.adaptive(
          title: Text('Был нажат элемент списка правой кнопкой!'),
          content: Text('Что нужно сделать c ${item.value} ?'),
        );
      },
    );
  }
}
