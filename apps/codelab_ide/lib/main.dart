import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_ide/codelab_app.dart';
import 'package:codelab_ide/di/app_di_module.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logger/logger.dart';
import 'package:xterm/core.dart';

import 'utils/xterm_log_output.dart';

void main() {
  CherryPick.openRootScope().installModules([AppDiModule(), EngineDiModule()]);
  initLogger(
    SimplePrinter(),
    MultiOutput([
      ConsoleOutput(),
      XtermLogOutput(
        CherryPick.openRootScope().resolve<Terminal>(named: 'outputTerminal'),
      ),
    ]),
  );

  runApp(const CodeLapApp());
}
