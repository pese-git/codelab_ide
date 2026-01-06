// Новая страница списка сессий с применением рефакторинга
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../../shared/presentation/molecules/feedback/empty_state.dart';
import '../../../shared/presentation/atoms/buttons/primary_button.dart';
import '../../../shared/utils/extensions/context_extensions.dart';
import '../bloc/session_manager_bloc.dart';
import '../molecules/session_card.dart';
import '../../domain/entities/session.dart';

/// Новая страница списка сессий с применением Atomic Design
///
/// Преимущества перед старой SessionListView:
/// - Использует переиспользуемые компоненты (SessionCard, EmptyState)
/// - Применяет централизованную тему
/// - Меньше кода (~180 строк vs 440)
/// - Использует расширения контекста для ошибок
/// - Легче тестировать
class SessionListPage extends StatelessWidget {
  final SessionManagerBloc sessionManagerBloc;
  final void Function(Session session) onSessionSelected;
  final void Function(String sessionId) onNewSession;

  // ✅ Добавляем logger для отладки
  static final _logger = Logger();

  const SessionListPage({
    super.key,
    required this.sessionManagerBloc,
    required this.onSessionSelected,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    _logger.d('[SessionListPage] 🏗️ Building widget');

    return BlocProvider.value(
      value: sessionManagerBloc,
      child: BlocConsumer<SessionManagerBloc, SessionManagerState>(
        listener: (context, state) {
          _logger.d(
            '[SessionListPage] 👂 Listener received state: ${state.runtimeType}',
          );
          state.maybeWhen(
            // ✅ Убрали sessionSwitched из listener - callback вызывается сразу при клике
            newSessionCreated: (sessionId) {
              _logger.i('[SessionListPage] ✅ New session created: $sessionId');
              onNewSession(sessionId);
            },
            error: (message) {
              _logger.e('[SessionListPage] ❌ Error: $message');
              // ✅ Использование расширения вместо встроенного кода
              context.showError(message);
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          _logger.d(
            '[SessionListPage] 🎨 Builder received state: ${state.runtimeType}',
          );
          return Column(
            children: [
              // Header
              _buildHeader(context),
              Divider(
                style: DividerThemeData(
                  thickness: 1,
                  decoration: BoxDecoration(color: AppColors.border),
                ),
              ),
              // Content
              Expanded(
                child: state.when(
                  initial: () {
                    _logger.d('[SessionListPage] 📄 Showing initial state');
                    return _buildEmptyState(context);
                  },
                  loading: () {
                    _logger.d('[SessionListPage] ⏳ Showing loading state');
                    return const Center(child: ProgressRing());
                  },
                  error: (message) {
                    _logger.d(
                      '[SessionListPage] ❌ Showing error state: $message',
                    );
                    return _buildErrorState(context, message);
                  },
                  loaded: (sessions, currentSessionId, currentAgent) {
                    _logger.d(
                      '[SessionListPage] ✅ Showing loaded state with ${sessions.length} sessions',
                    );
                    return _buildSessionList(
                      context,
                      sessions,
                      currentSessionId,
                    );
                  },
                  sessionSwitched: (sessionId, session) {
                    _logger.w(
                      '[SessionListPage] 🔄 Showing sessionSwitched state for $sessionId - THIS SHOULD BE BRIEF!',
                    );
                    return const SizedBox.shrink();
                  },
                  newSessionCreated: (sessionId) {
                    _logger.w(
                      '[SessionListPage] ➕ Showing newSessionCreated state for $sessionId - THIS SHOULD BE BRIEF!',
                    );
                    return const SizedBox.shrink();
                  },
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
      padding: AppSpacing.paddingLg, // ✅ Тема
      child: Row(
        children: [
          Icon(FluentIcons.chat, size: AppSpacing.iconLg), // ✅ Тема
          AppSpacing.gapHorizontalMd, // ✅ Тема
          Text(
            'AI Assistant Sessions',
            style: AppTypography.h4, // ✅ Тема
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
    // ✅ Использование переиспользуемого компонента
    return EmptyState(
      icon: FluentIcons.chat,
      title: 'No sessions yet',
      description: 'Create a new session to start chatting with AI',
      iconSize: 64,
      action: PrimaryButton(
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
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    // ✅ Использование EmptyState для ошибок
    return EmptyState(
      icon: FluentIcons.error,
      title: 'Failed to load sessions',
      description: message,
      iconSize: 64,
      action: Button(
        onPressed: () {
          sessionManagerBloc.add(const SessionManagerEvent.loadSessions());
        },
        child: const Text('Retry'),
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    List<Session> sessions,
    String? currentSessionId,
  ) {
    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // New Session Button
        Padding(
          padding: AppSpacing.paddingLg, // ✅ Тема
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
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
              onPressed: () => sessionManagerBloc.add(
                const SessionManagerEvent.createSession(),
              ),
            ),
          ),
        ),
        Divider(
          style: DividerThemeData(
            thickness: 1,
            decoration: BoxDecoration(color: AppColors.border),
          ),
        ),
        // Sessions List
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.paddingMd, // ✅ Тема
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isCurrent = session.id == currentSessionId;

              // ✅ Использование переиспользуемого компонента SessionCard
              return Padding(
                padding: AppSpacing.paddingVerticalSm, // ✅ Тема
                child: SessionCard(
                  session: session,
                  isCurrent: isCurrent,
                  onTap: isCurrent
                      ? null
                      : () {
                          // ✅ Сразу вызываем callback, чтобы избежать показа loader
                          onSessionSelected(session);
                          // Затем отправляем событие в bloc для обновления состояния
                          sessionManagerBloc.add(
                            SessionManagerEvent.selectSession(session.id),
                          );
                        },
                  onDelete: isCurrent
                      ? null
                      : () => _confirmDelete(context, session),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Session session) async {
    // ✅ Использование расширения вместо встроенного кода
    final confirmed = await context.showConfirmDialog(
      title: 'Delete Session',
      content:
          'Are you sure you want to delete this session?\n\n'
          'Session: ${session.displayTitle}\n'
          'Messages: ${session.messageCount}',
    );

    if (confirmed && context.mounted) {
      sessionManagerBloc.add(SessionManagerEvent.deleteSession(session.id));
    }
  }
}
