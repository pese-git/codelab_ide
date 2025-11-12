import '../../models/file_node.dart';
import '../../models/editor_tab.dart';
import '../editor/editor_tab_view.dart';
import '../splitters/horizontal_splitter.dart';
import '../splitters/vertical_splitter.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'editor_panel_toolbar.dart';

// Далее остальной переносимый код из example/lib/editor_panel.dart

class EditorPanel extends StatefulWidget {
  final String label;
  final List<EditorTab> initialTabs;

  const EditorPanel({
    super.key,
    required this.label,
    this.initialTabs = const [],
  });

  @override
  State<EditorPanel> createState() => EditorPanelState();
}

abstract class PaneNode {}

class EditorTabsPane extends PaneNode {
  List<EditorTab> tabs;
  int selectedIndex;
  EditorTabsPane({required this.tabs, this.selectedIndex = 0});
}

class SplitPane extends PaneNode {
  bool isVertical; // true = vertical, false = horizontal
  double fraction;
  PaneNode first;
  PaneNode second;
  SplitPane({
    required this.isVertical,
    required this.fraction,
    required this.first,
    required this.second,
  });
}

class EditorPanelState extends State<EditorPanel> {
  late PaneNode rootPane;
  EditorTabsPane? _lastActivePane;

  @override
  void initState() {
    super.initState();
    rootPane = EditorTabsPane(tabs: List.from(widget.initialTabs));
  }

  // --- ОПЕРАЦИИ НА ПАНЕЛЯХ ---
  void _addTabInPane(EditorTabsPane pane) {
    setState(() {
      final newTab = EditorTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'new_file.dart',
        filePath: 'lib/new_file.dart',
        content:
            '// New file content\nvoid main() {\n  print("Hello World!");\n}',
      );
      pane.tabs.add(newTab);
      pane.selectedIndex = pane.tabs.length - 1;
    });
  }

  void _saveTabsInPane(EditorTabsPane pane) {
    displayInfoBar(
      context,
      builder: (context, close) {
        return const InfoBar(
          title: Text('Files saved'),
          content: Text('All open files have been saved.'),
          severity: InfoBarSeverity.success,
        );
      },
    );
  }

  // --- API внешнего открытия файла ---
  void openFile({
    required String filePath,
    required String title,
    required String content,
    EditorTabsPane? targetPane,
  }) {
    setState(() {
      final pane =
          targetPane ?? _lastActivePane ?? _findFirstOrRootPane(rootPane);
      final existingIdx = pane.tabs.indexWhere((t) => t.filePath == filePath);
      if (existingIdx != -1) {
        pane.selectedIndex = existingIdx;
      } else {
        pane.tabs.add(
          EditorTab(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            filePath: filePath,
            content: content,
          ),
        );
        pane.selectedIndex = pane.tabs.length - 1;
      }
    });
  }

  EditorTabsPane _findFirstOrRootPane(PaneNode node) {
    if (node is EditorTabsPane) return node;
    if (node is SplitPane) {
      final first = _findFirstOrRootPane(node.first);
      if (first.tabs.isNotEmpty) return first;
      return _findFirstOrRootPane(node.second);
    }
    return node as EditorTabsPane;
  }

  void _updateTabContentInPane(EditorTabsPane pane, EditorTab tab) {
    setState(() {
      final idx = pane.tabs.indexWhere((t) => t.id == tab.id);
      if (idx != -1) pane.tabs[idx] = tab;
    });
  }

  void _closeTabInPane(EditorTabsPane pane, int tabIndex) {
    setState(() {
      pane.tabs.removeAt(tabIndex);
      if (pane.selectedIndex >= pane.tabs.length) {
        pane.selectedIndex = pane.tabs.length - 1;
      }
      // Если все вкладки закрылись — убрать Pane рекурсивно
      if (pane.tabs.isEmpty) {
        rootPane = _removePane(root: true, current: rootPane, target: pane);
      }
    });
  }

  void _splitPane(EditorTabsPane pane, {required bool isVertical}) {
    setState(() {
      _replacePane(
        root: true,
        current: rootPane,
        target: pane,
        newPane: SplitPane(
          isVertical: isVertical,
          fraction: 0.5,
          first: pane,
          second: EditorTabsPane(tabs: []),
        ),
      );
    });
  }

  void _replacePane({
    required bool root,
    required PaneNode current,
    required EditorTabsPane target,
    required PaneNode newPane,
  }) {
    if (current is SplitPane) {
      if (current.first == target) {
        current.first = newPane;
      } else if (current.second == target) {
        current.second = newPane;
      } else {
        _replacePane(
          root: false,
          current: current.first,
          target: target,
          newPane: newPane,
        );
        _replacePane(
          root: false,
          current: current.second,
          target: target,
          newPane: newPane,
        );
      }
    } else if (root && current == target) {
      rootPane = newPane;
    }
  }

  PaneNode _removePane({
    required bool root,
    required PaneNode current,
    required EditorTabsPane target,
  }) {
    if (current is SplitPane) {
      if (current.first == target) {
        return current.second;
      }
      if (current.second == target) {
        return current.first;
      }
      current.first = _removePane(
        root: false,
        current: current.first,
        target: target,
      );
      current.second = _removePane(
        root: false,
        current: current.second,
        target: target,
      );
      // collapse если один из детей стал EditorTabsPane и пустой
      if (current.first is EditorTabsPane &&
          (current.first as EditorTabsPane).tabs.isEmpty) {
        return current.second;
      }
      if (current.second is EditorTabsPane &&
          (current.second as EditorTabsPane).tabs.isEmpty) {
        return current.first;
      }
      return current;
    } else if (root && current == target) {
      return EditorTabsPane(tabs: []); // Пустой корень
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _buildPane(rootPane, widget.label),
    );
  }

  Widget _buildPane(PaneNode node, String label) {
    if (node is EditorTabsPane) {
      return _EditorPaneDragTarget(
        pane: node,
        isActive: _lastActivePane == node,
        onOpenFile: (fileNode) {
          openFile(
            filePath: fileNode.path,
            title: fileNode.name,
            content:
                '// Stub content for drag-and-drop: \\${fileNode.name}\\nvoid main() {\\n  print(\"Hello, \\${fileNode.name}!\");\\n}',
            targetPane: node,
          );
        },
        onFocused: () {
          if (_lastActivePane != node) setState(() => _lastActivePane = node);
        },
        child: Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus && _lastActivePane != node) {
              setState(() => _lastActivePane = node);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_lastActivePane != node) {
                setState(() => _lastActivePane = node);
              }
            },
            child: Column(
              children: [
                EditorPanelToolbar(
                  label: label,
                  onAddTab: () => _addTabInPane(node),
                  onSaveTabs: () => _saveTabsInPane(node),
                  onSplitVertical: () => _splitPane(node, isVertical: true),
                  onSplitHorizontal: () => _splitPane(node, isVertical: false),
                  canSplit: true,
                ),
                Expanded(
                  child: EditorTabView(
                    tabs: node.tabs,
                    onTabSelected: (i) => setState(() {
                      node.selectedIndex = i;
                      _lastActivePane = node;
                    }),
                    onTabClosed: (i) => _closeTabInPane(node, i),
                    onTabContentChanged: (tab) =>
                        _updateTabContentInPane(node, tab),
                    onTabsReordered: (newTabs) =>
                        setState(() => node.tabs = newTabs),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (node is SplitPane) {
      return node.isVertical
          ? Column(
              children: [
                Flexible(
                  flex: (node.fraction * 1000).toInt(),
                  child: _buildPane(node.first, label),
                ),
                VerticalSplitter(
                  onDrag: (dy) {
                    setState(() {
                      node.fraction += dy / context.size!.height;
                      node.fraction = node.fraction.clamp(0.2, 0.8);
                    });
                  },
                ),
                Flexible(
                  flex: ((1 - node.fraction) * 1000).toInt(),
                  child: _buildPane(node.second, label),
                ),
              ],
            )
          : Row(
              children: [
                Flexible(
                  flex: (node.fraction * 1000).toInt(),
                  child: _buildPane(node.first, label),
                ),
                HorizontalSplitter(
                  onDrag: (dx) {
                    setState(() {
                      node.fraction += dx / context.size!.width;
                      node.fraction = node.fraction.clamp(0.2, 0.8);
                    });
                  },
                ),
                Flexible(
                  flex: ((1 - node.fraction) * 1000).toInt(),
                  child: _buildPane(node.second, label),
                ),
              ],
            );
    } else {
      return const SizedBox.shrink();
    }
  }
}

// --- DragTarget wrapper for EditorTabsPane ---
class _EditorPaneDragTarget extends StatefulWidget {
  final EditorTabsPane pane;
  final Widget child;
  final bool isActive;
  final void Function(FileNode) onOpenFile;
  final VoidCallback? onFocused;
  const _EditorPaneDragTarget({
    required this.pane,
    required this.child,
    required this.isActive,
    required this.onOpenFile,
    this.onFocused,
  });
  @override
  State<_EditorPaneDragTarget> createState() => _EditorPaneDragTargetState();
}

class _EditorPaneDragTargetState extends State<_EditorPaneDragTarget> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<FileNode>(
      onWillAcceptWithDetails: (details) {
        final file = details.data;
        setState(() => _isDragOver = true);
        widget.onFocused?.call();
        return !file.isDirectory;
      },
      onLeave: (file) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        final file = details.data;
        setState(() => _isDragOver = false);
        widget.onOpenFile(file);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.ease,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragOver
                  ? Colors.blue
                  : (widget.isActive ? Colors.grey[50] : Colors.transparent),
              width: _isDragOver ? 2.5 : (widget.isActive ? 1 : 0),
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: widget.child,
        );
      },
    );
  }
}
