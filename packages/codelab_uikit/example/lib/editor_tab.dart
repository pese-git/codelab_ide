import 'package:fluent_ui/fluent_ui.dart' hide ButtonStyle, IconButton;
import 'package:flutter/material.dart' hide Colors;

class EditorTab {
  final String id;
  final String title;
  final String filePath;
  final String content;
  final bool isDirty;

  EditorTab({
    required this.id,
    required this.title,
    required this.filePath,
    required this.content,
    this.isDirty = false,
  });

  EditorTab copyWith({
    String? id,
    String? title,
    String? filePath,
    String? content,
    bool? isDirty,
  }) {
    return EditorTab(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class EditorTabView extends StatefulWidget {
  final List<EditorTab> tabs;
  final ValueChanged<int>? onTabSelected;
  final ValueChanged<int>? onTabClosed;
  final ValueChanged<EditorTab>? onTabContentChanged;

  const EditorTabView({
    super.key,
    required this.tabs,
    this.onTabSelected,
    this.onTabClosed,
    this.onTabContentChanged,
  });

  @override
  State<EditorTabView> createState() => _EditorTabViewState();
}

class _EditorTabViewState extends State<EditorTabView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: _buildEditorContent(),
        ),
      ],
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

  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[10],
        border: Border(
          bottom: BorderSide(color: Colors.grey[30]),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length,
        itemBuilder: (context, index) {
          final tab = widget.tabs[index];
          return _TabItem(
            tab: tab,
            isSelected: index == _selectedIndex,
            onTap: () => _selectTab(index),
            onClose: () => _closeTab(index),
          );
        },
      ),
    );
  }

  Widget _buildEditorContent() {
    final tab = widget.tabs[_selectedIndex];
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
                  border: Border.all(color: Colors.grey[30]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextFormBox(
                  maxLines: null,
                  expands: true,
                  controller: TextEditingController(text: tab.content),
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

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onTabSelected?.call(index);
  }

  void _closeTab(int index) {
    widget.onTabClosed?.call(index);
    if (index == _selectedIndex && widget.tabs.length > 1) {
      final newIndex = index == widget.tabs.length - 1 ? index - 1 : index;
      _selectTab(newIndex);
    }
  }
}

class _TabItem extends StatelessWidget {
  final EditorTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.document,
                    size: 16,
                    color: isSelected ? Colors.blue : Colors.grey[100],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tab.title}${tab.isDirty ? ' •' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.blue : Colors.grey[100],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              icon: Icon(
                FluentIcons.chrome_close,
                size: 12,
                color: Colors.grey[80],
              ),
              onPressed: onClose,
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
