import 'package:fluent_ui/fluent_ui.dart';
import 'ai_assistant_message_bubble.dart';

/// Модель сообщения для списка (или импортируйте из общего места)
class AIAssistantMessage {
  final String role; // 'user' | 'ai'
  final String content;
  const AIAssistantMessage({required this.role, required this.content});
}

/// Отображает список сообщений AI-ассистента.
class AIAssistantMessageList extends StatelessWidget {
  final List<AIAssistantMessage> messages;
  const AIAssistantMessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isUser = msg.role == 'user';
        return AIAssistantMessageBubble(content: msg.content, isUser: isUser);
      },
    );
  }
}
