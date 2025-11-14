import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/file_node.dart';

part 'file_manager_bloc.freezed.dart';

@freezed
abstract class OpenFileTab with _$OpenFileTab {
  const factory OpenFileTab({
    required String path,
    required String title,
    required String content,
    @Default(false) bool isDirty,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _OpenFileTab;
}

@freezed
class FileManagerEvent with _$FileManagerEvent {
  const factory FileManagerEvent.openFile({
    required String path,
    String? initialContent,
  }) = OpenFile;
  const factory FileManagerEvent.editFile({
    required String path,
    required String newContent,
  }) = EditFile;
  const factory FileManagerEvent.saveFile({required String path}) = SaveFile;
  const factory FileManagerEvent.closeFile({required String path}) = CloseFile;
  const factory FileManagerEvent.loadFileTree({required String rootPath}) =
      LoadFileTree;
  const factory FileManagerEvent.setFileTree({required FileNode tree}) =
      SetFileTree;
}

@freezed
abstract class FileManagerState with _$FileManagerState {
  const factory FileManagerState({
    required FileNode? fileTree,
    @Default(<String, OpenFileTab>{}) Map<String, OpenFileTab> openTabs,
    String? activePath,
    String? errorMessage,
    @Default(false) bool isLoadingTree,
  }) = _FileManagerState;

  factory FileManagerState.initial() => const FileManagerState(fileTree: null);
}

class FileManagerBloc extends Bloc<FileManagerEvent, FileManagerState> {
  FileManagerBloc() : super(FileManagerState.initial()) {
    on<LoadFileTree>(_onLoadFileTree);
    on<SetFileTree>(_onSetFileTree);
    on<OpenFile>(_onOpenFile);
    on<EditFile>(_onEditFile);
    on<SaveFile>(_onSaveFile);
    on<CloseFile>(_onCloseFile);
  }

  // TODO: Implement interaction with FileService (read/write)

  void _onLoadFileTree(LoadFileTree event, Emitter<FileManagerState> emit) {
    // Заглушка: загрузить дерево файлов
    emit(state.copyWith(isLoadingTree: true, errorMessage: null));
    // Дальнейшая интеграция с сервисом...
  }

  void _onSetFileTree(SetFileTree event, Emitter<FileManagerState> emit) {
    emit(state.copyWith(fileTree: event.tree, isLoadingTree: false));
  }

  void _onOpenFile(OpenFile event, Emitter<FileManagerState> emit) {
    final existingTab = state.openTabs[event.path];
    if (existingTab != null) {
      emit(state.copyWith(activePath: event.path));
      return;
    }
    // Здесь должен быть асинхронный FileService для чтения содержимого
    final newTab = OpenFileTab(
      path: event.path,
      title: event.path.split('/').last,
      content: event.initialContent ?? '// TODO: load content',
    );
    emit(
      state.copyWith(
        openTabs: {...state.openTabs, event.path: newTab},
        activePath: event.path,
      ),
    );
  }

  void _onEditFile(EditFile event, Emitter<FileManagerState> emit) {
    final tab = state.openTabs[event.path];
    if (tab != null) {
      emit(
        state.copyWith(
          openTabs: {
            ...state.openTabs,
            event.path: tab.copyWith(content: event.newContent, isDirty: true),
          },
        ),
      );
    }
  }

  void _onSaveFile(SaveFile event, Emitter<FileManagerState> emit) {
    final tab = state.openTabs[event.path];
    if (tab != null) {
      // TODO: вызвать FileService.write(); далее on complete:
      emit(
        state.copyWith(
          openTabs: {
            ...state.openTabs,
            event.path: tab.copyWith(isDirty: false, isSaving: false),
          },
        ),
      );
    }
  }

  void _onCloseFile(CloseFile event, Emitter<FileManagerState> emit) {
    final newTabs = Map<String, OpenFileTab>.from(state.openTabs);
    newTabs.remove(event.path);
    emit(
      state.copyWith(
        openTabs: newTabs,
        activePath: state.activePath == event.path ? null : state.activePath,
      ),
    );
  }
}
