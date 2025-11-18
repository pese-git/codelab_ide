import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_ide/codelab_app.dart';
import 'package:codelab_ide/di/app_di_module.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:xterm/core.dart';

import 'package:logger/logger.dart' show Level, MultiOutput, ConsoleOutput, SimplePrinter;
import 'package:codelab_core/logger/codelab_logger.dart';
import 'utils/xterm_log_output.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CherryPick.openRootScope().installModules([AppDiModule(), EngineDiModule()]);
  // Настройка CodelabLogger вместо initLogger
  codelabLogger.configure(
    level: Level.debug, // уровень логирования, можно повысить в релизе
    output: MultiOutput([
      ConsoleOutput(),
      XtermLogOutput(
        CherryPick.openRootScope().resolve<Terminal>(named: 'outputTerminal'),
      ),
    ]),
    printer: SimplePrinter(),
  );

  // Получить текущий конфиг
  final service = await CherryPick.openRootScope()
      .resolveAsync<GlobalConfigService>();
  final settings = service.getConfig('settings.json');
  codelabLogger.i("Settings: $settings", tag: 'main');

  // Слушать изменения
  service.onChanged.listen((filename) async {
    codelabLogger.i('Файл $filename изменен', tag: 'main');
    final service = await CherryPick.openRootScope()
        .resolveAsync<GlobalConfigService>();
    final settings = service.getConfig('settings.json');
    codelabLogger.i("Settings: $settings", tag: 'main');
  });
  runApp(const CodeLapApp());
}
