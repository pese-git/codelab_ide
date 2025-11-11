import 'package:fluent_ui/fluent_ui.dart';
import 'editor_tab.dart';
import 'editor_panel_toolbar.dart';
import 'horizontal_splitter.dart';

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

class _EditorPanelState extends State<EditorPanel> {
  late List<List<EditorTab>> _panes; // Split panes
  List<int> _selectedTabIndices = [0, 0];
  double _splitFraction = 0.5;
  bool _splitActive = false;

  @override
  void initState() {
    super.initState();
    _panes = [
      widget.initialTabs.isEmpty ? _createDefaultTabs() : List.from(widget.initialTabs),
      <EditorTab>[], // starts closed
    ];
    _selectedTabIndices = [0, 0];
    _splitFraction = 0.5;
    _splitActive = false;
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

  void _openNewTab() {
    final newTab = EditorTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'new_file.dart',
      filePath: 'lib/new_file.dart',
      content: '// New file content\nvoid main() {\n  print("Hello World!");\n}',
    );
    setState(() {
      final paneIndex = _splitActive && _panes[1].isNotEmpty ? 1 : 0;
      _panes[paneIndex].add(newTab);
      _selectedTabIndices[paneIndex] = _panes[paneIndex].length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          EditorPanelToolbar(
            label: widget.label,
            onAddTab: _openNewTab,
            onSaveTabs: () {
              displayInfoBar(
                context,
                builder: (context, close) {
                  return InfoBar(
                    title: const Text('Files saved'),
                    content: const Text('All open files have been saved.'),
                    severity: InfoBarSeverity.success,
                  );
                },
              );
            },
            onSplit: _onSplitPane,
            isSplitActive: _splitActive,
            canSplit: _panes[0].isNotEmpty && !_splitActive,
          ),
          Expanded(
            child: _splitActive ? _buildSplitEditors() : _buildSingleEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleEditor() {
    return EditorTabView(
      tabs: _panes[0],
      onTabSelected: (i) => setState(() => _selectedTabIndices[0] = i),
      onTabClosed: (i) {
        setState(() {
          _panes[0].removeAt(i);
          if (_selectedTabIndices[0] >= _panes[0].length) {
            _selectedTabIndices[0] = _panes[0].length - 1;
          }
        });
      },
      onTabContentChanged: (tab) {
        setState(() {
          final idx = _panes[0].indexWhere((t) => t.id == tab.id);
          if (idx != -1) _panes[0][idx] = tab;
        });
      },
      onTabsReordered: (newTabs) => setState(() => _panes[0] = newTabs),
    );
  }

  Widget _buildSplitEditors() {
    return Row(
      children: [
        Flexible(
          flex: (_splitFraction * 1000).toInt(),
          child: EditorTabView(
            tabs: _panes[0],
            onTabSelected: (i) => setState(() => _selectedTabIndices[0] = i),
            onTabClosed: (i) {
              setState(() {
                _panes[0].removeAt(i);
                if (_selectedTabIndices[0] >= _panes[0].length) {
                  _selectedTabIndices[0] = _panes[0].length - 1;
                }
                // если одна из панелей стала пустой, убираем split и все табы собираем в одну
                if (_panes[0].isEmpty || _panes[1].isEmpty) {
                  final allTabs = [..._panes[0], ..._panes[1]];
                  _panes = [allTabs, []];
                  _selectedTabIndices = [allTabs.isNotEmpty ? 0 : 0, 0];
                  _splitActive = false;
                }
              });
            },
            onTabContentChanged: (tab) {
              setState(() {
                final idx = _panes[0].indexWhere((t) => t.id == tab.id);
                if (idx != -1) _panes[0][idx] = tab;
              });
            },
            onTabsReordered: (newTabs) => setState(() => _panes[0] = newTabs),
          ),
        ),
        HorizontalSplitter(
          onDrag: (dx) {
            setState(() {
              _splitFraction += dx / context.size!.width;
              _splitFraction = _splitFraction.clamp(0.2, 0.8);
            });
          },
        ),
        Flexible(
          flex: ((1 - _splitFraction) * 1000).toInt(),
          child: EditorTabView(
            tabs: _panes[1],
            onTabSelected: (i) => setState(() => _selectedTabIndices[1] = i),
            onTabClosed: (i) {
              setState(() {
                _panes[1].removeAt(i);
                if (_selectedTabIndices[1] >= _panes[1].length) {
                  _selectedTabIndices[1] = _panes[1].length - 1;
                }
                // если одна из панелей стала пустой, убираем split и все табы собираем в одну
                if (_panes[0].isEmpty || _panes[1].isEmpty) {
                  final allTabs = [..._panes[0], ..._panes[1]];
                  _panes = [allTabs, []];
                  _selectedTabIndices = [allTabs.isNotEmpty ? 0 : 0, 0];
                  _splitActive = false;
                }
              });
            },
            onTabContentChanged: (tab) {
              setState(() {
                final idx = _panes[1].indexWhere((t) => t.id == tab.id);
                if (idx != -1) _panes[1][idx] = tab;
              });
            },
            onTabsReordered: (newTabs) => setState(() => _panes[1] = newTabs),
          ),
        )
      ],
    );
  }

  void _onSplitPane() {
    setState(() {
      final leftTabs = _panes[0];
      if (leftTabs.isNotEmpty) {
        // перенести/клонировать выбранный tab слева в правое окно
        final tabToSplit = leftTabs[_selectedTabIndices[0]];
        // Если tab уже есть справа — просто фокус
        if (!_panes[1].contains(tabToSplit)) {
          _panes[1].add(tabToSplit);
          _selectedTabIndices[1] = _panes[1].length - 1;
        } else {
          _selectedTabIndices[1] = _panes[1].indexOf(tabToSplit);
        }
        _splitActive = true;
      }
    });
  }
}
