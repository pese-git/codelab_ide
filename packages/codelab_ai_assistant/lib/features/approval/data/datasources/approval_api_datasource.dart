import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_response.dart';

/// Data source для работы с API подтверждений
///
/// Абстракция для взаимодействия с backend API.
/// Конкретная реализация будет зависеть от используемого API клиента.
abstract class ApprovalApiDataSource {
  /// Получить pending approvals для сессии
  ///
  /// [sessionId] - ID сессии
  /// Возвращает список запросов на подтверждение, ожидающих решения
  Future<List<ApprovalRequest>> getPendingApprovals(String sessionId);

  /// Отправить решение по подтверждению на сервер
  ///
  /// [response] - ответ с решением пользователя
  Future<void> sendApprovalDecision(ApprovalResponse response);
}
