import 'dart:io';
import 'package:fpdart/fpdart.dart';

/// Конфигурация проекта для различных языков программирования
class ProjectConfig {
  final String name;
  final String path;
  final String type; // dart, python, flutter, node, java, etc.
  final Map<String, dynamic> settings;
  final List<String> buildCommands;
  final List<String> runCommands;
  final List<String> testCommands;
  final Map<String, String> environment;

  ProjectConfig({
    required this.name,
    required this.path,
    required this.type,
    this.settings = const {},
    this.buildCommands = const [],
    this.runCommands = const [],
    this.testCommands = const [],
    this.environment = const {},
  });

  factory ProjectConfig.fromJson(Map<String, dynamic> json) {
    return ProjectConfig(
      name: json['name'] ?? 'Untitled Project',
      path: json['path'] ?? '',
      type: json['type'] ?? 'unknown',
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      buildCommands: List<String>.from(json['buildCommands'] ?? []),
      runCommands: List<String>.from(json['runCommands'] ?? []),
      testCommands: List<String>.from(json['testCommands'] ?? []),
      environment: Map<String, String>.from(json['environment'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type,
      'settings': settings,
      'buildCommands': buildCommands,
      'runCommands': runCommands,
      'testCommands': testCommands,
      'environment': environment,
    };
  }

  /// Определяет тип проекта на основе файлов в директории
  static Either<String, String> detectProjectType(String projectPath) {
    final directory = Directory(projectPath);
    if (!directory.existsSync()) {
      return Left('Directory does not exist');
    }

    final files = directory.listSync();
    final fileNames = files.map((e) => e.path.split('/').last).toList();

    if (fileNames.contains('pubspec.yaml')) {
      if (fileNames.contains('android') || fileNames.contains('ios')) {
        return const Right('flutter');
      }
      return const Right('dart');
    } else if (fileNames.contains('package.json')) {
      return const Right('node');
    } else if (fileNames.contains('requirements.txt') || 
               fileNames.any((f) => f.endsWith('.py'))) {
      return const Right('python');
    } else if (fileNames.contains('pom.xml') || 
               fileNames.any((f) => f.endsWith('.java'))) {
      return const Right('java');
    } else if (fileNames.contains('Cargo.toml')) {
      return const Right('rust');
    } else if (fileNames.contains('go.mod')) {
      return const Right('go');
    }

    return const Right('unknown');
  }

  /// Создает конфигурацию проекта по умолчанию для определенного типа
  static ProjectConfig createDefault(String projectPath, String projectType) {
    final projectName = projectPath.split('/').last;
    
    final defaultConfigs = {
      'flutter': ProjectConfig(
        name: projectName,
        path: projectPath,
        type: 'flutter',
        buildCommands: ['flutter build'],
        runCommands: ['flutter run'],
        testCommands: ['flutter test'],
        environment: {'FLUTTER_ROOT': ''},
      ),
      'dart': ProjectConfig(
        name: projectName,
        path: projectPath,
        type: 'dart',
        buildCommands: ['dart compile exe bin/main.dart'],
        runCommands: ['dart run'],
        testCommands: ['dart test'],
      ),
      'node': ProjectConfig(
        name: projectName,
        path: projectPath,
        type: 'node',
        buildCommands: ['npm run build'],
        runCommands: ['npm start'],
        testCommands: ['npm test'],
      ),
      'python': ProjectConfig(
        name: projectName,
        path: projectPath,
        type: 'python',
        buildCommands: [],
        runCommands: ['python main.py'],
        testCommands: ['python -m pytest'],
      ),
      'java': ProjectConfig(
        name: projectName,
        path: projectPath,
        type: 'java',
        buildCommands: ['mvn compile'],
        runCommands: ['mvn exec:java'],
        testCommands: ['mvn test'],
      ),
    };

    return defaultConfigs[projectType] ?? ProjectConfig(
      name: projectName,
      path: projectPath,
      type: 'unknown',
    );
  }
}