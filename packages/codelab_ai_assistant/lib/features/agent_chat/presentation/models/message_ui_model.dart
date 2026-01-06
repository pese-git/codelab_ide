// UI модель для сообщения
import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message.dart';
import '../../../shared/presentation/theme/app_theme.dart';

part 'message_ui_model.freezed.dart';

/// UI модель для отображения сообщения
/// 
/// Преобразует domain entity Message в UI-friendly формат
/// с предвычисленными цветами, стилями и форматированием
@freezed
abstract class MessageUIModel with _$MessageUIModel {
  const factory MessageUIModel({
    required String id,
    required String content,
    required MessageUIType type,
    required bool isUser,
    required Color backgroundColor,
    required Color borderColor,
    String? label,
    Color? labelColor,
    String? timestamp,
  }) = _MessageUIModel;

  const MessageUIModel._();

  /// Создать UI модель из domain entity
  factory MessageUIModel.fromDomain(Message message) {
    final isUser = message.role == MessageRole.user;
    
    // Определяем тип и цвета на основе content
    MessageUIType type = MessageUIType.text;
    Color backgroundColor = AppColors.assistantMessageBackground(0.1);
    Color borderColor = AppColors.assistantMessageBorder(0.3);
    String? label;
    Color? labelColor;

    message.content.when(
      text: (text, isFinal) {
        type = MessageUIType.text;
        if (isUser) {
          backgroundColor = AppColors.userMessageBackground(0.1);
          borderColor = AppColors.userMessageBorder(0.3);
        } else {
          backgroundColor = AppColors.assistantMessageBackground(0.1);
          borderColor = AppColors.assistantMessageBorder(0.3);
        }
      },
      toolCall: (callId, toolName, arguments) {
        type = MessageUIType.toolCall;
        backgroundColor = AppColors.toolCallBackground(0.1);
        borderColor = AppColors.toolCallBorder(0.3);
        label = '🔧 Tool: $toolName';
        labelColor = AppColors.warning;
      },
      toolResult: (callId, toolName, result, error) {
        type = MessageUIType.toolResult;
        backgroundColor = AppColors.toolResultBackground(0.1);
        borderColor = AppColors.toolResultBorder(0.3);
        label = '✓ Result: $toolName';
        labelColor = AppColors.success;
      },
      agentSwitch: (fromAgent, toAgent, reason) {
        type = MessageUIType.agentSwitch;
        backgroundColor = AppColors.agentSwitchBackground(0.1);
        borderColor = AppColors.agentSwitchBorder(0.3);
        label = '🔄 $fromAgent → $toAgent';
        labelColor = AppColors.secondary;
      },
      error: (errorMessage) {
        type = MessageUIType.error;
        backgroundColor = AppColors.errorMessageBackground(0.1);
        borderColor = AppColors.errorMessageBorder(0.3);
        label = '❌ Error';
        labelColor = AppColors.error;
      },
    );

    // Форматируем content для отображения
    final content = _formatContent(message.content);

    return MessageUIModel(
      id: message.id,
      content: content,
      type: type,
      isUser: isUser,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      label: label,
      labelColor: labelColor,
      timestamp: message.timestamp.toIso8601String(),
    );
  }

  static String _formatContent(MessageContent content) {
    return content.when(
      text: (text, isFinal) => text,
      toolCall: (callId, toolName, arguments) =>
          '**Tool Call:** `$toolName`\n\n```json\n$arguments\n```',
      toolResult: (callId, toolName, result, error) {
        if (error != null) {
          return error.fold(
            () => result != null
                ? result.fold(() => 'No result', (r) => '```json\n$r\n```')
                : 'No result',
            (e) => '**Error:** $e',
          );
        }
        if (result != null) {
          return result.fold(() => 'No result', (r) => '```json\n$r\n```');
        }
        return 'No result';
      },
      agentSwitch: (fromAgent, toAgent, reason) {
        final baseText = 'Agent switched: $fromAgent → $toAgent';
        if (reason != null) {
          return reason.fold(
            () => baseText,
            (r) => '$baseText\n\n**Reason:** $r',
          );
        }
        return baseText;
      },
      error: (errorMessage) {
        if (errorMessage.isEmpty) {
          return '**Error:** Unknown error occurred. Please check the logs for details.';
        }
        return '**Error:** $errorMessage';
      },
    );
  }
}

/// Тип сообщения для UI
enum MessageUIType {
  text,
  toolCall,
  toolResult,
  agentSwitch,
  error,
}
