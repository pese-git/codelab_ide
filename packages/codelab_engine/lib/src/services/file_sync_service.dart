import 'dart:async';
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
    codelabLogger.i('FileSyncService: Initialized', tag: 'file_sync_service');
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
    codelabLogger.i('FileSyncService: Opening file $filePath', tag: 'file_sync_service');
    _fileOpenedController.add(filePath);
  }

  /// Сохранить файл (уведомляет все компоненты)
  Future<void> saveFile(String filePath, String content) async {
    codelabLogger.i('FileSyncService: Saving file $filePath', tag: 'file_sync_service');
    final result = await _fileService.writeFile(filePath, content).run();
    await result.match(
      (error) async {
        codelabLogger.e('FileSyncService: Error saving file $filePath: $error', tag: 'file_sync_service');
      },
      (_) async {
        _fileSavedController.add(filePath);
        codelabLogger.i('FileSyncService: File saved successfully $filePath', tag: 'file_sync_service');
      },
    );
  }

  /// Файл был изменен во внешнем редакторе
  void notifyFileChanged(String filePath) {
    codelabLogger.i('FileSyncService: File changed externally $filePath', tag: 'file_sync_service');
    _fileChangedController.add(filePath);
  }

  /// Файл был удален
  void notifyFileDeleted(String filePath) {
    codelabLogger.i('FileSyncService: File deleted $filePath', tag: 'file_sync_service');
    _fileDeletedController.add(filePath);
  }

  /// Файловое дерево изменилось
  void notifyFileTreeChanged() {
    codelabLogger.i('FileSyncService: File tree changed', tag: 'file_sync_service');
    _fileTreeChangedController.add(null);
  }

  /// Настройка слушателя изменений проекта
  void _setupProjectListener() {
    codelabLogger.i('FileSyncService: Setting up project listener', tag: 'file_sync_service');
    _projectSubscription = _projectManagerService.projectStream.listen((
      config,
    ) {
      if (config != null) {
        codelabLogger.i('FileSyncService: Project opened: ${config.path}', tag: 'file_sync_service');
        _startWatchingProject(config.path);
      } else {
        codelabLogger.i('FileSyncService: Project closed', tag: 'file_sync_service');
        _stopWatching();
      }
    });
  }

  /// Запуск отслеживания изменений в проекте
  void _startWatchingProject(String projectPath) {
    codelabLogger.i('FileSyncService: Starting to watch project: $projectPath', tag: 'file_sync_service');
    _stopWatching(); // Останавливаем предыдущее отслеживание

    final task = _fileWatcherService.watchDirectory(projectPath);
    task.run().then((result) {
      result.match(
        (error) {
          codelabLogger.e('FileSyncService: Error starting file watching: $error', tag: 'file_sync_service');
        },
        (stream) {
          codelabLogger.i('FileSyncService: File watching started successfully', tag: 'file_sync_service');
          _fileWatcherSubscription = stream.listen(_handleFileSystemEvent);
        },
      );
    });
  }

  /// Обработка событий файловой системы
  void _handleFileSystemEvent(FileSystemEvent event) {
    codelabLogger.i(
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
    codelabLogger.i('FileSyncService: File created: $filePath', tag: 'file_sync_service');
    notifyFileTreeChanged();
  }

  void _handleFileModified(String filePath) {
    codelabLogger.i('FileSyncService: File modified: $filePath', tag: 'file_sync_service');
    _fileChangedController.add(filePath);
  }

  void _handleFileDeleted(String filePath) {
    codelabLogger.i('FileSyncService: File deleted: $filePath', tag: 'file_sync_service');
    _fileDeletedController.add(filePath);
    notifyFileTreeChanged();
  }

  void _handleFileMoved(String newPath, String? oldPath) {
    codelabLogger.i('FileSyncService: File moved: $oldPath -> $newPath', tag: 'file_sync_service');
    if (oldPath != null) {
      _fileDeletedController.add(oldPath);
    }
    notifyFileTreeChanged();
  }

  /// Остановка отслеживания
  void _stopWatching() {
    codelabLogger.i('FileSyncService: Stopping file watching', tag: 'file_sync_service');
    _fileWatcherSubscription?.cancel();
    _fileWatcherSubscription = null;
    _fileWatcherService.stopWatching();
  }

  /// Освобождение ресурсов
  void dispose() {
    codelabLogger.i('FileSyncService: Disposing', tag: 'file_sync_service');
    _stopWatching();
    _projectSubscription?.cancel();
    _fileOpenedController.close();
    _fileSavedController.close();
    _fileChangedController.close();
    _fileDeletedController.close();
    _fileTreeChangedController.close();
  }
}
