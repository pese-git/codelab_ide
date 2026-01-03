import 'dart:async';
import '../../features/tool_execution/data/models/tool_models.dart';

/// Результат запроса подтверждения операции
enum ToolApprovalResult {
  /// Пользователь одобрил операцию
  approved,
  
  /// Пользователь отклонил операцию
  rejected,
  
  /// Пользователь отменил диалог
  cancelled,
}

/// Запрос на подтверждение tool операции
class ToolApprovalRequest {
  /// Tool call, требующий подтверждения
  final ToolCall toolCall;
  
  /// Completer для возврата результата
  final Completer<ToolApprovalResult> completer;

  ToolApprovalRequest(this.toolCall, this.completer);
}

/// Сервис для запроса подтверждения выполнения tool операций (HITL)
/// 
/// Использует event-based подход: BLoC эмитирует запрос через stream,
/// UI слой слушает этот stream и показывает диалог, затем возвращает результат.
/// 
/// Это обеспечивает правильное разделение ответственности:
/// - BLoC не знает о UI деталях
/// - UI слой управляет показом диалогов
/// - Асинхронная коммуникация через streams
abstract class ToolApprovalService {
  /// Stream запросов на подтверждение
  /// 
  /// UI слой должен подписаться на этот stream и обрабатывать запросы,
  /// показывая диалоги и возвращая результаты через completer.
  Stream<ToolApprovalRequest> get approvalRequests;

  /// Запрашивает подтверждение пользователя для выполнения tool call
  /// 
  /// Эмитирует событие в [approvalRequests] stream и ожидает результата.
  /// 
  /// Возвращает [ToolApprovalResult] с результатом решения пользователя.
  Future<ToolApprovalResult> requestApproval(ToolCall call);
  
  /// Закрывает сервис и освобождает ресурсы
  void dispose();
}

/// Реализация ToolApprovalService через event-based механизм
class ToolApprovalServiceImpl implements ToolApprovalService {
  final StreamController<ToolApprovalRequest> _approvalController =
      StreamController<ToolApprovalRequest>.broadcast();

  @override
  Stream<ToolApprovalRequest> get approvalRequests => _approvalController.stream;

  @override
  Future<ToolApprovalResult> requestApproval(ToolCall call) async {
    final completer = Completer<ToolApprovalResult>();
    final request = ToolApprovalRequest(call, completer);
    
    // Эмитируем запрос в stream
    _approvalController.add(request);
    
    // Ожидаем результата от UI слоя
    return completer.future;
  }

  @override
  void dispose() {
    _approvalController.close();
  }
}
