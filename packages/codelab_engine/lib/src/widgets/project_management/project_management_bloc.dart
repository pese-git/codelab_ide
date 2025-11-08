import 'package:bloc/bloc.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_management_bloc.freezed.dart';

@freezed
class ProjectManagementEvent with _$ProjectManagementEvent {
  const factory ProjectManagementEvent.createProject({
    required String name,
    required String path,
    required String type,
  }) = CreateProjectEvent;

  const factory ProjectManagementEvent.openProject(String projectPath) = OpenProjectEvent;
  
  const factory ProjectManagementEvent.saveProject() = SaveProjectEvent;
  
  const factory ProjectManagementEvent.buildProject() = BuildProjectEvent;
  
  const factory ProjectManagementEvent.runProject() = RunProjectEvent;
  
  const factory ProjectManagementEvent.testProject() = TestProjectEvent;
  
  const factory ProjectManagementEvent.closeProject() = CloseProjectEvent;
  
  const factory ProjectManagementEvent.loadRecentProjects() = LoadRecentProjectsEvent;
}

@freezed
class ProjectManagementState with _$ProjectManagementState {
  const factory ProjectManagementState.initial() = InitialProjectState;
  
  const factory ProjectManagementState.loading() = LoadingProjectState;
  
  const factory ProjectManagementState.loaded({
    required ProjectConfig project,
    required FileNode fileTree,
    required bool hasUnsavedChanges,
  }) = LoadedProjectState;
  
  const factory ProjectManagementState.building() = BuildingProjectState;
  
  const factory ProjectManagementState.running() = RunningProjectState;
  
  const factory ProjectManagementState.testing() = TestingProjectState;
  
  const factory ProjectManagementState.error(String message) = ProjectErrorState;
  
  const factory ProjectManagementState.recentProjectsLoaded(List<ProjectConfig> projects) = RecentProjectsLoadedState;
}

class ProjectManagementBloc extends Bloc<ProjectManagementEvent, ProjectManagementState> {
  final ProjectService _projectService;
  final FileService _fileService;
  final RunService _runService;

  ProjectManagementBloc({
    required ProjectService projectService,
    required FileService fileService,
    required RunService runService,
  })  : _projectService = projectService,
        _fileService = fileService,
        _runService = runService,
        super(const ProjectManagementState.initial()) {
    on<CreateProjectEvent>(_onCreateProject);
    on<OpenProjectEvent>(_onOpenProject);
    on<SaveProjectEvent>(_onSaveProject);
    on<BuildProjectEvent>(_onBuildProject);
    on<RunProjectEvent>(_onRunProject);
    on<TestProjectEvent>(_onTestProject);
    on<CloseProjectEvent>(_onCloseProject);
    on<LoadRecentProjectsEvent>(_onLoadRecentProjects);
  }

  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    emit(const ProjectManagementState.loading());
    
    final result = await _projectService.createProject(
      name: event.name,
      path: event.path,
      type: event.type,
    ).run();
    
    result.match(
      (error) => emit(ProjectManagementState.error(error.toString())),
      (project) async {
        final fileTreeResult = _fileService.loadProjectTree(project.path);
        fileTreeResult.match(
          (error) => emit(ProjectManagementState.error(error.toString())),
          (fileTree) => emit(ProjectManagementState.loaded(
            project: project,
            fileTree: fileTree!,
            hasUnsavedChanges: false,
          )),
        );
      },
    );
  }

  Future<void> _onOpenProject(
    OpenProjectEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    emit(const ProjectManagementState.loading());
    
    final result = await _projectService.loadProject(event.projectPath).run();
    
    result.match(
      (error) => emit(ProjectManagementState.error(error.toString())),
      (project) async {
        final fileTreeResult = _fileService.loadProjectTree(project.path);
        fileTreeResult.match(
          (error) => emit(ProjectManagementState.error(error.toString())),
          (fileTree) => emit(ProjectManagementState.loaded(
            project: project,
            fileTree: fileTree!,
            hasUnsavedChanges: false,
          )),
        );
      },
    );
  }

  Future<void> _onSaveProject(
    SaveProjectEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    final currentState = state;
    if (currentState is LoadedProjectState) {
      // Здесь будет логика сохранения изменений проекта
      emit(currentState.copyWith(hasUnsavedChanges: false));
    }
  }

  Future<void> _onBuildProject(
    BuildProjectEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    final currentState = state;
    if (currentState is LoadedProjectState) {
      emit(const ProjectManagementState.building());
      
      for (final command in currentState.project.buildCommands) {
        final result = await _runService.runCommand(
          command,
          workingDirectory: currentState.project.path,
        ).run();
        
        result.match(
          (error) {
            emit(ProjectManagementState.error('Build failed: ${error.toString()}'));
            return;
          },
          (output) {
            // Можно добавить логирование вывода сборки
          },
        );
      }
      
      emit(currentState);
    }
  }

  Future<void> _onRunProject(
    RunProjectEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    final currentState = state;
    if (currentState is LoadedProjectState) {
      emit(const ProjectManagementState.running());
      
      for (final command in currentState.project.runCommands) {
        final result = await _runService.runCommand(
          command,
          workingDirectory: currentState.project.path,
        ).run();
        
        result.match(
          (error) {
            emit(ProjectManagementState.error('Run failed: ${error.toString()}'));
            return;
          },
          (output) {
            // Можно добавить логирование вывода выполнения
          },
        );
      }
      
      emit(currentState);
    }
  }

  Future<void> _onTestProject(
    TestProjectEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    final currentState = state;
    if (currentState is LoadedProjectState) {
      emit(const ProjectManagementState.testing());
      
      for (final command in currentState.project.testCommands) {
        final result = await _runService.runCommand(
          command,
          workingDirectory: currentState.project.path,
        ).run();
        
        result.match(
          (error) {
            emit(ProjectManagementState.error('Tests failed: ${error.toString()}'));
            return;
          },
          (output) {
            // Можно добавить логирование вывода тестов
          },
        );
      }
      
      emit(currentState);
    }
  }

  Future<void> _onCloseProject(
    CloseProjectEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    emit(const ProjectManagementState.initial());
  }

  Future<void> _onLoadRecentProjects(
    LoadRecentProjectsEvent event,
    Emitter<ProjectManagementState> emit,
  ) async {
    final result = await _projectService.getRecentProjects().run();
    
    result.match(
      (error) => emit(ProjectManagementState.error(error.toString())),
      (projects) => emit(ProjectManagementState.recentProjectsLoaded(projects)),
    );
  }
}