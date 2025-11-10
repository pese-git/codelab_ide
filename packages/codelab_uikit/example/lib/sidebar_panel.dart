import 'package:fluent_ui/fluent_ui.dart';

class SidebarPanel extends StatelessWidget {
  final int selectedIndex;
  const SidebarPanel({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return const ExplorerPanel();
      case 1:
        return const SidebarPlaceholder('Search');
      case 2:
        return const SidebarPlaceholder('Source Control');
      case 3:
        return const SidebarPlaceholder('Run/Debug');
      case 4:
        return const SidebarPlaceholder('Extensions');
      default:
        return const SizedBox(width: 200);
    }
  }
}

class ExplorerPanel extends StatelessWidget {
  const ExplorerPanel({super.key});
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

class SidebarPlaceholder extends StatelessWidget {
  final String name;
  const SidebarPlaceholder(this.name, {super.key});

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
