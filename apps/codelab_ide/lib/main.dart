import 'dart:io';

import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_ide/codelab_app.dart';
import 'package:codelab_ide/di/app_di_module.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:xterm/core.dart';

import 'package:logger/logger.dart'
    show Level, MultiOutput, ConsoleOutput, SimplePrinter;
import 'utils/date_and_size_rotating_file_log_output.dart';
import 'utils/xterm_log_output.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logDir = Directory('${Platform.environment['HOME']}/.codelab_ide/logs/')
    ..createSync(recursive: true); // обязательно создать поддиректорию!

  CherryPick.openRootScope().installModules([AppDiModule(), EngineDiModule()]);
  // Настройка CodelabLogger вместо initLogger
  codelabLogger.configure(
    level: Level.debug, // уровень логирования, можно повысить в релизе
    output: MultiOutput([
      ConsoleOutput(),
      XtermLogOutput(
        CherryPick.openRootScope().resolve<Terminal>(named: 'outputTerminal'),
      ),
      DateAndSizeRotatingFileLogOutput(
        directory: logDir.path,
        baseName: 'codelab',
        maxFileSizeBytes: 5 * 1024 * 1024,
        maxFilesPerDay: 5,
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
