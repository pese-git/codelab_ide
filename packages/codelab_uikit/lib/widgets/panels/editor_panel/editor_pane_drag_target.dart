// editor_pane_drag_target.dart

import 'package:codelab_uikit/models/file_node.dart';
import 'package:flutter/material.dart';

class EditorPaneDragTarget extends StatefulWidget {
  final dynamic pane;
  final Widget child;
  final bool isActive;
  final void Function(FileNode) onOpenFile;
  final VoidCallback? onFocused;

  const EditorPaneDragTarget({
    required this.pane,
    required this.child,
    required this.isActive,
    required this.onOpenFile,
    this.onFocused,
    super.key,
  });

  @override
  State<EditorPaneDragTarget> createState() => _EditorPaneDragTargetState();
}

class _EditorPaneDragTargetState extends State<EditorPaneDragTarget> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<FileNode>(
      onWillAcceptWithDetails: (details) {
        final file = details.data;
        setState(() => _isDragOver = true);
        widget.onFocused?.call();
        return !file.isDirectory;
      },
      onLeave: (file) => setState(() => _isDragOver = false),
      onAcceptWithDetails: (details) {
        final file = details.data;
        setState(() => _isDragOver = false);
        widget.onOpenFile(file);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.ease,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragOver
                  ? Colors.blue
                  : (widget.isActive ? Colors.grey[50]! : Colors.transparent),
              width: _isDragOver ? 2.5 : (widget.isActive ? 1 : 0),
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: widget.child,
        );
      },
    );
  }
}
