// /Users/penkovsky_sa/Projects/OpenSource/codelab_ide/packages/codelab_core/lib/logger/codelab_logger.dart
import 'package:logger/logger.dart';

/// Центральный расширяемый логгер проекта.
class CodelabLogger {
  static final CodelabLogger _instance = CodelabLogger._internal();
  factory CodelabLogger() => _instance;

  late Logger _logger;
  late LogFilter _filter;
  late LogPrinter _printer;
  late LogOutput _output;
  late Level _level;

  CodelabLogger._internal() {
    // Значения по умолчанию: красиво, полный вывод, в консоль
    _level = Level.debug;
    _printer = Logger.defaultPrinter();
    _filter = Logger.defaultFilter();
    _output = Logger.defaultOutput();
    _initLogger();
  }

  void configure({
    LogFilter? filter,
    LogPrinter? printer,
    LogOutput? output,
    Level? level,
  }) {
    if (filter != null) _filter = filter;
    if (printer != null) _printer = printer;
    if (output != null) _output = output;
    if (level != null) _level = level;
    _initLogger();
  }

  void _initLogger() {
    _logger = Logger(
      filter: _filter,
      printer: _printer,
      output: _output,
      level: _level,
    );
  }

  void setLevel(Level level) {
    _level = level;
    _initLogger();
  }

  // Методы логирования с поддержкой tag и context (и всеми параметрами)
  void t(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.t(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void d(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.d(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void i(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.i(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void w(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.w(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void e(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.e(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void f(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.f(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void log(
    Level level,
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.log(
    level,
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  // Deprecated/legacy
  void v(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.v(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void wtf(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.wtf(
    _composeMessage(message, tag, context),
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  // fluent-псевдонимы
  void info(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => i(
    message,
    tag: tag,
    context: context,
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void error(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => e(
    message,
    tag: tag,
    context: context,
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void debug(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => d(
    message,
    tag: tag,
    context: context,
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  void warn(
    dynamic message, {
    String? tag,
    Map<String, dynamic>? context,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) => w(
    message,
    tag: tag,
    context: context,
    time: time,
    error: error,
    stackTrace: stackTrace,
  );

  // compose message with tag/context
  String _composeMessage(
    dynamic message,
    String? tag,
    Map<String, dynamic>? ctx,
  ) {
    final ctxString = ctx != null && ctx.isNotEmpty
        ? ' | context: ${ctx.map((k, v) => MapEntry(k, v.toString()))}'
        : '';
    final tagString = tag != null && tag.isNotEmpty ? '[$tag] ' : '';
    return '$tagString$message$ctxString';
  }
}

final codelabLogger = CodelabLogger();
