import 'package:fluent_ui/fluent_ui.dart';

/// Пузырь сообщения ассистента или пользователя
class AIAssistantMessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const AIAssistantMessageBubble({
    Key? key,
    required this.content,
    this.isUser = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.lighter : Colors.grey[20],
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          content,
          style: FluentTheme.of(context).typography.body!.copyWith(
                color: isUser ? Colors.blue.darker : null,
              ),
        ),
      ),
    );
  }
}
