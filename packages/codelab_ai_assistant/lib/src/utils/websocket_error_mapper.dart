import '../models/tool_models.dart';

/// Маппер для преобразования ToolExecutionException в WebSocket error messages
/// 
/// Обеспечивает структурированную обработку ошибок и их преобразование
/// в понятные для Gateway сообщения.
class WebSocketErrorMapper {
  /// Преобразует ToolExecutionException в структурированное error сообщение
  /// 
  /// Маппинг кодов ошибок:
  /// - `file_not_found` -> "File not found: {path}"
  /// - `permission_denied` -> "Access denied: {path}"
  /// - `invalid_path` -> "Invalid path: {path}. Reason: {reason}"
  /// - `file_too_large` -> "File too large: {path} ({size} bytes, max: {max_size} bytes)"
  /// - `encoding_error` -> "Encoding error for file: {path}"
  /// - `user_rejected` -> "Operation rejected by user: {operation}"
  /// - `concurrent_modification` -> "File was modified by another process: {path}"
  /// - `directory_not_found` -> "Parent directory does not exist: {path}"
  /// - `invalid_line_range` -> "Invalid line range: {message}"
  /// - `unsupported_tool` -> "Unsupported tool: {tool_name}"
  /// - `general_error` -> "Tool execution failed: {message}"
  /// 
  /// Возвращает структурированное сообщение об ошибке для отправки в Gateway.
  static String mapException(ToolExecutionException e) {
    return switch (e.code) {
      'file_not_found' => _formatError(
          'File not found',
          e.message,
          e.details,
        ),
      'permission_denied' => _formatError(
          'Access denied',
          e.message,
          e.details,
        ),
      'invalid_path' => _formatError(
          'Invalid path',
          e.message,
          e.details,
        ),
      'file_too_large' => _formatError(
          'File too large',
          e.message,
          e.details,
        ),
      'encoding_error' => _formatError(
          'Encoding error',
          e.message,
          e.details,
        ),
      'user_rejected' => _formatError(
          'Operation rejected by user',
          e.message,
          e.details,
        ),
      'concurrent_modification' => _formatError(
          'Concurrent modification',
          e.message,
          e.details,
        ),
      'directory_not_found' => _formatError(
          'Directory not found',
          e.message,
          e.details,
        ),
      'invalid_line_range' => _formatError(
          'Invalid line range',
          e.message,
          e.details,
        ),
      'unsupported_tool' => _formatError(
          'Unsupported tool',
          e.message,
          e.details,
        ),
      'general_error' => _formatError(
          'Tool execution failed',
          e.message,
          e.details,
        ),
      _ => _formatError(
          'Unknown error',
          e.message,
          e.details,
        ),
    };
  }

  /// Форматирует error сообщение с деталями
  static String _formatError(
    String errorType,
    String message,
    Map<String, dynamic>? details,
  ) {
    final buffer = StringBuffer('[$errorType] $message');
    
    if (details != null && details.isNotEmpty) {
      buffer.write('\nDetails: ');
      final detailsStr = details.entries
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      buffer.write(detailsStr);
    }
    
    return buffer.toString();
  }
}
