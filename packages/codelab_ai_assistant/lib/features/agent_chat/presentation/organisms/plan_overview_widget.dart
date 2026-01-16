// Компонент для отображения полного обзора плана выполнения
import 'package:fluent_ui/fluent_ui.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../domain/entities/execution_plan.dart';
import '../molecules/subtask_tile.dart';

/// Виджет для отображения полного обзора плана выполнения
/// 
/// Показывает:
/// - Заголовок с исходной задачей
/// - Прогресс выполнения (если план подтвержден)
/// - Список всех подзадач
/// - Оценку времени
/// - Кнопки подтверждения/отклонения (если ожидает подтверждения)
class PlanOverviewWidget extends StatelessWidget {
  final ExecutionPlan plan;
  final VoidCallback? onApprove;
  final ValueChanged<String>? onReject;

  const PlanOverviewWidget({
    super.key,
    required this.plan,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок с иконкой
            Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  FluentIcons.task_list,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'План выполнения',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      plan.originalTask,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            ),

            AppSpacing.gapVerticalLg,

            // Прогресс-бар (если не ожидает подтверждения)
            if (!plan.isPendingConfirmation) ...[
              _buildProgressSection(),
              AppSpacing.gapVerticalLg,
            ],

            // Информационная панель для ожидающих подтверждения
            if (plan.isPendingConfirmation) ...[
              _buildPendingConfirmationBanner(context),
              AppSpacing.gapVerticalLg,
            ],

            // Заголовок списка подзадач
            Row(
            children: [
              Text(
                'Подзадачи',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapHorizontalSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grey40,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${plan.totalCount}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            ),

            AppSpacing.gapVerticalMd,

            // Список подзадач
            ...plan.subtasks.asMap().entries.map((entry) {
              return SubtaskTile(
                subtask: entry.value,
                index: entry.key + 1,
              );
            }),

            // Оценка времени
            plan.estimatedTotalTime.fold(
              () => const SizedBox.shrink(),
              (time) => Padding(
                padding: AppSpacing.paddingVerticalMd,
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.clock,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapHorizontalXs,
                    Text(
                      'Оценка времени: $time',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Кнопки подтверждения
            if (plan.isPendingConfirmation) ...[
              AppSpacing.gapVerticalLg,
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Прогресс выполнения',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(plan.progress * 100).toStringAsFixed(0)}%',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        AppSpacing.gapVerticalSm,
        ProgressBar(
          value: plan.progress * 100,
          strokeWidth: 8,
        ),
        AppSpacing.gapVerticalSm,
        Row(
          children: [
            _buildStatChip(
              icon: FluentIcons.completed,
              label: '${plan.completedCount} завершено',
              color: AppColors.success,
            ),
            AppSpacing.gapHorizontalSm,
            if (plan.failedCount > 0)
              _buildStatChip(
                icon: FluentIcons.error_badge,
                label: '${plan.failedCount} ошибок',
                color: AppColors.error,
              ),
            AppSpacing.gapHorizontalSm,
            if (plan.skippedCount > 0)
              _buildStatChip(
                icon: FluentIcons.forward,
                label: '${plan.skippedCount} пропущено',
                color: AppColors.grey130,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingConfirmationBanner(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusXs,
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            FluentIcons.info,
            color: AppColors.warning,
            size: 20,
          ),
          AppSpacing.gapHorizontalSm,
          Expanded(
            child: Text(
              'Этот план требует вашего подтверждения перед началом выполнения',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Button(
          onPressed: () => _showRejectDialog(context),
          child: const Text('Отклонить'),
        ),
        AppSpacing.gapHorizontalSm,
        FilledButton(
          onPressed: onApprove,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentIcons.accept, size: 16),
              AppSpacing.gapHorizontalXs,
              const Text('Подтвердить план'),
            ],
          ),
        ),
      ],
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Отклонить план'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Укажите причину отклонения плана. Это поможет агенту создать более подходящий план.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapVerticalMd,
            TextBox(
              controller: controller,
              placeholder: 'Например: "Слишком много шагов" или "Нужен другой подход"',
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                onReject?.call(reason);
                Navigator.pop(context);
              } else {
                // Показать ошибку, что причина обязательна
                displayInfoBar(
                  context,
                  builder: (context, close) => InfoBar(
                    title: const Text('Укажите причину'),
                    content: const Text('Пожалуйста, укажите причину отклонения плана'),
                    severity: InfoBarSeverity.warning,
                    onClose: close,
                  ),
                );
              }
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }
}
