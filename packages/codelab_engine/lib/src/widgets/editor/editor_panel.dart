import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/editor_manager_service.dart';
import 'editor_bloc.dart';

class EditorPanel extends StatefulWidget {
  final GlobalKey<uikit.EditorPanelState>? editorPanelKey;

  const EditorPanel({super.key, this.editorPanelKey});

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late final GlobalKey<uikit.EditorPanelState> _internalEditorPanelKey;

  @override
  void initState() {
    super.initState();
    _internalEditorPanelKey =
        widget.editorPanelKey ?? GlobalKey<uikit.EditorPanelState>();

    // Регистрируем ключ в сервисе управления редактором
    final editorManagerService = CherryPick.openRootScope()
        .resolve<EditorManagerService>();
    editorManagerService.setEditorPanelKey(_internalEditorPanelKey);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditorBloc>(
      create: (context) => EditorBloc(
        fileService: CherryPick.openRootScope().resolve<FileService>(),
      ),
      child: BlocBuilder<EditorBloc, EditorState>(
        builder: (context, state) {
          codelabLogger.d(
            'EditorPanel: Building with ${state.openTabs.length} tabs',
            tag: 'editor_panel',
          );
          return uikit.EditorPanel(
            key: _internalEditorPanelKey,
            label: 'Editor',
            initialTabs: state.openTabs,
          );
        },
      ),
    );
  }
}
