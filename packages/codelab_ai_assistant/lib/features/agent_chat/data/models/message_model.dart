// DTO модель для сообщения (Data слой)
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/message.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

/// DTO модель для сериализации/десериализации сообщения
///
/// Соответствует формату WebSocket протокола
@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    /// Тип сообщения (user_message, assistant_message, tool_call, etc.)
    required String type,

    /// Текстовое содержимое (для text сообщений)
    String? content,

    /// Роль отправителя
    String? role,

    /// Является ли сообщение финальным (для assistant_message)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'is_final') bool? isFinal,

    /// ID вызова инструмента (для tool_call, tool_result)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'call_id') String? callId,

    /// Имя инструмента (для tool_call, tool_result)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'tool_name') String? toolName,

    /// Аргументы инструмента (для tool_call)
    Map<String, dynamic>? arguments,

    /// Требует ли инструмент подтверждения (для tool_call)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'requires_approval') bool? requiresApproval,

    /// Результат выполнения (для tool_result)
    Map<String, dynamic>? result,

    /// Ошибка выполнения (для tool_result, error)
    String? error,

    /// Тип агента (для switch_agent)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'agent_type') String? agentType,

    /// Агент откуда переключаемся (для agent_switched)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'from_agent') String? fromAgent,

    /// Агент куда переключаемся (для agent_switched)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'to_agent') String? toAgent,

    /// Причина переключения
    String? reason,

    /// ID плана (для plan_notification, plan_update, plan_progress)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'plan_id') String? planId,

    /// Шаги плана (для plan_notification, plan_update)
    List<Map<String, dynamic>>? steps,

    /// Текущий шаг плана (для plan_update)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'current_step') String? currentStep,

    /// ID шага (для plan_progress)
    // ignore: invalid_annotation_target
    @JsonKey(name: 'step_id') String? stepId,

    /// Статус шага (для plan_progress)
    String? status,

    /// Решение (для plan_approval)
    String? decision,

    /// Обратная связь (для plan_approval)
    String? feedback,

    /// Метаданные
    Map<String, dynamic>? metadata,
  }) = _MessageModel;

  const MessageModel._();

  /// Создает модель из JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  /// Конвертирует DTO модель в domain entity
  Message toEntity() {
    final messageId = _generateId();
    final timestamp = DateTime.now();

    // Определяем роль
    final messageRole = _parseRole();

    // Определяем содержимое
    final messageContent = _parseContent();

    return Message(
      id: messageId,
      role: messageRole,
      content: messageContent,
      timestamp: timestamp,
      metadata: _buildMetadata(),
    );
  }

  /// Строит metadata для сообщения, включая requiresApproval для tool_call
  Option<Map<String, dynamic>> _buildMetadata() {
    final meta = <String, dynamic>{};
    
    // Добавляем существующие metadata
    if (metadata != null) {
      meta.addAll(metadata!);
    }
    
    // Для tool_call добавляем requiresApproval
    if (type == 'tool_call' && requiresApproval != null) {
      meta['requires_approval'] = requiresApproval!;
    }
    
    // Для сообщений планирования добавляем специфичные поля
    if (type == 'plan_notification' || type == 'plan_update' || type == 'plan_progress') {
      if (planId != null) meta['plan_id'] = planId!;
      if (steps != null) meta['steps'] = steps!;
      if (currentStep != null) meta['current_step'] = currentStep!;
      if (stepId != null) meta['step_id'] = stepId!;
      if (status != null) meta['status'] = status!;
    }
    
    return meta.isEmpty ? none() : some(meta);
  }

  /// Парсит роль из типа сообщения
  MessageRole _parseRole() {
    switch (type) {
      case 'user_message':
        return MessageRole.user;
      case 'assistant_message':
        return MessageRole.assistant;
      case 'tool_call':
      case 'tool_result':
        return MessageRole.tool;
      case 'error':
      case 'plan_notification':
      case 'plan_update':
      case 'plan_progress':
        return MessageRole.system;
      default:
        return role == 'user' ? MessageRole.user : MessageRole.assistant;
    }
  }

  /// Парсит содержимое из типа сообщения
  MessageContent _parseContent() {
    switch (type) {
      case 'user_message':
      case 'assistant_message':
        return MessageContent.text(
          text: content ?? '',
          isFinal: isFinal ?? true,
        );

      case 'tool_call':
        return MessageContent.toolCall(
          callId: callId ?? '',
          toolName: toolName ?? '',
          arguments: arguments ?? {},
        );

      case 'tool_result':
        return MessageContent.toolResult(
          callId: callId ?? '',
          toolName: toolName ?? '',
          result: result != null ? some(result!) : none(),
          error: error != null ? some(error!) : none(),
        );

      case 'agent_switched':
        // Логируем для отладки
        print('[MessageModel] agent_switched: from=$fromAgent, to=$toAgent, reason=$reason, metadata=$metadata');
        
        // Пытаемся извлечь информацию из metadata если основные поля пустые
        String? effectiveFrom = fromAgent;
        String? effectiveTo = toAgent;
        
        if ((effectiveFrom == null || effectiveFrom.isEmpty) && metadata != null) {
          effectiveFrom = metadata!['from_agent'] as String?;
        }
        
        if ((effectiveTo == null || effectiveTo.isEmpty) && metadata != null) {
          effectiveTo = metadata!['to_agent'] as String?;
        }
        
        return MessageContent.agentSwitch(
          fromAgent: effectiveFrom ?? 'unknown',
          toAgent: effectiveTo ?? 'unknown',
          reason: reason != null ? some(reason!) : none(),
        );

      case 'error':
        return MessageContent.error(
          message: content ?? error ?? 'Unknown error',
        );

      case 'plan_notification':
      case 'plan_update':
      case 'plan_progress':
        // Для сообщений планирования возвращаем текстовое представление
        // В будущем можно создать отдельные типы MessageContent
        return MessageContent.text(
          text: _formatPlanMessage(),
          isFinal: true,
        );

      default:
        return MessageContent.text(text: content ?? '', isFinal: true);
    }
  }

  /// Форматирует сообщение планирования для отображения
  String _formatPlanMessage() {
    switch (type) {
      case 'plan_notification':
        return '📋 План: ${content ?? ""}';
      case 'plan_update':
        final stepCount = steps?.length ?? 0;
        return '🔄 Обновление плана: $stepCount шагов';
      case 'plan_progress':
        return '⚙️ Прогресс: шаг $stepId - $status';
      default:
        return content ?? '';
    }
  }

  /// Генерирует уникальный ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${type}_${callId ?? ''}';
  }

  /// Создает DTO модель из domain entity
  factory MessageModel.fromEntity(Message entity) {
    return entity.content.when(
      text: (text, isFinal) => MessageModel(
        type: entity.isUser ? 'user_message' : 'assistant_message',
        content: text,
        role: entity.isUser ? 'user' : 'assistant',
        isFinal: isFinal,
      ),
      toolCall: (callId, toolName, arguments) => MessageModel(
        type: 'tool_call',
        callId: callId,
        toolName: toolName,
        arguments: arguments,
      ),
      toolResult: (callId, toolName, result, error) => MessageModel(
        type: 'tool_result',
        callId: callId,
        toolName: toolName,
        result: result?.toNullable(),
        error: error?.toNullable(),
      ),
      agentSwitch: (fromAgent, toAgent, reason) => MessageModel(
        type: 'agent_switched',
        fromAgent: fromAgent,
        toAgent: toAgent,
        reason: reason?.toNullable(),
      ),
      error: (message) => MessageModel(type: 'error', content: message),
      plan: (executionPlan) => MessageModel(
        type: 'plan_notification',
        content: 'План выполнения: ${executionPlan.originalTask}',
        planId: executionPlan.planId,
        metadata: {
          'plan_id': executionPlan.planId,
          'total_count': executionPlan.totalCount,
        },
      ),
    );
  }
}
