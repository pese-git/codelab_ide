import 'package:codelab_ide/widgets/bottom_terminal.dart';
import 'package:codelab_ide/widgets/project_status_info.dart';
import 'package:codelab_ide/widgets/start_wizard/start_wizard_panel.dart';
import 'package:codelab_uikit/codelab_uikit.dart';
import 'package:fluent_ui/fluent_ui.dart';

class IdeRootPage extends StatefulWidget {
  const IdeRootPage({super.key});

  @override
  State<IdeRootPage> createState() => _IdeRootPageState();
}

class _IdeRootPageState extends State<IdeRootPage> {
  double _sidebarPanelWidth = 200;
  int _selectedSidebarIndex = 0;
  bool _sidebarVisible = false;
  double _editorPanelFraction = 0.7;
  bool _bottomPanelVisible = false;
  bool _aiPanelVisible = false;
  double _aiPanelWidth = 320.0;
  bool _projectOpened = false;

  final GlobalKey<EditorPanelState> editorPanelKey =
      GlobalKey<EditorPanelState>();

  // Все demo данные вынесите в отдельный файл для чистоты (опционально)
  final List<FileNode> demoProject = [
    FileNode(
      path: '/project',
      name: 'project',
      isDirectory: true,
      children: [
        FileNode(
          path: '/project/lib',
          name: 'lib',
          isDirectory: true,
          children: [
            FileNode(path: '/project/lib/main.dart', name: 'main.dart'),
            FileNode(
              path: '/project/lib/home_page.dart',
              name: 'home_page.dart',
            ),
          ],
        ),
        FileNode(path: '/project/README.md', name: 'README.md'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: MainHeader(
        bottomPanelVisible: _bottomPanelVisible,
        onToggleBottomPanel: () =>
            setState(() => _bottomPanelVisible = !_bottomPanelVisible),
        aiPanelVisible: _aiPanelVisible,
        onToggleAiPanel: () =>
            setState(() => _aiPanelVisible = !_aiPanelVisible),
      ),
      content: LayoutBuilder(
        builder: (context, constraints) {
          final panelHeight = constraints.maxHeight;

          final editorHeight = panelHeight * _editorPanelFraction;
          final terminalHeight = panelHeight * (1 - _editorPanelFraction) - 8;

          return IdeLayout(
            sidebarNavigation: SidebarNavigation(
              selectedIndex: _selectedSidebarIndex,
              onSelected: (i) => setState(() {
                if (_selectedSidebarIndex == i) {
                  _sidebarVisible = !_sidebarVisible;
                } else {
                  _sidebarVisible = true;
                  _selectedSidebarIndex = i;
                }
              }),
            ),
            sidebarPanel: _sidebarVisible
                ? SidebarPanel(
                    selectedIndex: _selectedSidebarIndex,
                    explorerSlot: ExplorerPanel(
                      files: _projectOpened ? demoProject : [],
                      onFileOpen: (node) {
                        if (!node.isDirectory) {
                          String content =
                              '// Stub content for ${node.name}\nvoid main() {\n  print("Hello, ${node.name}!");\n}';
                          editorPanelKey.currentState?.openFile(
                            filePath: node.path,
                            title: node.name,
                            content: content,
                          );
                        }
                      },
                    ),
                  )
                : null,
            sidebarPanelWidth: _sidebarPanelWidth,
            sidebarSplitter: _sidebarVisible
                ? HorizontalSplitter(
                    onDrag: (delta) {
                      setState(() {
                        _sidebarPanelWidth += delta;
                        _sidebarPanelWidth = _sidebarPanelWidth.clamp(
                          130.0,
                          constraints.maxWidth - 120.0,
                        );
                      });
                    },
                  )
                : null,
            centerPanel: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _bottomPanelVisible
                            ? Column(
                                children: [
                                  SizedBox(
                                    height: editorHeight.clamp(
                                      100,
                                      panelHeight - 100,
                                    ),
                                    child: MainPanelArea(
                                      projectOpened: _projectOpened,
                                      workspaceSlot: EditorPanel(
                                        key: editorPanelKey,
                                        label: 'Editor 1',
                                      ),
                                      emptySlot: StartWizardPanel(
                                        onAction: (_) => setState(
                                          () => _projectOpened = true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  VerticalSplitter(
                                    onDrag: (delta) {
                                      setState(() {
                                        _editorPanelFraction +=
                                            delta / panelHeight;
                                        _editorPanelFraction =
                                            _editorPanelFraction.clamp(
                                              0.15,
                                              0.85,
                                            );
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    height: terminalHeight.clamp(
                                      50,
                                      panelHeight - 100,
                                    ),
                                    child: const BottomPanel(
                                      terminalSlot: BottomTerminal(),
                                    ),
                                  ),
                                ],
                              )
                            : MainPanelArea(
                                projectOpened: _projectOpened,
                                workspaceSlot: EditorPanel(
                                  key: editorPanelKey,
                                  label: 'Editor 1',
                                ),
                                emptySlot: StartWizard(
                                  onAction: (_) =>
                                      setState(() => _projectOpened = true),
                                ),
                              ),
                      ),
                      if (_aiPanelVisible)
                        HorizontalSplitter(
                          onDrag: (dx) {
                            setState(() {
                              _aiPanelWidth -= dx;
                              _aiPanelWidth = _aiPanelWidth.clamp(200.0, 500.0);
                            });
                          },
                        ),
                      if (_aiPanelVisible)
                        SizedBox(
                          width: _aiPanelWidth,
                          child: const AIAssistantPanel(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            rightPanel: RightPanel(aiSlot: const AIAssistantPanel()),
            rightPanelWidth: _aiPanelWidth,
            rightPanelSplitter: _aiPanelVisible
                ? HorizontalSplitter(
                    onDrag: (dx) {
                      setState(() {
                        _aiPanelWidth -= dx;
                        _aiPanelWidth = _aiPanelWidth.clamp(200.0, 500.0);
                      });
                    },
                  )
                : null,
          );
        },
      ),
      bottomBar: StatusBar(
        leading: Icon(FluentIcons.sync, size: 16, color: Colors.green),
        trailing: ProjectStatusInfo(),
      ),
    );
  }
}
