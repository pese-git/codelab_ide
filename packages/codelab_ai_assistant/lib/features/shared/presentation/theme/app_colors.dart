// Централизованная система цветов приложения
import 'package:fluent_ui/fluent_ui.dart';

/// Цветовая палитра приложения
/// 
/// Использует Fluent UI цвета для консистентности с Windows 11 дизайном
class AppColors {
  AppColors._();

  // Primary colors
  static Color get primary => Colors.blue;
  static Color get primaryLight => Colors.blue.light;
  static Color get primaryDark => Colors.blue.dark;

  // Secondary colors
  static Color get secondary => Colors.purple;
  static Color get secondaryLight => Colors.purple.light;
  static Color get secondaryDark => Colors.purple.dark;

  // Semantic colors
  static Color get success => Colors.green;
  static Color get successLight => Colors.green.light;
  static Color get warning => Colors.orange;
  static Color get warningLight => Colors.orange.light;
  static Color get error => Colors.red;
  static Color get errorLight => Colors.red.light;
  static Color get info => Colors.blue;
  static Color get infoLight => Colors.blue.light;

  // Agent colors
  static Color get orchestrator => Colors.purple;
  static Color get coder => Colors.blue;
  static Color get architect => Colors.orange;
  static Color get debug => Colors.red;
  static Color get ask => Colors.green;

  // Neutral colors
  static Color get grey10 => Colors.grey[10];
  static Color get grey20 => Colors.grey[20];
  static Color get grey40 => Colors.grey[40];
  static Color get grey60 => Colors.grey[60];
  static Color get grey80 => Colors.grey[80];
  static Color get grey100 => Colors.grey[100];
  static Color get grey120 => Colors.grey[120];
  static Color get grey130 => Colors.grey[130];
  static Color get grey160 => Colors.grey[160];

  // Background colors
  static Color get background => Colors.grey[10];
  static Color get surface => Colors.white;
  static Color get surfaceSecondary => Colors.grey[20];

  // Text colors
  static Color get textPrimary => Colors.black;
  static Color get textSecondary => Colors.grey[130];
  static Color get textDisabled => Colors.grey[100];
  static Color get textOnPrimary => Colors.white;

  // Border colors
  static Color get border => Colors.grey[60];
  static Color get borderLight => Colors.grey[40];
  static Color get borderDark => Colors.grey[80];

  // Message colors
  static Color userMessageBackground(double opacity) =>
      Colors.blue.withOpacity(opacity);
  static Color userMessageBorder(double opacity) =>
      Colors.blue.withOpacity(opacity);
  static Color assistantMessageBackground(double opacity) =>
      Colors.grey[20];
  static Color assistantMessageBorder(double opacity) =>
      Colors.grey[60];
  static Color toolCallBackground(double opacity) =>
      Colors.orange.withOpacity(opacity);
  static Color toolCallBorder(double opacity) =>
      Colors.orange.withOpacity(opacity);
  static Color toolResultBackground(double opacity) =>
      Colors.green.withOpacity(opacity);
  static Color toolResultBorder(double opacity) =>
      Colors.green.withOpacity(opacity);
  static Color agentSwitchBackground(double opacity) =>
      Colors.purple.withOpacity(opacity);
  static Color agentSwitchBorder(double opacity) =>
      Colors.purple.withOpacity(opacity);
  static Color errorMessageBackground(double opacity) =>
      Colors.red.withOpacity(opacity);
  static Color errorMessageBorder(double opacity) =>
      Colors.red.withOpacity(opacity);

  /// Получить цвет агента по его типу
  static Color getAgentColor(String agentType) {
    switch (agentType.toLowerCase()) {
      case 'orchestrator':
        return orchestrator;
      case 'coder':
      case 'code':
        return coder;
      case 'architect':
        return architect;
      case 'debug':
        return debug;
      case 'ask':
        return ask;
      default:
        return grey100;
    }
  }

  /// Получить цвет инструмента по его имени
  static Color getToolColor(String toolName) {
    switch (toolName.toLowerCase()) {
      case 'write_file':
      case 'create_directory':
        return warning;
      case 'delete_file':
        return error;
      case 'execute_command':
        return secondary;
      case 'move_file':
      case 'read_file':
        return info;
      default:
        return grey100;
    }
  }
}
