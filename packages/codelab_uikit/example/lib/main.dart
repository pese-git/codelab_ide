import 'package:fluent_ui/fluent_ui.dart';

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
      home: const IdeHomePage(),
      debugShowCheckedModeBanner: true,
    );
  }
}

class IdeHomePage extends StatefulWidget {
  const IdeHomePage({super.key});

  @override
  State<IdeHomePage> createState() => _IdeHomePageState();
}

class _IdeHomePageState extends State<IdeHomePage> {
  int _selectedSidebarIndex = 0;
  double _editorPanelFraction = 0.7;
  double _editorSplitFraction = 0.5;
  double _verticalDragStart = 0;
  double _horizontalDragStart = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const MainHeader(),
      content: Row(
        children: [
          SidebarNavigation(
            selectedIndex: _selectedSidebarIndex,
            onSelected: (i) => setState(() => _selectedSidebarIndex = i),
          ),
          SidebarPanel(selectedIndex: _selectedSidebarIndex),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final panelHeight = constraints.maxHeight;
                final editorHeight = panelHeight * _editorPanelFraction;
                final terminalHeight =
                    panelHeight * (1 - _editorPanelFraction) - 36;
                return Column(
                  children: [
                    SizedBox(
                      height: editorHeight.clamp(100, panelHeight - 100),
                      child: EditorSplitView(
                        splitFraction: _editorSplitFraction,
                        onDrag: (fraction) =>
                            setState(() => _editorSplitFraction = fraction),
                      ),
                    ),
                    _VerticalSplitter(
                      onDrag: (delta) {
                        setState(() {
                          _editorPanelFraction += delta / panelHeight;
                          _editorPanelFraction = _editorPanelFraction.clamp(
                            0.15,
                            0.85,
                          );
                        });
                      },
                    ),
                    SizedBox(
                      height: terminalHeight.clamp(50, panelHeight - 100),
                      child: const TerminalPanel(),
                    ),
                    const StatusBar(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- COMPONENTS --------------------

class MainHeader extends StatelessWidget {
  const MainHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Codelab IDE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        IconButton(icon: const Icon(FluentIcons.save), onPressed: () {}),
        IconButton(icon: const Icon(FluentIcons.play), onPressed: () {}),
        IconButton(icon: const Icon(FluentIcons.settings), onPressed: () {}),
      ],
    );
  }
}

/// Левое вертикальное меню
class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      color: Colors.grey[10],
      child: Column(
        children: [
          _SidebarIcon(
            icon: FluentIcons.open_folder_horizontal,
            index: 0,
            selected: selectedIndex == 0,
            tooltip: 'Explorer',
            onTap: () => onSelected(0),
          ),
          _SidebarIcon(
            icon: FluentIcons.search,
            index: 1,
            selected: selectedIndex == 1,
            tooltip: 'Search',
            onTap: () => onSelected(1),
          ),
          _SidebarIcon(
            icon: FluentIcons.git_graph,
            index: 2,
            selected: selectedIndex == 2,
            tooltip: 'Git',
            onTap: () => onSelected(2),
          ),
          _SidebarIcon(
            icon: FluentIcons.play,
            index: 3,
            selected: selectedIndex == 3,
            tooltip: 'Run',
            onTap: () => onSelected(3),
          ),
          _SidebarIcon(
            icon: FluentIcons.plug,
            index: 4,
            selected: selectedIndex == 4,
            tooltip: 'Extensions',
            onTap: () => onSelected(4),
          ),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _SidebarIcon({
    required this.icon,
    required this.index,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, color: selected ? Colors.blue : Colors.grey[100]),
          onPressed: onTap,
        ),
      ),
    );
  }
}

/// Меняющийся левый боковой регион
class SidebarPanel extends StatelessWidget {
  final int selectedIndex;
  const SidebarPanel({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return const _ExplorerPanel();
      case 1:
        return const _SidebarPlaceholder('Search');
      case 2:
        return const _SidebarPlaceholder('Source Control');
      case 3:
        return const _SidebarPlaceholder('Run/Debug');
      case 4:
        return const _SidebarPlaceholder('Extensions');
      default:
        return const SizedBox(width: 200);
    }
  }
}

/// Файловый менеджер
class _ExplorerPanel extends StatelessWidget {
  const _ExplorerPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[20],
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'EXPLORER',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(FluentIcons.page),
                  title: Text('main.dart'),
                ),
                ListTile(
                  leading: Icon(FluentIcons.page),
                  title: Text('home_page.dart'),
                ),
                ListTile(
                  leading: Icon(FluentIcons.folder_horizontal),
                  title: Text('lib/'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarPlaceholder extends StatelessWidget {
  final String name;
  const _SidebarPlaceholder(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[20],
      child: Center(
        child: Text(
          '$name\nбудет реализовано позже',
          style: const TextStyle(color: Color(0xFF888888), fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Вертикальный drag-разделитель (между редактором и терминалом)
class _VerticalSplitter extends StatelessWidget {
  final ValueChanged<double> onDrag;
  const _VerticalSplitter({super.key, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        onDrag(details.delta.dy);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 8,
          color: Colors.grey[30],
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[110],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Область редактора с горизонтальным split
class EditorSplitView extends StatefulWidget {
  final double splitFraction;
  final ValueChanged<double> onDrag;
  const EditorSplitView({
    super.key,
    required this.splitFraction,
    required this.onDrag,
  });

  @override
  State<EditorSplitView> createState() => _EditorSplitViewState();
}

class _EditorSplitViewState extends State<EditorSplitView> {
  double? _dragStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaWidth = constraints.maxWidth;
        final leftWidth = areaWidth * widget.splitFraction - 8;
        final rightWidth = areaWidth * (1 - widget.splitFraction);
        return Row(
          children: [
            SizedBox(
              width: leftWidth.clamp(100, areaWidth - 100),
              child: const EditorPanel(label: 'Editor 1'),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (details) {
                _dragStart = details.localPosition.dx;
              },
              onHorizontalDragUpdate: (details) {
                final d = details.localPosition.dx - (_dragStart ?? 0);
                final fraction = (widget.splitFraction + d / areaWidth).clamp(
                  0.15,
                  0.85,
                );
                widget.onDrag(fraction);
                _dragStart = details.localPosition.dx;
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 8,
                  color: Colors.grey[30],
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[110],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: rightWidth.clamp(100, areaWidth - 100),
              child: const EditorPanel(label: 'Editor 2'),
            ),
          ],
        );
      },
    );
  }
}

/// Панель редактора (левый/правый split)
class EditorPanel extends StatelessWidget {
  final String label;
  const EditorPanel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          '$label\n(Здесь будет редактор кода)',
          style: const TextStyle(fontSize: 18, color: Color(0xFF888888)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Терминал
class TerminalPanel extends StatelessWidget {
  const TerminalPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Terminal Area\n(Здесь будет терминал)',
          style: TextStyle(fontSize: 18, color: Color(0xFF50FA7B)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Status Bar
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: const Color(0xFFf2f2f2),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Text(
        'Ln 1, Col 1   Spaces: 2   UTF-8',
        style: TextStyle(fontSize: 13, color: Color(0xFF4e4e4e)),
      ),
    );
  }
}
