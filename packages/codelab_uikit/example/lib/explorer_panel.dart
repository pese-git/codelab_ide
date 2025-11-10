import 'package:fluent_ui/fluent_ui.dart';

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
