import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

/// Типы событий файловой системы
enum FileSystemEventType {
  created,
  modified,
  deleted,
  moved,
}

/// Событие изменения файла
class FileSystemEvent {
  final FileSystemEventType type;
  final String path;
  final String? oldPath; // Для события moved

  FileSystemEvent({
    required this.type,
    required this.path,
    this.oldPath,
  });

  @override
  String toString() {
    return 'FileSystemEvent(type: $type, path: $path, oldPath: $oldPath)';
  }
}

/// Сервис для отслеживания изменений в файловой системе
abstract interface class FileWatcherService {
  /// Запускает отслеживание директории
  TaskEither<String, Stream<FileSystemEvent>> watchDirectory(String directoryPath);
  
  /// Останавливает отслеживание
  void stopWatching();
  
  /// Проверяет, отслеживается ли директория
  bool isWatching(String directoryPath);
}

class FileWatcherServiceImpl implements FileWatcherService {
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  final Map<String, StreamController<FileSystemEvent>> _controllers = {};

  @override
  TaskEither<String, Stream<FileSystemEvent>> watchDirectory(String directoryPath) {
    return TaskEither<String, Stream<FileSystemEvent>>.tryCatch(
      () async {
        final directory = Directory(directoryPath);
        if (!await directory.exists()) {
          throw 'Directory does not exist: $directoryPath';
        }

        // Если уже отслеживаем эту директорию, возвращаем существующий стрим
        if (_controllers.containsKey(directoryPath)) {
          return _controllers[directoryPath]!.stream;
        }

        final controller = StreamController<FileSystemEvent>.broadcast();
        _controllers[directoryPath] = controller;

        // Создаем FileSystemWatcher
        final watcher = directory.watch(recursive: true);
        
        final subscription = watcher.listen(
          (event) {
            final fileSystemEvent = FileSystemEvent(
              type: _convertEventType(event.type),
              path: event.path,
              oldPath: event is FileSystemMoveEvent ? event.destination : null,
            );
            controller.add(fileSystemEvent);
          },
          onError: (error) {
            controller.addError(error);
          },
          cancelOnError: false,
        );

        _subscriptions[directoryPath] = subscription;

        return controller.stream;
      },
      (error, stackTrace) => error.toString(),
    );
  }

  @override
  void stopWatching() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _subscriptions.clear();
    _controllers.clear();
  }

  @override
  bool isWatching(String directoryPath) {
    return _subscriptions.containsKey(directoryPath);
  }

  /// Преобразует FileSystemEvent из dart:io в наш тип
  FileSystemEventType _convertEventType(int eventType) {
    // Константы из dart:io
    const int fileSystemEventCreate = 0;
    const int fileSystemEventModify = 1;
    const int fileSystemEventDelete = 2;
    const int fileSystemEventMove = 4;

    if (eventType == fileSystemEventCreate) {
      return FileSystemEventType.created;
    } else if (eventType == fileSystemEventModify) {
      return FileSystemEventType.modified;
    } else if (eventType == fileSystemEventDelete) {
      return FileSystemEventType.deleted;
    } else if (eventType == fileSystemEventMove) {
      return FileSystemEventType.moved;
    } else {
      return FileSystemEventType.modified;
    }
  }
}