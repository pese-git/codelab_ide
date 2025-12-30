// lib/ai_agent/ui/ai_assistant_panel.dart

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../bloc/ai_agent_bloc.dart';
import '../models/ws_message.dart';

class AiAssistantPanel extends StatefulWidget {
  final AiAgentBloc bloc;
  const AiAssistantPanel({super.key, required this.bloc});

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final TextEditingController _controller = TextEditingController();

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

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: history.length,
                itemBuilder: (ctx, idx) => _msgBubble(history[idx]),
              ),
            ),
            Divider(),
            // Кнопки подтверждения tool call
            if (pendingApproval != null) ...[
              _buildApprovalButtons(context, pendingApproval),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _controller,
                    placeholder: 'Введите ваш вопрос...',
                    enabled: !waiting && pendingApproval == null,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: waiting
                      ? const ProgressRing()
                      : const Icon(FluentIcons.send),
                  onPressed: (waiting || pendingApproval != null)
                      ? null
                      : _send,
                ),
              ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Для подтверждения: Создать файл $toolName с содержимым "${arguments['content'] ?? arguments}"?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Пожалуйста, подтвердите, чтобы я мог выполнить эту операцию.',
            style: TextStyle(color: Colors.grey[100]),
          ),
          const SizedBox(height: 12),
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
  }

  Widget _msgBubble(WSMessage msg) {
    return Align(
      alignment: msg.when(
        userMessage: (_, _) => Alignment.centerRight,
        assistantMessage: (_, _) => Alignment.centerLeft,
        toolCall: (_, _, _, _) => Alignment.centerLeft,
        toolResult: (_, _, _, _) => Alignment.centerLeft,
        agentSwitched: (_, _, _, _, _) => Alignment.center,
        error: (_) => Alignment.center,
      ),
      child: Card(
        backgroundColor: msg.when(
          userMessage: (_, _) => Colors.blue.normal,
          assistantMessage: (_, _) => Colors.grey[30],
          toolCall: (_, _, _, _) => Colors.orange.normal,
          toolResult: (_, _, _, _) => Colors.green.normal,
          agentSwitched: (_, _, _, _, _) => Colors.purple.normal,
          error: (_) => Colors.red.normal,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: GptMarkdown(
          msg.when(
            userMessage: (c, _) => c,
            assistantMessage: (content, _) => content ?? '',
            toolCall: (callId, tool, args, requiresApproval) =>
                'tool_call: $tool ($args)${requiresApproval ? " [requires approval]" : ""}',
            toolResult: (callId, toolName, result, error) =>
                error ?? (result != null ? result.toString() : 'No result'),
            agentSwitched: (content, fromAgent, toAgent, reason, confidence) =>
                '🔄 Agent switched: $fromAgent → $toAgent\n$content\nReason: $reason',
            error: (content) => 'Ошибка: ${content ?? "Unknown error"}',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
