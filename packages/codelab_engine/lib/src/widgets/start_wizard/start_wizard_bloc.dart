import 'package:bloc/bloc.dart';
import 'package:codelab_core/codelab_core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../services/lsp_service.dart';

part 'start_wizard_bloc.freezed.dart';

@freezed
class StartWizardEvent with _$StartWizardEvent {
  const factory StartWizardEvent.createProject({
    required String name,
    required String path,
    required String type,
  }) = CreateProjectEvent;

  const factory StartWizardEvent.openProject() = OpenProjectEvent;

  const factory StartWizardEvent.loadRecentProjects() = LoadRecentProjectsEvent;
}

@freezed
class StartWizardState with _$StartWizardState {
  const factory StartWizardState.initial() = InitialSelectProjectState;

  const factory StartWizardState.creating() = CreatingProjectState;

  const factory StartWizardState.opening() = OpeningProjectState;

  const factory StartWizardState.created(ProjectConfig project) =
      ProjectCreatedState;

  const factory StartWizardState.opened(ProjectConfig project) =
      ProjectOpenedState;

  const factory StartWizardState.error(String message) =
      SelectProjectErrorState;

  const factory StartWizardState.recentProjectsLoaded(
    List<ProjectConfig> projects,
  ) = RecentProjectsLoadedState;
}

class StartWizardBloc extends Bloc<StartWizardEvent, StartWizardState> {
  final FileService _fileService;
  final ProjectService _projectService;
  final ProjectManagerService _projectManagerService;
  final LspService _lspService;

  StartWizardBloc({
    required FileService fileService,
    required ProjectService projectService,
    required ProjectManagerService projectManagerService,
    required LspService lspService,
  }) : _projectService = projectService,
       _projectManagerService = projectManagerService,
       _fileService = fileService,
       _lspService = lspService,
       super(const StartWizardState.initial()) {
    //on<CreateProjectEvent>(_onCreateProject);
    on<OpenProjectEvent>(_onOpenProject);
    on<LoadRecentProjectsEvent>(_onLoadRecentProjects);
  }

  //  Future<void> _onCreateProject(
  //    CreateProjectEvent event,
  //    Emitter<StartWizardState> emit,
  //  ) async {
  //    emit(const StartWizardState.creating());
  //
  //    final result = await _projectService
  //        .createProject(name: event.name, path: event.path, type: event.type)
  //        .run();
  //
  //    result.match((error) => emit(StartWizardState.error(error.toString())), (
  //      project,
  //    ) {
  //      // Устанавливаем проект в глобальный менеджер
  //      _projectManagerService.setCurrentProject(project);
  //      emit(StartWizardState.created(project));
  //    });
  //  }

  Future<void> _onOpenProject(
    OpenProjectEvent event,
    Emitter<StartWizardState> emit,
  ) async {
    emit(const StartWizardState.opening());

    await _fileService
        .pickProjectDirectory()
        // Если отказ/ошибка: в error попадёт FileError, в success — путь или null (отмена пользователем)
        .flatMap((projectPath) {
          if (projectPath == null) {
            // Операцию отменили — эмулируем "успешный, но бездействие"
            return TaskEither<FileError, ProjectConfig>.right(
              ProjectConfig.createDefault(''),
            ); // Вернем null, ниже обработаем
          }
          return _projectService.loadProject(projectPath);
        })
        .run()
        .then((result) {
          result.match(
            (error) => emit(StartWizardState.error(error.toString())),
            (project) {
              _projectManagerService.setCurrentProject(project);
              // Инициализируем LSP для проекта
              if (project.path.isNotEmpty) {
                _lspService
                    .initialize(project.path)
                    .then((_) {
                      codelabLogger.d(
                        'LSP initialized for project: ${project.path}',
                        tag: 'start_wizard_bloc',
                      );
                    })
                    .catchError((error) {
                      codelabLogger.e(
                        'Failed to initialize LSP',
                        tag: 'start_wizard_bloc',
                        error: error,
                      );
                    });
              }
              emit(StartWizardState.opened(project));
            },
          );
        });
  }

  Future<void> _onLoadRecentProjects(
    LoadRecentProjectsEvent event,
    Emitter<StartWizardState> emit,
  ) async {
    final result = await _projectService.getRecentProjects().run();

    result.match(
      (error) => emit(StartWizardState.error(error.toString())),
      (projects) => emit(StartWizardState.recentProjectsLoaded(projects)),
    );
  }
}
