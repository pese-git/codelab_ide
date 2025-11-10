import 'package:fluent_ui/fluent_ui.dart';

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
