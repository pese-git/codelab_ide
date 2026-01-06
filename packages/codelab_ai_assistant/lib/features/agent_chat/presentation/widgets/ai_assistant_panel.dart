// lib/ai_agent/ui/ai_assistant_panel.dart

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cherrypick/cherrypick.dart';
import '../bloc/agent_chat_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/widgets/auth_wrapper.dart';
import '../../../session_management/presentation/bloc/session_manager_bloc.dart';
import '../../../session_management/presentation/widgets/session_list_view.dart';
import '../../../session_management/presentation/pages/session_list_page.dart';
import 'chat_view.dart';
import '../pages/chat_page.dart';

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

      // ✅ НЕ загружаем сессии сразу - это будет сделано после авторизации
      // в onAuthenticated callback

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
    // ✅ Используем новые страницы вместо старых виджетов
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _showChat
          ? ChatPage(
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
          : SessionListPage(
              key: const ValueKey('sessions'),
              sessionManagerBloc: _sessionManagerBloc!,
              onSessionSelected: (session) {
                // ✅ Сначала переключаемся на чат, чтобы избежать показа loader
                setState(() {
                  _showChat = true;
                });
                // Затем отключаемся от предыдущей сессии и подключаемся к новой
                // История загрузится автоматически при подключении
                widget.bloc.add(const AgentChatEvent.disconnect());
                widget.bloc.add(AgentChatEvent.connect(session.id));
                widget.bloc.add(AgentChatEvent.loadHistory(session.id));
              },
              onNewSession: (sessionId) {
                // ✅ Сначала переключаемся на чат, чтобы избежать показа loader
                setState(() {
                  _showChat = true;
                });
                // Затем отключаемся от предыдущей сессии и подключаемся к новой
                widget.bloc.add(const AgentChatEvent.disconnect());
                widget.bloc.add(AgentChatEvent.connect(sessionId));
              },
            ),
    );
  }
}
