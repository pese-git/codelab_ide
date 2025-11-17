import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_bloc.freezed.dart';

@freezed
class EditorEvent with _$EditorEvent {
  /// Задать новый файл и его содержимое
  const factory EditorEvent.setFile({
    required String filePath,
    required String content,
  }) = SetFile;

  /// Обновить контент (ручное редактирование)
  const factory EditorEvent.updateContent(String content) = UpdateContent;

  /// Сохранить файл
  const factory EditorEvent.save() = SaveContent;
}

@freezed
abstract class EditorState with _$EditorState {
  const factory EditorState({
    required String filePath,
    required String content,
    @Default(false) bool isDirty,
    @Default(false) bool isSaving,
  }) = _EditorState;

  factory EditorState.initial() => const EditorState(
    filePath: '',
    content: '',
    isDirty: false,
    isSaving: false,
  );
}

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  EditorBloc() : super(EditorState.initial()) {
    on<SetFile>((event, emit) {
      emit(
        EditorState(
          filePath: event.filePath,
          content: event.content,
          isDirty: false,
          isSaving: false,
        ),
      );
    });

    on<UpdateContent>((event, emit) {
      emit(state.copyWith(content: event.content, isDirty: true));
    });

    on<SaveContent>((event, emit) async {
      emit(state.copyWith(isSaving: true));
      // Здесь реализовать логику сохранения файла (например, через FileService)
      // Предполагается success, потом:
      emit(state.copyWith(isSaving: false, isDirty: false));
    });
  }
}
