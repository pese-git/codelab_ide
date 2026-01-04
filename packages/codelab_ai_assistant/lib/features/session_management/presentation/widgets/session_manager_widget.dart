import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/session_manager_bloc.dart';
import '../../domain/entities/session.dart';

/// Виджет для управления сессиями чата (Clean Architecture версия)
///
/// Функции:
/// - Показать список всех сессий
/// - Создать новую сессию
/// - Переключиться на другую сессию
/// - Удалить сессию
class SessionManagerWidget extends StatelessWidget {
  final SessionManagerBloc bloc;
  final void Function(Session session)? onSessionChanged;
  final VoidCallback? onNewSession;

  const SessionManagerWidget({
    super.key,
    required this.bloc,
    this.onSessionChanged,
    this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocConsumer<SessionManagerBloc, SessionManagerState>(
        listener: (context, state) {
          state.maybeWhen(
            sessionSwitched: (sessionId, session) {
              // Уведомить о смене сессии
              onSessionChanged?.call(session);

              // Показать уведомление
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: const Text('Session switched'),
                  content: Text('Loaded ${session.messageCount} messages'),
                  severity: InfoBarSeverity.success,
                ),
              );

              // Закрыть диалог
              Navigator.of(context).pop();
            },
            newSessionCreated: (sessionId) {
              // Уведомить о создании новой сессии
              onNewSession?.call();
              
              // Показать уведомление
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: const Text('New session created'),
                  content: Text('Session ID: $sessionId'),
                  severity: InfoBarSeverity.success,
                ),
              );
              
              // Закрыть диалог
              Navigator.of(context).pop();
            },
            error: (message) {
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: const Text('Error'),
                  content: Text(message),
                  severity: InfoBarSeverity.error,
                ),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return ContentDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Session Manager'),
                IconButton(
                  icon: const Icon(FluentIcons.refresh),
                  onPressed: () {
                    bloc.add(const SessionManagerEvent.loadSessions());
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              height: 400,
              child: state.when(
                initial: () =>
                    const Center(child: Text('Click refresh to load sessions')),
                loading: () => const Center(child: ProgressRing()),
                error: (message) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $message'),
                      const SizedBox(height: 16),
                      Button(
                        onPressed: () {
                          bloc.add(const SessionManagerEvent.loadSessions());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                loaded: (sessions, currentSessionId, currentAgent) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(FluentIcons.chat, size: 48),
                          const SizedBox(height: 16),
                          const Text('No sessions found'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              bloc.add(
                                const SessionManagerEvent.createSession(),
                              );
                            },
                            child: const Text('Create First Session'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isCurrent = session.id == currentSessionId;

                      return ListTile(
                        leading: Icon(
                          isCurrent ? FluentIcons.chat_solid : FluentIcons.chat,
                          color: isCurrent ? Colors.blue : null,
                        ),
                        title: Text(
                          session.id,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          'Messages: ${session.messageCount} | '
                          'Agent: ${session.currentAgent ?? "N/A"} | '
                          'Last: ${_formatDate(session.updatedAt.toIso8601String())}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCurrent)
                              IconButton(
                                icon: const Icon(FluentIcons.switch_user),
                                onPressed: () {
                                  bloc.add(
                                    SessionManagerEvent.selectSession(
                                      session.id,
                                    ),
                                  );
                                },
                              ),
                            IconButton(
                              icon: Icon(FluentIcons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, session),
                            ),
                          ],
                        ),
                        onPressed: isCurrent
                            ? null
                            : () {
                                bloc.add(
                                  SessionManagerEvent.selectSession(
                                    session.id,
                                  ),
                                );
                              },
                      );
                    },
                  );
                },
                sessionSwitched: (sessionId, history) {
                  // Показываем loading пока не перезагрузится список
                  return const Center(child: ProgressRing());
                },
                newSessionCreated: (sessionId) {
                  // Показываем loading пока не перезагрузится список
                  return const Center(child: ProgressRing());
                },
              ),
            ),
            actions: [
              Button(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  bloc.add(const SessionManagerEvent.createSession());
                },
                child: const Text('New Session'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete this session?\n\n'
          'Session: ${session.displayTitle}\n'
          'Messages: ${session.messageCount}',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      bloc.add(SessionManagerEvent.deleteSession(session.id));
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}
