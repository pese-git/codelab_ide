import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
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
import 'package:highlight/highlight_core.dart';

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
  late CodeController _codeController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _codeController = CodeController(
      text: widget.content,
      language: _getLanguage(widget.filePath),
    );
    _codeController.addListener(() {
      widget.onContentChanged(_codeController.text);
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.onContentChanged(_codeController.text);
    });
  }

  @override
  void didUpdateWidget(EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.content != widget.content) {
      final newLanguage = _getLanguage(widget.filePath);
      final newText = widget.content;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _codeController.language = newLanguage;
        if (_codeController.text != newText) {
          _codeController.text = newText;
        }
      });
    }
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
        return cpp;
      case 'c':
        return cpp; // Нет отдельного C в highlight, используем cpp
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
        return xml; // highlight зовет это xml
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
        return dart; // по умолчанию пусть будет dart
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }

  @override
  void dispose() {
    _codeController.dispose();
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
      ],
    );
  }
}
