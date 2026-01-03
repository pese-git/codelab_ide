// Data source для выполнения инструментов
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../models/tool_call_model.dart';
import '../models/tool_result_model.dart';
import 'file_system_datasource.dart';

/// Интерфейс для data source выполнения инструментов
abstract class ToolExecutorDataSource {
  /// Выполняет tool call и возвращает результат
  Future<ToolResultModel> execute(ToolCallModel toolCall);
  
  /// Получает список поддерживаемых инструментов
  List<String> getSupportedTools();
}

/// Реализация data source для выполнения инструментов
/// 
/// Адаптирует существующий ToolExecutor к новой архитектуре
class ToolExecutorDataSourceImpl implements ToolExecutorDataSource {
  final FileSystemDataSource _fileSystem;
  
  // Поддерживаемые инструменты
  static const List<String> _supportedTools = [
    'read_file',
    'write_file',
    'list_files',
    'create_directory',
    'run_command',
    'execute_command',
    'search_in_code',
  ];
  
  ToolExecutorDataSourceImpl({
    required FileSystemDataSource fileSystem,
  }) : _fileSystem = fileSystem;
  
  @override
  List<String> getSupportedTools() => _supportedTools;
  
  @override
  Future<ToolResultModel> execute(ToolCallModel toolCall) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await _executeByToolName(toolCall);
      stopwatch.stop();
      
      return ToolResultModel(
        callId: toolCall.callId,
        toolName: toolCall.toolName,
        success: true,
        result: result,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on ToolExecutionException catch (e) {
      stopwatch.stop();
      
      return ToolResultModel(
        callId: toolCall.callId,
        toolName: toolCall.toolName,
        success: false,
        errorCode: e.code,
        errorMessage: e.message,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      
      throw ToolExecutionException(
        code: 'unexpected_error',
        message: 'Unexpected error executing ${toolCall.toolName}: $e',
        cause: e,
      );
    }
  }
  
  /// Маршрутизирует выполнение по имени инструмента
  Future<Map<String, dynamic>> _executeByToolName(ToolCallModel toolCall) async {
    switch (toolCall.toolName) {
      case 'read_file':
        return await _executeReadFile(toolCall.arguments);
      case 'write_file':
        return await _executeWriteFile(toolCall.arguments);
      case 'list_files':
        return await _executeListFiles(toolCall.arguments);
      case 'create_directory':
        return await _executeCreateDirectory(toolCall.arguments);
      case 'run_command':
      case 'execute_command':
        return await _executeRunCommand(toolCall.arguments);
      case 'search_in_code':
        return await _executeSearchInCode(toolCall.arguments);
      default:
        throw ToolExecutionException(
          code: 'unsupported_tool',
          message: 'Unsupported tool: ${toolCall.toolName}',
        );
    }
  }
  
  /// Выполняет read_file
  Future<Map<String, dynamic>> _executeReadFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final startLine = args['start_line'] as int?;
    final endLine = args['end_line'] as int?;
    
    final content = await _fileSystem.readFile(path);
    
    // Обработка частичного чтения
    if (startLine != null || endLine != null) {
      final lines = content.split('\n');
      final start = (startLine ?? 1) - 1;
      final end = (endLine ?? lines.length) - 1;
      
      if (start < 0 || start >= lines.length) {
        throw ToolExecutionException(
          code: 'invalid_line_range',
          message: 'Invalid start_line: $startLine',
        );
      }
      
      if (end < start || end >= lines.length) {
        throw ToolExecutionException(
          code: 'invalid_line_range',
          message: 'Invalid end_line: $endLine',
        );
      }
      
      final selectedLines = lines.sublist(start, end + 1);
      return {
        'success': true,
        'content': selectedLines.join('\n'),
        'lines_read': selectedLines.length,
      };
    }
    
    return {
      'success': true,
      'content': content,
      'lines_read': content.split('\n').length,
    };
  }
  
  /// Выполняет write_file
  Future<Map<String, dynamic>> _executeWriteFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final content = args['content'] as String;
    final createDirs = args['create_dirs'] as bool? ?? false;
    final backup = args['backup'] as bool? ?? true;
    
    final backupPath = await _fileSystem.writeFile(
      path: path,
      content: content,
      createDirs: createDirs,
      backup: backup,
    );
    
    return {
      'success': true,
      'bytes_written': content.length,
      if (backupPath.isSome()) 'backup_path': backupPath.toNullable(),
    };
  }
  
  /// Выполняет list_files
  Future<Map<String, dynamic>> _executeListFiles(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final recursive = args['recursive'] as bool? ?? false;
    final includeHidden = args['include_hidden'] as bool? ?? false;
    final pattern = args['pattern'] as String?;
    
    final items = await _fileSystem.listFiles(
      path: path,
      recursive: recursive,
      includeHidden: includeHidden,
      pattern: pattern,
    );
    
    return {
      'success': true,
      'path': path,
      'items': items.map((item) => item.toJson()).toList(),
      'total_count': items.length,
    };
  }
  
  /// Выполняет create_directory
  Future<Map<String, dynamic>> _executeCreateDirectory(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final recursive = args['recursive'] as bool? ?? true;
    
    final result = await _fileSystem.createDirectory(
      path: path,
      recursive: recursive,
    );
    
    return result.fold(
      () => {
        'success': true,
        'path': path,
        'created': false,
        'already_exists': true,
      },
      (created) => {
        'success': true,
        'path': path,
        'created': created,
        'already_exists': !created,
      },
    );
  }
  
  /// Выполняет run_command
  Future<Map<String, dynamic>> _executeRunCommand(Map<String, dynamic> args) async {
    final command = args['command'] as String;
    final cwd = args['cwd'] as String? ?? '.';
    final timeout = args['timeout'] as int? ?? 60;
    final shell = args['shell'] as bool? ?? false;
    
    // Валидация команды
    _validateCommand(command);
    
    final result = await _fileSystem.runCommand(
      command: command,
      cwd: cwd,
      timeout: timeout,
      shell: shell,
    );
    
    return result;
  }
  
  /// Выполняет search_in_code
  Future<Map<String, dynamic>> _executeSearchInCode(Map<String, dynamic> args) async {
    final query = args['query'] as String;
    final path = args['path'] as String? ?? '.';
    final filePattern = args['file_pattern'] as String?;
    final caseSensitive = args['case_sensitive'] as bool? ?? false;
    final regex = args['regex'] as bool? ?? false;
    final maxResults = args['max_results'] as int? ?? 100;
    
    final matches = await _fileSystem.searchInCode(
      query: query,
      path: path,
      filePattern: filePattern,
      caseSensitive: caseSensitive,
      regex: regex,
      maxResults: maxResults,
    );
    
    return {
      'query': query,
      'matches': matches.map((m) => m.toJson()).toList(),
      'total_matches': matches.length,
      'truncated': matches.length >= maxResults,
    };
  }
  
  /// Валидирует безопасность команды
  void _validateCommand(String command) {
    final lowerCommand = command.toLowerCase().trim();
    
    // Опасные паттерны
    const dangerousPatterns = [
      'rm ', 'del ', 'format', 'mkfs', 'dd ',
      'sudo', 'su ', 'chmod', 'chown',
      '>', '>>', '|', '&&', ';',
      'curl', 'wget', 'nc ', 'netcat',
    ];
    
    for (final pattern in dangerousPatterns) {
      if (lowerCommand.contains(pattern)) {
        throw ToolExecutionException(
          code: 'dangerous_command',
          message: 'Command contains dangerous pattern: $pattern',
        );
      }
    }
    
    // Безопасные команды
    const safeCommands = [
      'flutter', 'dart', 'git', 'pub', 'fvm',
      'ls', 'dir', 'pwd', 'echo', 'cat', 'grep', 'find',
    ];
    
    final firstWord = lowerCommand.split(' ').first;
    final isSafe = safeCommands.any(
      (safe) => firstWord == safe || firstWord.startsWith('$safe.'),
    );
    
    if (!isSafe) {
      throw ToolExecutionException(
        code: 'unsafe_command',
        message: 'Command not in whitelist: $firstWord',
      );
    }
  }
}
