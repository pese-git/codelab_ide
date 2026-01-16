// Компонент для отображения одной подзадачи в плане
import 'package:fluent_ui/fluent_ui.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../domain/entities/execution_plan.dart';

/// Tile для отображения одной подзадачи в плане выполнения
/// 
/// Показывает:
/// - Статус подзадачи с иконкой
/// - Описание подзадачи
/// - Агента, который выполняет
/// - Оценку времени
/// - Ошибки (если есть)
/// - Зависимости (если есть)
class SubtaskTile extends StatelessWidget {
  final Subtask subtask;
  final int index;

  const SubtaskTile({
    super.key,
    required this.subtask,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Иконка статуса
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                subtask.status.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          AppSpacing.gapHorizontalMd,
          
          // Содержимое
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Описание
                Text(
                  '$index. ${subtask.description}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: subtask.status.isActive 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                    decoration: subtask.status == SubtaskStatus.completed
                      ? TextDecoration.lineThrough
                      : null,
                    color: subtask.status == SubtaskStatus.completed
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  ),
                ),
                
                AppSpacing.gapVerticalXs,
                
                // Метаданные
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    // Агент
                    _buildMetadataChip(
                      icon: FluentIcons.robot,
                      label: subtask.agent,
                      color: AppColors.secondary,
                    ),
                    
                    // Время
                    subtask.estimatedTime.fold(
                      () => const SizedBox.shrink(),
                      (time) => _buildMetadataChip(
                        icon: FluentIcons.clock,
                        label: time,
                        color: AppColors.grey130,
                      ),
                    ),
                    
                    // Статус
                    _buildMetadataChip(
                      icon: FluentIcons.status_circle_inner,
                      label: subtask.status.displayName,
                      color: _getStatusColor(),
                    ),
                  ],
                ),
                
                // Ошибка
                subtask.error.fold(
                  () => const SizedBox.shrink(),
                  (error) => Padding(
                    padding: AppSpacing.paddingVerticalXs,
                    child: Container(
                      padding: AppSpacing.paddingSm,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: AppSpacing.borderRadiusXs,
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            FluentIcons.error_badge,
                            size: 16,
                            color: AppColors.error,
                          ),
                          AppSpacing.gapHorizontalXs,
                          Expanded(
                            child: Text(
                              error,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Зависимости
                if (subtask.dependencies.isNotEmpty)
                  Padding(
                    padding: AppSpacing.paddingVerticalXs,
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.dependency_add,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        AppSpacing.gapHorizontalXs,
                        Expanded(
                          child: Text(
                            'Зависит от: ${subtask.dependencies.join(", ")}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip({
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

  Color _getStatusColor() {
    switch (subtask.status) {
      case SubtaskStatus.pending:
        return AppColors.grey130;
      case SubtaskStatus.inProgress:
        return AppColors.warning;
      case SubtaskStatus.completed:
        return AppColors.success;
      case SubtaskStatus.failed:
        return AppColors.error;
      case SubtaskStatus.skipped:
        return AppColors.grey100;
    }
  }
}
