import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:codelab_engine/deprecate/widgets/project_management/project_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectManagementWidget extends StatelessWidget {
  const ProjectManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectManagementBloc, ProjectManagementState>(
      builder: (context, state) {
        return Column(
          children: [
            // Панель управления проектом
            _buildProjectToolbar(context, state),
            const SizedBox(height: 8),
            // Статус проекта
            _buildProjectStatus(context, state),
          ],
        );
      },
    );
  }

  Widget _buildProjectToolbar(
    BuildContext context,
    ProjectManagementState state,
  ) {
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
            // Кнопки управления для открытого проекта
            if (state is LoadedProjectState) ...[
              ElevatedButton.icon(
                onPressed: () => context.read<ProjectManagementBloc>().add(
                  const SaveProjectEvent(),
                ),
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.read<ProjectManagementBloc>().add(
                  const BuildProjectEvent(),
                ),
                icon: const Icon(Icons.build),
                label: const Text('Build'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.read<ProjectManagementBloc>().add(
                  const RunProjectEvent(),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.read<ProjectManagementBloc>().add(
                  const TestProjectEvent(),
                ),
                icon: const Icon(Icons.bug_report),
                label: const Text('Test'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.read<ProjectManagementBloc>().add(
                  const CloseProjectEvent(),
                ),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStatus(
    BuildContext context,
    ProjectManagementState state,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.info, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: state.when(
                initial: () => const Text('No project opened'),
                loading: () => const Text('Loading project...'),
                loaded: (project, fileTree, hasUnsavedChanges) => Text(
                  'Project: ${project.name} (${project.type})'
                  '${hasUnsavedChanges ? ' • Unsaved changes' : ''}',
                ),
                building: () => const Text('Building project...'),
                running: () => const Text('Running project...'),
                testing: () => const Text('Running tests...'),
                error: (message) => Text(
                  'Error: $message',
                  style: const TextStyle(color: Colors.red),
                ),
                recentProjectsLoaded: (projects) =>
                    Text('Recent projects: ${projects.length}'),
              ),
            ),
          ],
        ),
      ),
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
                context.read<ProjectManagementBloc>().add(
                  CreateProjectEvent(
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
          context.read<ProjectManagementBloc>().add(
            OpenProjectEvent(projectPath),
          );
        }
      },
    );
  }
}
