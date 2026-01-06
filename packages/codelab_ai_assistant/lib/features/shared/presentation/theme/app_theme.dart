// Главный файл темы приложения
export 'app_colors.dart';
export 'app_typography.dart';
export 'app_spacing.dart';

/// Централизованная тема приложения
/// 
/// Экспортирует все компоненты системы дизайна:
/// - AppColors: цветовая палитра
/// - AppTypography: типографика
/// - AppSpacing: отступы и размеры
/// 
/// Использование:
/// ```dart
/// import 'package:codelab_ai_assistant/features/shared/presentation/theme/app_theme.dart';
/// 
/// Text('Hello', style: AppTypography.h1);
/// Container(
///   color: AppColors.primary,
///   padding: AppSpacing.paddingLg,
///   child: ...
/// );
/// ```
