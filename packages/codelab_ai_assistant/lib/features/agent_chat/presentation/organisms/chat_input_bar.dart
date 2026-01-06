// Панель ввода сообщений для чата
import 'package:fluent_ui/fluent_ui.dart';
import '../../../shared/presentation/theme/app_theme.dart';

/// Панель ввода сообщений с кнопкой отправки
/// 
/// Organism-уровень компонент, объединяющий:
/// - Поле ввода текста
/// - Кнопку отправки с индикатором загрузки
/// - Логику отправки по Enter
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool isLoading;
  final String? placeholder;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.isLoading = false,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextBox(
              controller: controller,
              placeholder: placeholder ?? 'Type your message...',
              enabled: enabled && !isLoading,
              maxLines: null,
              minLines: 1,
              onSubmitted: enabled && !isLoading ? (_) => onSend() : null,
            ),
          ),
          AppSpacing.gapHorizontalMd,
          SizedBox(
            width: 40,
            height: 40,
            child: FilledButton(
              onPressed: (enabled && !isLoading) ? onSend : null,
              style: ButtonStyle(
                padding: ButtonState.all(EdgeInsets.zero),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.send, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
