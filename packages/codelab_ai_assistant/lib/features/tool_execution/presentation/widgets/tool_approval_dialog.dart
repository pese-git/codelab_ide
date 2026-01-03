// lib/ai_agent/widgets/tool_approval_dialog.dart

import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart';

/// Dialog for approving, editing, or rejecting tool calls requiring HITL approval
class ToolApprovalDialog extends StatefulWidget {
  final String callId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final String? reason;
  final Function(String decision, {Map<String, dynamic>? modifiedArguments, String? feedback}) onDecision;

  const ToolApprovalDialog({
    super.key,
    required this.callId,
    required this.toolName,
    required this.arguments,
    this.reason,
    required this.onDecision,
  });

  @override
  State<ToolApprovalDialog> createState() => _ToolApprovalDialogState();
}

class _ToolApprovalDialogState extends State<ToolApprovalDialog> {
  late TextEditingController _argumentsController;
  late TextEditingController _feedbackController;
  bool _isEditing = false;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _argumentsController = TextEditingController(
      text: _formatJson(widget.arguments),
    );
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _argumentsController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String _formatJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  Map<String, dynamic>? _parseJson(String text) {
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map<String, dynamic>) {
        setState(() => _parseError = null);
        return parsed;
      }
      setState(() => _parseError = 'Invalid JSON format');
      return null;
    } catch (e) {
      setState(() => _parseError = 'JSON parse error: $e');
      return null;
    }
  }

  String _getToolIcon(String toolName) {
    switch (toolName) {
      case 'write_file':
        return '📝';
      case 'delete_file':
        return '🗑️';
      case 'execute_command':
        return '⚡';
      case 'create_directory':
        return '📁';
      case 'move_file':
        return '📦';
      default:
        return '🔧';
    }
  }

  Color _getToolColor(String toolName) {
    switch (toolName) {
      case 'write_file':
      case 'create_directory':
        return Colors.orange;
      case 'delete_file':
        return Colors.red;
      case 'execute_command':
        return Colors.purple;
      case 'move_file':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Row(
        children: [
          Text(_getToolIcon(widget.toolName), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text('Tool Approval Required'),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool info
            InfoBar(
              title: Text('Tool: ${widget.toolName}'),
              severity: InfoBarSeverity.warning,
              content: widget.reason != null
                  ? Text(widget.reason!)
                  : const Text('This operation requires your approval'),
            ),
            const SizedBox(height: 16),
            
            // Arguments section
            Text(
              'Arguments:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            
            if (_isEditing) ...[
              // Editable JSON
              TextBox(
                controller: _argumentsController,
                maxLines: 10,
                placeholder: 'Edit JSON arguments...',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              if (_parseError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _parseError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ] else ...[
              // Read-only JSON display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[20],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[60]),
                ),
                child: SelectableText(
                  _formatJson(widget.arguments),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Edit mode toggle
            ToggleSwitch(
              checked: _isEditing,
              onChanged: (value) => setState(() => _isEditing = value),
              content: const Text('Edit arguments'),
            ),
            
            const SizedBox(height: 16),
            
            // Feedback section (for reject)
            Text(
              'Feedback (optional):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextBox(
              controller: _feedbackController,
              placeholder: 'Reason for rejection or comments...',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        // Reject button
        Button(
          onPressed: () {
            final feedback = _feedbackController.text.trim();
            widget.onDecision(
              'reject',
              feedback: feedback.isEmpty ? 'User rejected this operation' : feedback,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Reject'),
        ),
        
        // Approve/Edit button
        FilledButton(
          onPressed: () {
            if (_isEditing) {
              // Parse and validate edited JSON
              final modifiedArgs = _parseJson(_argumentsController.text);
              if (modifiedArgs == null) {
                // Show error, don't close dialog
                return;
              }
              widget.onDecision(
                'edit',
                modifiedArguments: modifiedArgs,
              );
            } else {
              widget.onDecision('approve');
            }
            Navigator.of(context).pop();
          },
          child: Text(_isEditing ? 'Approve with Edits' : 'Approve'),
        ),
      ],
    );
  }
}
