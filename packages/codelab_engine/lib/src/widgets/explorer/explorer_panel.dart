import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:codelab_uikit/codelab_uikit.dart'
    as uikit
    show ExplorerPanel, ExplorerPanelState, FileNode;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'explorer_bloc.dart';

class ExplorerPanel extends StatefulWidget {
  final GlobalKey<uikit.ExplorerPanelState>? explorerKey;
  final void Function(String filePath, String workspacePath) onFileOpen;

  ExplorerPanel({super.key, this.explorerKey, required this.onFileOpen});

  @override
  State<StatefulWidget> createState() => ExplorerPanelState();
}

class ExplorerPanelState extends State<ExplorerPanel> {
  late final GlobalKey<uikit.ExplorerPanelState> _internalExplorerPanelKey;
  final ExplorerBloc _bloc = ExplorerBloc(
    projectManagerService: CherryPick.openRootScope()
        .resolve<ProjectManagerService>(),
    fileService: CherryPick.openRootScope().resolve<FileService>(),
    fileSyncService: CherryPick.openRootScope().resolve<FileSyncService>(),
  );

  @override
  void initState() {
    super.initState();
    _internalExplorerPanelKey =
        widget.explorerKey ?? GlobalKey<uikit.ExplorerPanelState>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExplorerBloc>(
      create: (context) => _bloc,
      child: BlocListener<ExplorerBloc, ExplorerState>(
        listener: (context, state) {
          state.mapOrNull(
            fileTreeLoaded: (s) {
              _internalExplorerPanelKey.currentState?.updateFileTree(
                s.fileTree,
              );
            },
            openedFile: (s) {
              if (!s.node.isDirectory) {
                widget.onFileOpen.call(s.node.path, s.node.workspacePath);
              }
            },
            nodeExpanded: (s) {
              //explorerKey.currentState?.expandNode?.call(s.path);
            },
            nodeCollapsed: (s) {
              //explorerKey.currentState?.collapseNode?.call(s.path);
            },
            error: (s) {
              displayInfoBar(
                context,
                builder: (ctx, _) => InfoBar(
                  title: const Text('Error'),
                  content: Text(s.message),
                  severity: InfoBarSeverity.error,
                ),
              );
            },
          );
        },
        child: uikit.ExplorerPanel(
          key: _internalExplorerPanelKey,
          onOpenFile: (uikit.FileNode fileNode) {
            _bloc.add(ExplorerEvent.openFile(fileNode));
          },
          // Больше не надо передавать files — панель сама всё хранит.
          // Управляет деревом и selection внутри себя.
          //onFileOpen: (uikit.FileNode fileNode) async {
          //  // Отправляем только команду открыть файл (обработка теперь только через сигнал openedFile)
          //  context.read<ExplorerBloc>().add(
          //    ExplorerEvent.openFile(fileNode.path),
          //  );
          //  // Автоматически после openedFile будет вызван mapOrNull.openedFile, который прокинет данные в showFile и/или onFileOpen дальше!
          //},
        ),
      ),
    );
  }
}
