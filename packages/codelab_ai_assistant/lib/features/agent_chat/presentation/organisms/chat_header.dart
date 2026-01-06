// Заголовок чата с навигацией и селектором агента
import 'package:fluent_ui/fluent_ui.dart';
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;
import '../../../shared/presentation/theme/app_theme.dart';

/// Заголовок чата с кнопкой назад и селектором агента
///
/// Organism-уровень компонент для верхней панели чата
class ChatHeader extends StatelessWidget {
  final VoidCallback onBack;
  final uikit.AgentType currentAgent;
  final void Function(uikit.AgentType) onAgentSelected;

  const ChatHeader({
    super.key,
    required this.onBack,
    required this.currentAgent,
    required this.onAgentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              FluentIcons.back,
              size: AppSpacing.iconMd,
            ),
            onPressed: onBack,
          ),
          AppSpacing.gapHorizontalSm,
          Icon(
            FluentIcons.chat,
            size: AppSpacing.iconMd,
          ),
          AppSpacing.gapHorizontalSm,
          Text(
            'AI Assistant',
            style: AppTypography.h5,
          ),
          AppSpacing.gapHorizontalLg,
          uikit.AgentSelector(
            currentAgent: currentAgent,
            onAgentSelected: onAgentSelected,
          ),
        ],
      ),
    );
  }
}
