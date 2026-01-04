// Domain entity для сообщения в чате
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'message.freezed.dart';

/// Роль отправителя сообщения
enum MessageRole { user, assistant, system, tool }

/// Domain entity представляющая сообщение в чате
@freezed
abstract class Message with _$Message {
  const factory Message({
    /// Уникальный идентификатор сообщения
    required String id,

    /// Роль отправителя
    required MessageRole role,

    /// Содержимое сообщения
    required MessageContent content,

    /// Timestamp создания сообщения
    required DateTime timestamp,

    /// Метаданные сообщения
    Option<Map<String, dynamic>>? metadata,
  }) = _Message;

  const Message._();

  /// Проверяет, является ли сообщение от пользователя
  bool get isUser => role == MessageRole.user;

  /// Проверяет, является ли сообщение от ассистента
  bool get isAssistant => role == MessageRole.assistant;

  /// Проверяет, является ли сообщение системным
  bool get isSystem => role == MessageRole.system;

  /// Проверяет, является ли сообщение результатом tool call
  bool get isTool => role == MessageRole.tool;

  /// Получает текстовое содержимое (если есть)
  Option<String> get textContent {
    return content.when(
      text: (text, isFinal) => some(text),
      toolCall: (_, __, ___) => none(),
      toolResult: (_, __, ___, ____) => none(),
      agentSwitch: (_, __, ___) => none(),
      error: (msg) => some(msg),
    );
  }
}

/// Содержимое сообщения (sealed class для разных типов)
@freezed
sealed class MessageContent with _$MessageContent {
  /// Текстовое сообщение
  const factory MessageContent.text({
    required String text,
    @Default(true) bool isFinal,
  }) = TextMessageContent;

  /// Вызов инструмента
  const factory MessageContent.toolCall({
    required String callId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) = ToolCallMessageContent;

  /// Результат выполнения инструмента
  const factory MessageContent.toolResult({
    required String callId,
    required String toolName,
    Option<Map<String, dynamic>>? result,
    Option<String>? error,
  }) = ToolResultMessageContent;

  /// Переключение агента
  const factory MessageContent.agentSwitch({
    required String fromAgent,
    required String toAgent,
    Option<String>? reason,
  }) = AgentSwitchMessageContent;

  /// Сообщение об ошибке
  const factory MessageContent.error({required String message}) =
      ErrorMessageContent;

  const MessageContent._();

  /// Проверяет, является ли содержимое текстом
  bool get isText => this is TextMessageContent;

  /// Проверяет, является ли содержимое tool call
  bool get isToolCall => this is ToolCallMessageContent;

  /// Проверяет, является ли содержимое tool result
  bool get isToolResult => this is ToolResultMessageContent;

  /// Проверяет, является ли содержимое переключением агента
  bool get isAgentSwitch => this is AgentSwitchMessageContent;

  /// Проверяет, является ли содержимое ошибкой
  bool get isError => this is ErrorMessageContent;
}

/// Параметры для отправки сообщения
@freezed
abstract class SendMessageParams with _$SendMessageParams {
  const factory SendMessageParams({
    /// Текст сообщения
    required String text,

    /// Дополнительные метаданные
    Option<Map<String, dynamic>>? metadata,
  }) = _SendMessageParams;
}

/// Параметры для переключения агента
@freezed
abstract class SwitchAgentParams with _$SwitchAgentParams {
  const factory SwitchAgentParams({
    /// Тип агента для переключения
    required String agentType,

    /// Контент для нового агента
    required String content,

    /// Причина переключения
    Option<String>? reason,
  }) = _SwitchAgentParams;
}

/// Параметры для загрузки истории
@freezed
abstract class LoadHistoryParams with _$LoadHistoryParams {
  const factory LoadHistoryParams({
    /// ID сессии для загрузки истории
    required String sessionId,
  }) = _LoadHistoryParams;
}
