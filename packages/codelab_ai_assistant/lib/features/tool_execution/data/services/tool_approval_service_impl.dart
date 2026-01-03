// Реализация сервиса подтверждения tool операций
import 'dart:async';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_approval.dart';
import '../repositories/tool_repository_impl.dart';

/// Обертка запроса на подтверждение с completer для UI
class ApprovalRequestWithCompleter {
  /// Domain entity запроса
  final ToolApprovalRequest request;
  
  /// Completer для возврата результата
  final Completer<ApprovalDecision> completer;

  ApprovalRequestWithCompleter(this.request, this.completer);
  
  /// Удобный доступ к toolCall
  ToolCall get toolCall => request.toolCall;
}

/// Реализация ToolApprovalService через event-based механизм
///
/// Использует domain entities напрямую без адаптеров
class ToolApprovalServiceImpl implements ToolApprovalService {
  final StreamController<ApprovalRequestWithCompleter> _approvalController =
      StreamController<ApprovalRequestWithCompleter>.broadcast();

  /// Stream запросов на подтверждение с completer
  Stream<ApprovalRequestWithCompleter> get approvalRequests =>
      _approvalController.stream;

  @override
  Future<ApprovalDecision> requestApproval(ToolCall toolCall) async {
    final completer = Completer<ApprovalDecision>();
    
    // Создаем domain entity запроса
    final domainRequest = ToolApprovalRequest(
      requestId: DateTime.now().millisecondsSinceEpoch.toString(),
      toolCall: toolCall,
      requestedAt: DateTime.now(),
    );
    
    final requestWithCompleter = ApprovalRequestWithCompleter(domainRequest, completer);
    
    // Эмитируем запрос в stream
    _approvalController.add(requestWithCompleter);
    
    // Ожидаем результата от UI слоя
    return completer.future;
  }

  /// Закрывает сервис и освобождает ресурсы
  void dispose() {
    _approvalController.close();
  }
}
