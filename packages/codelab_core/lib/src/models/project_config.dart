import 'dart:io';
import 'package:fpdart/fpdart.dart';

/// Basic project config for Dart only (can be extended later)
class ProjectConfig {
  final String name;
  final String path;
  final String type; // 'dart'
  final String entrypoint;
  final Map<String, dynamic> settings;
  final List<String> buildCommands;
  final List<String> runCommands;
  final List<String> testCommands;
  final Map<String, String> environment;

  ProjectConfig({
    required this.name,
    required this.path,
    required this.type,
    required this.entrypoint,
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
      type: json['type'] ?? 'dart',
      entrypoint: json['entrypoint'] ?? 'bin/main.dart',
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
      'entrypoint': entrypoint,
      'settings': settings,
      'buildCommands': buildCommands,
      'runCommands': runCommands,
      'testCommands': testCommands,
      'environment': environment,
    };
  }

  /// Detects Dart project by presence of pubspec.yaml (can be extended)
  static Either<String, String> detectProjectType(String projectPath) {
    final directory = Directory(projectPath);
    if (!directory.existsSync()) {
      return Left('Directory does not exist');
    }
    final files = directory.listSync();
    final fileNames = files.map((e) => e.path.split('/').last).toList();
    if (fileNames.contains('pubspec.yaml')) {
      return const Right('dart');
    }
    return const Right('unknown');
  }

  /// Creates a default Dart project config
  static ProjectConfig createDefault(String projectPath) {
    final projectName = projectPath.split('/').last;
    return ProjectConfig(
      name: projectName,
      path: projectPath,
      type: 'dart',
      entrypoint: 'bin/main.dart',
      buildCommands: ['dart compile exe bin/main.dart'],
      runCommands: ['dart run'],
      testCommands: ['dart test'],
    );
  }
}
