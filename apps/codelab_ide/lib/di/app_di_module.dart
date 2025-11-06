import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_ide/services/file_service.dart';
import 'package:codelab_ide/services/run_service.dart';

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
  }
}
