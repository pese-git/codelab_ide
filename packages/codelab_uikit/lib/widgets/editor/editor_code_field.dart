import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:code_forge/code_forge.dart';

class EditorCodeField extends StatefulWidget {
  final String filePath;
  final String workspacePath;
  @Deprecated('Do not use')
  final ValueChanged<String>? onChanged;
  final void Function(EditorCodeFieldState)? onStateCreated;

  const EditorCodeField({
    super.key,
    required this.filePath,
    @Deprecated('Do not use') this.onChanged,
    required this.workspacePath,
    this.onStateCreated,
  });

  @override
  State<EditorCodeField> createState() => EditorCodeFieldState();
}

class EditorCodeFieldState extends State<EditorCodeField> {
  late CodeForgeController _controller;
  late UndoRedoController _undoController;
  late LspConfig _lspConfig;

  void saveFile() {
    print('Saving file: ${widget.filePath}');
    print('Content before save - length: ${_controller.text.length}');
    print('Content before save: """\n${_controller.text}\n"""');
    print('Controller state: $_controller');
    _controller.saveFile();
    print('File saved');
  }

  String get currentContent => _controller.text;

  @override
  void initState() {
    super.initState();

    print('Initializing editor for file: ${widget.filePath}');
    _controller = CodeForgeController();
    _controller.addListener(() {
      print(
        'Editor content changed. Current length: ${_controller.text.length}',
      );
    });
    _undoController = UndoRedoController();
    widget.onStateCreated?.call(this);

    //LspStdioConfig.start(
    //  executable: 'dart',
    //  workspacePath: widget.workspacePath,
    //  languageId: 'dart',
    //).then((config) {
    //  setState(() {
    //    _lspConfig = config;
    //  });
    //});

    //WidgetsBinding.instance.addPersistentFrameCallback((oldWidget) {
    //  LspStdioConfig.start(
    //    executable: 'dart',
    //    workspacePath: widget.workspacePath,
    //    languageId: 'dart',
    //  ).then((config) {
    //    setState(() {
    //      _lspConfig = config;
    //    });
    //  });
    //});
  }

  @override
  void didUpdateWidget(covariant EditorCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Updating content from: ${_controller.text.length}');
    });
  }

  //oid _handleChanged() {
  // if (widget.onChanged != null) widget.onChanged!(_controller.text);
  //

  @override
  void dispose() {
    print('Disposing editor for file: ${widget.filePath}');
    //_controller.saveFile();
    _controller.dispose();
    _undoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeForge(
      key: ValueKey(widget.filePath),
      //lspConfig: _lspConfig,
      filePath: widget.filePath,
      controller: _controller,
      undoController: _undoController,
      textStyle: const material.TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
    );
  }
}
