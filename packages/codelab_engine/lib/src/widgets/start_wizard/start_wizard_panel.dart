import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_uikit/widgets/placeholder/start_wizard.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'start_wizard_bloc.dart';

class StartWizardPanel extends StatelessWidget {
  final void Function(String action) onAction;

  const StartWizardPanel({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StartWizardBloc>(
      create: (context) => StartWizardBloc(
        projectService: CherryPick.openRootScope().resolve<ProjectService>(),
        projectManagerService: CherryPick.openRootScope()
            .resolve<ProjectManagerService>(),
        fileService: CherryPick.openRootScope().resolve<FileService>(),
      ),
      child: BlocConsumer<StartWizardBloc, StartWizardState>(
        builder: (context, state) {
          return StartWizard(
            onAction: (path) {
              context.read<StartWizardBloc>().add(
                StartWizardEvent.openProject(),
              );
            },
          );
        },
        listener: (context, state) async {
          if (state is ProjectOpenedState) {
            onAction.call('');
          }
          // Обработка ошибок
          if (state is SelectProjectErrorState) {
            await displayInfoBar(
              context,
              builder: (context, close) {
                return InfoBar(
                  title: const Text('Error'),
                  content: Text("Failed to open project: ${state.message}"),
                  action: IconButton(
                    icon: const WindowsIcon(WindowsIcons.clear),
                    onPressed: close,
                  ),
                  severity: InfoBarSeverity.warning,
                );
              },
            );
          }
        },
      ),
    );
  }
}
