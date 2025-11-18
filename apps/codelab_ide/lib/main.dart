import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_ide/codelab_app.dart';
import 'package:codelab_ide/di/app_di_module.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logger/logger.dart';
import 'package:xterm/core.dart';

import 'utils/xterm_log_output.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Получить текущий конфиг
  final service = await CherryPick.openRootScope()
      .resolveAsync<GlobalConfigService>();
  final settings = service.getConfig('settings.json');
  logger.i("Settings: $settings");

  // Слушать изменения
  service.onChanged.listen((filename) async {
    logger.i('Файл $filename изменен');
    final service = await CherryPick.openRootScope()
        .resolveAsync<GlobalConfigService>();
    final settings = service.getConfig('settings.json');
    logger.i("Settings: $settings");
  });
  runApp(const CodeLapApp());
}
