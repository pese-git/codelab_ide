import 'dart:async';
import 'package:codelab_core/src/utils/logger.dart';
import 'package:codelab_core/codelab_core.dart';

/// Сервис для синхронизации между ExplorerPanel, EditorPanel и файловой системой
class FileSyncService {
  final FileService _fileService;
  final FileWatcherService _fileWatcherService;
  final ProjectManagerService _projectManagerService;

  StreamSubscription<FileSystemEvent>? _fileWatcherSubscription;
  StreamSubscription<ProjectConfig?>? _projectSubscription;

  // Стримы для уведомлений о изменениях
  final StreamController<String> _fileOpenedController =
      StreamController<String>.broadcast();
  final StreamController<String> _fileSavedController =
      StreamController<String>.broadcast();
  final StreamController<String> _fileChangedController =
      StreamController<String>.broadcast();
  final StreamController<String> _fileDeletedController =
      StreamController<String>.broadcast();
  final StreamController<void> _fileTreeChangedController =
      StreamController<void>.broadcast();

  FileSyncService({
    required FileService fileService,
    required FileWatcherService fileWatcherService,
    required ProjectManagerService projectManagerService,
  }) : _fileService = fileService,
       _fileWatcherService = fileWatcherService,
       _projectManagerService = projectManagerService {
    logger.i('FileSyncService: Initialized');
    _setupProjectListener();
  }

  /// Стрим открытия файлов
  Stream<String> get fileOpenedStream => _fileOpenedController.stream;

  /// Стрим сохранения файлов
  Stream<String> get fileSavedStream => _fileSavedController.stream;

  /// Стрим изменений файлов извне
  Stream<String> get fileChangedStream => _fileChangedController.stream;

  /// Стрим удаления файлов
  Stream<String> get fileDeletedStream => _fileDeletedController.stream;

  /// Стрим изменений файлового дерева
  Stream<void> get fileTreeChangedStream => _fileTreeChangedController.stream;

  /// Открыть файл (уведомляет все компоненты)
  Future<void> openFile(String filePath) async {
    logger.i('FileSyncService: Opening file $filePath');
    _fileOpenedController.add(filePath);
  }

  /// Сохранить файл (уведомляет все компоненты)
  Future<void> saveFile(String filePath, String content) async {
    logger.i('FileSyncService: Saving file $filePath');
    final result = await _fileService.writeFile(filePath, content).run();
    await result.match(
      (error) async {
        logger.e('FileSyncService: Error saving file $filePath: $error');
      },
      (_) async {
        _fileSavedController.add(filePath);
        logger.i('FileSyncService: File saved successfully $filePath');
      },
    );
  }

  /// Файл был изменен во внешнем редакторе
  void notifyFileChanged(String filePath) {
    logger.i('FileSyncService: File changed externally $filePath');
    _fileChangedController.add(filePath);
  }

  /// Файл был удален
  void notifyFileDeleted(String filePath) {
    logger.i('FileSyncService: File deleted $filePath');
    _fileDeletedController.add(filePath);
  }

  /// Файловое дерево изменилось
  void notifyFileTreeChanged() {
    logger.i('FileSyncService: File tree changed');
    _fileTreeChangedController.add(null);
  }

  /// Настройка слушателя изменений проекта
  void _setupProjectListener() {
    logger.i('FileSyncService: Setting up project listener');
    _projectSubscription = _projectManagerService.projectStream.listen((
      config,
    ) {
      if (config != null) {
        logger.i('FileSyncService: Project opened: ${config.path}');
        _startWatchingProject(config.path);
      } else {
        logger.i('FileSyncService: Project closed');
        _stopWatching();
      }
    });
  }

  /// Запуск отслеживания изменений в проекте
  void _startWatchingProject(String projectPath) {
    logger.i('FileSyncService: Starting to watch project: $projectPath');
    _stopWatching(); // Останавливаем предыдущее отслеживание

    final task = _fileWatcherService.watchDirectory(projectPath);
    task.run().then((result) {
      result.match(
        (error) {
          logger.e('FileSyncService: Error starting file watching: $error');
        },
        (stream) {
          logger.i('FileSyncService: File watching started successfully');
          _fileWatcherSubscription = stream.listen(_handleFileSystemEvent);
        },
      );
    });
  }

  /// Обработка событий файловой системы
  void _handleFileSystemEvent(FileSystemEvent event) {
    logger.i(
      'FileSyncService: File system event: ${event.type} - ${event.path}',
    );
    switch (event.type) {
      case FileSystemEventType.created:
        _handleFileCreated(event.path);
        break;
      case FileSystemEventType.modified:
        _handleFileModified(event.path);
        break;
      case FileSystemEventType.deleted:
        _handleFileDeleted(event.path);
        break;
      case FileSystemEventType.moved:
        _handleFileMoved(event.path, event.oldPath);
        break;
    }
  }

  void _handleFileCreated(String filePath) {
    logger.i('FileSyncService: File created: $filePath');
    notifyFileTreeChanged();
  }

  void _handleFileModified(String filePath) {
    logger.i('FileSyncService: File modified: $filePath');
    _fileChangedController.add(filePath);
  }

  void _handleFileDeleted(String filePath) {
    logger.i('FileSyncService: File deleted: $filePath');
    _fileDeletedController.add(filePath);
    notifyFileTreeChanged();
  }

  void _handleFileMoved(String newPath, String? oldPath) {
    logger.i('FileSyncService: File moved: $oldPath -> $newPath');
    if (oldPath != null) {
      _fileDeletedController.add(oldPath);
    }
    notifyFileTreeChanged();
  }

  /// Остановка отслеживания
  void _stopWatching() {
    logger.i('FileSyncService: Stopping file watching');
    _fileWatcherSubscription?.cancel();
    _fileWatcherSubscription = null;
    _fileWatcherService.stopWatching();
  }

  /// Освобождение ресурсов
  void dispose() {
    logger.i('FileSyncService: Disposing');
    _stopWatching();
    _projectSubscription?.cancel();
    _fileOpenedController.close();
    _fileSavedController.close();
    _fileChangedController.close();
    _fileDeletedController.close();
    _fileTreeChangedController.close();
  }
}
