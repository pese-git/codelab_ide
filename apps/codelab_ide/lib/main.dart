import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:codelab_ide/codelab_app.dart';
import 'package:flutter/material.dart';

void main() {
  CherryPick.openRootScope().installModules([AppDiModule()]);
  runApp(const CodeLapApp());
}
