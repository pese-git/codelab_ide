import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'select_project_bloc.dart';

/// Виджет для выбора и создания проектов (New Project/Open Project)
class SelectProjectWidget extends StatelessWidget {
  const SelectProjectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelectProjectBloc(
        projectService: CherryPick.openRootScope().resolve<ProjectService>(),

        projectManagerService: CherryPick.openRootScope()
            .resolve<ProjectManagerService>(),
      ),
      child: BlocListener<SelectProjectBloc, SelectProjectState>(
        listener: (context, state) {
          // Обработка ошибок
          if (state is SelectProjectErrorState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: const _SelectProjectContent(),
      ),
    );
  }
}

class _SelectProjectContent extends StatelessWidget {
  const _SelectProjectContent();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Кнопка создания проекта
            ElevatedButton.icon(
              onPressed: () => _showCreateProjectDialog(context),
              icon: const Icon(Icons.create_new_folder),
              label: const Text('New Project'),
            ),
            const SizedBox(width: 8),
            // Кнопка открытия проекта
            ElevatedButton.icon(
              onPressed: () => _openProject(context),
              icon: const Icon(Icons.folder_open),
              label: const Text('Open Project'),
            ),
            const Spacer(),
            // Статус проекта
            _buildProjectStatus(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStatus(BuildContext context) {
    return BlocBuilder<SelectProjectBloc, SelectProjectState>(
      builder: (context, state) {
        return Row(
          children: [
            const Icon(Icons.info, size: 16),
            const SizedBox(width: 8),
            Text(
              state.when(
                initial: () => 'No project opened',
                creating: () => 'Creating project...',
                opening: () => 'Opening project...',
                created: (project) => 'Created: ${project.name}',
                opened: (project) => 'Opened: ${project.name}',
                error: (message) => 'Error: $message',
                recentProjectsLoaded: (projects) =>
                    'Recent projects: ${projects.length}',
              ),
              style: TextStyle(
                color: state is SelectProjectErrorState ? Colors.red : null,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    String selectedType = 'dart';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'my_project',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                labelText: 'Project Path',
                hintText: '/path/to/projects',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: const [
                DropdownMenuItem(value: 'dart', child: Text('Dart Project')),
                DropdownMenuItem(
                  value: 'flutter',
                  child: Text('Flutter Project'),
                ),
                DropdownMenuItem(value: 'node', child: Text('Node.js Project')),
                DropdownMenuItem(
                  value: 'python',
                  child: Text('Python Project'),
                ),
                DropdownMenuItem(value: 'java', child: Text('Java Project')),
              ],
              onChanged: (value) => selectedType = value!,
              decoration: const InputDecoration(labelText: 'Project Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  pathController.text.isNotEmpty) {
                context.read<SelectProjectBloc>().add(
                  SelectProjectEvent.createProject(
                    name: nameController.text,
                    path: pathController.text,
                    type: selectedType,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openProject(BuildContext context) async {
    final fileService = CherryPick.openRootScope().resolve<FileService>();
    final result = await fileService.pickProjectDirectory().run();

    result.match(
      (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open project: $error'))),
      (projectPath) {
        if (projectPath != null) {
          context.read<SelectProjectBloc>().add(
            SelectProjectEvent.openProject(projectPath),
          );
        }
      },
    );
  }
}
