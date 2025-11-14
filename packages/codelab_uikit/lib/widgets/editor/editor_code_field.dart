import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/highlight_core.dart';
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

class EditorCodeField extends StatefulWidget {
  final String content;
  final String filePath;
  final ValueChanged<String>? onChanged;

  const EditorCodeField({
    super.key,
    required this.content,
    required this.filePath,
    this.onChanged,
  });

  @override
  State<EditorCodeField> createState() => _EditorCodeFieldState();
}

class _EditorCodeFieldState extends State<EditorCodeField> {
  late CodeController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = CodeController(
      text: widget.content,
      language: _getLanguage(widget.filePath),
    );
    _controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant EditorCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath) {
      _controller.dispose();
      _controller = CodeController(
        text: widget.content,
        language: _getLanguage(widget.filePath),
      );
      _controller.addListener(_handleChanged);
      setState(() {});
    } else if (widget.content != _controller.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.content;
      });
    }
  }

  void _handleChanged() {
    if (widget.onChanged != null) widget.onChanged!(_controller.text);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return material.Material(
      color: material.Colors.transparent,
      child: CodeTheme(
        data: CodeThemeData(styles: githubTheme),
        child: CodeField(
          controller: _controller,
          focusNode: _focusNode,
          textStyle: const material.TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          expands: true,
          padding: const EdgeInsets.all(16),
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
}
