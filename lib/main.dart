import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/project_model.dart';
import 'services/file_service.dart';
import 'services/run_service.dart';
import 'widgets/file_tree_widget.dart';
import 'widgets/editor_widget.dart';
import 'widgets/terminal_widget.dart';

void main() {
  runApp(
    ChangeNotifierProvider<ProjectState>(
      create: (context) => ProjectState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodeLab IDE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const IDEHomePage(),
    );
  }
}

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
      body: Consumer<ProjectState>(
        builder: (context, projectState, child) {
          return Row(
            children: [
              // File Tree Panel
              SizedBox(
                width: _fileTreeWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: FileTreeWidget(
                        fileTree: projectState.fileTree,
                        onFileSelected: (filePath) =>
                            _openFile(filePath, projectState),
                        selectedFile: projectState.currentFile,
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
                      child: projectState.currentFile != null
                          ? EditorWidget(
                              filePath: projectState.currentFile!,
                              content: projectState.fileContent,
                              onContentChanged: (content) {
                                Provider.of<ProjectState>(
                                  context,
                                  listen: false,
                                ).copyWith(fileContent: content);
                              },
                              onSave: () => _saveCurrentFile(projectState),
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
                        workingDirectory: projectState.projectPath,
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
    final projectPath = await FileService.pickProjectDirectory();
    if (!mounted) return;
    if (projectPath != null) {
      final fileTree = FileService.loadProjectTree(projectPath);
      Provider.of<ProjectState>(context, listen: false).copyWith(
        projectPath: projectPath,
        fileTree: fileTree,
        currentFile: null,
        fileContent: '',
      );
    }
  }

  void _openFile(String filePath, ProjectState projectState) async {
    final content = await FileService.readFile(filePath);
    if (!mounted) return;
    Provider.of<ProjectState>(
      context,
      listen: false,
    ).copyWith(currentFile: filePath, fileContent: content);
  }

  void _saveCurrentFile(ProjectState projectState) async {
    if (projectState.currentFile != null) {
      final success = await FileService.writeFile(
        projectState.currentFile!,
        projectState.fileContent,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save file')));
      }
    }
  }

  void _runCurrentFile(BuildContext context) {
    final projectState = Provider.of<ProjectState>(context, listen: false);
    if (projectState.currentFile != null) {
      final command = RunService.getRunCommand(projectState.currentFile!);
      // In a real implementation, you would execute this command in the terminal
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Would run: $command')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected to run')));
    }
  }
}
