import 'package:example/main_panel_area.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'main_header.dart';
import 'sidebar_navigation.dart';
import 'sidebar_panel.dart';
import 'bottom_panel.dart';
import 'status_bar.dart';
import 'horizontal_splitter.dart';
import 'vertical_splitter.dart';

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
  double _sidebarPanelWidth = 200;
  int _selectedSidebarIndex = 0;
  bool _sidebarVisible = false;
  double _editorPanelFraction = 0.7;
  double _editorSplitFraction = 0.5;
  bool _bottomPanelVisible = false;

  bool _projectOpened = false;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: MainHeader(
        bottomPanelVisible: _bottomPanelVisible,
        onToggleBottomPanel: () =>
            setState(() => _bottomPanelVisible = !_bottomPanelVisible),
      ),
      content: LayoutBuilder(
        builder: (context, constraints) {
          const minEditorWidth = 120.0;
          final maxSidebarWidth = constraints.maxWidth - minEditorWidth;
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SidebarNavigation(
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
                    SizedBox(
                      width: _sidebarVisible ? _sidebarPanelWidth : 0.0,
                      child: _sidebarVisible
                          ? SidebarPanel(selectedIndex: _selectedSidebarIndex)
                          : null,
                    ),
                    _sidebarVisible
                        ? HorizontalSplitter(
                            onDrag: (delta) {
                              setState(() {
                                _sidebarPanelWidth += delta;
                                _sidebarPanelWidth = _sidebarPanelWidth.clamp(
                                  130.0,
                                  maxSidebarWidth,
                                );
                              });
                            },
                          )
                        : const SizedBox(width: 0),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final panelHeight = constraints.maxHeight;
                          final editorHeight =
                              panelHeight * _editorPanelFraction;
                          final terminalHeight =
                              panelHeight * (1 - _editorPanelFraction) - 36;
                          return Column(
                            children: _bottomPanelVisible
                                ? [
                                    SizedBox(
                                      height: editorHeight.clamp(
                                        100,
                                        panelHeight - 100,
                                      ),
                                      child: MainPanelArea(
                                        projectOpened: _projectOpened,
                                        editorSplitFraction:
                                            _editorSplitFraction,
                                        onEditorDrag: (f) => setState(
                                          () => _editorSplitFraction = f,
                                        ),
                                        onWizardAction: (action) => setState(
                                          () => _projectOpened = true,
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
                                      child: const BottomPanel(),
                                    ),
                                  ]
                                : [
                                    Expanded(
                                      child: MainPanelArea(
                                        projectOpened: _projectOpened,
                                        editorSplitFraction:
                                            _editorSplitFraction,
                                        onEditorDrag: (f) => setState(
                                          () => _editorSplitFraction = f,
                                        ),
                                        onWizardAction: (action) => setState(
                                          () => _projectOpened = true,
                                        ),
                                      ),
                                    ),
                                  ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBar(),
            ],
          );
        },
      ),
    );
  }
}
