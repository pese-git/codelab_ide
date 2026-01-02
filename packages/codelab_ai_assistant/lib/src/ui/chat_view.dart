import 'package:codelab_uikit/codelab_uikit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../bloc/ai_agent_bloc.dart';
import '../models/ws_message.dart';
import '../widgets/tool_approval_dialog.dart' as hitl;

/// Виджет чата с AI агентом
class ChatView extends StatefulWidget {
  final AiAgentBloc bloc;
  final VoidCallback onBackToSessions;

  const ChatView({
    super.key,
    required this.bloc,
    required this.onBackToSessions,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
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
    return BlocBuilder<AiAgentBloc, AiAgentState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final chat = state.maybeMap<ChatState?>(
          chat: (value) => value,
          orElse: () => null,
        );
        final waiting = chat?.waitingResponse ?? false;
        final pendingApproval = chat?.pendingApproval;
        final List<WSMessage> history = (chat != null) ? chat.history : [];
        final currentAgent = AgentType.fromString(
          chat?.currentAgent ?? 'orchestrator',
        );

        return Column(
          children: [
            // Header
            _buildHeader(context, currentAgent),
            const Divider(style: DividerThemeData(thickness: 1)),
            // Messages
            Expanded(
              child: history.isEmpty
                  ? _buildEmptyChat(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (ctx, idx) => _msgBubble(history[idx]),
                    ),
            ),
            // Tool approval buttons
            if (pendingApproval != null) ...[
              const Divider(style: DividerThemeData(thickness: 1)),
              _buildApprovalButtons(context, pendingApproval),
            ],
            // Input bar
            const Divider(style: DividerThemeData(thickness: 1)),
            _buildInputBar(context, waiting, pendingApproval != null),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AgentType currentAgent) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(FluentIcons.back, size: 20),
            onPressed: widget.onBackToSessions,
          ),
          const SizedBox(width: 8),
          const Icon(FluentIcons.chat, size: 20),
          const SizedBox(width: 8),
          const Text(
            'AI Assistant',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          AgentSelector(
            currentAgent: currentAgent,
            onAgentSelected: (agentType) {
              widget.bloc.add(
                AiAgentEvent.switchAgent(
                  agentType.toApiString(),
                  'Switched to ${agentType.displayName}',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.chat, size: 64, color: Colors.grey[100]),
          const SizedBox(height: 24),
          const Text(
            'Start a conversation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything or describe what you want to build',
            style: TextStyle(fontSize: 14, color: Colors.grey[120]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool waiting, bool hasApproval) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextBox(
              controller: _controller,
              placeholder: 'Type your message...',
              enabled: !waiting && !hasApproval,
              maxLines: null,
              minLines: 1,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            height: 40,
            child: FilledButton(
              onPressed: (waiting || hasApproval) ? null : _send,
              style: ButtonStyle(padding: ButtonState.all(EdgeInsets.zero)),
              child: waiting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.send, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalButtons(BuildContext context, dynamic pendingApproval) {
    final toolCall = pendingApproval.toolCall;
    final toolName = toolCall.toolName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border(top: BorderSide(color: Colors.orange, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.warning, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tool approval required: $toolName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This operation requires your approval before execution.',
            style: TextStyle(color: Colors.grey[130], fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                onPressed: () {
                  widget.bloc.add(const AiAgentEvent.rejectToolCall());
                },
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => hitl.ToolApprovalDialog(
                      callId: toolCall.callId,
                      toolName: toolName,
                      arguments: toolCall.arguments,
                      reason: 'This operation requires user approval',
                      onDecision: (decision, {modifiedArguments, feedback}) {
                        if (decision == 'approve') {
                          widget.bloc.add(const AiAgentEvent.approveToolCall());
                        } else if (decision == 'reject') {
                          widget.bloc.add(const AiAgentEvent.rejectToolCall());
                        } else if (decision == 'edit') {
                          widget.bloc.add(const AiAgentEvent.approveToolCall());
                        }
                      },
                    ),
                  );
                },
                child: const Text('Review Details'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  widget.bloc.add(const AiAgentEvent.approveToolCall());
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
    widget.bloc.add(AiAgentEvent.sendUserMessage(text));
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

  Widget _msgBubble(WSMessage msg) {
    final isUser = msg.maybeWhen(
      userMessage: (_, __) => true,
      switchAgent: (_, __, ___) => true,
      hitlDecision: (_, __, ___, ____) => true,
      orElse: () => false,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(msg), const SizedBox(width: 12)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMessageColor(msg),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getBorderColor(msg), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) _buildMessageHeader(msg),
                  GptMarkdown(_getMessageContent(msg)),
                ],
              ),
            ),
          ),
          if (isUser) ...[const SizedBox(width: 12), _buildAvatar(msg)],
        ],
      ),
    );
  }

  Widget _buildAvatar(WSMessage msg) {
    final isUser = msg.maybeWhen(
      userMessage: (_, __) => true,
      switchAgent: (_, __, ___) => true,
      hitlDecision: (_, __, ___, ____) => true,
      orElse: () => false,
    );

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? Colors.blue.withOpacity(0.2) : Colors.grey[40],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isUser ? FluentIcons.contact : FluentIcons.robot,
        size: 16,
        color: isUser ? Colors.blue : Colors.grey[130],
      ),
    );
  }

  Widget _buildMessageHeader(WSMessage msg) {
    String? label;
    Color? color;

    msg.maybeWhen(
      toolCall: (_, tool, __, requiresApproval) {
        label = '🔧 Tool: $tool';
        color = Colors.orange;
      },
      toolResult: (_, toolName, __, ___) {
        label = '✓ Result: $toolName';
        color = Colors.green;
      },
      agentSwitched: (_, fromAgent, toAgent, __, ___) {
        label = '🔄 $fromAgent → $toAgent';
        color = Colors.purple;
      },
      error: (_) {
        label = '❌ Error';
        color = Colors.red;
      },
      orElse: () {},
    );

    if (label == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label!,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getMessageColor(WSMessage msg) {
    return msg.when(
      userMessage: (_, __) => Colors.blue.withOpacity(0.1),
      assistantMessage: (_, __) => Colors.grey[20]!,
      toolCall: (_, __, ___, ____) => Colors.orange.withOpacity(0.1),
      toolResult: (_, __, ___, ____) => Colors.green.withOpacity(0.1),
      agentSwitched: (_, __, ___, ____, _____) =>
          Colors.purple.withOpacity(0.1),
      error: (_) => Colors.red.withOpacity(0.1),
      switchAgent: (_, __, ___) => Colors.blue.withOpacity(0.1),
      hitlDecision: (_, __, ___, ____) => Colors.blue.withOpacity(0.1),
    );
  }

  Color _getBorderColor(WSMessage msg) {
    return msg.when(
      userMessage: (_, __) => Colors.blue.withOpacity(0.3),
      assistantMessage: (_, __) => Colors.grey[60]!,
      toolCall: (_, __, ___, ____) => Colors.orange.withOpacity(0.3),
      toolResult: (_, __, ___, ____) => Colors.green.withOpacity(0.3),
      agentSwitched: (_, __, ___, ____, _____) =>
          Colors.purple.withOpacity(0.3),
      error: (_) => Colors.red.withOpacity(0.3),
      switchAgent: (_, __, ___) => Colors.blue.withOpacity(0.3),
      hitlDecision: (_, __, ___, ____) => Colors.blue.withOpacity(0.3),
    );
  }

  String _getMessageContent(WSMessage msg) {
    return msg.when(
      userMessage: (c, _) => c,
      assistantMessage: (content, _) => content ?? '_(No content)_',
      toolCall: (callId, tool, args, requiresApproval) =>
          '**Tool Call:** `$tool`\n\n```json\n$args\n```${requiresApproval ? "\n\n⚠️ Requires approval" : ""}',
      toolResult: (callId, toolName, result, error) =>
          error ?? (result != null ? '```json\n$result\n```' : 'No result'),
      agentSwitched: (content, fromAgent, toAgent, reason, confidence) =>
          '${content ?? "Agent switched"}\n\n**Reason:** $reason',
      error: (content) {
        if (content == null || content.isEmpty) {
          return '**Error:** Unknown error occurred. Please check the logs for details.';
        }
        return '**Error:** $content';
      },
      switchAgent: (agentType, content, reason) =>
          '${content ?? "Switching to $agentType agent"}${reason != null ? "\n\n**Reason:** $reason" : ""}',
      hitlDecision: (callId, decision, modifiedArgs, feedback) =>
          '**Decision:** $decision${feedback != null ? "\n\n**Feedback:** $feedback" : ""}',
    );
  }
}
