// Domain entity для результата выполнения инструмента
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'tool_result.freezed.dart';

/// Domain entity представляющая результат выполнения инструмента
///
/// Использует sealed class для exhaustive pattern matching
@freezed
sealed class ToolResult with _$ToolResult {
  /// Успешное выполнение инструмента
  const factory ToolResult.success({
    /// ID вызова инструмента
    required String callId,

    /// Имя инструмента
    required String toolName,

    /// Данные результата
    required Map<String, dynamic> data,

    /// Время выполнения в миллисекундах
    required int durationMs,

    /// Timestamp завершения
    required DateTime completedAt,
  }) = ToolSuccess;

  /// Ошибка выполнения инструмента
  const factory ToolResult.failure({
    /// ID вызова инструмента
    required String callId,

    /// Имя инструмента
    required String toolName,

    /// Код ошибки
    required String errorCode,

    /// Сообщение об ошибке
    required String errorMessage,

    /// Дополнительные детали ошибки
    Option<Map<String, dynamic>>? details,

    /// Timestamp ошибки
    required DateTime failedAt,
  }) = ToolFailure;

  const ToolResult._();

  /// Проверяет, успешен ли результат
  bool get isSuccess => this is ToolSuccess;

  /// Проверяет, является ли результат ошибкой
  bool get isFailure => this is ToolFailure;

  /// Получает ID вызова
  String get callId => when(
    success: (id, _, __, ___, ____) => id,
    failure: (id, _, __, ___, ____, _____) => id,
  );

  /// Получает имя инструмента
  String get toolName => when(
    success: (_, name, __, ___, ____) => name,
    failure: (_, name, __, ___, ____, _____) => name,
  );
}

/// Специфичные типы результатов для разных инструментов

/// Результат чтения файла
@freezed
abstract class FileReadResult with _$FileReadResult {
  const factory FileReadResult({
    /// Содержимое файла
    required String content,

    /// Количество прочитанных строк
    required int linesRead,

    /// Путь к файлу
    required String path,
  }) = _FileReadResult;

  const FileReadResult._();

  /// Конвертирует в общий формат данных
  Map<String, dynamic> toData() => {
    'content': content,
    'lines_read': linesRead,
    'path': path,
  };
}

/// Результат записи файла
@freezed
abstract class FileWriteResult with _$FileWriteResult {
  const factory FileWriteResult({
    /// Количество записанных байт
    required int bytesWritten,

    /// Путь к файлу
    required String path,

    /// Путь к резервной копии (если создавалась)
    Option<String>? backupPath,
  }) = _FileWriteResult;

  const FileWriteResult._();

  /// Конвертирует в общий формат данных
  Map<String, dynamic> toData() => {
    'bytes_written': bytesWritten,
    'path': path,
    if (backupPath != null && backupPath!.isSome())
      'backup_path': backupPath!.toNullable(),
  };
}

/// Результат выполнения команды
@freezed
abstract class CommandResult with _$CommandResult {
  const factory CommandResult({
    /// Команда которая была выполнена
    required String command,

    /// Код возврата
    required int exitCode,

    /// Стандартный вывод
    required String stdout,

    /// Вывод ошибок
    required String stderr,

    /// Время выполнения в миллисекундах
    required int durationMs,

    /// Был ли timeout
    required bool timedOut,
  }) = _CommandResult;

  const CommandResult._();

  /// Проверяет успешность выполнения
  bool get isSuccess => exitCode == 0 && !timedOut;

  /// Конвертирует в общий формат данных
  Map<String, dynamic> toData() => {
    'command': command,
    'exit_code': exitCode,
    'stdout': stdout,
    'stderr': stderr,
    'duration_ms': durationMs,
    'timed_out': timedOut,
    'success': isSuccess,
  };
}

/// Результат поиска в коде
@freezed
abstract class SearchResult with _$SearchResult {
  const factory SearchResult({
    /// Поисковый запрос
    required String query,

    /// Список найденных совпадений
    required List<SearchMatch> matches,

    /// Общее количество совпадений
    required int totalMatches,

    /// Были ли результаты обрезаны (достигнут лимит)
    required bool truncated,

    /// Время выполнения в миллисекундах
    required int durationMs,
  }) = _SearchResult;

  const SearchResult._();

  /// Проверяет, найдены ли совпадения
  bool get hasMatches => matches.isNotEmpty;

  /// Конвертирует в общий формат данных
  Map<String, dynamic> toData() => {
    'query': query,
    'matches': matches.map((m) => m.toData()).toList(),
    'total_matches': totalMatches,
    'truncated': truncated,
    'duration_ms': durationMs,
  };
}

/// Одно совпадение в результатах поиска
@freezed
abstract class SearchMatch with _$SearchMatch {
  const factory SearchMatch({
    /// Путь к файлу
    required String file,

    /// Номер строки
    required int line,

    /// Номер колонки
    required int column,

    /// Найденный текст
    required String matchedText,

    /// Содержимое всей строки
    required String lineContent,
  }) = _SearchMatch;

  const SearchMatch._();

  /// Конвертирует в общий формат данных
  Map<String, dynamic> toData() => {
    'file': file,
    'line': line,
    'column': column,
    'matched_text': matchedText,
    'line_content': lineContent,
  };
}
