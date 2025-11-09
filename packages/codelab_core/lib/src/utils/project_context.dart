import 'package:codelab_core/codelab_core.dart';
import 'package:fpdart/fpdart.dart';

/// Утилиты для удобного доступа к текущему проекту из любого места
class ProjectContext {
  /// Получить текущий проект через DI
  static ProjectConfig? getCurrentProject(ProjectManagerService projectManager) {
    return projectManager.currentProject;
  }
  
  /// Получить текущий проект или ошибку
  static Either<String, ProjectConfig> getCurrentProjectOrError(
    ProjectManagerService projectManager,
  ) {
    return projectManager.getCurrentProjectOrError();
  }
  
  /// Подписаться на изменения проекта
  static Stream<ProjectConfig?> watchProjectChanges(
    ProjectManagerService projectManager,
  ) {
    return projectManager.projectStream;
  }
  
  /// Проверить, загружен ли проект определенного типа
  static bool isProjectType(
    ProjectManagerService projectManager, 
    String type,
  ) {
    final project = projectManager.currentProject;
    return project?.type == type;
  }
  
  /// Получить команды сборки для текущего проекта
  static List<String> getBuildCommands(ProjectManagerService projectManager) {
    final project = projectManager.currentProject;
    return project?.buildCommands ?? [];
  }
  
  /// Получить команды запуска для текущего проекта
  static List<String> getRunCommands(ProjectManagerService projectManager) {
    final project = projectManager.currentProject;
    return project?.runCommands ?? [];
  }
  
  /// Получить команды тестирования для текущего проекта
  static List<String> getTestCommands(ProjectManagerService projectManager) {
    final project = projectManager.currentProject;
    return project?.testCommands ?? [];
  }
}