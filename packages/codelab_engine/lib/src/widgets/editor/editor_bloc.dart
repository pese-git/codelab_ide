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
}

// Состояние EditorBloc
@freezed
abstract class EditorState with _$EditorState {
  const factory EditorState({
    @Default([]) List<uikit.EditorTab> openTabs,
    @Default('') String activeTab,
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
  }

  void _setupFileSyncListeners() {
    // Слушаем события открытия файлов
    _fileOpenedSubscription = _fileSyncService.fileOpenedStream.listen((
      filePath,
    ) {
      print('EditorBloc: File opened: $filePath');
      // TODO: Открыть файл в редакторе через EditorManagerService
    });

    // Слушаем события сохранения файлов
    _fileSavedSubscription = _fileSyncService.fileSavedStream.listen((
      filePath,
    ) {
      print('EditorBloc: File saved: $filePath');
      // TODO: Обновить состояние вкладки
    });

    // Слушаем события изменения файлов
    _fileChangedSubscription = _fileSyncService.fileChangedStream.listen((
      filePath,
    ) {
      print('EditorBloc: File changed externally: $filePath');
      add(EditorEvent.fileChanged(filePath));
    });

    // Слушаем события удаления файлов
    _fileDeletedSubscription = _fileSyncService.fileDeletedStream.listen((
      filePath,
    ) {
      print('EditorBloc: File deleted: $filePath');
      add(EditorEvent.fileDeleted(filePath));
    });
  }

  // Обработка открытия файла
  Future<void> _onOpenFile(OpenFile event, Emitter<EditorState> emit) async {
    print('EditorBloc: Opening file: ${event.filePath}');

    try {
      final result = await _fileService.readFile(event.filePath).run();

      result.match(
        (error) {
          print('EditorBloc: Error reading file: $error');
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
            emit(
              state.copyWith(openTabs: updatedTabs, activeTab: event.filePath),
            );
          } else {
            // Файл уже открыт - переключаемся на него
            emit(state.copyWith(activeTab: event.filePath));
          }
        },
      );
    } catch (e, s) {
      codelabLogger.e('EditorBloc: Exception opening file: $e', tag: 'editor_bloc', error: e, stackTrace: s);
    }
  }

  // Обработка изменения файла
  Future<void> _onFileChanged(
    FileChanged event,
    Emitter<EditorState> emit,
  ) async {
    print('EditorBloc: File changed externally: ${event.filePath}');

    // TODO: Обновить содержимое вкладки если файл открыт
    // TODO: Показать уведомление пользователю
  }

  // Обработка удаления файла
  Future<void> _onFileDeleted(
    FileDeleted event,
    Emitter<EditorState> emit,
  ) async {
    print('EditorBloc: File deleted: ${event.filePath}');

    // Убираем вкладку если файл был удален
    final updatedTabs = state.openTabs
        .where((tab) => tab.id != event.filePath)
        .toList();

    emit(
      state.copyWith(
        openTabs: updatedTabs,
        activeTab: state.activeTab == event.filePath ? '' : state.activeTab,
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
