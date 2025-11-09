import 'package:bloc/bloc.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'select_project_bloc.freezed.dart';

@freezed
class SelectProjectEvent with _$SelectProjectEvent {
  const factory SelectProjectEvent.createProject({
    required String name,
    required String path,
    required String type,
  }) = CreateProjectEvent;

  const factory SelectProjectEvent.openProject(String projectPath) =
      OpenProjectEvent;

  const factory SelectProjectEvent.loadRecentProjects() =
      LoadRecentProjectsEvent;
}

@freezed
class SelectProjectState with _$SelectProjectState {
  const factory SelectProjectState.initial() = InitialSelectProjectState;

  const factory SelectProjectState.creating() = CreatingProjectState;

  const factory SelectProjectState.opening() = OpeningProjectState;

  const factory SelectProjectState.created(ProjectConfig project) =
      ProjectCreatedState;

  const factory SelectProjectState.opened(ProjectConfig project) =
      ProjectOpenedState;

  const factory SelectProjectState.error(String message) =
      SelectProjectErrorState;

  const factory SelectProjectState.recentProjectsLoaded(
    List<ProjectConfig> projects,
  ) = RecentProjectsLoadedState;
}

class SelectProjectBloc extends Bloc<SelectProjectEvent, SelectProjectState> {
  final ProjectService _projectService;
  final ProjectManagerService _projectManagerService;

  SelectProjectBloc({
    required ProjectService projectService,
    required ProjectManagerService projectManagerService,
  }) : _projectService = projectService,
       _projectManagerService = projectManagerService,
       super(const SelectProjectState.initial()) {
    on<CreateProjectEvent>(_onCreateProject);
    on<OpenProjectEvent>(_onOpenProject);
    on<LoadRecentProjectsEvent>(_onLoadRecentProjects);
  }

  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<SelectProjectState> emit,
  ) async {
    emit(const SelectProjectState.creating());

    final result = await _projectService
        .createProject(name: event.name, path: event.path, type: event.type)
        .run();

    result.match((error) => emit(SelectProjectState.error(error.toString())), (
      project,
    ) {
      // Устанавливаем проект в глобальный менеджер
      _projectManagerService.setCurrentProject(project);
      emit(SelectProjectState.created(project));
    });
  }

  Future<void> _onOpenProject(
    OpenProjectEvent event,
    Emitter<SelectProjectState> emit,
  ) async {
    emit(const SelectProjectState.opening());

    final result = await _projectService.loadProject(event.projectPath).run();

    result.match((error) => emit(SelectProjectState.error(error.toString())), (
      project,
    ) {
      // Устанавливаем проект в глобальный менеджер
      _projectManagerService.setCurrentProject(project);
      emit(SelectProjectState.opened(project));
    });
  }

  Future<void> _onLoadRecentProjects(
    LoadRecentProjectsEvent event,
    Emitter<SelectProjectState> emit,
  ) async {
    final result = await _projectService.getRecentProjects().run();

    result.match(
      (error) => emit(SelectProjectState.error(error.toString())),
      (projects) => emit(SelectProjectState.recentProjectsLoaded(projects)),
    );
  }
}
