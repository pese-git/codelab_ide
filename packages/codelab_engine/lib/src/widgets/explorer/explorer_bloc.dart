import 'dart:async';

import 'package:codelab_core/codelab_core.dart' as core;
import 'package:codelab_engine/codelab_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit show FileNode;

part 'explorer_bloc.freezed.dart';

@freezed
class ExplorerEvent with _$ExplorerEvent {
  const factory ExplorerEvent.toggleExpanded(String path) = ToggleExpanded;
  const factory ExplorerEvent.selectFile(String path) = SelectFile;
  const factory ExplorerEvent.setFileTree(
    String projectPath,
    uikit.FileNode? fileTree,
  ) = SetFileTree;
  const factory ExplorerEvent.refreshFileTree() = RefreshFileTree;
}

@freezed
abstract class ExplorerState with _$ExplorerState {
  const factory ExplorerState({
    @Default(<String>{}) Set<String> expandedNodes,
    String? projectPath,
    String? selectedFile,
    String? selectedContent,
    uikit.FileNode? fileTree,
  }) = _ExplorerState;
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
       super(const ExplorerState()) {
    // Обработка изменения раскрытых узлов
    on<ToggleExpanded>((event, emit) {
      // Передаем в новый Set состояние, чтобы не мутировать старый
      final expanded = Set<String>.from(state.expandedNodes);
      if (expanded.contains(event.path)) {
        expanded.remove(event.path);
      } else {
        expanded.add(event.path);
      }
      emit(state.copyWith(expandedNodes: expanded));
    });

    // Обработка выбора файла: читаем контент и обновляем состояние
    on<SelectFile>((event, emit) async {
      emit(
        state.copyWith(selectedFile: event.path, selectedContent: null),
      ); // Сразу сбрасываем контент до обновления
      final result = await _fileService.readFile(event.path).run();
      result.match(
        (error) => emit(
          state.copyWith(
            selectedFile: event.path,
            selectedContent: '// Ошибка чтения файла: $error',
          ),
        ),
        (realContent) => emit(
          state.copyWith(
            selectedFile: event.path,
            selectedContent: realContent,
          ),
        ),
      );
    });

    // Обработка смены/установки дерева — сбрасываем раскрытые узлы и выбранный файл
    on<SetFileTree>((event, emit) {
      emit(
        state.copyWith(
          projectPath: event.projectPath,
          fileTree: event.fileTree,
          expandedNodes: <String>{},
          selectedFile: null,
          selectedContent: null,
        ),
      );
    });

    // Обработка обновления дерева файлов
    on<RefreshFileTree>((event, emit) {
      if (state.projectPath != null && state.projectPath!.isNotEmpty) {
        _loadFileTree(state.projectPath!);
      }
    });

    // Слушаем смену проекта — пересоздаем дерево файлов
    _projectSubscription = _projectManagerService.projectStream.listen((
      config,
    ) {
      if (config == null) {
        add(const ExplorerEvent.setFileTree('', null));
        return;
      }
      _loadFileTree(config.path);
    });

    // Слушаем события удаления файлов
    _fileDeletedSubscription = _fileSyncService.fileDeletedStream.listen((filePath) {
      add(const ExplorerEvent.refreshFileTree());
    });

    // Слушаем события изменения дерева файлов
    _fileTreeChangedSubscription = _fileSyncService.fileTreeChangedStream.listen((_) {
      add(const ExplorerEvent.refreshFileTree());
    });
  }

  /// Загружает дерево файлов для указанного пути проекта
  void _loadFileTree(String projectPath) {
    final fileTreeResult = _fileService.loadProjectTree(projectPath);
    fileTreeResult.match(
      (error) {
        // В случае ошибки – можно логировать
        codelabLogger.e('Error loading file tree', tag: 'explorer_bloc', error: error);
      },
      (core.FileNode? fileTree) {
        if (fileTree == null) {
          add(ExplorerEvent.setFileTree(projectPath, null));
          return;
        }
        // Рекурсивная конвертация дерева core → uikit
        uikit.FileNode convert(core.FileNode node) => uikit.FileNode(
          path: node.path,
          name: node.name,
          isDirectory: node.isDirectory,
          children: node.children.map(convert).toList(),
        );
        final resultMap = convert(fileTree);
        add(ExplorerEvent.setFileTree(projectPath, resultMap));
      },
    );
  }

  @override
  Future<void> close() {
    _projectSubscription.cancel();
    _fileDeletedSubscription.cancel();
    _fileTreeChangedSubscription.cancel();
    return super.close();
  }
}