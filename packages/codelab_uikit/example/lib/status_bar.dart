import 'package:fluent_ui/fluent_ui.dart';

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
