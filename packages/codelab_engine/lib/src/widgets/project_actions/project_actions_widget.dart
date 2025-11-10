import 'package:codelab_core/codelab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'project_actions_bloc.dart';

/// Виджет для управления действиями проекта (Build/Run/Test/Save/Close)
class ProjectActionsWidget extends StatelessWidget {
  const ProjectActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectActionsBloc(
        runService: context.read<RunService>(),
        projectManagerService: context.read<ProjectManagerService>(),
      ),
      child: BlocListener<ProjectActionsBloc, ProjectActionsState>(
        listener: (context, state) {
          // Обработка ошибок
          if (state is ProjectActionsErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: const _ProjectActionsContent(),
      ),
    );
  }
}

class _ProjectActionsContent extends StatelessWidget {
  const _ProjectActionsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectActionsBloc, ProjectActionsState>(
      builder: (context, state) {
        // Показываем кнопки действий только когда проект загружен
        final projectManager = context.read<ProjectManagerService>();
        final hasProject = projectManager.currentProject != null;

        if (!hasProject) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // Кнопка сборки
                ElevatedButton.icon(
                  onPressed: () => context.read<ProjectActionsBloc>().add(
                    const ProjectActionsEvent.buildProject(),
                  ),
                  icon: const Icon(Icons.build),
                  label: const Text('Build'),
                ),
                const SizedBox(width: 8),
                // Кнопка запуска
                ElevatedButton.icon(
                  onPressed: () => context.read<ProjectActionsBloc>().add(
                    const ProjectActionsEvent.runProject(),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run'),
                ),
                const SizedBox(width: 8),
                // Кнопка тестирования
                ElevatedButton.icon(
                  onPressed: () => context.read<ProjectActionsBloc>().add(
                    const ProjectActionsEvent.testProject(),
                  ),
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
