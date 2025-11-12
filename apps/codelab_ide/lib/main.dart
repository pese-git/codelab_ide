import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_ide/di/app_di_module.dart';
import 'package:codelab_ide/pages/ide_root_page.dart';
import 'package:fluent_ui/fluent_ui.dart';

void main() {
  CherryPick.openRootScope().installModules([AppDiModule()]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Codelab IDE',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
      ),
      home: const IdeRootPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}




/*
import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_ide/codelab_app.dart';
import 'package:codelab_ide/di/app_di_module.dart';
import 'package:flutter/material.dart';

void main() {
  CherryPick.openRootScope().installModules([AppDiModule()]);
  runApp(const CodeLapApp());
}
*/