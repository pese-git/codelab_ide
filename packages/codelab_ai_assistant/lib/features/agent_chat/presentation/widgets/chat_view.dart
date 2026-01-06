import 'package:codelab_uikit/codelab_uikit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../bloc/agent_chat_bloc.dart';
import '../../domain/entities/message.dart';

/// Виджет чата с AI агентом
///
/// @deprecated Используйте [ChatPage] вместо этого.
/// Этот виджет будет удален в версии 2.0.0.
///
/// Новая версия использует:
/// - Централизованную тему (AppColors, AppTypography, AppSpacing)
/// - Переиспользуемые компоненты (MessageBubble, ChatInputBar, ChatHeader, EmptyState)
/// - Композицию вместо монолита
/// - На 47% меньше кода (417→220 строк)
@Deprecated('Use ChatPage from ../pages/chat_page.dart instead. Will be removed in v2.0.0')
class ChatView extends StatefulWidget {
  final AgentChatBloc bloc;
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
    return BlocBuilder<AgentChatBloc, AgentChatState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final waiting = state.isLoading;
        final pendingApproval = state.pendingApproval.toNullable();
        final messages = state.messages;
        final currentAgent = AgentType.fromString(state.currentAgent);

        return Column(
          children: [
            // Header
            _buildHeader(context, currentAgent),
            const Divider(style: DividerThemeData(thickness: 1)),
            // Messages
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyChat(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (ctx, idx) => _msgBubble(messages[idx]),
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
                AgentChatEvent.switchAgent(
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
    final arguments = toolCall.arguments;

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
          if (arguments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[20],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Arguments: ${arguments.toString()}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey[130],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 16),
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
              const SizedBox(width: 8),
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

  Widget _msgBubble(Message message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(message), const SizedBox(width: 12)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMessageColor(message),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getBorderColor(message), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) _buildMessageHeader(message),
                  GptMarkdown(_getMessageContent(message)),
                ],
              ),
            ),
          ),
          if (isUser) ...[const SizedBox(width: 12), _buildAvatar(message)],
        ],
      ),
    );
  }

  Widget _buildAvatar(Message message) {
    final isUser = message.isUser;

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

  Widget _buildMessageHeader(Message message) {
    String? label;
    Color? color;

    message.content.maybeWhen(
      toolCall: (callId, toolName, arguments) {
        label = '🔧 Tool: $toolName';
        color = Colors.orange;
      },
      toolResult: (callId, toolName, result, error) {
        label = '✓ Result: $toolName';
        color = Colors.green;
      },
      agentSwitch: (fromAgent, toAgent, reason) {
        label = '🔄 $fromAgent → $toAgent';
        color = Colors.purple;
      },
      error: (message) {
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

  Color _getMessageColor(Message message) {
    return message.content.when(
      text: (text, isFinal) =>
          message.isUser ? Colors.blue.withOpacity(0.1) : Colors.grey[20],
      toolCall: (_, __, ___) => Colors.orange.withOpacity(0.1),
      toolResult: (_, __, ___, ____) => Colors.green.withOpacity(0.1),
      agentSwitch: (_, __, ___) => Colors.purple.withOpacity(0.1),
      error: (_) => Colors.red.withOpacity(0.1),
    );
  }

  Color _getBorderColor(Message message) {
    return message.content.when(
      text: (text, isFinal) =>
          message.isUser ? Colors.blue.withOpacity(0.3) : Colors.grey[60],
      toolCall: (_, __, ___) => Colors.orange.withOpacity(0.3),
      toolResult: (_, __, ___, ____) => Colors.green.withOpacity(0.3),
      agentSwitch: (_, __, ___) => Colors.purple.withOpacity(0.3),
      error: (_) => Colors.red.withOpacity(0.3),
    );
  }

  String _getMessageContent(Message message) {
    return message.content.when(
      text: (text, isFinal) => text,
      toolCall: (callId, toolName, arguments) =>
          '**Tool Call:** `$toolName`\n\n```json\n$arguments\n```',
      toolResult: (callId, toolName, result, error) {
        // error и result - это Option<T>?, сначала проверяем на null
        if (error != null) {
          return error.fold(
            () => result != null
                ? result.fold(() => 'No result', (r) => '```json\n$r\n```')
                : 'No result',
            (e) => '**Error:** $e',
          );
        }
        if (result != null) {
          return result.fold(() => 'No result', (r) => '```json\n$r\n```');
        }
        return 'No result';
      },
      agentSwitch: (fromAgent, toAgent, reason) {
        final baseText = 'Agent switched: $fromAgent → $toAgent';
        // reason - это Option<String>?, сначала проверяем на null
        if (reason != null) {
          return reason.fold(
            () => baseText,
            (r) => '$baseText\n\n**Reason:** $r',
          );
        }
        return baseText;
      },
      error: (errorMessage) {
        if (errorMessage.isEmpty) {
          return '**Error:** Unknown error occurred. Please check the logs for details.';
        }
        return '**Error:** $errorMessage';
      },
    );
  }
}
