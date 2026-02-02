// Маппер для конвертации между новыми Message entities и старыми WSMessage моделями
import 'package:fpdart/fpdart.dart';
import '../models/ws_message.dart';
import '../../domain/entities/message.dart';

/// Утилита для маппинга между domain entities и legacy UI models
/// 
/// Используется для обратной совместимости UI компонентов
/// во время миграции на Clean Architecture
class MessageMapper {
  /// Конвертирует domain Message в legacy WSMessage для UI
  static WSMessage toWSMessage(Message message) {
    return message.content.when(
      text: (text, isFinal) {
        if (message.isUser) {
          return WSMessage.userMessage(content: text, role: 'user');
        } else {
          return WSMessage.assistantMessage(content: text, isFinal: isFinal);
        }
      },
      
      toolCall: (callId, toolName, arguments) => WSMessage.toolCall(
        callId: callId,
        toolName: toolName,
        arguments: arguments,
        requiresApproval: false,
      ),
      
      toolResult: (callId, toolName, result, error) => WSMessage.toolResult(
        callId: callId,
        toolName: toolName,
        result: result?.toNullable(),
        error: error?.toNullable(),
      ),
      
      agentSwitch: (fromAgent, toAgent, reason) => WSMessage.agentSwitched(
        content: 'Agent switched: $fromAgent → $toAgent',
        fromAgent: fromAgent,
        toAgent: toAgent,
        reason: reason?.toNullable(),
        confidence: null,
      ),
      
      error: (errorMessage) => WSMessage.error(content: errorMessage),
      
      planApprovalRequired: (approvalRequestId, planId, planSummary, content) =>
        WSMessage.planApprovalRequired(
          approvalRequestId: approvalRequestId,
          planId: planId,
          planSummary: planSummary,
          content: content,
        ),
    );
  }
  
  /// Конвертирует список domain Messages в список legacy WSMessages
  static List<WSMessage> toWSMessageList(List<Message> messages) {
    return messages.map(toWSMessage).toList();
  }
  
  /// Конвертирует legacy WSMessage в domain Message (если нужно)
  static Message fromWSMessage(WSMessage wsMessage) {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = DateTime.now();
    
    return wsMessage.when(
      userMessage: (content, role) => Message(
        id: messageId,
        role: MessageRole.user,
        content: MessageContent.text(text: content, isFinal: true),
        timestamp: timestamp,
        metadata: none(),
      ),
      
      assistantMessage: (content, isFinal) => Message(
        id: messageId,
        role: MessageRole.assistant,
        content: MessageContent.text(text: content ?? '', isFinal: isFinal),
        timestamp: timestamp,
        metadata: none(),
      ),
      
      toolCall: (callId, toolName, arguments, requiresApproval) => Message(
        id: messageId,
        role: MessageRole.tool,
        content: MessageContent.toolCall(
          callId: callId,
          toolName: toolName,
          arguments: arguments,
        ),
        timestamp: timestamp,
        metadata: none(),
      ),
      
      toolResult: (callId, toolName, result, error) => Message(
        id: messageId,
        role: MessageRole.tool,
        content: MessageContent.toolResult(
          callId: callId,
          toolName: toolName ?? '',
          result: result != null ? some(result) : none(),
          error: error != null ? some(error) : none(),
        ),
        timestamp: timestamp,
        metadata: none(),
      ),
      
      agentSwitched: (content, fromAgent, toAgent, reason, confidence) => Message(
        id: messageId,
        role: MessageRole.system,
        content: MessageContent.agentSwitch(
          fromAgent: fromAgent ?? 'unknown',
          toAgent: toAgent ?? 'unknown',
          reason: reason != null ? some(reason) : none(),
        ),
        timestamp: timestamp,
        metadata: some({
          if (fromAgent != null) 'from_agent': fromAgent,
          if (toAgent != null) 'to_agent': toAgent,
          if (confidence != null) 'confidence': confidence,
        }),
      ),
      
      error: (content) => Message(
        id: messageId,
        role: MessageRole.system,
        content: MessageContent.error(message: content ?? 'Unknown error'),
        timestamp: timestamp,
        metadata: none(),
      ),
      
      switchAgent: (agentType, content, reason) => Message(
        id: messageId,
        role: MessageRole.system,
        content: MessageContent.text(
          text: content ?? 'Switching to $agentType',
          isFinal: true,
        ),
        timestamp: timestamp,
        metadata: none(),
      ),
      
      hitlDecision: (callId, decision, modifiedArguments, feedback) => Message(
        id: messageId,
        role: MessageRole.system,
        content: MessageContent.text(
          text: 'HITL Decision: $decision',
          isFinal: true,
        ),
        timestamp: timestamp,
        metadata: none(),
      ),
      
      planApprovalRequired: (content, approvalRequestId, planId, planSummary) => Message(
        id: messageId,
        role: MessageRole.system,
        content: MessageContent.planApprovalRequired(
          approvalRequestId: approvalRequestId,
          planId: planId,
          planSummary: planSummary,
          content: content,
        ),
        timestamp: timestamp,
        metadata: some({
          'approval_request_id': approvalRequestId,
          'plan_id': planId,
          'plan_summary': planSummary,
        }),
      ),
      
      planDecision: (approvalRequestId, planId, decision, feedback, modificationRequest) => Message(
        id: messageId,
        role: MessageRole.system,
        content: MessageContent.text(
          text: 'Plan Decision: $decision',
          isFinal: true,
        ),
        timestamp: timestamp,
        metadata: some({
          'approval_request_id': approvalRequestId,
          'plan_id': planId,
          'decision': decision,
          if (feedback != null) 'feedback': feedback,
          if (modificationRequest != null) 'modification_request': modificationRequest,
        }),
      ),
    );
  }
}
