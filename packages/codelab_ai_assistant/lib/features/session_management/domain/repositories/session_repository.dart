// Repository interface для управления сессиями
import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/type_defs.dart';
import '../entities/session.dart';

/// Интерфейс репозитория для управления сессиями чата
/// 
/// Определяет контракт для работы с сессиями, не зависящий от реализации.
/// Реализация находится в data слое.
abstract class SessionRepository {
  /// Создает новую сессию
  /// 
  /// Возвращает [Right] с созданной сессией или [Left] с ошибкой
  FutureEither<Session> createSession(CreateSessionParams params);
  
  /// Загружает сессию по ID
  /// 
  /// Возвращает [Right] с сессией или [Left] с ошибкой (например, NotFoundFailure)
  FutureEither<Session> loadSession(LoadSessionParams params);
  
  /// Получает список всех сессий
  /// 
  /// Возвращает [Right] со списком сессий или [Left] с ошибкой
  FutureEither<List<Session>> listSessions();
  
  /// Удаляет сессию по ID
  /// 
  /// Возвращает [Right] с Unit при успехе или [Left] с ошибкой
  FutureEither<Unit> deleteSession(DeleteSessionParams params);
  
  /// Получает последнюю активную сессию из кеша
  /// 
  /// Возвращает [Right] с Option<Session> (none если нет кешированной сессии)
  FutureEither<Option<Session>> getLastSession();
  
  /// Обновляет заголовок сессии
  /// 
  /// Возвращает [Right] с обновленной сессией или [Left] с ошибкой
  FutureEither<Session> updateSessionTitle(String sessionId, String title);
}
