import 'package:codelab_uikit/widgets/ai_assistant_ui/ai_assistant_ui.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Демонстрация стейтфул-ассистента с бизнес-логикой и собранным UI
class AIAssistantPanel extends StatefulWidget {
  const AIAssistantPanel({super.key});
  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel> {
  final TextEditingController _controller = TextEditingController();
  final List<AIAssistantMessage> _messages = [
    const AIAssistantMessage(role: 'ai', content: 'Привет! Я ассистент.'),
    const AIAssistantMessage(role: 'user', content: 'Расскажи про Flutter.'),
    const AIAssistantMessage(
      role: 'ai',
      content: 'Flutter — UI toolkit от Google...',
    ),
  ];
  bool _sending = false;

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(AIAssistantMessage(role: 'user', content: text));
      _controller.clear();
      _sending = true;
    });
    // Здесь будет вызов к LLM/AI!
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.add(AIAssistantMessage(role: 'ai', content: 'Ответ на: $text'));
      _sending = false;
    });
  }

  void _clear() {
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AIAssistantHeader(onClear: _clear),
        const Divider(size: 1),
        Expanded(child: AIAssistantMessageList(messages: _messages)),
        const Divider(size: 1),
        AIAssistantInputBar(
          controller: _controller,
          onSend: _send,
          sending: _sending,
        ),
      ],
    );
  }
}
