// Middleware для обработки выполнения инструментов
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../../core/error/failures.dart';
import '../bloc/agent_chat_bloc.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_result.dart';
import '../../../tool_execution/domain/usecases/execute_tool.dart';
import '../../domain/usecases/send_tool_result.dart';
import '../../domain/entities/message.dart';
import 'bloc_middleware.dart';

/// Middleware для автоматического выполнения tool calls
///
/// Отвечает за:
/// - Обработку MessageReceivedEvent с toolCall content
/// - Проверку, не является ли tool_call историческим
/// - Выполнение tool через ExecuteToolUseCase
/// - Отправку результата на сервер через SendToolResultUseCase
/// - Добавление сообщения о результате в UI
///
/// Это извлекает ~150 строк логики из AgentChatBloc.
class ToolExecutionMiddleware implements BlocMiddleware {
  final ExecuteToolUseCase _executeTool;
  final SendToolResultUseCase _sendToolResult;
  final Logger _logger;

  ToolExecutionMiddleware({
    required ExecuteToolUseCase executeTool,
    required SendToolResultUseCase sendToolResult,
    required Logger logger,
  })  : _executeTool = executeTool,
        _sendToolResult = sendToolResult,
        _logger = logger;

  @override
  bool canHandle(AgentChatEvent event) {
    return event is MessageReceivedEvent;
  }

  @override
  Future<bool> handle(
    AgentChatEvent event,
    Emitter<AgentChatState> emit,
    AgentChatBloc bloc,
  ) async {
    if (event is! MessageReceivedEvent) {
      return false;
    }

    // Проверяем, является ли это tool_call
    var shouldExecute = false;
    String? callId;
    String? toolName;
    Map<String, dynamic>? arguments;
    bool requiresApproval = false;

    event.message.content.maybeWhen(
      toolCall: (id, name, args) {
        shouldExecute = true;
        callId = id;
        toolName = name;
        arguments = args;
      },
      orElse: () {},
    );

    if (!shouldExecute || callId == null || toolName == null) {
      return false; // Не tool_call, пропускаем
    }

    // BUGFIX: Проверяем, не является ли это tool_call из истории
    // Tool_calls из истории НЕ должны выполняться автоматически
    bool isFromHistory = false;
    event.message.metadata?.fold(() => null, (meta) {
      isFromHistory = meta['source'] == 'history';
    });

    if (isFromHistory) {
      _logger.i(
        'Skipping tool_call from history: $callId ($toolName). '
        'Will be restored via restorePendingApprovals() if still pending.',
      );
      return false; // НЕ выполняем исторические tool_calls
    }

    _logger.i('Executing NEW tool from WebSocket: $toolName');

    // Получаем флаг requiresApproval из metadata сообщения
    event.message.metadata?.fold(() => null, (meta) {
      if (meta.containsKey('requires_approval')) {
        requiresApproval = meta['requires_approval'] as bool? ?? false;
      }
    });

    // Создаем ToolCall entity
    final toolCall = ToolCall(
      id: callId!,
      toolName: toolName!,
      arguments: arguments ?? {},
      requiresApproval: requiresApproval,
      createdAt: DateTime.now(),
    );

    // Выполняем tool
    final result = await _executeTool(
      ExecuteToolParams(toolCall: toolCall),
    );

    // Обрабатываем результат
    await result.fold(
      (failure) async {
        _logger.e('Tool execution failed: ${failure.message}');
        
        // Отправляем ошибку на сервер
        await _sendToolResult(
          SendToolResultParams(
            callId: callId!,
            toolName: toolName!,
            error: failure.message,
          ),
        );
      },
      (toolResult) async {
        _logger.i('Tool executed successfully: $toolName');
        
        // Отправляем результат на сервер используя pattern matching
        toolResult.map(
          success: (success) async {
            await _sendToolResult(
              SendToolResultParams(
                callId: callId!,
                toolName: toolName!,
                result: success.data,
              ),
            );
          },
          failure: (failure) async {
            await _sendToolResult(
              SendToolResultParams(
                callId: callId!,
                toolName: toolName!,
                error: failure.errorMessage,
              ),
            );
          },
        );
      },
    );

    // Возвращаем false, чтобы событие продолжило обработку в BLoC
    // (для добавления сообщения в state)
    return false;
  }
}
