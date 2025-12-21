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
            Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _controller,
                    placeholder: 'Введите ваш вопрос...',
                    enabled: !waiting,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: waiting
                      ? const ProgressRing()
                      : const Icon(FluentIcons.send),
                  onPressed: waiting ? null : _send,
                ),
              ],
            ),
          ],
        );
      },
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
        toolCall: (_, _, _) => Alignment.centerLeft,
        toolResult: (_, _, _) => Alignment.centerLeft,
        error: (_) => Alignment.center,
      ),
      child: Card(
        backgroundColor: msg.when(
          userMessage: (_, _) => Colors.blue.normal,
          assistantMessage: (_, _) => Colors.grey[30],
          toolCall: (_, _, _) => Colors.orange.normal,
          toolResult: (_, _, _) => Colors.green.normal,
          error: (_) => Colors.red.normal,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: GptMarkdown(
          msg.when(
            userMessage: (c, _) => c,
            assistantMessage: (t, _) => t,
            toolCall: (callId, tool, args) => 'tool_call: $tool ($args)',
            toolResult: (callId, result, error) => error ?? result.toString(),
            error: (content) => 'Ошибка: $content',
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
