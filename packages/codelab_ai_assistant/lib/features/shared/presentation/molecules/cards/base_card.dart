// Базовая карточка для переиспользования
import 'package:fluent_ui/fluent_ui.dart';
import '../../theme/app_theme.dart';

/// Базовая карточка с консистентным стилем
/// 
/// Используется как основа для всех карточек в приложении
class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final VoidCallback? onPressed;
  final bool selected;

  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? AppSpacing.paddingMd,
      child: child,
    );

    final card = Card(
      padding: EdgeInsets.zero,
      backgroundColor: backgroundColor ??
          (selected ? AppColors.primary.withOpacity(0.1) : null),
      borderColor: borderColor ??
          (selected ? AppColors.primary : AppColors.border),
      borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
      child: content,
    );

    if (onPressed != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }

    return card;
  }
}
