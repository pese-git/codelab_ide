// Domain entity для подтверждения выполнения инструмента (HITL)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'tool_call.dart';

part 'tool_approval.freezed.dart';

/// Результат запроса подтверждения
@freezed
sealed class ApprovalDecision with _$ApprovalDecision {
  /// Пользователь одобрил операцию
  const factory ApprovalDecision.approved() = ApprovalApproved;

  /// Пользователь отклонил операцию
  const factory ApprovalDecision.rejected({
    /// Причина отклонения
    Option<String>? reason,
  }) = ApprovalRejected;

  /// Пользователь отредактировал аргументы
  const factory ApprovalDecision.modified({
    /// Измененные аргументы
    required Map<String, dynamic> modifiedArguments,

    /// Комментарий к изменениям
    Option<String>? comment,
  }) = ApprovalModified;

  /// Операция отменена (timeout или закрытие диалога)
  const factory ApprovalDecision.cancelled() = ApprovalCancelled;

  const ApprovalDecision._();

  /// Проверяет, одобрена ли операция
  bool get isApproved => this is ApprovalApproved || this is ApprovalModified;

  /// Проверяет, отклонена ли операция
  bool get isRejected => this is ApprovalRejected;

  /// Проверяет, отменена ли операция
  bool get isCancelled => this is ApprovalCancelled;

  /// Проверяет, были ли изменены аргументы
  bool get isModified => this is ApprovalModified;
}

/// Запрос на подтверждение выполнения инструмента
@freezed
abstract class ToolApprovalRequest with _$ToolApprovalRequest {
  const factory ToolApprovalRequest({
    /// Уникальный ID запроса
    required String requestId,

    /// Tool call требующий подтверждения
    required ToolCall toolCall,

    /// Timestamp создания запроса
    required DateTime requestedAt,

    /// Timeout для ответа (в секундах)
    @Default(300) int timeoutSeconds,

    /// Дополнительный контекст для пользователя
    Option<String>? context,
  }) = _ToolApprovalRequest;

  const ToolApprovalRequest._();

  /// Проверяет, истек ли timeout
  bool isExpired(DateTime now) {
    final elapsed = now.difference(requestedAt);
    return elapsed.inSeconds > timeoutSeconds;
  }

  /// Получает оставшееся время до timeout
  Duration getRemainingTime(DateTime now) {
    final elapsed = now.difference(requestedAt);
    final remaining = timeoutSeconds - elapsed.inSeconds;
    return Duration(seconds: remaining > 0 ? remaining : 0);
  }

  /// Проверяет, является ли операция критичной
  bool get isCritical {
    return toolCall.toolName == 'write_file' ||
        toolCall.toolName == 'run_command' ||
        toolCall.toolName == 'create_directory';
  }
}

/// Ответ на запрос подтверждения
@freezed
abstract class ToolApprovalResponse with _$ToolApprovalResponse {
  const factory ToolApprovalResponse({
    /// ID запроса на который отвечаем
    required String requestId,

    /// Решение пользователя
    required ApprovalDecision decision,

    /// Timestamp ответа
    required DateTime respondedAt,

    /// Время принятия решения (в миллисекундах)
    required int decisionTimeMs,
  }) = _ToolApprovalResponse;

  const ToolApprovalResponse._();

  /// Создает ответ с одобрением
  factory ToolApprovalResponse.approve({
    required String requestId,
    required DateTime requestedAt,
  }) {
    final now = DateTime.now();
    return ToolApprovalResponse(
      requestId: requestId,
      decision: const ApprovalDecision.approved(),
      respondedAt: now,
      decisionTimeMs: now.difference(requestedAt).inMilliseconds,
    );
  }

  /// Создает ответ с отклонением
  factory ToolApprovalResponse.reject({
    required String requestId,
    required DateTime requestedAt,
    String? reason,
  }) {
    final now = DateTime.now();
    return ToolApprovalResponse(
      requestId: requestId,
      decision: ApprovalDecision.rejected(
        reason: reason != null ? some(reason) : none(),
      ),
      respondedAt: now,
      decisionTimeMs: now.difference(requestedAt).inMilliseconds,
    );
  }

  /// Создает ответ с модификацией
  factory ToolApprovalResponse.modify({
    required String requestId,
    required DateTime requestedAt,
    required Map<String, dynamic> modifiedArguments,
    String? comment,
  }) {
    final now = DateTime.now();
    return ToolApprovalResponse(
      requestId: requestId,
      decision: ApprovalDecision.modified(
        modifiedArguments: modifiedArguments,
        comment: comment != null ? some(comment) : none(),
      ),
      respondedAt: now,
      decisionTimeMs: now.difference(requestedAt).inMilliseconds,
    );
  }

  /// Создает ответ с отменой
  factory ToolApprovalResponse.cancel({
    required String requestId,
    required DateTime requestedAt,
  }) {
    final now = DateTime.now();
    return ToolApprovalResponse(
      requestId: requestId,
      decision: const ApprovalDecision.cancelled(),
      respondedAt: now,
      decisionTimeMs: now.difference(requestedAt).inMilliseconds,
    );
  }
}
