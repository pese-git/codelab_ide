import 'package:fluent_ui/fluent_ui.dart';

/// Нижняя панель для ввода запроса ассистента
class AIAssistantInputBar extends StatelessWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend;
  final VoidCallback? onSuggestion;
  final bool sending;

  const AIAssistantInputBar({
    super.key,
    this.controller,
    this.onSend,
    this.onSuggestion,
    this.sending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 12, top: 7, bottom: 7),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(FluentIcons.lightbulb),
            onPressed: onSuggestion,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
          Expanded(
            child: TextBox(
              controller: controller,
              placeholder: 'Введите ваш вопрос...',
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Отправить',
            child: FilledButton(
              onPressed: sending ? null : onSend,
              style: ButtonStyle(
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              child: sending
                  ? const ProgressRing(strokeWidth: 2)
                  : const Icon(FluentIcons.send),
            ),
          ),
        ],
      ),
    );
  }
}
