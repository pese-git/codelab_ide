// lib/ai_agent/ui/ai_assistant_panel.dart

import 'package:fluent_ui/fluent_ui.dart';
import 'package:cherrypick/cherrypick.dart';
import '../bloc/ai_agent_bloc.dart';
import '../bloc/session_manager_bloc.dart';
import '../models/session_models.dart';
import 'session_list_view.dart';
import 'chat_view.dart';

/// Главная панель AI Assistant с навигацией между списком сессий и чатом
/// 
/// При открытии панели отображается список сессий (как в RooCode).
/// После выбора сессии или создания новой открывается чат.
class AiAssistantPanel extends StatefulWidget {
  final AiAgentBloc bloc;
  const AiAssistantPanel({super.key, required this.bloc});

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  bool _showChat = false;
  SessionManagerBloc? _sessionManagerBloc;

  @override
  void initState() {
    super.initState();
    _initSessionManager();
  }

  void _initSessionManager() {
    try {
      // Получить SessionManagerBloc из DI
      _sessionManagerBloc = CherryPick.openRootScope()
          .resolve<SessionManagerBloc>();
      
      // Загрузить список сессий при инициализации
      _sessionManagerBloc?.add(const SessionManagerEvent.loadSessions());
      
      // Проверить, есть ли активная сессия с историей
      final currentState = widget.bloc.state;
      if (currentState is ChatState && currentState.history.isNotEmpty) {
        // Если есть история, показываем чат
        setState(() {
          _showChat = true;
        });
      }
    } catch (e) {
      // SessionManagerBloc не зарегистрирован - показываем чат напрямую
      setState(() {
        _showChat = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если SessionManagerBloc не доступен, показываем только чат
    if (_sessionManagerBloc == null) {
      return ChatView(
        bloc: widget.bloc,
        onBackToSessions: () {
          // Нет списка сессий, ничего не делаем
        },
      );
    }

    // Навигация между списком сессий и чатом
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _showChat
          ? ChatView(
              key: const ValueKey('chat'),
              bloc: widget.bloc,
              onBackToSessions: () {
                setState(() {
                  _showChat = false;
                });
                // Перезагрузить список сессий
                _sessionManagerBloc?.add(const SessionManagerEvent.loadSessions());
              },
            )
          : SessionListView(
              key: const ValueKey('sessions'),
              sessionManagerBloc: _sessionManagerBloc!,
              onSessionSelected: (history) {
                // Загрузить историю в чат
                widget.bloc.add(AiAgentEvent.loadHistory(history));
                setState(() {
                  _showChat = true;
                });
              },
              onNewSession: () {
                // Очистить чат для новой сессии
                widget.bloc.add(AiAgentEvent.loadHistory(
                  SessionHistory(
                    sessionId: _sessionManagerBloc?.state.maybeMap(
                      loaded: (state) => state.currentSessionId ?? 'new-session',
                      newSessionCreated: (state) => state.sessionId,
                      orElse: () => 'new-session',
                    ) ?? 'new-session',
                    messages: [],
                    messageCount: 0,
                  ),
                ));
                setState(() {
                  _showChat = true;
                });
              },
            ),
    );
  }
}
