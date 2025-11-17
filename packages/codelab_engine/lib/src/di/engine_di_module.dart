import 'package:cherrypick/cherrypick.dart';
import '../services/editor_manager_service.dart';

/// DI модуль для codelab_engine
class EngineDiModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<EditorManagerService>()
        .toProvide(() => EditorManagerService())
        .singleton();
  }
}
