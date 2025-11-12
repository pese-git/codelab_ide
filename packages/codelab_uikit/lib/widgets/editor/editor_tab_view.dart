import 'package:fluent_ui/fluent_ui.dart' hide ButtonStyle, IconButton;
import 'package:flutter/material.dart' hide Colors, Tab;
import '../../models/editor_tab.dart';

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

  @override
  void didUpdateWidget(covariant EditorTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.tabs.length && widget.tabs.isNotEmpty) {
      _selectedIndex = widget.tabs.length - 1;
    }
    if (widget.tabs.isEmpty) {
      _selectedIndex = 0;
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
                if (_selectedIndex >= widget.tabs.length - 1 && _selectedIndex > 0) {
                  _selectedIndex--;
                }
              });
            },
          )
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
          Icon(
            FluentIcons.document,
            size: 48,
            color: Colors.grey[100],
          ),
          const SizedBox(height: 16),
          Text(
            'No files open',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open a file to start editing',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[80],
            ),
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
              'File: [1m${tab.filePath}[0m',
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
                  border: Border.all(color: Colors.grey[30]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextFormBox(
                  maxLines: null,
                  expands: true,
                  initialValue: tab.content,
                  style: const TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 14,
                  ),
                  onChanged: (value) {
                    final updatedTab = tab.copyWith(
                      content: value,
                      isDirty: true,
                    );
                    widget.onTabContentChanged?.call(updatedTab);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
