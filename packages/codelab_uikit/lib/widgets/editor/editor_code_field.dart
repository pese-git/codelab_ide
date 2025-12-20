import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:code_forge/code_forge.dart';

class EditorCodeField extends StatefulWidget {
  @Deprecated('do not use')
  final String content;
  final String filePath;
  final String workspacePath;
  @Deprecated('Do not use')
  final ValueChanged<String>? onChanged;

  const EditorCodeField({
    super.key,
    required this.content,
    required this.filePath,
    @Deprecated('Do not use') this.onChanged,
    required this.workspacePath,
  });

  @override
  State<EditorCodeField> createState() => EditorCodeFieldState();
}

class EditorCodeFieldState extends State<EditorCodeField> {
  late CodeForgeController _controller;
  late UndoRedoController _undoController;
  late LspConfig _lspConfig;

  //void saveFile() => _controller.saveFile();

  @override
  void initState() {
    super.initState();

    _controller = CodeForgeController();
    _undoController = UndoRedoController();
    //_controller.addListener(_handleChanged);

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
    //  setState(() async {
    //    _lspConfig = await LspStdioConfig.start(
    //      executable: 'dart',
    //      workspacePath: widget.workspacePath,
    //      languageId: 'dart',
    //    );
    //  });
    //});
  }

  @override
  void didUpdateWidget(covariant EditorCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    //if (widget.content != _controller.text) {
    //  WidgetsBinding.instance.addPostFrameCallback((_) {
    //    _controller.text = widget.content;
    //  });
    //}
  }

  //oid _handleChanged() {
  // if (widget.onChanged != null) widget.onChanged!(_controller.text);
  //

  @override
  void dispose() {
    //_controller.saveFile();
    _controller.dispose();
    _undoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeForge(
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
