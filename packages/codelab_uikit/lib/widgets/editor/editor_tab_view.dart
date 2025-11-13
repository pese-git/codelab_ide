import 'package:fluent_ui/fluent_ui.dart' hide ButtonStyle, IconButton;
import 'package:flutter/material.dart' as material;
import 'package:highlight/highlight_core.dart';
import '../../models/editor_tab.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:flutter_highlight/themes/github.dart';

class EditorTabView extends StatefulWidget {
  final List<EditorTab> tabs;
  final ValueChanged<int>? onTabSelected;
  final ValueChanged<int>? onTabClosed;
  final ValueChanged<EditorTab>? onTabContentChanged;
  final ValueChanged<List<EditorTab>>? onTabsReordered;

  const EditorTabView({
    super.key,
    required this.tabs,
    this.onTabSelected,
    this.onTabClosed,
    this.onTabContentChanged,
    this.onTabsReordered,
  });

  @override
  State<EditorTabView> createState() => _EditorTabViewState();
}

class _EditorTabViewState extends State<EditorTabView> {
  int _selectedIndex = 0;

  late CodeController _codeController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _codeController = CodeController(
      text: widget.tabs.isNotEmpty ? widget.tabs[0].content : '',
      language: _getLanguage(
        widget.tabs.isNotEmpty ? widget.tabs[0].filePath : '',
      ),
    );
    _codeController.addListener(_handleCodeChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleCodeChanged() {
    if (widget.tabs.isNotEmpty) {
      final tab = widget.tabs[_selectedIndex];
      final updatedTab = tab.copyWith(
        content: _codeController.text,
        isDirty: true,
      );
      widget.onTabContentChanged?.call(updatedTab);
    }
  }

  @override
  void didUpdateWidget(covariant EditorTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.tabs.length && widget.tabs.isNotEmpty) {
      _selectedIndex = widget.tabs.length - 1;
    }
    if (widget.tabs.isEmpty) {
      _selectedIndex = 0;
    }
    if (widget.tabs.isNotEmpty &&
        widget.tabs[_selectedIndex].content != _codeController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _codeController.text = widget.tabs[_selectedIndex].content;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return _buildEmptyState();
    }

    return TabView(
      tabs: [
        for (final tab in widget.tabs)
          Tab(
            text: Text('${tab.title}${tab.isDirty ? ' •' : ''}'),
            semanticLabel: tab.title,
            icon: const Icon(FluentIcons.document),
            body: _buildEditorContent(tab),
            onClosed: () {
              final idx = widget.tabs.indexOf(tab);
              widget.onTabClosed?.call(idx);
              setState(() {
                if (_selectedIndex >= widget.tabs.length - 1 &&
                    _selectedIndex > 0) {
                  _selectedIndex--;
                }
              });
            },
          ),
      ],
      currentIndex: _selectedIndex,
      onChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
        widget.onTabSelected?.call(index);
      },
      tabWidthBehavior: TabWidthBehavior.sizeToContent,
      closeButtonVisibility: CloseButtonVisibilityMode.always,
      showScrollButtons: true,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          var tabs = List.of(widget.tabs);
          if (oldIndex < newIndex) newIndex -= 1;
          final item = tabs.removeAt(oldIndex);
          tabs.insert(newIndex, item);
          widget.onTabsReordered?.call(tabs);
          if (_selectedIndex == oldIndex)
            _selectedIndex = newIndex;
          else if (_selectedIndex == newIndex)
            _selectedIndex = oldIndex;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.document, size: 48, color: Colors.grey[100]),
          const SizedBox(height: 16),
          Text(
            'No files open',
            style: TextStyle(fontSize: 16, color: Colors.grey[100]),
          ),
          const SizedBox(height: 8),
          Text(
            'Open a file to start editing',
            style: TextStyle(fontSize: 14, color: Colors.grey[80]),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorContent(EditorTab tab) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${tab.filePath}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[100],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF323130)),
                ),
                child: material.Material(
                  color: Colors.transparent,
                  child: CodeTheme(
                    data: CodeThemeData(styles: githubTheme),
                    child: CodeField(
                      controller: _codeController,
                      focusNode: _focusNode,
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      expands: true,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Mode? _getLanguage(String filePath) {
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return dart;
      case 'py':
        return python;
      case 'js':
      case 'jsx':
        return javascript;
      case 'ts':
      case 'tsx':
        return typescript;
      case 'java':
        return java;
      case 'cpp':
      case 'cc':
      case 'cxx':
      case 'c':
        return cpp;
      case 'cs':
        return cs;
      case 'go':
        return go;
      case 'rs':
        return rust;
      case 'swift':
        return swift;
      case 'kt':
        return kotlin;
      case 'php':
        return php;
      case 'rb':
        return ruby;
      case 'html':
        return xml;
      case 'css':
        return css;
      case 'yaml':
      case 'yml':
        return yaml;
      case 'json':
        return json;
      case 'md':
        return markdown;
      default:
        return markdown;
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }
}
