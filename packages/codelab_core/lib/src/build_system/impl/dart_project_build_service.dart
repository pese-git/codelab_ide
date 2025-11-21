import '../project_build_service.dart';
import '../build_mode.dart';
import '../../models/project_config.dart';
import '../build_result.dart';

class DartProjectBuildService implements ProjectBuildService {
  @override
  Future<BuildResult> build(ProjectConfig config, BuildMode mode) async {
    // Пример для release-режима:
    // Реальная реализация: запуск "dart compile exe ${config.entrypoint}"
    if (mode == BuildMode.release) {
      // TODO: вызвать Process.run('dart', ['compile', 'exe', config.entrypoint])
      // Обработка stdout/stderr
      // Возвращаем успешный (пока заглушка):
      return BuildResult(success: true, outputPath: 'build/${config.entrypoint}.exe');
    }
    // Для debug — сборка не требуется, сразу true
    return BuildResult(success: true);
  }

  @override
  Future<BuildResult> run(ProjectConfig config, BuildMode mode) async {
    String command;
    if (mode == BuildMode.debug) {
      command = 'dart run --observe ${config.entrypoint}';
    } else {
      command = 'dart run --release ${config.entrypoint}';
    }
    // Реализовать Process.start или Process.run команду выше,
    // вернуть BuildResult с успешностью и путём/ошибкой
    return BuildResult(success: true);
  }
}
