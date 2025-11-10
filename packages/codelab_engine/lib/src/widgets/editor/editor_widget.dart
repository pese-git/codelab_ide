import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:highlight/highlight.dart' show Mode;
import '../../../codelab_engine.dart';
import 'editor_bloc.dart';

class EditorWidget extends StatefulWidget {
  final String filePath;
  final String content;

  const EditorWidget({
    super.key,
    required this.filePath,
    required this.content,
  });

  @override
  State<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<EditorWidget> {
  late CodeController _codeController;
  late FocusNode _focusNode;
  late EditorBloc _bloc;
  String _lastFilePath = '';
  bool _ignoreControllerChanges = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _bloc = EditorBloc();

    // Первичная инициализация состояния редактора
    _bloc.add(
      EditorEvent.setFile(filePath: widget.filePath, content: widget.content),
    );

    _codeController = CodeController(
      text: widget.content,
      language: _getLanguage(widget.filePath),
    );

    _codeController.addListener(() {
      if (!_ignoreControllerChanges) {
        _bloc.add(EditorEvent.updateContent(_codeController.text));
      }
    });

    _lastFilePath = widget.filePath;
  }

  @override
  void didUpdateWidget(covariant EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isValid = widget.filePath.isNotEmpty && widget.content.isNotEmpty;
    if ((widget.filePath != oldWidget.filePath ||
            widget.content != oldWidget.content) &&
        isValid) {
      _bloc.add(
        EditorEvent.setFile(filePath: widget.filePath, content: widget.content),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditorBloc>.value(
      value: _bloc,
      child: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) {
          // Синхронизируем контроллер с новым файлом или внешним изменением контента
          if (_lastFilePath != state.filePath ||
              _codeController.text != state.content ||
              _codeController.language != _getLanguage(state.filePath)) {
            _ignoreControllerChanges = true;
            _codeController.language = _getLanguage(state.filePath);
            if (_codeController.text != state.content) {
              _codeController.text = state.content;
            }
            _lastFilePath = state.filePath;
            _ignoreControllerChanges = false;
          }

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
                    const Icon(Icons.code, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getFileName(state.filePath),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: state.isSaving
                          ? null
                          : () => context.read<ProjectBloc>().add(
                              ProjectEvent.saveCurrentFile(
                                currentFile: state.filePath,
                                fileContent: state.content,
                              ),
                            ),
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    if (state.isDirty)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Unsaved',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
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
        },
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
        return dart;
    }
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }
}
