// Компактный индикатор прогресса выполнения плана
import 'package:fluent_ui/fluent_ui.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../domain/entities/execution_plan.dart';

/// Компактный индикатор прогресса выполнения плана
/// 
/// Показывает:
/// - Иконку плана
/// - Название и краткую информацию
/// - Прогресс-бар
/// - Количество завершенных подзадач
/// 
/// При нажатии можно открыть полный обзор плана
class PlanProgressIndicator extends StatelessWidget {
  final ExecutionPlan plan;
  final VoidCallback? onTap;

  const PlanProgressIndicator({
    super.key,
    required this.plan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTap,
      style: ButtonStyle(
        padding: ButtonState.all(EdgeInsets.zero),
      ),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: AppSpacing.borderRadiusXs,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                FluentIcons.task_list,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapHorizontalMd,

            // Содержимое
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Выполнение плана',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Процент
                      Text(
                        '${(plan.progress * 100).toStringAsFixed(0)}%',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalXs,

                  // Прогресс-бар
                  ProgressBar(
                    value: plan.progress * 100,
                    strokeWidth: 4,
                  ),
                  AppSpacing.gapVerticalXs,

                  // Статистика
                  Row(
                    children: [
                      Icon(
                        FluentIcons.completed,
                        size: 12,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${plan.completedCount}/${plan.totalCount} подзадач',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (plan.failedCount > 0) ...[
                        AppSpacing.gapHorizontalSm,
                        Icon(
                          FluentIcons.error_badge,
                          size: 12,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${plan.failedCount} ошибок',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Текущая подзадача
                      plan.currentSubtask.fold(
                        () => const SizedBox.shrink(),
                        (subtask) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '⚙️',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                subtask.agent,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.gapHorizontalMd,

            // Стрелка
            Icon(
              FluentIcons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
