
/// Базовый класс для всех ошибок приложения
abstract class AppError implements Exception {
  final String message;
  final Object? cause;

  const AppError(this.message, {this.cause});

  @override
  String toString() => cause != null 
    ? '$message (cause: $cause)' 
    : message;
}

/// Ошибки работы с файлами
class FileError extends AppError {
  const FileError(super.message, {super.cause});

  factory FileError.directoryNotFound(String path) => 
    FileError('Directory not found: $path');

  factory FileError.fileNotFound(String path) => 
    FileError('File not found: $path');

  factory FileError.permissionDenied(String path) => 
    FileError('Permission denied for: $path');

  factory FileError.readError(String path, Object cause) => 
    FileError('Failed to read file: $path', cause: cause);

  factory FileError.writeError(String path, Object cause) => 
    FileError('Failed to write file: $path', cause: cause);

  factory FileError.pickDirectoryError(Object cause) => 
    FileError('Failed to pick directory', cause: cause);
}

/// Ошибки выполнения команд
class CommandError extends AppError {
  final int? exitCode;

  const CommandError(super.message, {this.exitCode, super.cause});

  factory CommandError.executionFailed(String command, int exitCode, String stderr) => 
    CommandError(
      'Command failed: $command (exit code: $exitCode)',
      exitCode: exitCode,
      cause: stderr,
    );

  factory CommandError.processError(String command, Object cause) => 
    CommandError('Failed to execute command: $command', cause: cause);

  factory CommandError.unsupportedFileType(String extension) => 
    CommandError('Unsupported file type: .$extension');
}

/// Ошибки состояния приложения
class StateError extends AppError {
  const StateError(super.message, {super.cause});

  factory StateError.projectNotLoaded() => 
    StateError('No project loaded');

  factory StateError.fileNotSelected() => 
    StateError('No file selected');

  factory StateError.invalidState(String details) => 
    StateError('Invalid application state: $details');
}


