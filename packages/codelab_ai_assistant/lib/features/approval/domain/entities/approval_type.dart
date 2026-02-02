/// Тип подтверждения в системе
///
/// Определяет различные типы операций, требующих подтверждения пользователя.
/// Используется для унификации механизма подтверждений.
enum ApprovalType {
  /// Подтверждение выполнения инструмента (tool)
  tool,

  /// Подтверждение плана выполнения
  plan,

  // Будущие типы подтверждений:
  // fileOperation - операции с файлами (удаление, перемещение)
  // dangerousCommand - опасные команды
  // apiCall - вызовы внешних API
  // databaseOperation - операции с базой данных
}

/// Расширение для работы с ApprovalType
extension ApprovalTypeExtension on ApprovalType {
  /// Получить строковое представление типа
  String get value {
    switch (this) {
      case ApprovalType.tool:
        return 'tool';
      case ApprovalType.plan:
        return 'plan';
    }
  }

  /// Создать ApprovalType из строки
  static ApprovalType fromString(String value) {
    switch (value) {
      case 'tool':
        return ApprovalType.tool;
      case 'plan':
        return ApprovalType.plan;
      default:
        throw ArgumentError('Unknown approval type: $value');
    }
  }
}
