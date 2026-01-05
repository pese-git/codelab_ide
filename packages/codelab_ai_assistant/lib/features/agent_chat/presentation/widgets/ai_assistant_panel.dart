// lib/ai_agent/ui/ai_assistant_panel.dart

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cherrypick/cherrypick.dart';
import '../bloc/agent_chat_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/widgets/auth_wrapper.dart';
import '../../../session_management/presentation/bloc/session_manager_bloc.dart';
import '../../../session_management/presentation/widgets/session_list_view.dart';
import 'chat_view.dart';

/// Главная панель AI Assistant с навигацией между списком сессий и чатом
///
/// При открытии панели отображается список сессий (как в RooCode).
/// После выбора сессии или создания новой открывается чат.
class AiAssistantPanel extends StatefulWidget {
  final AgentChatBloc bloc;
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

      // Проверить, есть ли активная сессия с сообщениями
      final currentState = widget.bloc.state;
      if (currentState.messages.isNotEmpty) {
        // Если есть сообщения, показываем чат
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
    // Оборачиваем в AuthWrapper для проверки авторизации
    try {
      final authBloc = CherryPick.openRootScope().resolve<AuthBloc>();
      
      return BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: AuthWrapper(
          onAuthenticated: () {
            // После успешной авторизации перезагружаем список сессий
            _sessionManagerBloc?.add(const SessionManagerEvent.loadSessions());
          },
          child: _buildContent(),
        ),
      );
    } catch (e) {
      // AuthBloc не зарегистрирован (OAuth отключен), показываем контент напрямую
      return _buildContent();
    }
  }

  Widget _buildContent() {
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
                _sessionManagerBloc?.add(
                  const SessionManagerEvent.loadSessions(),
                );
              },
            )
          : SessionListView(
              key: const ValueKey('sessions'),
              sessionManagerBloc: _sessionManagerBloc!,
              onSessionSelected: (session) {
                // Отключиться от предыдущей сессии, подключиться к новой и загрузить историю
                widget.bloc.add(const AgentChatEvent.disconnect());
                widget.bloc.add(AgentChatEvent.connect(session.id));
                widget.bloc.add(AgentChatEvent.loadHistory(session.id));
                setState(() {
                  _showChat = true;
                });
              },
              onNewSession: (sessionId) {
                // Отключиться от предыдущей сессии и подключиться к новой
                widget.bloc.add(const AgentChatEvent.disconnect());
                widget.bloc.add(AgentChatEvent.connect(sessionId));
                setState(() {
                  _showChat = true;
                });
              },
            ),
    );
  }
}
