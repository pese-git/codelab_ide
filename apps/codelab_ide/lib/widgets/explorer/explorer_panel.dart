import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_ide/widgets/explorer/explorer_bloc.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:codelab_uikit/codelab_uikit.dart'
    as uikit
    show ExplorerPanel, FileNode;
import 'package:flutter_bloc/flutter_bloc.dart';

class ExplorerPanel extends StatelessWidget {
  final void Function(uikit.FileNode) onFileOpen;
  const ExplorerPanel({super.key, required this.onFileOpen});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExplorerBloc>(
      create: (context) => ExplorerBloc(
        projectManagerService: CherryPick.openRootScope()
            .resolve<ProjectManagerService>(),
        fileService: CherryPick.openRootScope().resolve<FileService>(),
      ),
      child: BlocConsumer<ExplorerBloc, ExplorerState>(
        builder: (context, state) {
          return uikit.ExplorerPanel(
            files: state.fileTree != null ? [state.fileTree!] : [],
            onFileOpen: onFileOpen,
          );
        },
        listener: (context, state) {},
      ),
    );
  }
}
