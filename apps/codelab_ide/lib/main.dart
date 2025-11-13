import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_ide/codelab_app.dart';
import 'package:codelab_ide/di/app_di_module.dart';
import 'package:fluent_ui/fluent_ui.dart';

void main() {
  CherryPick.openRootScope().installModules([AppDiModule()]);
  runApp(const CodeLapApp());
}
