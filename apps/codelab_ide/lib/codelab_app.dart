import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_ide/pages/home_page.dart';
import 'package:codelab_ide/project_bloc.dart';
import 'package:codelab_ide/services/file_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CodeLapApp extends StatelessWidget {
  const CodeLapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectBloc>(
      create: (context) => ProjectBloc(
        fileService: CherryPick.openRootScope().resolve<FileService>(),
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
