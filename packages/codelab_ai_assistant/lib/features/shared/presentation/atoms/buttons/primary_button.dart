// Основная кнопка приложения
import 'package:fluent_ui/fluent_ui.dart';
import '../../theme/app_theme.dart';

/// Основная кнопка (FilledButton) с консистентным стилем
/// 
/// Использует централизованную тему для размеров и отступов
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final ButtonSize size;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _getHeight(),
      child: FilledButton(
        onPressed: (isLoading || onPressed == null) ? null : onPressed,
        style: ButtonStyle(
          padding: ButtonState.all(_getPadding()),
        ),
        child: isLoading
            ? SizedBox(
                width: AppSpacing.iconSm,
                height: AppSpacing.iconSm,
                child: const ProgressRing(strokeWidth: 2),
              )
            : child,
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppSpacing.buttonHeightSm;
      case ButtonSize.medium:
        return AppSpacing.buttonHeightMd;
      case ButtonSize.large:
        return AppSpacing.buttonHeightLg;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return AppSpacing.paddingHorizontalSm;
      case ButtonSize.medium:
        return AppSpacing.paddingHorizontalMd;
      case ButtonSize.large:
        return AppSpacing.paddingHorizontalLg;
    }
  }
}

/// Размеры кнопок
enum ButtonSize {
  small,
  medium,
  large,
}
