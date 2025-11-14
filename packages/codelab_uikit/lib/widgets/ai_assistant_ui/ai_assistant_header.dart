import 'package:fluent_ui/fluent_ui.dart';

/// Верхний бар AI ассистента, без логики. Вызывает onClear при нажатии на крестик.
class AIAssistantHeader extends StatelessWidget {
  final VoidCallback? onClear;
  final String title;
  const AIAssistantHeader({Key? key, this.onClear, this.title = 'AI Assistant'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.lighter,
            child: Icon(FluentIcons.chat, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: FluentTheme.of(context).typography.title,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: onClear,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
