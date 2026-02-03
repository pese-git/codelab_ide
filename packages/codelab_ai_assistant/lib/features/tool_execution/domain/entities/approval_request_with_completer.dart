import 'dart:async';
import 'tool_approval.dart';
import 'tool_call.dart';

/// Обертка запроса на подтверждение с completer для UI
///
/// Используется для передачи запроса на подтверждение в UI слой
/// вместе с completer'ом для возврата результата.
///
/// Это legacy структура для обратной совместимости с существующим UI.
/// В будущем будет заменена на event-driven подход.
class ApprovalRequestWithCompleter {
  /// Domain entity запроса
  final ToolApprovalRequest request;

  /// Completer для возврата результата
  final Completer<ApprovalDecision> completer;

  /// Флаг, указывающий что это восстановленный запрос
  final bool isRestored;

  ApprovalRequestWithCompleter(
    this.request,
    this.completer, {
    this.isRestored = false,
  });

  /// Удобный доступ к toolCall
  ToolCall get toolCall => request.toolCall;
}
