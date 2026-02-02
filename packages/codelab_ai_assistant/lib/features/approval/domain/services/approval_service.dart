import '../entities/approval_request.dart';
import '../entities/approval_response.dart';
import '../entities/approval_decision.dart';

/// Унифицированный сервис для управления всеми типами подтверждений
///
/// Предоставляет единый интерфейс для работы с подтверждениями различных типов:
/// - Tool approval (подтверждение выполнения инструментов)
/// - Plan approval (подтверждение планов выполнения)
/// - Будущие типы (file operations, dangerous commands, etc.)
///
/// Основные возможности:
/// - Запрос подтверждения с ожиданием решения пользователя
/// - Восстановление pending approvals после переподключения
/// - Отправка решений на сервер
/// - Stream для получения запросов в UI
abstract class ApprovalService {
  /// Запросить подтверждение (generic для всех типов)
  ///
  /// Создает запрос на подтверждение и ожидает решения пользователя.
  /// Возвращает Future с решением, которое будет завершено когда пользователь
  /// примет решение через UI.
  ///
  /// [request] - запрос на подтверждение с type-specific данными
  ///
  /// Возвращает [ApprovalDecision] с решением пользователя.
  /// Future может быть отменен по таймауту (указанному в request).
  Future<ApprovalDecision> requestApproval(ApprovalRequest request);

  /// Восстановить все pending approvals для сессии
  ///
  /// Вызывается при подключении к сессии для восстановления
  /// запросов на подтверждение после перезапуска/переустановки IDE.
  ///
  /// [sessionId] - ID сессии для восстановления
  ///
  /// Возвращает список восстановленных запросов.
  Future<List<ApprovalRequest>> restorePendingApprovals(String sessionId);

  /// Отправить решение на сервер
  ///
  /// Отправляет решение пользователя на backend и завершает
  /// соответствующий Future из [requestApproval].
  ///
  /// [response] - ответ с решением пользователя
  Future<void> sendDecision(ApprovalResponse response);

  /// Stream всех запросов на подтверждение
  ///
  /// UI слой подписывается на этот stream для отображения
  /// диалогов подтверждения.
  Stream<ApprovalRequest> get approvalRequests;

  /// Очистить активные completers при отключении от сессии
  ///
  /// Вызывается при disconnect чтобы при повторном подключении
  /// pending approvals могли быть восстановлены заново.
  void clearActiveCompleters();

  /// Закрыть сервис и освободить ресурсы
  void dispose();
}
