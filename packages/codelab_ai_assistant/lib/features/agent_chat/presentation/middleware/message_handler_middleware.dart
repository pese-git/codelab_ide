// Middleware для обработки входящих сообщений
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/send_tool_result.dart';
import '../../../tool_execution/domain/usecases/execute_tool.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_result.dart';

/// Middleware для обработки входящих сообщений
///
/// Ответственности:
/// - Обработка различных типов сообщений (text, tool_call, agent_switch и т.д.)
/// - Автоматическое выполнение tool calls
/// - Отправка результатов tool execution на сервер
/// - Определение текущего агента из agent_switch сообщений
class MessageHandlerMiddleware {
  final ExecuteToolUseCase _executeTool;
  final SendToolResultUseCase _sendToolResult;
  final Logger _logger;

  MessageHandlerMiddleware({
    required ExecuteToolUseCase executeTool,
    required SendToolResultUseCase sendToolResult,
    required Logger logger,
  })  : _executeTool = executeTool,
        _sendToolResult = sendToolResult,
        _logger = logger;

  /// Обработать входящее сообщение
  ///
  /// Возвращает обновленное имя агента если произошло переключение
  /// Вызывает onPlanApproval если требуется подтверждение плана
  /// Вызывает onSessionInfo если получена информация о сессии
  Future<Option<String>> handleMessage({
    required Message message,
    required void Function(Message message) onPlanApproval,
    void Function(String sessionId)? onSessionInfo,
  }) async {
    _logMessageReceived(message);

    // Обрабатываем session_info для получения ID сессии
    message.content.maybeWhen(
      sessionInfo: (sessionId, isNewSession) {
        _logger.i('[MessageHandlerMiddleware] 🆔 Session info received: $sessionId (new: $isNewSession)');
        onSessionInfo?.call(sessionId);
      },
      orElse: () {},
    );

    // Обрабатываем agent_switch для обновления текущего агента
    final newAgent = _extractAgentSwitch(message);

    // Обрабатываем plan_approval_required
    message.content.maybeWhen(
      planApprovalRequired: (approvalRequestId, planId, planSummary, content) {
        _logger.i('[MessageHandlerMiddleware] 📋 Plan approval required: $planId');
        onPlanApproval(message);
      },
      orElse: () {},
    );

    // Автоматически выполняем tool calls (если не из истории)
    await _handleToolCall(message);

    return newAgent;
  }

  /// Логирование полученного сообщения
  void _logMessageReceived(Message message) {
    final messageSource = message.metadata?.fold(
      () => 'websocket',
      (meta) => meta['source'] ?? 'websocket',
    );

    _logger.d(
      '[MessageHandlerMiddleware] 📨 Message received: ${message.role}, '
      'content type: ${message.content.runtimeType}, '
      'source: $messageSource',
    );
  }

  /// Извлечь имя нового агента из agent_switch сообщения
  Option<String> _extractAgentSwitch(Message message) {
    return message.content.maybeWhen(
      agentSwitch: (from, to, reason) {
        if (to.isNotEmpty) {
          _logger.i(
            '[MessageHandlerMiddleware] 🔄 Agent switched: ${from.isNotEmpty ? from : "unknown"} → $to',
          );
          return some(to);
        } else {
          _logger.w('[MessageHandlerMiddleware] ⚠️ Agent switch message received but toAgent is empty');
          return none<String>();
        }
      },
      orElse: () => none<String>(),
    );
  }

  /// Обработать tool_call сообщение
  Future<void> _handleToolCall(Message message) async {
    await message.content.maybeWhen(
      toolCall: (callId, toolName, arguments) async {
        // Проверяем, не является ли это tool_call из истории
        final isFromHistory = _isMessageFromHistory(message);

        if (isFromHistory) {
          _logger.i(
            '[MessageHandlerMiddleware] 📜 Skipping tool_call from history: $callId ($toolName). '
            'Will be restored via restorePendingApprovals() if still pending.',
          );
          return;
        }

        _logger.i('[MessageHandlerMiddleware] ▶️ Executing NEW tool from WebSocket: $toolName');

        // Получаем флаг requiresApproval из metadata
        final requiresApproval = _extractRequiresApproval(message);

        final toolCall = ToolCall(
          id: callId,
          toolName: toolName,
          arguments: arguments,
          requiresApproval: requiresApproval,
          createdAt: DateTime.now(),
        );

        await _executeAndSendToolResult(toolCall);
      },
      orElse: () async {},
    );
  }

  /// Проверить, является ли сообщение из истории
  bool _isMessageFromHistory(Message message) {
    return message.metadata?.fold(
      () => false,
      (meta) => meta['source'] == 'history',
    ) ?? false;
  }

  /// Извлечь флаг requiresApproval из metadata
  bool _extractRequiresApproval(Message message) {
    return message.metadata?.fold(
      () => false,
      (meta) => meta['requires_approval'] as bool? ?? false,
    ) ?? false;
  }

  /// Выполнить tool и отправить результат на сервер
  Future<void> _executeAndSendToolResult(ToolCall toolCall) async {
    final result = await _executeTool(
      ExecuteToolParams(toolCall: toolCall),
    );

    await result.fold(
      (failure) async {
        _logger.e('[MessageHandlerMiddleware] ❌ Tool execution failed: ${failure.message}');
        
        // Отправляем ошибку на сервер
        await _sendToolResult(
          SendToolResultParams(
            callId: toolCall.id,
            toolName: toolCall.toolName,
            error: failure.message,
          ),
        );
      },
      (toolResult) async {
        _logger.i('[MessageHandlerMiddleware] ✅ Tool executed successfully: ${toolCall.toolName}');
        
        // Отправляем результат на сервер
        await toolResult.when(
          success: (id, name, data, duration, time) async {
            await _sendToolResult(
              SendToolResultParams(
                callId: toolCall.id,
                toolName: toolCall.toolName,
                result: data,
              ),
            );
          },
          failure: (id, name, code, msg, details, time) async {
            await _sendToolResult(
              SendToolResultParams(
                callId: toolCall.id,
                toolName: toolCall.toolName,
                error: msg,
              ),
            );
          },
        );
      },
    );
  }
}
