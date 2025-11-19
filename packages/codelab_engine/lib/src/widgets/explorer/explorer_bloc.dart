import 'dart:async';

import 'package:codelab_core/codelab_core.dart' as core;
import 'package:codelab_engine/codelab_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit show FileNode;

part 'explorer_bloc.freezed.dart';

// imports ...

@freezed
class ExplorerEvent with _$ExplorerEvent {
  const factory ExplorerEvent.loadFileTree(String projectPath) = LoadFileTree;
  const factory ExplorerEvent.openFile(uikit.FileNode node) = OpenFile;
  const factory ExplorerEvent.expandNode(String path) = ExpandNode;
  const factory ExplorerEvent.collapseNode(String path) = CollapseNode;
  const factory ExplorerEvent.refresh() = Refresh;
}

@freezed
class ExplorerState with _$ExplorerState {
  const factory ExplorerState.initial() = Initial;
  const factory ExplorerState.fileTreeLoaded(uikit.FileNode fileTree) =
      FileTreeLoaded;
  const factory ExplorerState.openedFile({required uikit.FileNode node}) =
      OpenedFile;
  const factory ExplorerState.nodeExpanded(String path) = NodeExpanded;
  const factory ExplorerState.nodeCollapsed(String path) = NodeCollapsed;
  const factory ExplorerState.error({required String message, Object? error}) =
      ExplorerError;
}

class ExplorerBloc extends Bloc<ExplorerEvent, ExplorerState> {
  final core.ProjectManagerService _projectManagerService;
  final core.FileService _fileService;
  final FileSyncService _fileSyncService;
  late final StreamSubscription<core.ProjectConfig?> _projectSubscription;
  late final StreamSubscription<String> _fileDeletedSubscription;
  late final StreamSubscription<void> _fileTreeChangedSubscription;

  ExplorerBloc({
    required core.ProjectManagerService projectManagerService,
    required core.FileService fileService,
    required FileSyncService fileSyncService,
  }) : _projectManagerService = projectManagerService,
       _fileService = fileService,
       _fileSyncService = fileSyncService,
       super(const ExplorerState.initial()) {
    on<LoadFileTree>((event, emit) async {
      final result = _fileService.loadProjectTree(event.projectPath);
      result.match(
        (error) => emit(
          ExplorerState.error(message: 'Error loading file tree', error: error),
        ),
        (core.FileNode? fileTree) {
          if (fileTree != null) {
            emit(ExplorerState.fileTreeLoaded(_coreToUikit(fileTree)));
          }
        },
      );
    });

    on<OpenFile>((event, emit) async {
      emit(ExplorerState.openedFile(node: event.node));
    });

    on<ExpandNode>((event, emit) {
      emit(ExplorerState.nodeExpanded(event.path));
    });
    on<CollapseNode>((event, emit) {
      emit(ExplorerState.nodeCollapsed(event.path));
    });
    on<Refresh>((event, emit) {
      emit(const ExplorerState.initial());
    });

    // Реагируем на смену проекта, удаление или изменение структуры — подгружаем дерево
    _projectSubscription = _projectManagerService.projectStream.listen((
      config,
    ) {
      if (config != null) {
        add(ExplorerEvent.loadFileTree(config.path));
      }
    });
    _fileDeletedSubscription = _fileSyncService.fileDeletedStream.listen((_) {
      add(const Refresh());
    });
    _fileTreeChangedSubscription = _fileSyncService.fileTreeChangedStream
        .listen((_) {
          add(const Refresh());
        });
  }

  @override
  Future<void> close() {
    _projectSubscription.cancel();
    _fileDeletedSubscription.cancel();
    _fileTreeChangedSubscription.cancel();
    return super.close();
  }

  uikit.FileNode _coreToUikit(core.FileNode node) => uikit.FileNode(
    path: node.path,
    name: node.name,
    isDirectory: node.isDirectory,
    children: node.children.map(_coreToUikit).toList(),
  );
}
