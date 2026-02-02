import 'package:fluent_ui/fluent_ui.dart';
import '../../../shared/presentation/theme/app_theme.dart';

/// Диалог для одобрения плана выполнения задачи
/// 
/// Отображает:
/// - Цель задачи
/// - Список подзадач с деталями
/// - Общее время выполнения
/// - Кнопки действий: Approve, Reject, Modify
class PlanApprovalDialog extends StatefulWidget {
  final String approvalRequestId;
  final String planId;
  final Map<String, dynamic> planSummary;
  final Function(String decision, String? feedback) onDecision;

  const PlanApprovalDialog({
    super.key,
    required this.approvalRequestId,
    required this.planId,
    required this.planSummary,
    required this.onDecision,
  });

  @override
  State<PlanApprovalDialog> createState() => _PlanApprovalDialogState();
}

class _PlanApprovalDialogState extends State<PlanApprovalDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _showFeedbackField = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  String get _goal => widget.planSummary['goal'] as String? ?? 'No goal specified';
  
  int get _subtasksCount => widget.planSummary['subtasks_count'] as int? ?? 0;
  
  String get _totalEstimatedTime => 
      widget.planSummary['total_estimated_time'] as String? ?? 'Unknown';
  
  List<Map<String, dynamic>> get _subtasks {
    final subtasks = widget.planSummary['subtasks'];
    if (subtasks is List) {
      return subtasks.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
      title: Row(
        children: [
          const Icon(FluentIcons.task_manager, size: 24),
          const SizedBox(width: 12),
          const Text('План выполнения задачи'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGoalSection(),
            const SizedBox(height: 16),
            _buildSummarySection(),
            const SizedBox(height: 16),
            _buildSubtasksSection(),
            if (_showFeedbackField) ...[
              const SizedBox(height: 16),
              _buildFeedbackSection(),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => _handleDecision('reject'),
          child: const Text('Отклонить'),
        ),
        Button(
          onPressed: () {
            setState(() {
              _showFeedbackField = !_showFeedbackField;
            });
          },
          child: Text(_showFeedbackField ? 'Скрыть изменения' : 'Изменить план'),
        ),
        FilledButton(
          onPressed: () => _handleDecision('approve'),
          child: const Text('Одобрить'),
        ),
      ],
    );
  }

  Widget _buildGoalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цель',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _goal,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: FluentIcons.task_list,
            label: 'Подзадач',
            value: '$_subtasksCount',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: FluentIcons.clock,
            label: 'Время',
            value: _totalEstimatedTime,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection() {
    if (_subtasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey40.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Нет подзадач'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Подзадачи',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_subtasks.length, (index) {
          final subtask = _subtasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildSubtaskCard(subtask, index + 1),
          );
        }),
      ],
    );
  }

  Widget _buildSubtaskCard(Map<String, dynamic> subtask, int index) {
    final description = subtask['description'] as String? ?? 'No description';
    final agent = subtask['agent'] as String? ?? 'unknown';
    final estimatedTime = subtask['estimated_time'] as String? ?? 'Unknown';
    final dependencies = subtask['dependencies'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey40.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.grey130.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSubtaskBadge(
                icon: FluentIcons.robot,
                label: agent,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              _buildSubtaskBadge(
                icon: FluentIcons.clock,
                label: estimatedTime,
                color: AppColors.warning,
              ),
              if (dependencies.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildSubtaskBadge(
                  icon: FluentIcons.dependency_add,
                  label: '${dependencies.length} deps',
                  color: AppColors.grey130,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Комментарии к изменениям',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextBox(
          controller: _feedbackController,
          placeholder: 'Опишите, что нужно изменить в плане...',
          maxLines: 4,
          minLines: 3,
        ),
      ],
    );
  }

  void _handleDecision(String decision) {
    final feedback = _feedbackController.text.trim();
    
    // Если выбрано "modify" но нет feedback, показываем поле
    if (decision == 'modify' && feedback.isEmpty && !_showFeedbackField) {
      setState(() {
        _showFeedbackField = true;
      });
      return;
    }

    // Если есть feedback, отправляем как modify
    final finalDecision = feedback.isNotEmpty ? 'modify' : decision;
    final finalFeedback = feedback.isNotEmpty ? feedback : null;

    widget.onDecision(finalDecision, finalFeedback);
    Navigator.of(context).pop();
  }
}
