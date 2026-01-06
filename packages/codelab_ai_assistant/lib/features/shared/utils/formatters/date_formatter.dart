// Утилиты для форматирования дат
/// Форматирование дат для UI
class DateFormatter {
  DateFormatter._();

  /// Форматирует дату в относительный формат (например, "2h ago", "Just now")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (diff.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Форматирует дату в короткий формат (DD/MM/YYYY)
  static String formatShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Форматирует дату в полный формат (DD Month YYYY, HH:MM)
  static String formatFull(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Форматирует время (HH:MM)
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Форматирует ISO строку в относительный формат
  static String formatIsoRelative(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return formatRelative(date);
    } catch (e) {
      return isoDate;
    }
  }

  /// Форматирует ISO строку в короткий формат
  static String formatIsoShort(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return formatShort(date);
    } catch (e) {
      return isoDate;
    }
  }
}
