import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_engine/codelab_engine.dart';

class AppDiModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<FileService>().toProvide(() => FileServiceImpl()).singleton();
    bind<RunService>()
        .toProvide(
          () =>
              RunServiceImpl(fileService: currentScope.resolve<FileService>()),
        )
        .singleton();
    bind<ProjectService>()
        .toProvide(() => ProjectServiceImpl())
        .singleton();
    bind<ProjectManagerService>()
        .toProvide(() => ProjectManagerServiceImpl())
        .singleton();
    bind<FileWatcherService>()
        .toProvide(() => FileWatcherServiceImpl())
        .singleton();
    bind<FileSyncService>()
        .toProvide(() => FileSyncService(
              fileService: currentScope.resolve<FileService>(),
              fileWatcherService: currentScope.resolve<FileWatcherService>(),
              projectManagerService: currentScope.resolve<ProjectManagerService>(),
            ))
        .singleton();
  }
}