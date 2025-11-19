import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:codelab_uikit/codelab_uikit.dart';
import 'package:codelab_uikit/widgets/ai_assistant_ui/ai_assistant_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Codelab IDE',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
      ),
      home: const IdeRootPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class IdeRootPage extends StatefulWidget {
  const IdeRootPage({super.key});

  @override
  State<IdeRootPage> createState() => _IdeRootPageState();
}

class _IdeRootPageState extends State<IdeRootPage> {
  double _sidebarPanelWidth = 210;
  int _selectedSidebarIndex = 0;
  bool _sidebarVisible = false;
  double _editorPanelFraction = 0.7;
  bool _bottomPanelVisible = false;
  bool _aiPanelVisible = false;
  double _aiPanelWidth = 320.0;
  bool _projectOpened = false;

  final GlobalKey<EditorPanelState> editorPanelKey =
      GlobalKey<EditorPanelState>();
  int _fileCounter = 1;

  void _openFile(FileNode node, String content) {
    if (!node.isDirectory) {
      editorPanelKey.currentState?.openFile(
        filePath: node.path,
        title: node.name,
        content: content,
      );
    }
  }

  void _openSampleFile() {
    editorPanelKey.currentState?.openFile(
      filePath: '/project/sample_${_fileCounter}.dart',
      title: 'sample_${_fileCounter}.dart',
      content:
          '// Sample file $_fileCounter\nvoid main() {\n  print("Hello from GlobalKey!");\n}',
    );
    setState(() {
      _fileCounter++;
    });
  }

  void _closeAllFiles() {
    editorPanelKey.currentState?.closeAllFiles();
    setState(() {
      _fileCounter = 1;
    });
  }

  void _saveAllFiles() {
    editorPanelKey.currentState?.saveAllFiles();
  }

  void _showActiveTabInfo() {
    final activeTab = editorPanelKey.currentState?.activeTab;
    if (activeTab != null) {
      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Active Tab Info'),
            content: Text(
              'Active file: ${activeTab.title}\nPath: ${activeTab.filePath}',
            ),
            severity: InfoBarSeverity.info,
          );
        },
      );
    } else {
      displayInfoBar(
        context,
        builder: (context, close) {
          return const InfoBar(
            title: Text('No Active Tab'),
            content: Text('There is no active tab currently.'),
            severity: InfoBarSeverity.warning,
          );
        },
      );
    }
  }

  // Все demo данные вынесите в отдельный файл для чистоты (опционально)
  final FileNode demoProject = FileNode(
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
          FileNode(path: '/project/lib/home_page.dart', name: 'home_page.dart'),
        ],
      ),
      FileNode(path: '/project/README.md', name: 'README.md'),
    ],
  );

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
                      initialFileTree: _projectOpened ? demoProject : null,
                      onOpenFile: (node) {
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
                    runDebugSlot: RunAndDebugPanel(),
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
                                      emptySlot: StartWizard(
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
                                    child: BottomPanel(
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
                          child: ExampleAIAssistant(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            rightPanel: RightPanel(aiSlot: ExampleAIAssistant()),
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
        trailing: MyProjectStatusInfo(),
      ),
    );
  }
}

/// Демонстрация стейтфул-ассистента с бизнес-логикой и собранным UI
class ExampleAIAssistant extends StatefulWidget {
  const ExampleAIAssistant({super.key});
  @override
  State<ExampleAIAssistant> createState() => _ExampleAIAssistantState();
}

class _ExampleAIAssistantState extends State<ExampleAIAssistant> {
  final TextEditingController _controller = TextEditingController();
  final List<AIAssistantMessage> _messages = [
    const AIAssistantMessage(role: 'ai', content: 'Привет! Я ассистент.'),
    const AIAssistantMessage(role: 'user', content: 'Расскажи про Flutter.'),
    const AIAssistantMessage(
      role: 'ai',
      content: 'Flutter — UI toolkit от Google...',
    ),
  ];
  bool _sending = false;

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(AIAssistantMessage(role: 'user', content: text));
      _controller.clear();
      _sending = true;
    });
    // Здесь будет вызов к LLM/AI!
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.add(AIAssistantMessage(role: 'ai', content: 'Ответ на: $text'));
      _sending = false;
    });
  }

  void _clear() {
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AIAssistantHeader(onClear: _clear),
        const Divider(size: 1),
        Expanded(child: AIAssistantMessageList(messages: _messages)),
        const Divider(size: 1),
        AIAssistantInputBar(
          controller: _controller,
          onSend: _send,
          sending: _sending,
        ),
      ],
    );
  }
}

class BottomTerminal extends StatefulWidget {
  const BottomTerminal({super.key});

  @override
  State<StatefulWidget> createState() {
    return BottomTerminalState();
  }
}

class BottomTerminalState extends State<BottomTerminal> {
  final terminal = Terminal(maxLines: 10000);

  final terminalController = TerminalController();

  late final Pty pty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _startPty();
    });
  }

  void _startPty() {
    pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );

    pty.output
        .cast<List<int>>()
        .transform(Utf8Decoder())
        .listen(terminal.write);

    pty.exitCode.then((code) {
      terminal.write('the process exited with exit code $code');
    });

    terminal.onOutput = (data) {
      pty.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (w, h, pw, ph) {
      pty.resize(h, w);
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: TerminalView(
        terminal,
        controller: terminalController,
        autofocus: true,
        backgroundOpacity: 0.7,
        onSecondaryTapDown: (details, offset) async {
          final selection = terminalController.selection;
          if (selection != null) {
            final text = terminal.buffer.getText(selection);
            terminalController.clearSelection();
            await Clipboard.setData(ClipboardData(text: text));
          } else {
            final data = await Clipboard.getData('text/plain');
            final text = data?.text;
            if (text != null) {
              terminal.paste(text);
            }
          }
        },
      ),
    );
  }

  bool get isDesktop {
    if (kIsWeb) return false;
    return [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform);
  }

  String get shell {
    if (Platform.isMacOS || Platform.isLinux) {
      return Platform.environment['SHELL'] ?? 'bash';
    }

    if (Platform.isWindows) {
      return 'cmd.exe';
    }

    return 'sh';
  }
}

class MyProjectStatusInfo extends StatelessWidget {
  const MyProjectStatusInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(FluentIcons.sync_folder, size: 15, color: Colors.blue),
        const SizedBox(width: 8),
        const Text(
          'Synced',
          style: TextStyle(fontSize: 13, color: Colors.black),
        ),
        const SizedBox(width: 20),
        Icon(FluentIcons.branch_merge, size: 15, color: Colors.green),
        const SizedBox(width: 8),
        const Text(
          'main',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
