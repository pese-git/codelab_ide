import 'package:json_annotation/json_annotation.dart';

part 'tool_models.g.dart';

/// Модель для входящих tool calls от Gateway
@JsonSerializable()
class ToolCall {
  /// Уникальный идентификатор вызова инструмента
  @JsonKey(name: 'call_id')
  final String callId;

  /// Имя инструмента для выполнения
  @JsonKey(name: 'tool_name')
  final String toolName;

  /// Аргументы для инструмента
  final Map<String, dynamic> arguments;

  /// Требуется ли подтверждение пользователя (для HITL операций)
  @JsonKey(name: 'requires_confirmation', defaultValue: false)
  final bool requiresConfirmation;

  const ToolCall({
    required this.callId,
    required this.toolName,
    required this.arguments,
    this.requiresConfirmation = false,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallToJson(this);

  @override
  String toString() =>
      'ToolCall(callId: $callId, toolName: $toolName, requiresConfirmation: $requiresConfirmation)';
}

/// Модель для отправки результатов выполнения инструментов обратно в Gateway
@JsonSerializable()
class ToolResult {
  /// Идентификатор вызова, к которому относится результат
  @JsonKey(name: 'call_id')
  final String callId;

  /// Результат выполнения операции (если успешно)
  final FileOperationResult? result;

  /// Сообщение об ошибке (если произошла ошибка)
  final String? error;

  const ToolResult({
    required this.callId,
    this.result,
    this.error,
  });

  factory ToolResult.fromJson(Map<String, dynamic> json) =>
      _$ToolResultFromJson(json);

  Map<String, dynamic> toJson() => _$ToolResultToJson(this);

  /// Создает успешный результат
  factory ToolResult.success({
    required String callId,
    required FileOperationResult result,
  }) {
    return ToolResult(
      callId: callId,
      result: result,
    );
  }

  /// Создает результат с ошибкой
  factory ToolResult.error({
    required String callId,
    required String error,
  }) {
    return ToolResult(
      callId: callId,
      error: error,
    );
  }

  @override
  String toString() => 'ToolResult(callId: $callId, error: $error)';
}

/// Результат выполнения файловой операции
@JsonSerializable()
class FileOperationResult {
  /// Успешность операции
  final bool success;

  /// Содержимое файла (для read_file)
  final String? content;

  /// Количество прочитанных строк (для read_file)
  @JsonKey(name: 'lines_read')
  final int? linesRead;

  /// Количество записанных байт (для write_file)
  @JsonKey(name: 'bytes_written')
  final int? bytesWritten;

  /// Путь к резервной копии (для write_file с backup=true)
  @JsonKey(name: 'backup_path')
  final String? backupPath;

  /// Сообщение об ошибке
  final String? error;

  const FileOperationResult({
    required this.success,
    this.content,
    this.linesRead,
    this.bytesWritten,
    this.backupPath,
    this.error,
  });

  factory FileOperationResult.fromJson(Map<String, dynamic> json) =>
      _$FileOperationResultFromJson(json);

  Map<String, dynamic> toJson() => _$FileOperationResultToJson(this);

  /// Создает успешный результат чтения файла
  factory FileOperationResult.readSuccess({
    required String content,
    int? linesRead,
  }) {
    return FileOperationResult(
      success: true,
      content: content,
      linesRead: linesRead,
    );
  }

  /// Создает успешный результат записи файла
  factory FileOperationResult.writeSuccess({
    required int bytesWritten,
    String? backupPath,
  }) {
    return FileOperationResult(
      success: true,
      bytesWritten: bytesWritten,
      backupPath: backupPath,
    );
  }

  /// Создает результат с ошибкой
  factory FileOperationResult.failure({
    required String error,
  }) {
    return FileOperationResult(
      success: false,
      error: error,
    );
  }

  @override
  String toString() =>
      'FileOperationResult(success: $success, error: $error)';
}

/// Аргументы для read_file инструмента
@JsonSerializable()
class ReadFileArgs {
  /// Путь к файлу относительно рабочего каталога проекта
  final String path;

  /// Кодировка файла (по умолчанию 'utf-8')
  @JsonKey(defaultValue: 'utf-8')
  final String encoding;

  /// Начальная строка для чтения (1-based)
  @JsonKey(name: 'start_line')
  final int? startLine;

  /// Конечная строка для чтения (1-based)
  @JsonKey(name: 'end_line')
  final int? endLine;

  const ReadFileArgs({
    required this.path,
    this.encoding = 'utf-8',
    this.startLine,
    this.endLine,
  });

  factory ReadFileArgs.fromJson(Map<String, dynamic> json) =>
      _$ReadFileArgsFromJson(json);

  Map<String, dynamic> toJson() => _$ReadFileArgsToJson(this);

  @override
  String toString() =>
      'ReadFileArgs(path: $path, startLine: $startLine, endLine: $endLine)';
}

/// Аргументы для write_file инструмента
@JsonSerializable()
class WriteFileArgs {
  /// Путь к файлу относительно рабочего каталога проекта
  final String path;

  /// Содержимое для записи
  final String content;

  /// Кодировка файла (по умолчанию 'utf-8')
  @JsonKey(defaultValue: 'utf-8')
  final String encoding;

  /// Создавать ли директории, если они не существуют
  @JsonKey(name: 'create_dirs', defaultValue: false)
  final bool createDirs;

  /// Создавать ли резервную копию перед перезаписью
  @JsonKey(defaultValue: true)
  final bool backup;

  const WriteFileArgs({
    required this.path,
    required this.content,
    this.encoding = 'utf-8',
    this.createDirs = false,
    this.backup = true,
  });

  factory WriteFileArgs.fromJson(Map<String, dynamic> json) =>
      _$WriteFileArgsFromJson(json);

  Map<String, dynamic> toJson() => _$WriteFileArgsToJson(this);

  @override
  String toString() =>
      'WriteFileArgs(path: $path, createDirs: $createDirs, backup: $backup)';
}

/// Кастомное исключение для ошибок выполнения инструментов
class ToolExecutionException implements Exception {
  /// Код ошибки
  final String code;

  /// Сообщение об ошибке
  final String message;

  /// Дополнительные детали
  final Map<String, dynamic>? details;

  /// Исходное исключение
  final Object? cause;

  const ToolExecutionException({
    required this.code,
    required this.message,
    this.details,
    this.cause,
  });

  /// Файл не найден
  factory ToolExecutionException.fileNotFound(String path) {
    return ToolExecutionException(
      code: 'file_not_found',
      message: 'File not found: $path',
      details: {'path': path},
    );
  }

  /// Нет прав доступа
  factory ToolExecutionException.permissionDenied(String path) {
    return ToolExecutionException(
      code: 'permission_denied',
      message: 'Permission denied: $path',
      details: {'path': path},
    );
  }

  /// Небезопасный путь
  factory ToolExecutionException.invalidPath(String path, String reason) {
    return ToolExecutionException(
      code: 'invalid_path',
      message: 'Invalid path: $path. Reason: $reason',
      details: {'path': path, 'reason': reason},
    );
  }

  /// Ошибка кодировки
  factory ToolExecutionException.encodingError(String path, Object cause) {
    return ToolExecutionException(
      code: 'encoding_error',
      message: 'Encoding error for file: $path',
      details: {'path': path},
      cause: cause,
    );
  }

  /// Файл слишком большой
  factory ToolExecutionException.fileTooLarge(String path, int size, int maxSize) {
    return ToolExecutionException(
      code: 'file_too_large',
      message: 'File too large: $path ($size bytes, max: $maxSize bytes)',
      details: {'path': path, 'size': size, 'max_size': maxSize},
    );
  }

  /// Пользователь отклонил операцию
  factory ToolExecutionException.userRejected(String operation) {
    return ToolExecutionException(
      code: 'user_rejected',
      message: 'User rejected operation: $operation',
      details: {'operation': operation},
    );
  }

  /// Конкурентная модификация
  factory ToolExecutionException.concurrentModification(String path) {
    return ToolExecutionException(
      code: 'concurrent_modification',
      message: 'File was modified by another process: $path',
      details: {'path': path},
    );
  }

  /// Общая ошибка
  factory ToolExecutionException.general(String message, {Object? cause}) {
    return ToolExecutionException(
      code: 'general_error',
      message: message,
      cause: cause,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('ToolExecutionException($code): $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (cause != null) {
      buffer.write('\nCause: $cause');
    }
    return buffer.toString();
  }
}
