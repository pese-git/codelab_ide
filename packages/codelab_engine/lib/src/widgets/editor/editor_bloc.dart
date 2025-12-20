import 'dart:async';
import 'package:cherrypick/cherrypick.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;

import '../../services/file_sync_service.dart';

part 'editor_bloc.freezed.dart';

// События EditorBloc
@freezed
abstract class EditorEvent with _$EditorEvent {
  const factory EditorEvent.openFile(String filePath, String workspacePath) =
      OpenFile;
  const factory EditorEvent.fileChanged(String filePath) = FileChanged;
  const factory EditorEvent.fileDeleted(String filePath) = FileDeleted;
  const factory EditorEvent.saveFile(uikit.EditorTab tab) = SaveFile;
}

// Состояние EditorBloc
@freezed
abstract class EditorState with _$EditorState {
  /// Initial state: nothing opened yet
  const factory EditorState.initial() = EditorInitial;

  const factory EditorState.loading() = EditorLoading;

  /// File opened successfully
  const factory EditorState.openedFile({
    required String filePath,
    required String workspacePath,
    required String content,
  }) = EditorOpenedFile;

  /// File changed (external or internal modification)
  const factory EditorState.fileChanged({
    required String filePath,
    required String content,
  }) = EditorFileChanged;

  /// File deleted
  const factory EditorState.fileDeleted({required String filePath}) =
      EditorFileDeleted;

  /// File saved successfully
  const factory EditorState.savedFile({
    required String filePath,
    required String content,
  }) = EditorSavedFile;

  /// Error state: operation failed
  const factory EditorState.error({
    required String filePath,
    required String message,
    Object? error,
  }) = EditorError;
}

// EditorBloc
class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final FileService _fileService;
  final FileSyncService _fileSyncService;
  StreamSubscription<String>? _fileOpenedSubscription;
  StreamSubscription<String>? _fileSavedSubscription;
  StreamSubscription<String>? _fileChangedSubscription;
  StreamSubscription<String>? _fileDeletedSubscription;

  EditorBloc({required FileService fileService})
    : _fileService = fileService,
      _fileSyncService = CherryPick.openRootScope().resolve<FileSyncService>(),
      super(const EditorState.initial()) {
    _setupFileSyncListeners();
    on<OpenFile>(_onOpenFile);
    on<FileChanged>(_onFileChanged);
    on<FileDeleted>(_onFileDeleted);
    on<SaveFile>(_onSaveFile);
  }

  void _setupFileSyncListeners() {
    _fileOpenedSubscription = _fileSyncService.fileOpenedStream.listen((
      filePath,
    ) {
      codelabLogger.d('EditorBloc: File opened: $filePath', tag: 'editor_bloc');
      // Можешь тут добавить обработку, если нужно реагировать на это событие
    });
    _fileSavedSubscription = _fileSyncService.fileSavedStream.listen((
      filePath,
    ) {
      codelabLogger.d('EditorBloc: File saved: $filePath', tag: 'editor_bloc');
    });
    _fileChangedSubscription = _fileSyncService.fileChangedStream.listen((
      filePath,
    ) {
      codelabLogger.d(
        'EditorBloc: File changed externally: $filePath',
        tag: 'editor_bloc',
      );
      add(EditorEvent.fileChanged(filePath));
    });
    _fileDeletedSubscription = _fileSyncService.fileDeletedStream.listen((
      filePath,
    ) {
      codelabLogger.d(
        'EditorBloc: File deleted: $filePath',
        tag: 'editor_bloc',
      );
      add(EditorEvent.fileDeleted(filePath));
    });
  }

  Future<void> _onOpenFile(OpenFile event, Emitter<EditorState> emit) async {
    codelabLogger.d(
      'EditorBloc: Opening file: ${event.filePath}',
      tag: 'editor_bloc',
    );
    emit(EditorState.loading());
    try {
      /*
      final result = await _fileService.readFile(event.filePath).run();
      result.match(
        (error) {
          codelabLogger.e(
            'EditorBloc: Error reading file: $error',
            tag: 'editor_bloc',
            error: error,
          );
          emit(
            EditorState.error(
              filePath: event.filePath,
              message: 'Error reading file',
              error: error,
            ),
          );
        },
        (content) {
          emit(
            EditorState.openedFile(
              filePath: event.filePath,
              workspacePath: event.workspacePath,
              content: content,
            ),
          );
        },
      );
      */
      emit(
        EditorState.openedFile(
          filePath: event.filePath,
          workspacePath: event.workspacePath,
          content: '',
        ),
      );
    } catch (e, s) {
      emit(
        EditorState.error(
          filePath: event.filePath,
          message: 'Exception while opening file',
          error: e,
        ),
      );
      codelabLogger.e(
        'EditorBloc: Exception opening file: $e',
        tag: 'editor_bloc',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _onFileChanged(
    FileChanged event,
    Emitter<EditorState> emit,
  ) async {
    codelabLogger.d(
      'EditorBloc: File changed externally: ${event.filePath}',
      tag: 'editor_bloc',
    );
    emit(EditorState.loading());
    final result = await _fileService.readFile(event.filePath).run();
    result.match(
      (error) => emit(
        EditorState.error(
          filePath: event.filePath,
          message: 'Error reading file after external change',
          error: error,
        ),
      ),
      (content) => emit(
        EditorState.fileChanged(filePath: event.filePath, content: content),
      ),
    );
  }

  Future<void> _onFileDeleted(
    FileDeleted event,
    Emitter<EditorState> emit,
  ) async {
    emit(EditorState.loading());
    codelabLogger.d(
      'EditorBloc: File deleted: ${event.filePath}',
      tag: 'editor_bloc',
    );
    emit(EditorState.fileDeleted(filePath: event.filePath));
  }

  Future<void> _onSaveFile(SaveFile event, Emitter<EditorState> emit) async {
    final tab = event.tab;
    codelabLogger.d(
      'EditorBloc: Saving file: ${tab.filePath}',
      tag: 'editor_bloc',
    );
    emit(EditorState.loading());
    final result = await _fileService
        .writeFile(tab.filePath, tab.content)
        .run();
    result.match(
      (error) => emit(
        EditorState.error(
          filePath: tab.filePath,
          message: 'Error saving file',
          error: error,
        ),
      ),
      (_) => emit(
        EditorState.savedFile(filePath: tab.filePath, content: tab.content),
      ),
    );
  }

  @override
  Future<void> close() {
    _fileOpenedSubscription?.cancel();
    _fileSavedSubscription?.cancel();
    _fileChangedSubscription?.cancel();
    _fileDeletedSubscription?.cancel();
    return super.close();
  }
}
