import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;

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

  EditorBloc({required FileService fileService})
    : _fileService = fileService,
      super(const EditorState()) {
    // Обработчики событий
    on<EditorEvent>((event, emit) async {
      await event.map(
        openFile: (event) => _onOpenFile(event, emit),
        fileChanged: (event) => _onFileChanged(event, emit),
        fileDeleted: (event) => _onFileDeleted(event, emit),
      );
    });
  }

  // Обработка открытия файла
  Future<void> _onOpenFile(OpenFile event, Emitter<EditorState> emit) async {
    print('EditorBloc: Opening file ${event.filePath}');

    // Проверяем, не открыт ли файл уже
    if (state.openTabs.any((tab) => tab.id == event.filePath)) {
      print('EditorBloc: File already open, switching to tab');
      emit(state.copyWith(activeTab: event.filePath));
      return;
    }

    // Читаем содержимое файла
    final readResult = await _fileService.readFile(event.filePath).run();

    await readResult.match(
      (error) {
        print('EditorBloc: Error reading file: $error');
        // Создаем вкладку с сообщением об ошибке
        final errorTab = uikit.EditorTab(
          id: event.filePath,
          title: event.filePath.split('/').last,
          content: '// Ошибка чтения файла: $error',
          filePath: '',
        );

        emit(
          state.copyWith(
            openTabs: [...state.openTabs, errorTab],
            activeTab: event.filePath,
          ),
        );
      },
      (content) async {
        print('EditorBloc: File read successfully, length: ${content.length}');

        // Создаем новую вкладку
        final newTab = uikit.EditorTab(
          id: event.filePath,
          title: event.filePath.split('/').last,
          content: content,
          filePath: '',
        );

        // Добавляем вкладку к существующим
        final updatedTabs = [...state.openTabs, newTab];

        emit(state.copyWith(openTabs: updatedTabs, activeTab: event.filePath));
      },
    );
  }

  // Обработка внешних изменений файла
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
}
