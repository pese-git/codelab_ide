import 'package:fluent_ui/fluent_ui.dart';

class ProjectStatusInfo extends StatelessWidget {
  const ProjectStatusInfo({super.key});

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
