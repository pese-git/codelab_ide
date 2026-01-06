// Новая страница чата с применением рефакторинга
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../../shared/presentation/molecules/feedback/empty_state.dart';
import '../../../shared/utils/extensions/agent_type_extensions.dart';
import '../bloc/agent_chat_bloc.dart';
import '../molecules/message_bubble.dart';
import '../organisms/chat_input_bar.dart';
import '../organisms/chat_header.dart';

/// Новая страница чата с применением Atomic Design
/// 
/// Преимущества перед старой ChatView:
/// - Использует переиспользуемые компоненты
/// - Применяет централизованную тему
/// - Меньше кода (~200 строк vs 417)
/// - Композиция вместо монолита
/// - Легче тестировать
class ChatPage extends StatefulWidget {
  final AgentChatBloc bloc;
  final VoidCallback onBackToSessions;
  final VoidCallback? onLogout;

  const ChatPage({
    super.key,
    required this.bloc,
    required this.onBackToSessions,
    this.onLogout,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentChatBloc, AgentChatState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final waiting = state.isLoading;
        final pendingApproval = state.pendingApproval.toNullable();
        final messages = state.messages;
        final currentAgentStr = state.currentAgent;

        return Column(
          children: [
            // Header с использованием нового компонента
            ChatHeader(
              onBack: widget.onBackToSessions,
              currentAgent: currentAgentStr.toUikitAgentType(), // ✅ Используем extension
              onAgentSelected: (agentType) {
                widget.bloc.add(
                  AgentChatEvent.switchAgent(
                    agentType.toDomainString(), // ✅ Используем extension
                    'Switched to ${agentType.displayName}',
                  ),
                );
              },
              onLogout: widget.onLogout,
            ),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? EmptyState(
                      icon: FluentIcons.chat,
                      title: 'Start a conversation',
                      description: 'Ask me anything or describe what you want to build',
                      iconSize: 64,
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.paddingLg,
                      itemCount: messages.length,
                      // ✅ Оптимизация производительности
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      cacheExtent: 200,
                      itemBuilder: (ctx, idx) => RepaintBoundary(
                        child: MessageBubble(
                          key: ValueKey(messages[idx].id), // ✅ Ключ для оптимизации
                          message: messages[idx],
                        ),
                      ),
                    ),
            ),

            // Tool approval buttons
            if (pendingApproval != null) ...[
              Divider(
                style: DividerThemeData(
                  thickness: 1,
                  decoration: BoxDecoration(color: AppColors.border),
                ),
              ),
              _buildApprovalButtons(context, pendingApproval),
            ],

            // Input bar с использованием нового компонента
            ChatInputBar(
              controller: _controller,
              onSend: _send,
              enabled: !waiting && pendingApproval == null,
              isLoading: waiting,
            ),
          ],
        );
      },
    );
  }

  Widget _buildApprovalButtons(BuildContext context, dynamic pendingApproval) {
    final toolCall = pendingApproval.toolCall;
    final toolName = toolCall.toolName;
    final arguments = toolCall.arguments;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: AppColors.warning,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.warning,
                color: AppColors.warning,
                size: AppSpacing.iconMd,
              ),
              AppSpacing.gapHorizontalSm,
              Expanded(
                child: Text(
                  'Tool approval required: $toolName',
                  style: AppTypography.labelLarge,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,
          Text(
            'This operation requires your approval before execution.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (arguments.isNotEmpty) ...[
            AppSpacing.gapVerticalSm,
            Container(
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: AppColors.grey20,
                borderRadius: AppSpacing.borderRadiusXs,
              ),
              child: Text(
                'Arguments: ${arguments.toString()}',
                style: AppTypography.codeSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          AppSpacing.gapVerticalLg,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                onPressed: () {
                  widget.bloc.add(
                    const AgentChatEvent.rejectToolCall('User rejected'),
                  );
                },
                child: const Text('Reject'),
              ),
              AppSpacing.gapHorizontalSm,
              FilledButton(
                onPressed: () {
                  widget.bloc.add(const AgentChatEvent.approveToolCall());
                },
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.bloc.add(AgentChatEvent.sendMessage(text));
    _controller.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  // ✅ Удален _stringToUikitAgentType - теперь используется extension
}
