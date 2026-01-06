// Расширения для BuildContext
import 'package:fluent_ui/fluent_ui.dart';

/// Расширения для удобного доступа к теме и навигации
extension ContextExtensions on BuildContext {
  /// Получить FluentThemeData
  FluentThemeData get theme => FluentTheme.of(this);

  /// Получить цвета темы
  AccentColor get accentColor => theme.accentColor;

  /// Получить Typography
  Typography get typography => theme.typography;

  /// Получить размер экрана
  Size get screenSize => MediaQuery.of(this).size;

  /// Получить ширину экрана
  double get screenWidth => screenSize.width;

  /// Получить высоту экрана
  double get screenHeight => screenSize.height;

  /// Проверить, является ли экран маленьким (< 600px)
  bool get isSmallScreen => screenWidth < 600;

  /// Проверить, является ли экран средним (600-1200px)
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  /// Проверить, является ли экран большим (>= 1200px)
  bool get isLargeScreen => screenWidth >= 1200;

  /// Показать InfoBar
  void showInfoBar({
    required String title,
    required String message,
    InfoBarSeverity severity = InfoBarSeverity.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    displayInfoBar(
      this,
      duration: duration,
      builder: (context, close) => InfoBar(
        title: Text(title),
        content: Text(message),
        severity: severity,
        onClose: close,
      ),
    );
  }

  /// Показать успешное сообщение
  void showSuccess(String message) {
    showInfoBar(
      title: 'Success',
      message: message,
      severity: InfoBarSeverity.success,
    );
  }

  /// Показать ошибку
  void showError(String message) {
    showInfoBar(
      title: 'Error',
      message: message,
      severity: InfoBarSeverity.error,
      duration: const Duration(seconds: 5),
    );
  }

  /// Показать предупреждение
  void showWarning(String message) {
    showInfoBar(
      title: 'Warning',
      message: message,
      severity: InfoBarSeverity.warning,
    );
  }

  /// Показать информацию
  void showInfo(String message) {
    showInfoBar(
      title: 'Info',
      message: message,
      severity: InfoBarSeverity.info,
    );
  }

  /// Показать диалог подтверждения
  Future<bool> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => ContentDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
