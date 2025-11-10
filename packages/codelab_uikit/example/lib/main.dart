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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Row(
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
      ),
      content: Row(
        children: [
          _buildSidebarNavigation(),
          _buildSidebarContent(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 7,
                  child: _buildEditorArea(),
                ),
                Expanded(
                  flex: 3,
                  child: _buildTerminalArea(),
                ),
                _buildStatusBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Custom vertical sidebar navigation
  Widget _buildSidebarNavigation() => Container(
    width: 56,
    color: Colors.grey[10],
    child: Column(
      children: [
        _sidebarIcon(
          FluentIcons.open_folder_horizontal,
          0,
          tooltip: 'Explorer',
        ),
        _sidebarIcon(FluentIcons.search, 1, tooltip: 'Search'),
        _sidebarIcon(FluentIcons.git_graph, 2, tooltip: 'Git'),
        _sidebarIcon(FluentIcons.play, 3, tooltip: 'Run'),
        _sidebarIcon(FluentIcons.plug, 4, tooltip: 'Extensions'),
      ],
    ),
  );

  Widget _sidebarIcon(IconData icon, int idx, {String? tooltip}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(
          icon,
          color: _selectedSidebarIndex == idx ? Colors.blue : Colors.grey[100],
        ),
        onPressed: () => setState(() => _selectedSidebarIndex = idx),
      ),
    ),
  );

  // Dynamic content based on sidebar selection
  Widget _buildSidebarContent() {
    switch (_selectedSidebarIndex) {
      case 0:
        return _buildFileExplorer();
      case 1:
        return _placeholderBody('Search');
      case 2:
        return _placeholderBody('Source Control');
      case 3:
        return _placeholderBody('Run/Debug');
      case 4:
        return _placeholderBody('Extensions');
      default:
        return const SizedBox(width: 200);
    }
  }

  Widget _buildFileExplorer() => Container(
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

  Widget _placeholderBody(String name) => Container(
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

  Widget _buildEditorArea() => Container(
    color: Colors.white,
    child: const Center(
      child: Text(
        'Editor Area\n(Здесь будет редактор кода)',
        style: TextStyle(fontSize: 20, color: Color(0xFF888888)),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _buildStatusBar() => Container(
        height: 28,
        color: const Color(0xFFf2f2f2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text(
          'Ln 1, Col 1   Spaces: 2   UTF-8',
          style: TextStyle(fontSize: 13, color: Color(0xFF4e4e4e)),
        ),
      );

  Widget _buildTerminalArea() => Container(
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
