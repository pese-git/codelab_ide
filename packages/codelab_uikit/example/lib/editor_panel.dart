import 'package:fluent_ui/fluent_ui.dart';
import 'editor_tab.dart';

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
  late List<EditorTab> _tabs;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = widget.initialTabs.isEmpty 
      ? _createDefaultTabs()
      : List.from(widget.initialTabs);
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
      _tabs.add(newTab);
      _selectedTabIndex = _tabs.length - 1;
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onTabClosed(int index) {
    setState(() {
      _tabs.removeAt(index);
      if (_selectedTabIndex >= _tabs.length) {
        _selectedTabIndex = _tabs.length - 1;
      }
    });
  }

  void _onTabContentChanged(EditorTab updatedTab) {
    setState(() {
      final index = _tabs.indexWhere((tab) => tab.id == updatedTab.id);
      if (index != -1) {
        _tabs[index] = updatedTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: EditorTabView(
              tabs: _tabs,
              onTabSelected: _onTabSelected,
              onTabClosed: _onTabClosed,
              onTabContentChanged: _onTabContentChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[10],
        border: Border(
          bottom: BorderSide(color: Colors.grey[30]),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[100],
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(FluentIcons.add, size: 16),
            onPressed: _openNewTab,
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(FluentIcons.save, size: 16),
            onPressed: () {
              // Save all tabs logic would go here
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
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.all(6)),
            ),
          ),
        ],
      ),
    );
  }
}
