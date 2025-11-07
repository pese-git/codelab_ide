import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';

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
