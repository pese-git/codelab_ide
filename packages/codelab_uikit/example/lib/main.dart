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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Codelab IDE'),
        //leading: IconButton(
        //  icon: const Icon(FluentIcons.page),
        //  onPressed: () {},
        //),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(FluentIcons.save), onPressed: () {}),
            IconButton(icon: const Icon(FluentIcons.play), onPressed: () {}),
            IconButton(
              icon: const Icon(FluentIcons.settings),
              onPressed: () {},
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        displayMode: PaneDisplayMode.compact,
        size: const NavigationPaneSize(),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.open_folder_horizontal),
            title: const Text('Explorer'),
            body: _buildFileExplorer(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.search),
            title: const Text('Search'),
            body: _placeholderBody('Search'),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.git_graph),
            title: const Text('Git'),
            body: _placeholderBody('Source Control'),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.play),
            title: const Text('Run'),
            body: _placeholderBody('Run/Debug'),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.plug),
            title: const Text('Extensions'),
            body: _placeholderBody('Extensions'),
          ),
        ],
      ),
      /*
      content: Stack(
        children: [
          Positioned.fill(child: _buildEditorArea()),
          Align(alignment: Alignment.bottomCenter, child: _buildStatusBar()),
        ],
      ),
      */
    );
  }

  Widget _buildFileExplorer() => Container(
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

  Widget _buildEditorArea() => Padding(
    padding: const EdgeInsets.only(left: 75), // Сдвиг под NavigationPane
    child: Container(
      color: Colors.white,
      child: const Center(
        child: Text(
          'Editor Area\n(Здесь будет редактор кода)',
          style: TextStyle(fontSize: 20, color: Color(0xFF888888)),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  Widget _placeholderBody(String name) => Center(
    child: Text(
      '$name area (будет реализовано позже)',
      style: const TextStyle(color: Color(0xFF888888), fontSize: 17),
      textAlign: TextAlign.center,
    ),
  );

  Widget _buildStatusBar() => Container(
    height: 28,
    color: const Color(0xFFf2f2f2), // светло-серый, или любой по желанию,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: const Text(
      'Ln 1, Col 1   Spaces: 2   UTF-8',
      style: TextStyle(fontSize: 13, color: Color(0xFF4e4e4e)),
    ),
  );
}
