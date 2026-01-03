// Маппер для конвертации между новыми Session entities и старыми SessionInfo моделями
import '../models/session_models.dart';
import '../../features/session_management/domain/entities/session.dart';

/// Утилита для маппинга между domain entities и legacy UI models
class SessionMapper {
  /// Конвертирует domain Session в legacy SessionInfo для UI
  static SessionInfo toSessionInfo(Session session) {
    return SessionInfo(
      sessionId: session.id,
      messageCount: session.messageCount,
      lastActivity: session.updatedAt.toIso8601String(),
      currentAgent: session.currentAgent,
    );
  }
  
  /// Конвертирует список domain Sessions в список legacy SessionInfo
  static List<SessionInfo> toSessionInfoList(List<Session> sessions) {
    return sessions.map(toSessionInfo).toList();
  }
  
  /// Конвертирует domain Session в legacy SessionHistory
  static SessionHistory toSessionHistory(Session session) {
    return SessionHistory(
      sessionId: session.id,
      messages: const [], // История сообщений загружается отдельно
      messageCount: session.messageCount,
      currentAgent: session.currentAgent,
    );
  }
}
