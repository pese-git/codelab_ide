import 'dart:async';
import 'package:codelab_core/codelab_core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/subjects.dart';
import '../models/project_config.dart';

/// Глобальный сервис для управления текущим проектом с реактивным обновлением
abstract interface class ProjectManagerService {
  /// Текущий активный проект
  ProjectConfig? get currentProject;

  /// Stream для отслеживания изменений проекта
  Stream<ProjectConfig?> get projectStream;

  /// Установить текущий проект
  void setCurrentProject(ProjectConfig project);

  /// Очистить текущий проект
  void clearCurrentProject();

  /// Получить текущий проект или ошибку если проект не загружен
  Either<String, ProjectConfig> getCurrentProjectOrError();
}

class ProjectManagerServiceImpl implements ProjectManagerService {
  ProjectConfig? _currentProject;
  final _projectController = BehaviorSubject<ProjectConfig?>();

  @override
  ProjectConfig? get currentProject => _currentProject;

  @override
  Stream<ProjectConfig?> get projectStream => _projectController.stream;

  @override
  void setCurrentProject(ProjectConfig project) {
    _currentProject = project;
    _projectController.add(project);
  }

  @override
  void clearCurrentProject() {
    _currentProject = null;
    _projectController.add(null);
  }

  @override
  Either<String, ProjectConfig> getCurrentProjectOrError() {
    return _currentProject != null
        ? Right(_currentProject!)
        : Left('No project is currently loaded');
  }

  void dispose() {
    _projectController.close();
  }
}
