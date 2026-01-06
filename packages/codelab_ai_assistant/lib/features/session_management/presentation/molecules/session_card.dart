// Карточка сессии
import 'package:fluent_ui/fluent_ui.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../../shared/presentation/molecules/cards/base_card.dart';
import '../../../shared/utils/formatters/date_formatter.dart';
import '../../../shared/utils/formatters/agent_formatter.dart';
import '../../domain/entities/session.dart';

/// Карточка сессии с информацией и действиями
/// 
/// Molecule-уровень компонент, использующий:
/// - BaseCard для основы
/// - Форматтеры для дат и агентов
/// - Тему для стилей
class SessionCard extends StatelessWidget {
  final Session session;
  final bool isCurrent;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SessionCard({
    super.key,
    required this.session,
    this.isCurrent = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: AppSpacing.paddingLg,
      selected: isCurrent,
      backgroundColor: isCurrent
          ? AppColors.primary.withOpacity(0.1)
          : null,
      borderColor: isCurrent
          ? AppColors.primary
          : AppColors.border,
      onPressed: onTap, // ✅ Передаем onTap в BaseCard
      child: Row(
        children: [
          // Иконка
          _buildIcon(),
          AppSpacing.gapHorizontalMd,
          
          // Контент
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                AppSpacing.gapVerticalXs,
                _buildMetadata(),
              ],
            ),
          ),
          
          // Бейдж агента
          _buildAgentBadge(),
          
          // Кнопка удаления
          if (!isCurrent && onDelete != null) ...[
            AppSpacing.gapHorizontalSm,
            _buildDeleteButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: AppSpacing.avatarLg,
      height: AppSpacing.avatarLg,
      decoration: BoxDecoration(
        color: isCurrent 
            ? AppColors.primary.withOpacity(0.2) 
            : AppColors.grey40,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Icon(
        isCurrent ? FluentIcons.chat_solid : FluentIcons.chat,
        color: isCurrent ? AppColors.primary : AppColors.grey120,
        size: AppSpacing.iconMd,
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            session.displayTitle,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isCurrent) ...[
          AppSpacing.gapHorizontalSm,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppSpacing.borderRadiusXs,
            ),
            child: Text(
              'Active',
              style: AppTypography.captionSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        Icon(
          FluentIcons.message,
          size: AppSpacing.iconXs,
          color: AppColors.textSecondary,
        ),
        AppSpacing.gapHorizontalXs,
        Text(
          '${session.messageCount} messages',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.gapHorizontalMd,
        Icon(
          FluentIcons.clock,
          size: AppSpacing.iconXs,
          color: AppColors.textSecondary,
        ),
        AppSpacing.gapHorizontalXs,
        Flexible(
          child: Text(
            DateFormatter.formatIsoRelative(
              session.updatedAt.toIso8601String(),
            ),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentBadge() {
    final agentColor = AppColors.getAgentColor(session.currentAgent);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: agentColor.withOpacity(0.2),
        borderRadius: AppSpacing.borderRadiusXs,
        border: Border.all(
          color: agentColor,
          width: 1,
        ),
      ),
      child: Text(
        AgentFormatter.formatAgentName(session.currentAgent),
        style: AppTypography.captionSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: agentColor,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      icon: Icon(
        FluentIcons.delete,
        size: AppSpacing.iconSm,
        color: AppColors.error,
      ),
      onPressed: onDelete,
    );
  }
}
