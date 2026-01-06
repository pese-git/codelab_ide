// Компонент для отображения пустого состояния
import 'package:fluent_ui/fluent_ui.dart';
import '../../theme/app_theme.dart';

/// Компонент для отображения пустого состояния
/// 
/// Показывает иконку, заголовок, описание и опциональную кнопку действия
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: AppColors.grey100,
          ),
          AppSpacing.gapVerticalXl,
          Text(
            title,
            style: AppTypography.h4,
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            AppSpacing.gapVerticalSm,
            Text(
              description!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            AppSpacing.gapVerticalXxl,
            action!,
          ],
        ],
      ),
    );
  }
}
