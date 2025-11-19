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
  State<EditorPanel> createState() => EditorPanelState();
}

class EditorPanelState extends State<EditorPanel> {
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
      child: BlocConsumer<EditorBloc, EditorState>(
        builder: (context, state) {
          codelabLogger.d(
            'EditorPanel: Building with ${state.openTabs.length} tabs',
            tag: 'editor_panel',
          );
          return uikit.EditorPanel(
            key: _internalEditorPanelKey,
            label: 'Editor',
            initialTabs: state.openTabs,
            onTabSave: (tab) async {
              context.read<EditorBloc>().add(EditorEvent.saveFile(tab));
            },
          );
        },
        listener: (BuildContext context, EditorState state) {
          //if (state.activeTab != null) {
          //  _internalEditorPanelKey.currentState?.openFile(
          //    filePath: state.activeTab!.filePath,
          //    title: state.activeTab!.title,
          //    content: state.activeTab!.content,
          //  );
          //}
        },
      ),
    );
  }

  void openFile({
    required String filePath,
    //uikit.EditorTabsPane? targetPane,
  }) async {
    //_bloc.add(EditorEvent.openFile(filePath));
    final fileService = CherryPick.openRootScope().resolve<FileService>();
    final result = await fileService.readFile(filePath).run();

    result.match(
      (error) {
        codelabLogger.e(
          'EditorBloc: Error reading file: $error',
          tag: 'editor_bloc',
          error: error,
        );
      },
      (content) {
        _internalEditorPanelKey.currentState?.openFile(
          filePath: filePath,
          title: filePath.split('/').last,
          content: content,
        );
      },
    );
  }
}
