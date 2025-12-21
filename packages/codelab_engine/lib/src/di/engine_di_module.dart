import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_engine/src/services/lsp_service.dart';
import '../services/editor_manager_service.dart';

/// DI модуль для codelab_engine
class EngineDiModule extends Module {
  @override
  void builder(Scope currentScope) {
    bind<LspService>().toProvide(() => LspService()).singleton();
    bind<EditorManagerService>()
        .toProvide(() => EditorManagerService())
        .singleton();
  }
}
