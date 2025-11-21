import 'build_mode.dart';
import '../models/project_config.dart';
import 'build_result.dart';

abstract interface class ProjectBuildService {
  Future<BuildResult> build(ProjectConfig config, BuildMode mode);
  Future<BuildResult> run(ProjectConfig config, BuildMode mode);
}
