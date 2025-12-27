import 'dart:io';
import 'package:codelab_core/codelab_core.dart';
import 'package:path/path.dart' as p;
import '../models/tool_models.dart';

/// Сервис для выполнения tool calls на стороне IDE
class ToolExecutor {
  /// Валидатор путей
  final PathValidator _pathValidator;

  /// Максимальный размер читаемого файла (10MB)
  static const int maxReadFileSize = 10 * 1024 * 1024;

  /// Максимальный размер записываемого файла (5MB)
  static const int maxWriteFileSize = 5 * 1024 * 1024;

  ToolExecutor({required PathValidator pathValidator})
    : _pathValidator = pathValidator;

  /// Выполняет tool call и возвращает результат
  ///
  /// Маршрутизирует вызов к соответствующему методу обработки
  /// в зависимости от [toolCall.toolName].
  ///
  /// Throws [ToolExecutionException] если инструмент не поддерживается
  /// или произошла ошибка выполнения.
  Future<FileOperationResult> executeToolCall(ToolCall toolCall) async {
    try {
      switch (toolCall.toolName) {
        case 'read_file':
          return await _readFile(toolCall.arguments);
        case 'write_file':
          return await _writeFile(toolCall.arguments);
        default:
          throw ToolExecutionException(
            code: 'unsupported_tool',
            message: 'Unsupported tool: ${toolCall.toolName}',
          );
      }
    } on ToolExecutionException {
      rethrow;
    } catch (e, stackTrace) {
      throw ToolExecutionException.general(
        'Failed to execute tool ${toolCall.toolName}: $e',
        cause: stackTrace,
      );
    }
  }

  /// Выполняет операцию чтения файла
  Future<FileOperationResult> _readFile(Map<String, dynamic> arguments) async {
    try {
      // Парсинг аргументов
      final args = ReadFileArgs.fromJson(arguments);

      // Валидация пути
      final fullPath = _pathValidator.validateAndGetFullPath(args.path);

      // Проверка существования файла
      final file = File(fullPath);
      if (!await file.exists()) {
        throw ToolExecutionException.fileNotFound(args.path);
      }

      // Проверка размера файла
      final fileSize = await file.length();
      if (fileSize > maxReadFileSize) {
        throw ToolExecutionException.fileTooLarge(
          args.path,
          fileSize,
          maxReadFileSize,
        );
      }

      // Чтение файла
      String content;
      try {
        content = await file.readAsString();
      } catch (e) {
        throw ToolExecutionException.encodingError(args.path, e);
      }

      // Обработка частичного чтения (по строкам)
      int? linesRead;
      if (args.startLine != null || args.endLine != null) {
        final lines = content.split('\n');
        final startLine = (args.startLine ?? 1) - 1; // Convert to 0-based
        final endLine = (args.endLine ?? lines.length) - 1;

        // Валидация диапазона строк
        if (startLine < 0 || startLine >= lines.length) {
          throw ToolExecutionException(
            code: 'invalid_line_range',
            message: 'Invalid start_line: ${args.startLine}',
          );
        }
        if (endLine < startLine || endLine >= lines.length) {
          throw ToolExecutionException(
            code: 'invalid_line_range',
            message: 'Invalid end_line: ${args.endLine}',
          );
        }

        final selectedLines = lines.sublist(startLine, endLine + 1);
        content = selectedLines.join('\n');
        linesRead = selectedLines.length;
      } else {
        linesRead = content.split('\n').length;
      }

      return FileOperationResult.readSuccess(
        content: content,
        linesRead: linesRead,
      );
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      throw ToolExecutionException.invalidPath(
        arguments['path'] ?? 'unknown',
        e.message,
      );
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        // Permission denied
        throw ToolExecutionException.permissionDenied(
          arguments['path'] ?? 'unknown',
        );
      }
      throw ToolExecutionException.general(
        'File system error: ${e.message}',
        cause: e,
      );
    } catch (e, stackTrace) {
      throw ToolExecutionException.general(
        'Failed to read file: $e',
        cause: stackTrace,
      );
    }
  }

  /// Выполняет операцию записи файла
  Future<FileOperationResult> _writeFile(Map<String, dynamic> arguments) async {
    try {
      // Парсинг аргументов
      final args = WriteFileArgs.fromJson(arguments);

      // Проверка размера контента
      final contentBytes = args.content.length;
      if (contentBytes > maxWriteFileSize) {
        throw ToolExecutionException.fileTooLarge(
          args.path,
          contentBytes,
          maxWriteFileSize,
        );
      }

      // Валидация пути
      final fullPath = _pathValidator.validateAndGetFullPath(args.path);

      final file = File(fullPath);
      final fileExists = await file.exists();

      // Создание директорий если необходимо
      if (args.createDirs) {
        final dir = Directory(p.dirname(fullPath));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        // Проверка существования родительской директории
        final dir = Directory(p.dirname(fullPath));
        if (!await dir.exists()) {
          throw ToolExecutionException(
            code: 'directory_not_found',
            message: 'Parent directory does not exist: ${p.dirname(args.path)}',
          );
        }
      }

      // Создание резервной копии если файл существует и backup=true
      String? backupPath;
      if (fileExists && args.backup) {
        backupPath = await _createBackup(file);
      }

      // Запись файла
      try {
        await file.writeAsString(args.content);
      } catch (e) {
        // Восстановление из резервной копии при ошибке
        if (backupPath != null) {
          await _restoreFromBackup(backupPath, fullPath);
        }
        throw ToolExecutionException.encodingError(args.path, e);
      }

      final bytesWritten = contentBytes;

      return FileOperationResult.writeSuccess(
        bytesWritten: bytesWritten,
        backupPath: backupPath != null
            ? p.relative(backupPath, from: _pathValidator.workspaceRoot)
            : null,
      );
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      throw ToolExecutionException.invalidPath(
        arguments['path'] ?? 'unknown',
        e.message,
      );
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        // Permission denied
        throw ToolExecutionException.permissionDenied(
          arguments['path'] ?? 'unknown',
        );
      }
      throw ToolExecutionException.general(
        'File system error: ${e.message}',
        cause: e,
      );
    } catch (e, stackTrace) {
      throw ToolExecutionException.general(
        'Failed to write file: $e',
        cause: stackTrace,
      );
    }
  }

  /// Создает резервную копию файла
  ///
  /// Возвращает путь к резервной копии.
  Future<String> _createBackup(File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${file.path}.backup.$timestamp';
    await file.copy(backupPath);
    return backupPath;
  }

  /// Восстанавливает файл из резервной копии
  Future<void> _restoreFromBackup(
    String backupPath,
    String originalPath,
  ) async {
    try {
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.copy(originalPath);
        await backupFile.delete();
      }
    } catch (e) {
      // Логируем ошибку, но не выбрасываем исключение
      // так как основная операция уже провалилась
      print('Failed to restore from backup: $e');
    }
  }
}
