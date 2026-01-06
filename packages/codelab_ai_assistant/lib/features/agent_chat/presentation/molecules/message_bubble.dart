// Компонент для отображения одного сообщения
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../domain/entities/message.dart';

/// Bubble для отображения одного сообщения в чате
/// 
/// Преимущества перед встроенным в ChatView:
/// - Переиспользуемый компонент (~80 строк vs встроенный код)
/// - Использует централизованную тему
/// - Легко тестировать
/// - Single Responsibility
class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser),
            AppSpacing.gapHorizontalMd,
          ],
          Flexible(
            child: Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: _getBorderColor(),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) _buildMessageHeader(),
                  GptMarkdown(_getMessageContent()),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            AppSpacing.gapHorizontalMd,
            _buildAvatar(isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: AppSpacing.avatarMd,
      height: AppSpacing.avatarMd,
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.primary.withOpacity(0.2)
            : AppColors.grey40,
        borderRadius: BorderRadius.circular(AppSpacing.avatarMd / 2),
      ),
      child: Icon(
        isUser ? FluentIcons.contact : FluentIcons.robot,
        size: AppSpacing.iconSm,
        color: isUser ? AppColors.primary : AppColors.grey130,
      ),
    );
  }

  Widget _buildMessageHeader() {
    String? label;
    Color? color;

    message.content.maybeWhen(
      toolCall: (callId, toolName, arguments) {
        label = '🔧 Tool: $toolName';
        color = AppColors.warning;
      },
      toolResult: (callId, toolName, result, error) {
        label = '✓ Result: $toolName';
        color = AppColors.success;
      },
      agentSwitch: (fromAgent, toAgent, reason) {
        label = '🔄 $fromAgent → $toAgent';
        color = AppColors.secondary;
      },
      error: (message) {
        label = '❌ Error';
        color = AppColors.error;
      },
      orElse: () {},
    );

    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: AppSpacing.paddingVerticalXs,
      child: Text(
        label!,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    return message.content.when(
      text: (text, isFinal) => message.isUser
          ? AppColors.userMessageBackground(0.1)
          : AppColors.assistantMessageBackground(0.1),
      toolCall: (_, __, ___) => AppColors.toolCallBackground(0.1),
      toolResult: (_, __, ___, ____) => AppColors.toolResultBackground(0.1),
      agentSwitch: (_, __, ___) => AppColors.agentSwitchBackground(0.1),
      error: (_) => AppColors.errorMessageBackground(0.1),
    );
  }

  Color _getBorderColor() {
    return message.content.when(
      text: (text, isFinal) => message.isUser
          ? AppColors.userMessageBorder(0.3)
          : AppColors.assistantMessageBorder(0.3),
      toolCall: (_, __, ___) => AppColors.toolCallBorder(0.3),
      toolResult: (_, __, ___, ____) => AppColors.toolResultBorder(0.3),
      agentSwitch: (_, __, ___) => AppColors.agentSwitchBorder(0.3),
      error: (_) => AppColors.errorMessageBorder(0.3),
    );
  }

  String _getMessageContent() {
    return message.content.when(
      text: (text, isFinal) => text,
      toolCall: (callId, toolName, arguments) =>
          '**Tool Call:** `$toolName`\n\n```json\n$arguments\n```',
      toolResult: (callId, toolName, result, error) {
        if (error != null) {
          return error.fold(
            () => result != null
                ? result.fold(() => 'No result', (r) => '```json\n$r\n```')
                : 'No result',
            (e) => '**Error:** $e',
          );
        }
        if (result != null) {
          return result.fold(() => 'No result', (r) => '```json\n$r\n```');
        }
        return 'No result';
      },
      agentSwitch: (fromAgent, toAgent, reason) {
        final baseText = 'Agent switched: $fromAgent → $toAgent';
        if (reason != null) {
          return reason.fold(
            () => baseText,
            (r) => '$baseText\n\n**Reason:** $r',
          );
        }
        return baseText;
      },
      error: (errorMessage) {
        if (errorMessage.isEmpty) {
          return '**Error:** Unknown error occurred. Please check the logs for details.';
        }
        return '**Error:** $errorMessage';
      },
    );
  }
}
