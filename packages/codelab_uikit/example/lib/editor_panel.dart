import 'package:fluent_ui/fluent_ui.dart';
import 'editor_tab.dart';
import 'editor_panel_toolbar.dart';
import 'horizontal_splitter.dart';
import 'vertical_splitter.dart';

class EditorPanel extends StatefulWidget {
  final String label;
  final List<EditorTab> initialTabs;

  const EditorPanel({
    super.key,
    required this.label,
    this.initialTabs = const [],
  });

  @override
  State<EditorPanel> createState() => _EditorPanelState();
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

class _EditorPanelState extends State<EditorPanel> {
  late PaneNode rootPane;

  @override
  void initState() {
    super.initState();
    rootPane = EditorTabsPane(
      tabs: widget.initialTabs.isEmpty
          ? _createDefaultTabs()
          : List.from(widget.initialTabs),
    );
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

  List<EditorTab> _createDefaultTabs() {
    return [
      EditorTab(
        id: '1',
        title: 'main.dart',
        filePath: 'lib/main.dart',
        content: '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: const Center(
        child: Text('Hello World!'),
      ),
    );
  }
}
''',
      ),
      EditorTab(
        id: '2',
        title: 'pubspec.yaml',
        filePath: 'pubspec.yaml',
        content: '''
name: my_app
description: A new Flutter project.

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
''',
      ),
      EditorTab(
        id: '3',
        title: 'README.md',
        filePath: 'README.md',
        content: '''
# My Flutter App

This is a sample Flutter application.

## Features

- Feature 1
- Feature 2
- Feature 3

## Getting Started

1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run`
''',
      ),
    ];
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
      return Column(
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
              onTabSelected: (i) => setState(() => node.selectedIndex = i),
              onTabClosed: (i) => _closeTabInPane(node, i),
              onTabContentChanged: (tab) => _updateTabContentInPane(node, tab),
              onTabsReordered: (newTabs) => setState(() => node.tabs = newTabs),
            ),
          ),
        ],
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
