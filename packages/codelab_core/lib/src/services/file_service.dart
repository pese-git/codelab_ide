import 'dart:io';
import 'package:codelab_core/codelab_core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:file_picker/file_picker.dart';

abstract interface class FileService {
  TaskEither<FileError, String?> pickProjectDirectory();
  Either<FileError, FileNode?> loadProjectTree(String projectPath);
  TaskEither<FileError, String> readFile(String filePath);
  TaskEither<FileError, bool> writeFile(String filePath, String content);
  String getFileExtension(String fileName);
}

class FileServiceImpl extends FileService {
  @override
  TaskEither<FileError, String?> pickProjectDirectory() {
    return TaskEither<FileError, String?>.tryCatch(
      () async {
        final selectedDirectory = await FilePicker.platform.getDirectoryPath();
        return selectedDirectory;
      },
      (error, stackTrace) => FileError.pickDirectoryError(error),
    );
  }

  @override
  Either<FileError, FileNode?> loadProjectTree(String projectPath) {
    return Either.tryCatch(
      () {
        final directory = Directory(projectPath);
        if (!directory.existsSync()) {
          throw FileError.directoryNotFound(projectPath);
        }
        return FileNode.fromDirectory(directory);
      },
      (error, stackTrace) {
        if (error is FileError) return error;
        return FileError('Failed to load project tree: $error', cause: stackTrace);
      },
    );
  }

  @override
  TaskEither<FileError, String> readFile(String filePath) {
    return TaskEither<FileError, String>.tryCatch(
      () async {
        final file = File(filePath);
        if (!await file.exists()) {
          throw FileError.fileNotFound(filePath);
        }
        return await file.readAsString();
      },
      (error, stackTrace) {
        if (error is FileError) return error;
        return FileError.readError(filePath, error);
      },
    );
  }

  @override
  TaskEither<FileError, bool> writeFile(String filePath, String content) {
    return TaskEither<FileError, bool>.tryCatch(
      () async {
        final file = File(filePath);
        await file.writeAsString(content);
        return true;
      },
      (error, stackTrace) {
        if (error is FileError) return error;
        return FileError.writeError(filePath, error);
      },
    );
  }

  @override
  String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
