import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/session_management/presentation/bloc/session_manager_bloc.dart';
import '../../features/session_management/domain/entities/session.dart';
import '../models/session_models.dart';
import '../utils/session_mapper.dart';

/// Виджет списка сессий в стиле RooCode
/// Отображается при первом открытии панели AI Assistant
class SessionListView extends StatelessWidget {
  final SessionManagerBloc sessionManagerBloc;
  final void Function(SessionHistory history) onSessionSelected;
  final void Function(String sessionId) onNewSession;

  const SessionListView({
    super.key,
    required this.sessionManagerBloc,
    required this.onSessionSelected,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sessionManagerBloc,
      child: BlocConsumer<SessionManagerBloc, SessionManagerState>(
        listener: (context, state) {
          state.maybeWhen(
            sessionSwitched: (sessionId, history) {
              onSessionSelected(history);
            },
            newSessionCreated: (sessionId) {
              onNewSession(sessionId);
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
          return Column(
            children: [
              // Header
              _buildHeader(context),
              const Divider(style: DividerThemeData(thickness: 1)),
              // Content
              Expanded(
                child: state.when(
                  initial: () => _buildEmptyState(context),
                  loading: () => const Center(child: ProgressRing()),
                  error: (message) => _buildErrorState(context, message),
                  loaded: (sessions, currentSessionId, currentAgent) =>
                      _buildSessionList(
                        context,
                        SessionMapper.toSessionInfoList(sessions),
                        currentSessionId,
                      ),
                  sessionSwitched: (_, __) => const Center(child: ProgressRing()),
                  newSessionCreated: (_) => const Center(child: ProgressRing()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(FluentIcons.chat, size: 24),
          const SizedBox(width: 12),
          const Text(
            'AI Assistant Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(FluentIcons.refresh),
            onPressed: () {
              sessionManagerBloc.add(const SessionManagerEvent.loadSessions());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FluentIcons.chat,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new session to start chatting with AI',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              sessionManagerBloc.add(const SessionManagerEvent.createSession());
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.add, size: 16),
                  SizedBox(width: 8),
                  Text('New Session'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Text(
            'Failed to load sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[100],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Button(
            onPressed: () {
              sessionManagerBloc.add(const SessionManagerEvent.loadSessions());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    List<SessionInfo> sessions,
    String? currentSessionId,
  ) {
    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // New Session Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                sessionManagerBloc.add(const SessionManagerEvent.createSession());
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.add, size: 16),
                    SizedBox(width: 8),
                    Text('New Session'),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(style: DividerThemeData(thickness: 1)),
        // Sessions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isCurrent = session.sessionId == currentSessionId;
              return _buildSessionCard(context, session, isCurrent);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    SessionInfo session,
    bool isCurrent,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      backgroundColor: isCurrent ? Colors.blue.withOpacity(0.1) : null,
      borderColor: isCurrent ? Colors.blue : Colors.grey[60],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent ? Colors.blue.withOpacity(0.2) : Colors.grey[40],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCurrent ? FluentIcons.chat_solid : FluentIcons.chat,
            color: isCurrent ? Colors.blue : Colors.grey[120],
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _formatSessionTitle(session.sessionId),
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(FluentIcons.message, size: 12, color: Colors.grey[120]),
              const SizedBox(width: 4),
              Text(
                '${session.messageCount} messages',
                style: TextStyle(fontSize: 12, color: Colors.grey[120]),
              ),
              const SizedBox(width: 12),
              Icon(FluentIcons.clock, size: 12, color: Colors.grey[120]),
              const SizedBox(width: 4),
              Text(
                _formatDate(session.lastActivity),
                style: TextStyle(fontSize: 12, color: Colors.grey[120]),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.currentAgent != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAgentColor(session.currentAgent!).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getAgentColor(session.currentAgent!),
                    width: 1,
                  ),
                ),
                child: Text(
                  _formatAgentName(session.currentAgent!),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getAgentColor(session.currentAgent!),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (!isCurrent)
              IconButton(
                icon: Icon(FluentIcons.delete, size: 16, color: Colors.red),
                onPressed: () => _confirmDelete(context, session),
              ),
          ],
        ),
        onPressed: isCurrent
            ? null
            : () {
                sessionManagerBloc.add(
                  SessionManagerEvent.selectSession(session.sessionId),
                );
              },
      ),
    );
  }

  String _formatSessionTitle(String sessionId) {
    // Форматируем session ID для отображения
    if (sessionId.length > 30) {
      return '${sessionId.substring(0, 27)}...';
    }
    return sessionId;
  }

  String _formatAgentName(String agent) {
    final agentNames = {
      'orchestrator': '🪃 Orchestrator',
      'coder': '💻 Code',
      'architect': '🏗️ Architect',
      'debug': '🪲 Debug',
      'ask': '❓ Ask',
    };
    return agentNames[agent] ?? agent;
  }

  Color _getAgentColor(String agent) {
    switch (agent) {
      case 'orchestrator':
        return Colors.purple;
      case 'coder':
        return Colors.blue;
      case 'architect':
        return Colors.orange;
      case 'debug':
        return Colors.red;
      case 'ask':
        return Colors.green;
      default:
        return Colors.grey;
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

  Future<void> _confirmDelete(BuildContext context, SessionInfo session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete this session?\n\n'
          'Session: ${_formatSessionTitle(session.sessionId)}\n'
          'Messages: ${session.messageCount}',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ButtonStyle(
              backgroundColor: ButtonState.all(Colors.red),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      sessionManagerBloc.add(SessionManagerEvent.deleteSession(session.sessionId));
    }
  }
}
