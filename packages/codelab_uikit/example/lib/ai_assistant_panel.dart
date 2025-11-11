import 'package:fluent_ui/fluent_ui.dart';

class AIAssistantPanel extends StatelessWidget {
  const AIAssistantPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF323130),
      width: double.infinity,
      child: const Center(
        child: Text(
          'AI Assistant\n(заглушка)',
          style: TextStyle(
            color: Color(0xFF4e4e4e),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
