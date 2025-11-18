import 'dart:convert';
import 'dart:io';
import 'package:codelab_core/codelab_core.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ProjectService {
  TaskEither<FileError, ProjectConfig> createProject({
    required String name,
    required String path,
    required String type,
  });

  TaskEither<FileError, ProjectConfig> loadProject(String projectPath);
  TaskEither<FileError, bool> saveProjectConfig(ProjectConfig config);
  TaskEither<FileError, List<ProjectConfig>> getRecentProjects();
  TaskEither<FileError, ProjectConfig> detectAndConfigureProject(
    String projectPath,
  );
}

class ProjectServiceImpl implements ProjectService {
  ProjectServiceImpl();

  @override
  TaskEither<FileError, ProjectConfig> createProject({
    required String name,
    required String path,
    required String type,
  }) {
    return TaskEither<FileError, ProjectConfig>.tryCatch(
      () async {
        final projectPath = '$path${Platform.pathSeparator}$name';
        final directory = Directory(projectPath);

        if (await directory.exists()) {
          throw FileError('Project directory already exists: $projectPath');
        }

        await directory.create(recursive: true);

        // Создаем базовые файлы в зависимости от типа проекта
        await _createProjectStructure(projectPath, type);

        final config = ProjectConfig.createDefault(projectPath, type);
        await _saveConfigToFile(config);

        return config;
      },
      (error, stackTrace) {
        if (error is FileError) return error;
        return FileError('Failed to create project: $error');
      },
    );
  }

  @override
  TaskEither<FileError, ProjectConfig> loadProject(String projectPath) {
    return TaskEither<FileError, ProjectConfig>.tryCatch(
      () async {
        final configFile = File(
          '$projectPath${Platform.pathSeparator}.codelab_project.json',
        );

        if (await configFile.exists()) {
          final content = await configFile.readAsString();
          final json = Map<String, dynamic>.from(jsonDecode(content));
          return ProjectConfig.fromJson(json);
        } else {
          // Автоопределение типа проекта без рекурсии
          final directory = Directory(projectPath);
          if (!directory.existsSync()) {
            throw FileError('Project directory does not exist: $projectPath');
          }

          final files = directory.listSync();
          final fileNames = files.map((e) => e.path.split('/').last).toList();

          String projectType = 'unknown';
          if (fileNames.contains('pubspec.yaml')) {
            projectType =
                fileNames.contains('android') || fileNames.contains('ios')
                ? 'flutter'
                : 'dart';
          } else if (fileNames.contains('package.json')) {
            projectType = 'node';
          } else if (fileNames.contains('requirements.txt') ||
              fileNames.any((f) => f.endsWith('.py'))) {
            projectType = 'python';
          } else if (fileNames.contains('pom.xml') ||
              fileNames.any((f) => f.endsWith('.java'))) {
            projectType = 'java';
          }

          final config = ProjectConfig.createDefault(projectPath, projectType);
          await _saveConfigToFile(config);
          return config;
        }
      },
      (error, stackTrace) {
        if (error is FileError) return error;
        return FileError('Failed to load project: $error');
      },
    );
  }

  @override
  TaskEither<FileError, ProjectConfig> detectAndConfigureProject(
    String projectPath,
  ) {
    return TaskEither<FileError, ProjectConfig>.tryCatch(
      () async {
        // Простая реализация определения типа проекта
        final directory = Directory(projectPath);
        if (!directory.existsSync()) {
          throw FileError('Project directory does not exist: $projectPath');
        }

        final files = directory.listSync();
        final fileNames = files.map((e) => e.path.split('/').last).toList();

        String projectType = 'unknown';
        if (fileNames.contains('pubspec.yaml')) {
          projectType =
              fileNames.contains('android') || fileNames.contains('ios')
              ? 'flutter'
              : 'dart';
        } else if (fileNames.contains('package.json')) {
          projectType = 'node';
        } else if (fileNames.contains('requirements.txt') ||
            fileNames.any((f) => f.endsWith('.py'))) {
          projectType = 'python';
        } else if (fileNames.contains('pom.xml') ||
            fileNames.any((f) => f.endsWith('.java'))) {
          projectType = 'java';
        }

        final config = ProjectConfig.createDefault(projectPath, projectType);
        await _saveConfigToFile(config);
        return config;
      },
      (error, stackTrace) {
        if (error is FileError) return error;
        return FileError('Failed to detect project: $error');
      },
    );
  }

  @override
  TaskEither<FileError, bool> saveProjectConfig(ProjectConfig config) {
    return TaskEither<FileError, bool>.tryCatch(
      () async {
        await _saveConfigToFile(config);
        return true;
      },
      (error, stackTrace) {
        if (error is FileError) return error;
        return FileError('Failed to save project config: $error');
      },
    );
  }

  @override
  TaskEither<FileError, List<ProjectConfig>> getRecentProjects() {
    return TaskEither<FileError, List<ProjectConfig>>.tryCatch(
      () async {
        // В реальном приложении здесь будет чтение из базы данных или файла настроек
        return [];
      },
      (error, stackTrace) =>
          FileError('Failed to load recent projects: $error'),
    );
  }

  Future<void> _createProjectStructure(String projectPath, String type) async {
    switch (type) {
      case 'dart':
        final pubspec = File(
          '$projectPath${Platform.pathSeparator}pubspec.yaml',
        );
        await pubspec.writeAsString('''
name: ${projectPath.split(Platform.pathSeparator).last}
version: 1.0.0
environment:
  sdk: ^3.0.0

dependencies:

dev_dependencies:
''');
        final binDir = Directory('$projectPath${Platform.pathSeparator}bin');
        await binDir.create();
        final mainFile = File(
          '$projectPath${Platform.pathSeparator}bin${Platform.pathSeparator}main.dart',
        );
        await mainFile.writeAsString('''
void main() {
  print('Hello, World!');
}
''');
        break;

      case 'python':
        final mainFile = File('$projectPath${Platform.pathSeparator}main.py');
        await mainFile.writeAsString('''
def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
''');
        break;

      case 'node':
        final packageJson = File(
          '$projectPath${Platform.pathSeparator}package.json',
        );
        await packageJson.writeAsString('''
{
  "name": "${projectPath.split(Platform.pathSeparator).last}",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \\"Error: no test specified\\" && exit 1"
  }
}
''');
        final indexFile = File('$projectPath${Platform.pathSeparator}index.js');
        await indexFile.writeAsString('''
console.log("Hello, World!");
''');
        break;
    }
  }

  Future<void> _saveConfigToFile(ProjectConfig config) async {
    final configFile = File(
      '${config.path}${Platform.pathSeparator}.codelab_project.json',
    );
    await configFile.writeAsString(jsonEncode(config.toJson()));
  }
}
