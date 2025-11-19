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
  const factory EditorEvent.openFile(String filePath) = OpenFile;
  const factory EditorEvent.fileChanged(String filePath) = FileChanged;
  const factory EditorEvent.fileDeleted(String filePath) = FileDeleted;
  const factory EditorEvent.saveFile(uikit.EditorTab tab) = SaveFile;
}

// Состояние EditorBloc
@freezed
abstract class EditorState with _$EditorState {
  const factory EditorState({
    @Default([]) List<uikit.EditorTab> openTabs,
    uikit.EditorTab? activeTab,
  }) = _EditorState;
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
      super(const EditorState()) {
    _setupFileSyncListeners();

    // Обработчики событий
    on<OpenFile>(_onOpenFile);
    on<FileChanged>(_onFileChanged);
    on<FileDeleted>(_onFileDeleted);
    on<SaveFile>(_onSaveFile);
  }

  void _setupFileSyncListeners() {
    // Слушаем события открытия файлов
    _fileOpenedSubscription = _fileSyncService.fileOpenedStream.listen((
      filePath,
    ) {
      codelabLogger.d('EditorBloc: File opened: $filePath', tag: 'editor_bloc');
      // TODO: Открыть файл в редакторе через EditorManagerService
    });

    // Слушаем события сохранения файлов
    _fileSavedSubscription = _fileSyncService.fileSavedStream.listen((
      filePath,
    ) {
      codelabLogger.d('EditorBloc: File saved: $filePath', tag: 'editor_bloc');
      // TODO: Обновить состояние вкладки
    });

    // Слушаем события изменения файлов
    _fileChangedSubscription = _fileSyncService.fileChangedStream.listen((
      filePath,
    ) {
      codelabLogger.d(
        'EditorBloc: File changed externally: $filePath',
        tag: 'editor_bloc',
      );
      add(EditorEvent.fileChanged(filePath));
    });

    // Слушаем события удаления файлов
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

  // Обработка открытия файла
  Future<void> _onOpenFile(OpenFile event, Emitter<EditorState> emit) async {
    codelabLogger.d(
      'EditorBloc: Opening file: ${event.filePath}',
      tag: 'editor_bloc',
    );

    try {
      final result = await _fileService.readFile(event.filePath).run();

      result.match(
        (error) {
          codelabLogger.e(
            'EditorBloc: Error reading file: $error',
            tag: 'editor_bloc',
            error: error,
          );
        },
        (content) {
          // Проверяем, не открыт ли файл уже
          uikit.EditorTab? existingTab;
          for (final tab in state.openTabs) {
            if (tab.filePath == event.filePath) {
              existingTab = tab;
              break;
            }
          }

          if (existingTab == null) {
            // Создаем новую вкладку
            final newTab = uikit.EditorTab(
              id: event.filePath,
              title: event.filePath.split('/').last,
              filePath: event.filePath,
              content: content,
            );

            final updatedTabs = [...state.openTabs, newTab];
            emit(state.copyWith(openTabs: updatedTabs, activeTab: newTab));
          } else {
            // Файл уже открыт - переключаемся на него
            emit(state.copyWith(activeTab: existingTab));
          }
        },
      );
    } catch (e, s) {
      codelabLogger.e(
        'EditorBloc: Exception opening file: $e',
        tag: 'editor_bloc',
        error: e,
        stackTrace: s,
      );
    }
  }

  // Обработка изменения файла
  Future<void> _onFileChanged(
    FileChanged event,
    Emitter<EditorState> emit,
  ) async {
    codelabLogger.d(
      'EditorBloc: File changed externally: ${event.filePath}',
      tag: 'editor_bloc',
    );

    // TODO: Обновить содержимое вкладки если файл открыт
    // TODO: Показать уведомление пользователю
  }

  // Обработка удаления файла
  Future<void> _onFileDeleted(
    FileDeleted event,
    Emitter<EditorState> emit,
  ) async {
    codelabLogger.d(
      'EditorBloc: File deleted: ${event.filePath}',
      tag: 'editor_bloc',
    );

    // Убираем вкладку если файл был удален
    final updatedTabs = state.openTabs
        .where((tab) => tab.id != event.filePath)
        .toList();

    emit(state.copyWith(openTabs: updatedTabs, activeTab: null));
  }

  // Обработка сохранения файла
  Future<void> _onSaveFile(SaveFile event, Emitter<EditorState> emit) async {
    final tab = event.tab;
    codelabLogger.d(
      'EditorBloc: Saving file: ${tab.filePath}',
      tag: 'editor_bloc',
    );
    final result = await _fileService
        .writeFile(tab.filePath, tab.content)
        .run();
    result.match(
      (err) {
        // Здесь можно добавить показ ошибки пользователю
        codelabLogger.e(
          'EditorBloc: Ошибка сохранения файла: $err',
          tag: 'editor_bloc',
          error: err,
        );
      },
      (_) {
        // После успешного сохранения сбрасываем dirty-метку
        final updatedTabs = state.openTabs.map((t) {
          if (t.id == tab.id) {
            return t.copyWith(isDirty: false);
          }
          return t;
        }).toList();
        emit(state.copyWith(openTabs: updatedTabs));
        codelabLogger.d(
          'EditorBloc: Файл успешно сохранён: ${tab.filePath}',
          tag: 'editor_bloc',
        );
      },
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
