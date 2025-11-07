import 'package:codelab_engine/codelab_engine.dart';
import 'package:codelab_engine/src/models/file_node.dart';
import 'package:codelab_engine/src/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_bloc.freezed.dart';

@freezed
class ProjectEvent with _$ProjectEvent {
  const factory ProjectEvent.openProject() = OpenProject;
  const factory ProjectEvent.runProject() = RunProject;
  const factory ProjectEvent.setFileTree(FileNode fileTree) = SetFileTree;
  const factory ProjectEvent.selectFile(String filePath) = SelectFile;
  const factory ProjectEvent.loadFileContent(String filePath) = LoadFileContent;
  const factory ProjectEvent.updateFileContent(String content) =
      UpdateFileContent;
  const factory ProjectEvent.saveCurrentFile({
    required String currentFile,
    required String fileContent,
  }) = SaveCurrentFile;
}

@freezed
class ProjectState with _$ProjectState {
  const factory ProjectState({
    String? projectPath,
    FileNode? fileTree,
    String? currentFile,
    String? loadedFile,
    @Default('') String fileContent,
    @Default(false) bool isLoading,
    String? error,
    @Default(false) bool isSaving,
    @Default(false) bool saveSuccess,
  }) = _ProjectState;

  factory ProjectState.initial() => const ProjectState(fileContent: '');
}

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final FileService _fileService;
  final RunService _runService;

  ProjectBloc({required FileService fileService, required RunService runService})
    : _fileService = fileService,
    _runService = runService,
      super(ProjectState.initial()) {
    on<OpenProject>((event, emit) async {
      emit(state.copyWith(isLoading: true, error: null, saveSuccess: false));
      try {
        final projectPath = await fileService.pickProjectDirectory();
        final fileTree = _fileService.loadProjectTree(projectPath!);
        emit(
          state.copyWith(
            projectPath: projectPath,
            fileTree: fileTree,
            currentFile: null,
            fileContent: '',
            isLoading: false,
            error: null,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(isLoading: false, error: 'Failed to open project: $e'),
        );
      }
    });

    on<RunProject>((event, emit) {
      emit(state.copyWith(isLoading: true));
      try {
        final command = _runService.getRunCommand(state.currentFile!);

        logger.i("Command: $command");
          emit(
          state.copyWith(
            isLoading: false,
  
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(isLoading: false, error: 'Failed to open project: $e'),
        );
      }
    });

    on<SetFileTree>((event, emit) {
      emit(state.copyWith(fileTree: event.fileTree));
    });

    on<SelectFile>((event, emit) async {
      // 1. Сначала фиксируем выбранный файл
      emit(
        state.copyWith(
          isLoading: true,
          error: null,
          currentFile: event.filePath,
        ),
      );
      try {
        final content = await _fileService.readFile(event.filePath);

        // 2. После await состояние блока могло измениться — используем последнее:
        final latestState = state;

        // ТОЛЬКО если пользователь всё ещё ждёт этот файл:
        if (latestState.currentFile == event.filePath) {
          emit(
            latestState.copyWith(
              fileContent: content,
              loadedFile: event.filePath,
              isLoading: false,
            ),
          );
        } else {
          // Пользователь уже выбрал другой файл — не меняем content
          emit(latestState.copyWith(isLoading: false));
        }
      } catch (e) {
        emit(
          state.copyWith(isLoading: false, error: 'Failed to open file: $e'),
        );
      }
    });

    on<LoadFileContent>((event, emit) async {
      emit(state.copyWith(isLoading: true, error: null));
      try {
        final content = await _fileService.readFile(event.filePath);
        emit(state.copyWith(fileContent: content, isLoading: false));
      } catch (e) {
        emit(
          state.copyWith(isLoading: false, error: 'Failed to read file: $e'),
        );
      }
    });

    on<UpdateFileContent>((event, emit) {
      emit(state.copyWith(fileContent: event.content, saveSuccess: false));
    });

    on<SaveCurrentFile>((SaveCurrentFile event, emit) async {
      if (state.currentFile == null) return;
      emit(state.copyWith(isSaving: true, saveSuccess: false));
      try {
        final success = await _fileService.writeFile(
          event.currentFile,
          event.fileContent,
        );
        emit(state.copyWith(isSaving: false, saveSuccess: success));
      } catch (e) {
        emit(
          state.copyWith(
            isSaving: false,
            error: 'Failed to save file: $e',
            saveSuccess: false,
          ),
        );
      }
    });
  }
}
