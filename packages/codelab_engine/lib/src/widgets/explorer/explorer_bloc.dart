import 'dart:async';

import 'package:codelab_core/codelab_core.dart' as core;
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late final StreamSubscription<core.ProjectConfig?> _projectSubscription;

  ExplorerBloc({
    required core.ProjectManagerService projectManagerService,
    required core.FileService fileService,
  }) : _projectManagerService = projectManagerService,
       _fileService = fileService,
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

    // Слушаем смену проекта — пересоздаем дерево файлов
    _projectSubscription = _projectManagerService.projectStream.listen((
      config,
    ) {
      if (config == null) {
        add(const ExplorerEvent.setFileTree('', null));
        return;
      }
      final fileTreeResult = _fileService.loadProjectTree(config.path);
      fileTreeResult.match(
        (_) {}, // В случае ошибки – можно логировать, если нужно
        (core.FileNode? fileTree) {
          if (fileTree == null) {
            add(ExplorerEvent.setFileTree(config.path, null));
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
          add(ExplorerEvent.setFileTree(config.path, resultMap));
        },
      );
    });
  }

  @override
  Future<void> close() {
    _projectSubscription.cancel();
    return super.close();
  }
}
