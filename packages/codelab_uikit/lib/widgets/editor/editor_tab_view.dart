import 'package:fluent_ui/fluent_ui.dart';
// import 'package:flutter/material.dart' as material;
import '../../models/editor_tab.dart';
import 'editor_code_field.dart';

class EditorTabView extends StatefulWidget {
  final List<EditorTab> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;
  final ValueChanged<int>? onTabClosed;
  final ValueChanged<EditorTab>? onTabContentChanged;
  final ValueChanged<List<EditorTab>>? onTabsReordered;
  @Deprecated('Do not use')
  final ValueChanged<EditorTab>? onTabSave;

  const EditorTabView({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onTabSelected,
    this.onTabClosed,
    this.onTabContentChanged,
    this.onTabsReordered,
    this.onTabSave,
  });

  @override
  State<EditorTabView> createState() => _EditorTabViewState();
}

class _EditorTabViewState extends State<EditorTabView> {
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
            },
          ),
      ],
      currentIndex: widget.selectedIndex,
      onChanged: (index) {
        widget.onTabSelected?.call(index);
      },
      tabWidthBehavior: TabWidthBehavior.sizeToContent,
      closeButtonVisibility: CloseButtonVisibilityMode.always,
      showScrollButtons: true,
      onReorder: (oldIndex, newIndex) {
        var tabs = List.of(widget.tabs);
        if (oldIndex < newIndex) newIndex -= 1;
        final item = tabs.removeAt(oldIndex);
        tabs.insert(newIndex, item);
        widget.onTabsReordered?.call(tabs);
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
            Row(
              children: [
                Expanded(
                  child: BreadcrumbBar<String>(
                    //key: ValueKey(tab.filePath),
                    items: [
                      for (final part in tab.filePath.split('/'))
                        BreadcrumbItem(
                          label: Text(
                            part,
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: part,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const WindowsIcon(WindowsIcons.save, size: 18.0),
                  onPressed: () => widget.onTabSave?.call(tab),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF323130)),
                ),
                child: EditorCodeField(
                  key: ValueKey(tab.filePath),
                  content: tab.content,
                  filePath: tab.filePath,
                  workspacePath: tab.workspacePath,
                  onChanged: (newText) {
                    final updatedTab = tab.copyWith(
                      content: newText,
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
