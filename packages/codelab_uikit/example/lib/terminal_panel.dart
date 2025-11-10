import 'package:fluent_ui/fluent_ui.dart';

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
