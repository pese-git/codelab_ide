import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

class EditorWidget extends StatefulWidget {
  final String filePath;
  final String content;
  final Function(String) onContentChanged;
  final Function() onSave;

  const EditorWidget({
    super.key,
    required this.filePath,
    required this.content,
    required this.onContentChanged,
    required this.onSave,
  });

  @override
  EditorWidgetState createState() => EditorWidgetState();
}

class EditorWidgetState extends State<EditorWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textController = TextEditingController(text: widget.content);

    _textController.addListener(() {
      // Avoid notifyListeners during build phase
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.onContentChanged(_textController.text);
      });
    });
  }

  @override
  void didUpdateWidget(EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.content != widget.content) {
      _textController.text = widget.content;
    }
  }

  String _getLanguage(String filePath) {
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'dart':
        return 'dart';
      case 'py':
        return 'python';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'java':
        return 'java';
      case 'cpp':
      case 'cc':
      case 'cxx':
        return 'cpp';
      case 'c':
        return 'c';
      case 'cs':
        return 'csharp';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'swift':
        return 'swift';
      case 'kt':
        return 'kotlin';
      case 'php':
        return 'php';
      case 'rb':
        return 'ruby';
      case 'html':
        return 'html';
      case 'css':
        return 'css';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'json':
        return 'json';
      case 'md':
        return 'markdown';
      default:
        return '';
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.code, size: 16),
              const SizedBox(width: 8),
              Text(
                _getFileName(widget.filePath),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: widget.onSave,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: HighlightView(
              _textController.text,
              language: _getLanguage(widget.filePath),
              theme: githubTheme,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
