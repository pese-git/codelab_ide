import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:codelab_ide/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CodeLapApp extends StatelessWidget {
  const CodeLapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectBloc>(
      create: (context) => ProjectBloc(
        fileService: CherryPick.openRootScope().resolve<FileService>(), 
        runService: CherryPick.openRootScope().resolve<RunService>(),
      ),
      child: MaterialApp(
        title: 'CodeLab IDE',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const IDEHomePage(),
      ),
    );
  }
}
