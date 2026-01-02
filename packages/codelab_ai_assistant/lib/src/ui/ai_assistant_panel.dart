// lib/ai_agent/ui/ai_assistant_panel.dart

import 'package:codelab_uikit/codelab_uikit.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:cherrypick/cherrypick.dart';
import '../bloc/ai_agent_bloc.dart';
import '../bloc/session_manager_bloc.dart';
import '../models/ws_message.dart';
import '../widgets/tool_approval_dialog.dart' as hitl;
import '../widgets/session_manager_widget.dart';

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
        final currentAgent = AgentType.fromString(
          chat?.currentAgent ?? 'orchestrator',
        );

        return Column(
          children: [
            // Header с индикатором агента и кнопкой управления сессиями
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    'AI Assistant',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
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
                  const Spacer(),
                  // Кнопка управления сессиями
                  IconButton(
                    icon: const Icon(FluentIcons.history),
                    onPressed: () => _showSessionManager(context),
                  ),
                ],
              ),
            ),
            const Divider(size: 1),
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
          Row(
            children: [
              Icon(FluentIcons.warning, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tool approval required: $toolName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This operation requires your approval before execution.',
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
              Button(
                onPressed: () {
                  // Show detailed approval dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => hitl.ToolApprovalDialog(
                      callId: toolCall.callId,
                      toolName: toolName,
                      arguments: arguments,
                      reason: 'This operation requires user approval',
                      onDecision: (decision, {modifiedArguments, feedback}) {
                        if (decision == 'approve') {
                          widget.bloc.add(const AiAgentEvent.approveToolCall());
                        } else if (decision == 'reject') {
                          widget.bloc.add(const AiAgentEvent.rejectToolCall());
                        } else if (decision == 'edit') {
                          // TODO: Add edit support in BLoC
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
                child: const Text('Quick Approve'),
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

  Future<void> _showSessionManager(BuildContext context) async {
    try {
      // Получить SessionManagerBloc из DI через Cherrypick
      final sessionManagerBloc = CherryPick.openRootScope()
          .resolve<SessionManagerBloc>();

      // Загрузить список сессий
      sessionManagerBloc.add(const SessionManagerEvent.loadSessions());

      // Показать диалог
      await showDialog(
        context: context,
        builder: (dialogContext) => SessionManagerWidget(
          bloc: sessionManagerBloc,
          onSessionChanged: (history) {
            // Загрузить историю в чат при смене сессии
            widget.bloc.add(AiAgentEvent.loadHistory(history));
          },
        ),
      );
    } catch (e) {
      // Если SessionManagerBloc не зарегистрирован (нет SharedPreferences)
      if (context.mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) => const InfoBar(
            title: Text('Session Manager not available'),
            content: Text('SharedPreferences not configured in DI module'),
            severity: InfoBarSeverity.warning,
          ),
        );
      }
    }
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
        switchAgent: (_, _, _) =>
            Alignment.centerRight, // User request to switch
        hitlDecision: (_, _, _, _) => Alignment.centerRight, // User decision
      ),
      child: Card(
        backgroundColor: msg.when(
          userMessage: (_, _) => Colors.blue.normal,
          assistantMessage: (_, _) => Colors.grey[30],
          toolCall: (_, _, _, _) => Colors.orange.normal,
          toolResult: (_, _, _, _) => Colors.green.normal,
          agentSwitched: (_, _, _, _, _) => Colors.purple.normal,
          error: (_) => Colors.red.normal,
          switchAgent: (_, _, _) =>
              Colors.blue.light, // User switch request color
          hitlDecision: (_, _, _, _) =>
              Colors.blue.light, // User decision color
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
            switchAgent: (agentType, content, reason) =>
                '🔀 Switching to $agentType agent\n$content${reason != null ? "\nReason: $reason" : ""}',
            hitlDecision: (callId, decision, modifiedArgs, feedback) =>
                '✓ Decision: $decision${feedback != null ? " - $feedback" : ""}',
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
