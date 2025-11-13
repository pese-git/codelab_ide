import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_engine/codelab_engine.dart';
import 'package:codelab_ide/pages/ide_root_page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CodeLapApp extends StatelessWidget {
  const CodeLapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProjectBloc>(
          create: (context) => ProjectBloc(
            fileService: CherryPick.openRootScope().resolve<FileService>(),
            runService: CherryPick.openRootScope().resolve<RunService>(),
          ),
        ),
        //BlocProvider<ExplorerBloc>(
        //  create: (context) => ExplorerBloc(
        //    fileService: CherryPick.openRootScope().resolve<FileService>(),
        //    projectManagerService: CherryPick.openRootScope()
        //        .resolve<ProjectManagerService>(),
        //  ),
        //),
        BlocProvider<ProjectManagementBloc>(
          create: (context) => ProjectManagementBloc(
            projectService: CherryPick.openRootScope()
                .resolve<ProjectService>(),
            fileService: CherryPick.openRootScope().resolve<FileService>(),
            runService: CherryPick.openRootScope().resolve<RunService>(),
            projectManagerService: CherryPick.openRootScope()
                .resolve<ProjectManagerService>(),
          ),
        ),
      ],
      child: FluentApp(
        title: 'Codelab IDE',
        theme: FluentThemeData(
          brightness: Brightness.light,
          accentColor: Colors.blue,
        ),
        home: const IdeRootPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
