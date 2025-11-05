import 'package:codelab_ide/codelab_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'project_bloc.dart';

void main() {
  runApp(
    BlocProvider<ProjectBloc>(
      create: (context) => ProjectBloc(),
      child: const MyApp(),
    ),
  );
}
