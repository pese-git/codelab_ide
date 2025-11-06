import 'package:codelab_engine/codelab_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IDEHomePage extends StatefulWidget {
  const IDEHomePage({super.key});

  @override
  IDEHomePageState createState() => IDEHomePageState();
}

class IDEHomePageState extends State<IDEHomePage> {
  double _fileTreeWidth = 250.0;
  double _terminalHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeLab IDE'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _openProject(),
            tooltip: 'Open Project',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _runCurrentFile(context),
            tooltip: 'Run Current File',
          ),
        ],
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, projectState) {
          return Row(
            children: [
              // File Tree Panel
              SizedBox(
                width: _fileTreeWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: FileTreeWidget(
                        key: ValueKey(projectState.projectPath),
                        initialFileTree: projectState.fileTree,
                        onFileSelected: (filePath) => context
                            .read<ProjectBloc>()
                            .add(ProjectEvent.selectFile(filePath)),
                      ),
                    ),
                  ],
                ),
              ),
              // Resize handle
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _fileTreeWidth += details.delta.dx;
                      _fileTreeWidth = _fileTreeWidth.clamp(150.0, 400.0);
                    });
                  },
                  child: Container(width: 4, color: Colors.grey[300]),
                ),
              ),
              // Editor and Terminal
              Expanded(
                child: Column(
                  children: [
                    // Editor Panel
                    Expanded(
                      child:
                          projectState.currentFile != null &&
                              !projectState.isLoading &&
                              projectState.loadedFile ==
                                  projectState.currentFile
                          ? EditorWidget(
                              key: ValueKey(projectState.currentFile),
                              filePath: projectState.currentFile!,
                              content: projectState.fileContent,
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.code,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No file selected',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Select a file from the file tree to start editing',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    // Resize handle
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeRow,
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            _terminalHeight -= details.delta.dy;
                            _terminalHeight = _terminalHeight.clamp(
                              100.0,
                              400.0,
                            );
                          });
                        },
                        child: Container(height: 4, color: Colors.grey[300]),
                      ),
                    ),
                    // Terminal Panel
                    SizedBox(
                      height: _terminalHeight,
                      child: TerminalWidget(
                        key: ValueKey(projectState.projectPath),
                        projectDirectory: projectState.projectPath,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openProject() async {
    context.read<ProjectBloc>().add(ProjectEvent.openProject());
  }

  void _runCurrentFile(BuildContext context) {
        context.read<ProjectBloc>().add(ProjectEvent.runProject());
    /*
    final projectState = context.read<ProjectBloc>().state;
    if (projectState.currentFile != null) {
      final runService = CherryPick.openRootScope().resolve<RunService>();
      final command = runService.getRunCommand(projectState.currentFile!);
      // Здесь можно интегрировать с реальным запуском или передавать в TerminalBloc
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Would run: $command')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected to run')));
    }
    */
  }
}
