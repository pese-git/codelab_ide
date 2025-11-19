import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/editor_manager_service.dart';
import 'editor_bloc.dart';

import 'package:flutter/services.dart';

class SaveTabIntent extends Intent {
  const SaveTabIntent();
}

class EditorPanel extends StatefulWidget {
  final GlobalKey<uikit.EditorPanelState>? editorPanelKey;

  const EditorPanel({super.key, this.editorPanelKey});

  @override
  State<EditorPanel> createState() => EditorPanelState();
}

class EditorPanelState extends State<EditorPanel> {
  late final GlobalKey<uikit.EditorPanelState> _internalEditorPanelKey;
  final _bloc = EditorBloc(
    fileService: CherryPick.openRootScope().resolve<FileService>(),
  );

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
      create: (context) => _bloc,
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
              const SaveTabIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
              const SaveTabIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            SaveTabIntent: CallbackAction<SaveTabIntent>(
              onInvoke: (intent) => _saveActiveTab(context),
            ),
          },
          child: BlocConsumer<EditorBloc, EditorState>(
            builder: (context, state) {
              codelabLogger.d(
                'EditorPanel: build with state: ${state.runtimeType}',
                tag: 'editor_panel',
              );
              return uikit.EditorPanel(
                key: _internalEditorPanelKey,
                initialTabs: [],
                label: 'Editor',
                onTabSave: (tab) async {
                  codelabLogger.d(
                    'EditorPanel: Save tab pressed for file ${tab.filePath}',
                    tag: 'editor_panel',
                  );
                  context.read<EditorBloc>().add(EditorEvent.saveFile(tab));
                },
              );
            },
            listener: (BuildContext context, EditorState state) {
              codelabLogger.d(
                'EditorPanel: BlocConsumer listener got state: ${state.runtimeType}',
                tag: 'editor_panel',
              );
              state.mapOrNull(
                openedFile: (s) {
                  codelabLogger.d(
                    'EditorPanel: openedFile for ${s.filePath}',
                    tag: 'editor_panel',
                  );
                  _internalEditorPanelKey.currentState?.openFile(
                    filePath: s.filePath,
                    title: s.filePath.split('/').last,
                    content: s.content,
                  );
                },
                fileChanged: (s) {
                  codelabLogger.d(
                    'EditorPanel: fileChanged for ${s.filePath}',
                    tag: 'editor_panel',
                  );
                  //_internalEditorPanelKey.currentState?.openFile(
                  //  filePath: s.filePath,
                  //  title: s.filePath.split('/').last,
                  //  content: s.content,
                  //);
                  // Можно добавить уведомление/snackbar о том, что файл изменён
                },
                fileDeleted: (s) {
                  codelabLogger.d(
                    'EditorPanel: fileDeleted for ${s.filePath}',
                    tag: 'editor_panel',
                  );
                  //_internalEditorPanelKey.currentState?.closeFile(s.filePath);
                },
                savedFile: (s) {
                  codelabLogger.d(
                    'EditorPanel: savedFile for ${s.filePath}',
                    tag: 'editor_panel',
                  );
                  // Здесь можно подсветить/показать toast сохранения
                  displayInfoBar(
                    context,
                    builder: (context, close) {
                      return InfoBar(
                        title: Text('Info'),
                        content: Text(
                          'EditorPanel: savedFile for ${s.filePath}',
                        ),
                        severity: InfoBarSeverity.success,
                      );
                    },
                  );
                },
                error: (s) {
                  codelabLogger.e(
                    'EditorPanel: error for ${s.filePath} - ${s.message}',
                    tag: 'editor_panel',
                    error: s.error,
                  );
                  // Показать ошибку (snackbar/dialog/log)
                  displayInfoBar(
                    context,
                    builder: (context, close) {
                      return InfoBar(
                        title: Text('Error'),
                        content: Text(
                          'EditorPanel: error for ${s.filePath} - ${s.message}',
                        ),
                        severity: InfoBarSeverity.error,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void openFile({required String filePath}) {
    codelabLogger.d(
      'EditorPanel: openFile called for $filePath',
      tag: 'editor_panel',
    );
    // Делегируем открытие файла бизнес-логике
    _bloc.add(EditorEvent.openFile(filePath));
  }

  void _saveActiveTab(BuildContext context) {
    final activeTab = _internalEditorPanelKey.currentState?.activeTab;
    if (activeTab != null) {
      codelabLogger.d(
        'Shortcut: Saving active tab ${activeTab.filePath}',
        tag: 'editor_panel',
      );
      _bloc.add(EditorEvent.saveFile(activeTab));
    } else {
      codelabLogger.d('Shortcut: No active tab to save.', tag: 'editor_panel');
    }
  }
}
