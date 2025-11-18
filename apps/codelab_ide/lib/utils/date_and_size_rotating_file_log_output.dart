import 'dart:io';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';

class DateAndSizeRotatingFileLogOutput extends LogOutput {
  final String directory;
  final String baseName;
  final int maxFileSizeBytes;
  final int maxFilesPerDay;

  IOSink? _sink;
  File? _currentFile;
  String? _currentDateStr;

  final _mutex = Lock();

  DateAndSizeRotatingFileLogOutput({
    required this.directory,
    this.baseName = 'codelab',
    this.maxFileSizeBytes = 5 * 1024 * 1024,
    this.maxFilesPerDay = 5,
  }) {
    Directory(directory).createSync(recursive: true);
    _openLog();
  }

  String _dateStr() {
    return DateFormat('yyyyMMdd').format(DateTime.now());
  }

  String _getLogPath({int? suffix}) {
    final date = _dateStr();
    return [
      directory.endsWith("/") ? directory : "$directory/",
      baseName,
      '_',
      date,
      '.log',
      if (suffix != null) '.$suffix',
    ].join();
  }

  void _openLog() {
    _currentDateStr = _dateStr();
    final path = _getLogPath();
    _currentFile = File(path);
    _sink = _currentFile!.openWrite(mode: FileMode.append);
  }

  Future<void> _rotateIfNeeded() async {
    // По дате
    final dateStr = _dateStr();
    if (_currentDateStr != dateStr) {
      await _sink?.flush();
      await _sink?.close();
      _openLog();
      return;
    }

    // По размеру
    if (_currentFile != null &&
        await _currentFile!.exists() &&
        await _currentFile!.length() >= maxFileSizeBytes) {
      await _sink?.flush();
      await _sink?.close();

      for (int i = maxFilesPerDay - 1; i >= 1; i--) {
        final from = File(_getLogPath(suffix: i));
        final to = File(_getLogPath(suffix: i + 1));
        if (await from.exists()) {
          if (i == maxFilesPerDay - 1) {
            await from.delete();
          } else {
            await from.rename(to.path);
          }
        }
      }
      await _currentFile!.rename(_getLogPath(suffix: 1));
      _openLog();
    }
  }

  @override
  void output(OutputEvent event) {
    _mutex.synchronized(() async {
      await _rotateIfNeeded();
      for (final line in event.lines) {
        _sink?.writeln(line);
      }
      await _sink?.flush();
    });
  }

  Future<void> close() async {
    await _mutex.synchronized(() async {
      await _sink?.flush();
      await _sink?.close();
    });
  }
}
