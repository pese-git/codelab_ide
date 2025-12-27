import 'package:flutter/material.dart';

/// Результат диалога подтверждения операции
enum ToolApprovalResult {
  /// Операция одобрена
  approved,

  /// Операция отклонена
  rejected,

  /// Диалог отменен
  cancelled,
}

/// Диалог для подтверждения операций write_file
/// 
/// Отображает детали операции и позволяет пользователю
/// одобрить или отклонить выполнение.
class ToolApprovalDialog extends StatelessWidget {
  /// Путь к файлу
  final String filePath;

  /// Содержимое для записи
  final String content;

  /// Существует ли файл (для отображения предупреждения о перезаписи)
  final bool fileExists;

  /// Будет ли создана резервная копия
  final bool willCreateBackup;

  const ToolApprovalDialog({
    super.key,
    required this.filePath,
    required this.content,
    required this.fileExists,
    required this.willCreateBackup,
  });

  /// Показывает диалог и возвращает результат
  static Future<ToolApprovalResult> show({
    required BuildContext context,
    required String filePath,
    required String content,
    required bool fileExists,
    required bool willCreateBackup,
  }) async {
    final result = await showDialog<ToolApprovalResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ToolApprovalDialog(
        filePath: filePath,
        content: content,
        fileExists: fileExists,
        willCreateBackup: willCreateBackup,
      ),
    );

    return result ?? ToolApprovalResult.cancelled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentLines = content.split('\n').length;
    final contentSize = content.length;
    final contentSizeKb = (contentSize / 1024).toStringAsFixed(2);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            fileExists ? Icons.edit_document : Icons.note_add,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileExists ? 'Confirm File Modification' : 'Confirm File Creation',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Предупреждение о перезаписи
            if (fileExists)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will overwrite the existing file',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (fileExists) const SizedBox(height: 16),

            // Информация о файле
            _buildInfoRow(
              context,
              icon: Icons.insert_drive_file,
              label: 'File Path',
              value: filePath,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.format_list_numbered,
              label: 'Lines',
              value: contentLines.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.data_usage,
              label: 'Size',
              value: '$contentSizeKb KB',
            ),
            if (willCreateBackup) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.backup,
                label: 'Backup',
                value: 'Will be created',
                valueColor: theme.colorScheme.primary,
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Превью контента
            Text(
              'Content Preview:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _getContentPreview(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Кнопка Cancel
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(ToolApprovalResult.cancelled);
          },
          child: const Text('Cancel'),
        ),

        // Кнопка Reject
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).pop(ToolApprovalResult.rejected);
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
          ),
          child: const Text('Reject'),
        ),

        // Кнопка Approve
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(ToolApprovalResult.approved);
          },
          child: const Text('Approve'),
        ),
      ],
    );
  }

  /// Строит строку информации
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Получает превью контента (первые 50 строк)
  String _getContentPreview() {
    const maxLines = 50;
    final lines = content.split('\n');

    if (lines.length <= maxLines) {
      return content;
    }

    final preview = lines.take(maxLines).join('\n');
    final remainingLines = lines.length - maxLines;
    return '$preview\n\n... and $remainingLines more lines';
  }
}
