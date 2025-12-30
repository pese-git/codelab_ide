import 'dart:convert';
import 'dart:io';
import 'package:codelab_core/codelab_core.dart';
import 'package:path/path.dart' as p;
import 'package:cherrypick/cherrypick.dart';
import 'package:glob/glob.dart';
import '../models/tool_models.dart';

/// Сервис для выполнения tool calls на стороне IDE
class ToolExecutor {
  /// Максимальный размер читаемого файла (10MB)
  static const int maxReadFileSize = 10 * 1024 * 1024;

  /// Максимальный размер записываемого файла (5MB)
  static const int maxWriteFileSize = 5 * 1024 * 1024;

  // Whitelist безопасных команд (не требуют HITL)
  static const _safeCommands = [
    'flutter',
    'dart',
    'git',
    'pub',
    'fvm',
    'ls',
    'dir',
    'pwd',
    'echo',
    'cat',
    'grep',
    'find',
  ];

  // Blacklist опасных паттернов
  static const _dangerousPatterns = [
    'rm ',
    'del ',
    'format',
    'mkfs',
    'dd ',
    'sudo',
    'su ',
    'chmod',
    'chown',
    '>',
    '>>',
    '|',
    '&&',
    ';',
    'curl',
    'wget',
    'nc ',
    'netcat',
  ];

  ToolExecutor();

  /// Получает PathValidator с актуальным workspace root
  PathValidator _getPathValidator() {
    try {
      final projectManager = CherryPick.openRootScope().resolve<ProjectManagerService>();
      final project = projectManager.currentProject;
      if (project != null) {
        return PathValidator(workspaceRoot: project.path);
      }
    } catch (e) {
      print('[ToolExecutor] Failed to resolve ProjectManagerService: $e');
    }
    
    // Fallback: используем временную директорию
    print('[ToolExecutor] Using fallback workspace root: /tmp');
    return PathValidator(workspaceRoot: '/tmp');
  }

  /// Выполняет tool call и возвращает результат
  ///
  /// Маршрутизирует вызов к соответствующему методу обработки
  /// в зависимости от [toolCall.toolName].
  ///
  /// Throws [ToolExecutionException] если инструмент не поддерживается
  /// или произошла ошибка выполнения.
  Future<dynamic> executeToolCall(ToolCall toolCall) async {
    try {
      switch (toolCall.toolName) {
        case 'read_file':
          return await _readFile(toolCall.arguments);
        case 'write_file':
          return await _writeFile(toolCall.arguments);
        case 'list_files':
          return await _listFiles(toolCall.arguments);
        case 'create_directory':
          return await _createDirectory(toolCall.arguments);
        case 'run_command':
          return await _runCommand(toolCall.arguments);
        case 'search_in_code':
          return await _searchInCode(toolCall.arguments);
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
      final pathValidator = _getPathValidator();
      final fullPath = pathValidator.validateAndGetFullPath(args.path);

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
      final pathValidator = _getPathValidator();
      final fullPath = pathValidator.validateAndGetFullPath(args.path);

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
            ? p.relative(backupPath, from: pathValidator.workspaceRoot)
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

  // ==========================================================================
  // List Files Tool
  // ==========================================================================

  /// Выполняет операцию получения списка файлов
  Future<ListFilesResult> _listFiles(Map<String, dynamic> arguments) async {
    try {
      // Парсинг аргументов
      final args = ListFilesArgs.fromJson(arguments);

      // Валидация пути
      final pathValidator = _getPathValidator();
      final fullPath = pathValidator.validateAndGetFullPath(args.path);

      // Проверка существования директории
      final directory = Directory(fullPath);
      if (!await directory.exists()) {
        return ListFilesResult.failure(
          path: args.path,
          error: 'Directory not found: ${args.path}',
        );
      }

      // Список файлов
      final items = <FileItem>[];
      final glob = args.pattern != null ? Glob(args.pattern!) : null;

      await for (final entity in directory.list(recursive: args.recursive)) {
        final relativePath = p.relative(entity.path, from: pathValidator.workspaceRoot);
        final name = p.basename(entity.path);

        // Пропускаем скрытые файлы если не включены
        if (!args.includeHidden && name.startsWith('.')) {
          continue;
        }

        // Применяем glob паттерн если указан
        if (glob != null && !glob.matches(relativePath)) {
          continue;
        }

        FileStat? stat;
        try {
          stat = await entity.stat();
        } catch (e) {
          print('Failed to stat file: ${entity.path}, error: $e');
          continue;
        }

        final item = FileItem(
          name: name,
          path: relativePath,
          type: entity is Directory ? 'directory' : 'file',
          size: entity is File ? stat.size : null,
          modified: stat.modified,
        );

        items.add(item);
      }

      return ListFilesResult.successResult(
        path: args.path,
        items: items,
      );
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      return ListFilesResult.failure(
        path: arguments['path'] ?? 'unknown',
        error: 'Invalid path: ${e.message}',
      );
    } catch (e, stackTrace) {
      print('Error listing files: $e\n$stackTrace');
      return ListFilesResult.failure(
        path: arguments['path'] ?? 'unknown',
        error: 'Failed to list files: $e',
      );
    }
  }

  // ==========================================================================
  // Create Directory Tool
  // ==========================================================================

  /// Выполняет операцию создания директории
  Future<CreateDirectoryResult> _createDirectory(Map<String, dynamic> arguments) async {
    try {
      // Парсинг аргументов
      final args = CreateDirectoryArgs.fromJson(arguments);

      // Валидация пути
      final pathValidator = _getPathValidator();
      final fullPath = pathValidator.validateAndGetFullPath(args.path);

      final directory = Directory(fullPath);

      // Проверка существования
      final alreadyExists = await directory.exists();
      if (alreadyExists) {
        return CreateDirectoryResult.successResult(
          path: args.path,
          created: false,
          alreadyExists: true,
        );
      }

      // Создание директории
      await directory.create(recursive: args.recursive);

      return CreateDirectoryResult.successResult(
        path: args.path,
        created: true,
        alreadyExists: false,
      );
    } on ToolExecutionException {
      rethrow;
    } on PathValidationException catch (e) {
      return CreateDirectoryResult.failure(
        path: arguments['path'] ?? 'unknown',
        error: 'Invalid path: ${e.message}',
      );
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        // Permission denied
        return CreateDirectoryResult.failure(
          path: arguments['path'] ?? 'unknown',
          error: 'Permission denied',
        );
      }
      return CreateDirectoryResult.failure(
        path: arguments['path'] ?? 'unknown',
        error: 'File system error: ${e.message}',
      );
    } catch (e, stackTrace) {
      print('Error creating directory: $e\n$stackTrace');
      return CreateDirectoryResult.failure(
        path: arguments['path'] ?? 'unknown',
        error: 'Failed to create directory: $e',
      );
    }
  }

  // ==========================================================================
  // Run Command Tool
  // ==========================================================================

  /// Выполняет операцию запуска команды
  Future<RunCommandResult> _runCommand(Map<String, dynamic> arguments) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final args = RunCommandArgs.fromJson(arguments);
      print('[ToolExecutor] Running command: ${args.command}');

      // Validate command safety
      _validateCommandSafety(args.command);

      // Resolve working directory
      final validator = _getPathValidator();
      String workingDirectory;
      
      // If cwd is '.' or empty, use workspace root directly
      if (args.cwd == '.' || args.cwd.isEmpty) {
        workingDirectory = validator.workspaceRoot;
      } else {
        // Validate and resolve custom working directory
        final validationResult = validator.isPathSafe(args.cwd);
        if (!validationResult.isValid) {
          throw ToolExecutionException(
            code: 'invalid_path',
            message: validationResult.error ?? 'Invalid working directory',
          );
        }
        workingDirectory = validationResult.fullPath!;
      }

      final directory = Directory(workingDirectory);
      if (!await directory.exists()) {
        throw ToolExecutionException(
          code: 'directory_not_found',
          message: 'Working directory not found: ${args.cwd}',
        );
      }

      // Validate timeout
      if (args.timeout < 1 || args.timeout > 300) {
        throw ToolExecutionException(
          code: 'invalid_timeout',
          message: 'Timeout must be between 1 and 300 seconds',
        );
      }

      // Parse command
      final commandParts = _parseCommand(args.command);
      if (commandParts.isEmpty) {
        throw ToolExecutionException(
          code: 'empty_command',
          message: 'Command cannot be empty',
        );
      }

      // Execute command
      final process = await Process.start(
        commandParts.first,
        commandParts.skip(1).toList(),
        workingDirectory: workingDirectory,
        runInShell: args.shell,
      );

      // Capture output
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      
      process.stdout.transform(utf8.decoder).listen((data) {
        stdoutBuffer.write(data);
      });
      
      process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
      });

      // Wait for completion with timeout
      int exitCode;
      bool timedOut = false;
      
      try {
        exitCode = await process.exitCode.timeout(
          Duration(seconds: args.timeout),
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
          message: 'Failed to execute command: $e',
        );
      }

      stopwatch.stop();

      final result = RunCommandResult(
        command: args.command,
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
        timedOut: timedOut,
      );

      if (timedOut) {
        print('[ToolExecutor] Command timed out after ${args.timeout}s: ${args.command}');
      } else if (exitCode != 0) {
        print('[ToolExecutor] Command failed with exit code $exitCode: ${args.command}');
      } else {
        print('[ToolExecutor] Command completed successfully: ${args.command}');
      }

      return result;
    } on ToolExecutionException {
      rethrow;
    } catch (e, stackTrace) {
      print('[ToolExecutor] Error running command: $e\n$stackTrace');
      throw ToolExecutionException(
        code: 'run_command_error',
        message: 'Failed to run command: $e',
      );
    }
  }

  /// Validate command safety
  void _validateCommandSafety(String command) {
    final lowerCommand = command.toLowerCase().trim();

    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (lowerCommand.contains(pattern)) {
        throw ToolExecutionException(
          code: 'dangerous_command',
          message: 'Command contains dangerous pattern: $pattern',
        );
      }
    }

    // Check if command starts with safe command
    final firstWord = lowerCommand.split(' ').first;
    final isSafe = _safeCommands.any((safe) => firstWord == safe || firstWord.startsWith('$safe.'));
    
    if (!isSafe) {
      throw ToolExecutionException(
        code: 'unsafe_command',
        message: 'Command not in whitelist: $firstWord',
      );
    }
  }

  /// Parse command string into parts
  List<String> _parseCommand(String command) {
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    bool escaped = false;

    for (int i = 0; i < command.length; i++) {
      final char = command[i];

      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

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

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  // ==========================================================================
  // Search In Code Tool
  // ==========================================================================

  Future<SearchInCodeResult> _searchInCode(Map<String, dynamic> arguments) async {
    final stopwatch = Stopwatch()..start();

    try {
      final args = SearchInCodeArgs.fromJson(arguments);
      print('[ToolExecutor] Searching for: ${args.query} in ${args.path}');

      // Validate path
      final validator = _getPathValidator();
      final validationResult = validator.isPathSafe(args.path);
      if (!validationResult.isValid) {
        throw ToolExecutionException(
          code: 'invalid_path',
          message: validationResult.error ?? 'Invalid search path',
        );
      }

      final searchPath = validationResult.fullPath!;
      final directory = Directory(searchPath);
      if (!await directory.exists()) {
        throw ToolExecutionException(
          code: 'directory_not_found',
          message: 'Search directory not found: ${args.path}',
        );
      }

      // Validate max_results
      if (args.maxResults < 1 || args.maxResults > 1000) {
        throw ToolExecutionException(
          code: 'invalid_max_results',
          message: 'max_results must be between 1 and 1000',
        );
      }

      // Try ripgrep first, fallback to grep
      final matches = await _executeSearch(args, searchPath);

      stopwatch.stop();

      final truncated = matches.length >= args.maxResults;
      final result = SearchInCodeResult(
        query: args.query,
        matches: matches,
        totalMatches: matches.length,
        truncated: truncated,
        durationMs: stopwatch.elapsedMilliseconds,
      );

      print('[ToolExecutor] Found ${matches.length} matches for: ${args.query}');
      return result;
    } on ToolExecutionException {
      rethrow;
    } catch (e, stackTrace) {
      print('[ToolExecutor] Error searching code: $e\n$stackTrace');
      throw ToolExecutionException(
        code: 'search_error',
        message: 'Failed to search code: $e',
      );
    }
  }

  Future<List<SearchMatch>> _executeSearch(
    SearchInCodeArgs args,
    String searchPath,
  ) async {
    // Try ripgrep first (faster)
    try {
      return await _searchWithRipgrep(args, searchPath);
    } catch (e) {
      print('[ToolExecutor] Ripgrep not available, falling back to grep: $e');
      // Fallback to grep
      return await _searchWithGrep(args, searchPath);
    }
  }

  Future<List<SearchMatch>> _searchWithRipgrep(
    SearchInCodeArgs args,
    String searchPath,
  ) async {
    final rgArgs = <String>[
      '--json',
      '--max-count=${args.maxResults}',
      if (!args.caseSensitive) '--ignore-case',
      if (!args.regex) '--fixed-strings',
      if (args.filePattern != null) '--glob=${args.filePattern}',
      args.query,
      searchPath,
    ];

    final process = await Process.start('rg', rgArgs);
    final output = await process.stdout.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    if (exitCode != 0 && exitCode != 1) {
      // Exit code 1 means no matches, which is ok
      final stderr = await process.stderr.transform(utf8.decoder).join();
      throw Exception('ripgrep failed: $stderr');
    }

    return _parseRipgrepOutput(output, searchPath);
  }

  Future<List<SearchMatch>> _searchWithGrep(
    SearchInCodeArgs args,
    String searchPath,
  ) async {
    final grepArgs = <String>[
      '-r', // recursive
      '-n', // line numbers
      '-H', // show filename
      if (!args.caseSensitive) '-i',
      if (!args.regex) '-F',
      if (args.filePattern != null) '--include=${args.filePattern}',
      args.query,
      searchPath,
    ];

    final process = await Process.start('grep', grepArgs);
    final output = await process.stdout.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    if (exitCode != 0 && exitCode != 1) {
      final stderr = await process.stderr.transform(utf8.decoder).join();
      throw Exception('grep failed: $stderr');
    }

    return _parseGrepOutput(output, searchPath, args.maxResults);
  }

  List<SearchMatch> _parseRipgrepOutput(String output, String searchPath) {
    final matches = <SearchMatch>[];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        if (json['type'] != 'match') continue;

        final data = json['data'] as Map<String, dynamic>;
        final path = data['path'] as Map<String, dynamic>;
        final lineNumber = (data['line_number'] as num).toInt();
        final lines = data['lines'] as Map<String, dynamic>;
        final submatches = data['submatches'] as List;

        final file = p.relative(
          path['text'] as String,
          from: searchPath,
        );
        final lineContent = (lines['text'] as String).trimRight();

        for (final submatch in submatches) {
          final matchData = submatch as Map<String, dynamic>;
          final start = (matchData['start'] as num).toInt();
          final end = (matchData['end'] as num).toInt();
          final matchedText = lineContent.substring(start, end);

          matches.add(SearchMatch(
            file: file,
            line: lineNumber,
            column: start + 1,
            matchedText: matchedText,
            lineContent: lineContent,
          ));
        }
      } catch (e) {
        print('[ToolExecutor] Failed to parse ripgrep line: $line, error: $e');
      }
    }

    return matches;
  }

  List<SearchMatch> _parseGrepOutput(
    String output,
    String searchPath,
    int maxResults,
  ) {
    final matches = <SearchMatch>[];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (matches.length >= maxResults) break;

      try {
        // Format: filename:line:content
        final parts = line.split(':');
        if (parts.length < 3) continue;

        final filePath = parts[0];
        final lineNumber = int.parse(parts[1]);
        final lineContent = parts.sublist(2).join(':').trimRight();

        final file = p.relative(filePath, from: searchPath);

        matches.add(SearchMatch(
          file: file,
          line: lineNumber,
          column: 1, // grep doesn't provide column info
          matchedText: '', // grep doesn't isolate matched text
          lineContent: lineContent,
        ));
      } catch (e) {
        print('[ToolExecutor] Failed to parse grep line: $line, error: $e');
      }
    }

    return matches;
  }
}
