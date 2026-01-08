// lib/ai_agent/ui/ai_assistant_panel.dart

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cherrypick/cherrypick.dart';
import '../bloc/agent_chat_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/widgets/auth_wrapper.dart';
import '../../../session_management/presentation/bloc/session_manager_bloc.dart';
import '../../../session_management/presentation/pages/session_list_page.dart';
import '../../../server_settings/server_settings.dart';
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
  late final ServerSettingsBloc _serverSettingsBloc;

  @override
  void initState() {
    super.initState();
    _serverSettingsBloc = CherryPick.openRootScope().resolve<ServerSettingsBloc>();
    _initSessionManager();
  }

  @override
  void dispose() {
    _serverSettingsBloc.close();
    super.dispose();
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
    // Оборачиваем в BlocProvider для ServerSettingsBloc -> ServerSettingsWrapper -> AuthWrapper
    // для правильного порядка инициализации
    try {
      final authBloc = CherryPick.openRootScope().resolve<AuthBloc>();

      return MultiBlocProvider(
        providers: [
          BlocProvider<ServerSettingsBloc>.value(value: _serverSettingsBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: ServerSettingsWrapper(
          child: AuthWrapper(
            onAuthenticated: () {
              // После успешной авторизации перезагружаем список сессий
              _sessionManagerBloc?.add(const SessionManagerEvent.loadSessions());
            },
            onServerSettingsRequested: () {
              // При нажатии на "Настройки сервера" отправляем событие clearSettings
              _serverSettingsBloc.add(const ServerSettingsEvent.clearSettings());
            },
            child: _buildContent(),
          ),
        ),
      );
    } catch (e) {
      // AuthBloc не зарегистрирован (OAuth отключен), показываем контент с ServerSettingsWrapper
      return BlocProvider<ServerSettingsBloc>.value(
        value: _serverSettingsBloc,
        child: ServerSettingsWrapper(
          child: _buildContent(),
        ),
      );
    }
  }

  Widget _buildContent() {
    return Builder(
      builder: (context) {
        // Получаем AuthBloc через context
        AuthBloc? authBloc;
        try {
          authBloc = context.read<AuthBloc>();
        } catch (e) {
          // AuthBloc не доступен в контексте
        }

        // Если SessionManagerBloc не доступен, показываем только чат
        if (_sessionManagerBloc == null) {
          return ChatPage(
            bloc: widget.bloc,
            onBackToSessions: () {
              // Нет списка сессий, ничего не делаем
            },
            onLogout: authBloc != null
                ? () {
                    // Отключаемся от WebSocket перед logout
                    widget.bloc.add(const AgentChatEvent.disconnect());
                    // Вызываем logout в AuthBloc
                    authBloc?.add(const AuthEvent.logout());
                  }
                : null,
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
                  onLogout: authBloc != null
                      ? () {
                          // Отключаемся от WebSocket перед logout
                          widget.bloc.add(const AgentChatEvent.disconnect());
                          // Вызываем logout в AuthBloc
                          authBloc?.add(const AuthEvent.logout());
                        }
                      : null,
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
                  onLogout: authBloc != null
                      ? () {
                          // Отключаемся от WebSocket перед logout
                          widget.bloc.add(const AgentChatEvent.disconnect());
                          // Вызываем logout в AuthBloc
                          authBloc?.add(const AuthEvent.logout());
                        }
                      : null,
                ),
        );
      },
    );
  }
}
