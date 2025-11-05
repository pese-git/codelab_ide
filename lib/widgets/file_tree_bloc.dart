import 'package:codelab_ide/models/file_node.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_tree_bloc.freezed.dart';

@freezed
class FileTreeEvent with _$FileTreeEvent {
  const factory FileTreeEvent.toggleExpanded(String path) = ToggleExpanded;
  const factory FileTreeEvent.selectFile(String path) = SelectFile;
  const factory FileTreeEvent.setFileTree(FileNode? fileTree) = SetFileTree;
}

@freezed
class FileTreeState with _$FileTreeState {
  const factory FileTreeState({
    @Default(<String>{}) Set<String> expandedNodes,
    String? selectedFile,
    FileNode? fileTree,
  }) = _FileTreeState;
}

class FileTreeBloc extends Bloc<FileTreeEvent, FileTreeState> {
  FileTreeBloc() : super(const FileTreeState()) {
    on<ToggleExpanded>((event, emit) {
      final expanded = Set<String>.from(state.expandedNodes);
      if (expanded.contains(event.path)) {
        expanded.remove(event.path);
      } else {
        expanded.add(event.path);
      }
      emit(state.copyWith(expandedNodes: expanded));
    });

    on<SelectFile>((event, emit) {
      emit(state.copyWith(selectedFile: event.path));
    });

    on<SetFileTree>((event, emit) {
      emit(state.copyWith(fileTree: event.fileTree));
    });
  }
}
