import 'package:bloc/bloc.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_actions_bloc.freezed.dart';

@freezed
class ProjectActionsEvent with _$ProjectActionsEvent {
  const factory ProjectActionsEvent.buildProject() = BuildProjectEvent;

  const factory ProjectActionsEvent.runProject() = RunProjectEvent;

  const factory ProjectActionsEvent.testProject() = TestProjectEvent;
}

@freezed
class ProjectActionsState with _$ProjectActionsState {
  const factory ProjectActionsState.initial() = InitialProjectActionsState;

  const factory ProjectActionsState.building() = BuildingProjectState;

  const factory ProjectActionsState.running() = RunningProjectState;

  const factory ProjectActionsState.testing() = TestingProjectState;

  const factory ProjectActionsState.saved() = ProjectSavedState;

  const factory ProjectActionsState.built() = ProjectBuiltState;

  const factory ProjectActionsState.ran() = ProjectRanState;

  const factory ProjectActionsState.tested() = ProjectTestedState;

  const factory ProjectActionsState.error(String message) =
      ProjectActionsErrorState;
}

class ProjectActionsBloc
    extends Bloc<ProjectActionsEvent, ProjectActionsState> {
  final RunService _runService;
  final ProjectManagerService _projectManagerService;

  ProjectActionsBloc({
    required RunService runService,
    required ProjectManagerService projectManagerService,
  }) : _runService = runService,
       _projectManagerService = projectManagerService,
       super(const ProjectActionsState.initial()) {
    on<BuildProjectEvent>(_onBuildProject);
    on<RunProjectEvent>(_onRunProject);
    on<TestProjectEvent>(_onTestProject);
  }

  Future<void> _onBuildProject(
    BuildProjectEvent event,
    Emitter<ProjectActionsState> emit,
  ) async {
    final projectResult = _projectManagerService.getCurrentProjectOrError();

    projectResult.match((error) => emit(ProjectActionsState.error(error)), (
      project,
    ) async {
      emit(const ProjectActionsState.building());

      for (final command in project.buildCommands) {
        final result = await _runService
            .runCommand(command, workingDirectory: project.path)
            .run();

        result.match(
          (error) {
            emit(
              ProjectActionsState.error('Build failed: ${error.toString()}'),
            );
            return;
          },
          (output) {
            // Можно добавить логирование вывода сборки
          },
        );
      }

      emit(const ProjectActionsState.built());
    });
  }

  Future<void> _onRunProject(
    RunProjectEvent event,
    Emitter<ProjectActionsState> emit,
  ) async {
    final projectResult = _projectManagerService.getCurrentProjectOrError();

    projectResult.match((error) => emit(ProjectActionsState.error(error)), (
      project,
    ) async {
      emit(const ProjectActionsState.running());

      for (final command in project.runCommands) {
        final result = await _runService
            .runCommand(command, workingDirectory: project.path)
            .run();

        result.match(
          (error) {
            emit(ProjectActionsState.error('Run failed: ${error.toString()}'));
            return;
          },
          (output) {
            // Можно добавить логирование вывода выполнения
          },
        );
      }

      emit(const ProjectActionsState.ran());
    });
  }

  Future<void> _onTestProject(
    TestProjectEvent event,
    Emitter<ProjectActionsState> emit,
  ) async {
    final projectResult = _projectManagerService.getCurrentProjectOrError();

    projectResult.match((error) => emit(ProjectActionsState.error(error)), (
      project,
    ) async {
      emit(const ProjectActionsState.testing());

      for (final command in project.testCommands) {
        final result = await _runService
            .runCommand(command, workingDirectory: project.path)
            .run();

        result.match(
          (error) {
            emit(
              ProjectActionsState.error('Tests failed: ${error.toString()}'),
            );
            return;
          },
          (output) {
            // Можно добавить логирование вывода тестов
          },
        );
      }

      emit(const ProjectActionsState.tested());
    });
  }
}
