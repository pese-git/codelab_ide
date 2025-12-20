import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:code_forge/code_forge.dart';

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
  late CodeForgeController _controller;
  late UndoRedoController _undoController;

  @override
  void initState() {
    super.initState();
    _controller = CodeForgeController()..text = widget.content;
    _undoController = UndoRedoController();
    _controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant EditorCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != _controller.text) {
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
    _controller.dispose();
    _undoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return material.Material(
      color: material.Colors.transparent,
      child: CodeForge(
        controller: _controller,
        undoController: _undoController,
        textStyle: const material.TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }
}
