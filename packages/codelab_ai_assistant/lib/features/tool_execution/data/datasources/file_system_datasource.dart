// Data source для работы с файловой системой
import 'dart:io';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:cherrypick/cherrypick.dart';
import '../../../../core/error/exceptions.dart';

/// Модель элемента файловой системы
class FileItemModel {
  final String name;
  final String path;
  final String type;
  final int? size;
  final DateTime? modified;
  
  FileItemModel({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.modified,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'type': type,
    if (size != null) 'size': size,
    if (modified != null) 'modified': modified!.toIso8601String(),
  };
}

/// Модель совпадения при поиске
class SearchMatchModel {
  final String file;
  final int line;
  final int column;
  final String matchedText;
  final String lineContent;
  
  SearchMatchModel({
    required this.file,
    required this.line,
    required this.column,
    required this.matchedText,
    required this.lineContent,
  });
  
  Map<String, dynamic> toJson() => {
    'file': file,
    'line': line,
    'column': column,
    'matched_text': matchedText,
    'line_content': lineContent,
  };
}

/// Интерфейс для data source работы с файловой системой
abstract class FileSystemDataSource {
  Future<String> readFile(String path);
  Future<Option<String>> writeFile({
    required String path,
    required String content,
    bool createDirs = false,
    bool backup = true,
  });
  Future<List<FileItemModel>> listFiles({
    required String path,
    bool recursive = false,
    bool includeHidden = false,
    String? pattern,
  });
  Future<Option<bool>> createDirectory({
    required String path,
    bool recursive = true,
  });
  Future<Map<String, dynamic>> runCommand({
    required String command,
    String cwd = '.',
    int timeout = 60,
    bool shell = false,
  });
  Future<List<SearchMatchModel>> searchInCode({
    required String query,
    String path = '.',
    String? filePattern,
    bool caseSensitive = false,
    bool regex = false,
    int maxResults = 100,
  });
  String getWorkspaceRoot();
}

/// Реализация FileSystemDataSource
class FileSystemDataSourceImpl implements FileSystemDataSource {
  static const int maxReadFileSize = 10 * 1024 * 1024;
  static const int maxWriteFileSize = 5 * 1024 * 1024;
  
  @override
  String getWorkspaceRoot() {
    try {
      final projectManager = CherryPick.openRootScope()
          .resolve<ProjectManagerService>();
      final project = projectManager.currentProject;
      if (project != null) return project.path;
    } catch (e) {
      // Fallback
    }
    return Directory.current.path;
  }
  
  PathValidator _getPathValidator() {
    return PathValidator(workspaceRoot: getWorkspaceRoot());
  }
  
  @override
  Future<String> readFile(String path) async {
    try {
      final validator = _getPathValidator();
      final fullPath = validator.validateAndGetFullPath(path);
      
      final file = File(fullPath);
      if (!await file.exists()) {
        throw ToolExecutionException(
          code: 'file_not_found',
          message: 'File not found: $path',
        );
      }
      
      final fileSize = await file.length();
      if (fileSize > maxReadFileSize) {
        throw ToolExecutionException(
          code: 'file_too_large',
          message: 'File too large: $fileSize bytes',
        );
      }
      
      return await file.readAsString();
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      throw ToolExecutionException(
        code: 'invalid_path',
        message: e.message,
      );
    }
  }
  
  @override
  Future<Option<String>> writeFile({
    required String path,
    required String content,
    bool createDirs = false,
    bool backup = true,
  }) async {
    try {
      final validator = _getPathValidator();
      final fullPath = validator.validateAndGetFullPath(path);
      
      final file = File(fullPath);
      
      if (createDirs) {
        final dir = Directory(p.dirname(fullPath));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
      
      Option<String> backupPath = none();
      if (await file.exists() && backup) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupFullPath = '$fullPath.backup.$timestamp';
        await file.copy(backupFullPath);
        backupPath = some(p.relative(backupFullPath, from: validator.workspaceRoot));
      }
      
      await file.writeAsString(content);
      return backupPath;
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      throw ToolExecutionException(code: 'invalid_path', message: e.message);
    }
  }
  
  @override
  Future<List<FileItemModel>> listFiles({
    required String path,
    bool recursive = false,
    bool includeHidden = false,
    String? pattern,
  }) async {
    try {
      final validator = _getPathValidator();
      final fullPath = validator.validateAndGetFullPath(path);
      
      final directory = Directory(fullPath);
      if (!await directory.exists()) {
        throw ToolExecutionException(
          code: 'directory_not_found',
          message: 'Directory not found: $path',
        );
      }
      
      final items = <FileItemModel>[];
      final glob = pattern != null ? Glob(pattern) : null;
      
      await for (final entity in directory.list(recursive: recursive)) {
        final relativePath = p.relative(entity.path, from: validator.workspaceRoot);
        final name = p.basename(entity.path);
        
        if (!includeHidden && name.startsWith('.')) continue;
        if (glob != null && !glob.matches(relativePath)) continue;
        
        final stat = await entity.stat();
        
        items.add(FileItemModel(
          name: name,
          path: relativePath,
          type: entity is Directory ? 'directory' : 'file',
          size: entity is File ? stat.size : null,
          modified: stat.modified,
        ));
      }
      
      return items;
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      throw ToolExecutionException(code: 'invalid_path', message: e.message);
    }
  }
  
  @override
  Future<Option<bool>> createDirectory({
    required String path,
    bool recursive = true,
  }) async {
    try {
      final validator = _getPathValidator();
      final fullPath = validator.validateAndGetFullPath(path);
      
      final directory = Directory(fullPath);
      if (await directory.exists()) return some(false);
      
      await directory.create(recursive: recursive);
      return some(true);
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      throw ToolExecutionException(code: 'invalid_path', message: e.message);
    }
  }
  
  @override
  Future<Map<String, dynamic>> runCommand({
    required String command,
    String cwd = '.',
    int timeout = 60,
    bool shell = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final validator = _getPathValidator();
      final workingDirectory = cwd == '.' 
          ? validator.workspaceRoot
          : validator.validateAndGetFullPath(cwd);
      
      final commandParts = _parseCommand(command);
      final process = await Process.start(
        commandParts.first,
        commandParts.skip(1).toList(),
        workingDirectory: workingDirectory,
        runInShell: shell,
      );
      
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      
      process.stdout.transform(utf8.decoder).listen(stdoutBuffer.write);
      process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);
      
      int exitCode;
      bool timedOut = false;
      
      try {
        exitCode = await process.exitCode.timeout(
          Duration(seconds: timeout),
          onTimeout: () {
            process.kill();
            timedOut = true;
            return -1;
          },
        );
      } catch (e) {
        process.kill();
        throw ToolExecutionException(
          code: 'command_execution_error',
          message: 'Failed to execute: $e',
        );
      }
      
      stopwatch.stop();
      
      return {
        'command': command,
        'exit_code': exitCode,
        'stdout': stdoutBuffer.toString(),
        'stderr': stderrBuffer.toString(),
        'duration_ms': stopwatch.elapsedMilliseconds,
        'timed_out': timedOut,
      };
    } on ToolExecutionException {
      rethrow;
    }
  }
  
  @override
  Future<List<SearchMatchModel>> searchInCode({
    required String query,
    String path = '.',
    String? filePattern,
    bool caseSensitive = false,
    bool regex = false,
    int maxResults = 100,
  }) async {
    // Simplified implementation - returns empty list
    // Full implementation would use ripgrep/grep
    return [];
  }
  
  List<String> _parseCommand(String command) {
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < command.length; i++) {
      final char = command[i];
      
      if (char == '"' || char == "'") {
        inQuotes = !inQuotes;
        continue;
      }
      
      if (char == ' ' && !inQuotes) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
        continue;
      }
      
      buffer.write(char);
    }
    
    if (buffer.isNotEmpty) parts.add(buffer.toString());
    return parts;
  }
}
