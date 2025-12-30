import 'package:logger/logger.dart';
import '../models/tool_models.dart';
import '../services/tool_executor.dart';
import '../services/tool_approval_service.dart';

final _logger = Logger();

/// Абстракция для интеграции tool_call из AI agent с системами IDE.
abstract class ToolApi {
  /// Выполнить tool call с поддержкой HITL операций.
  /// 
  /// Параметры:
  /// - [callId] - уникальный идентификатор вызова
  /// - [toolName] - имя инструмента для выполнения
  /// - [arguments] - аргументы для инструмента
  /// - [requiresApproval] - требуется ли подтверждение пользователя
  /// 
  /// Возвращает [FileOperationResult] с результатом выполнения.
  /// 
  /// Throws [ToolExecutionException] при ошибках выполнения.
  Future<FileOperationResult> call({
    required String callId,
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool requiresApproval,
  });
}

/// Реализация ToolApi с интеграцией ToolExecutor и ToolApprovalService
class ToolApiImpl implements ToolApi {
  final ToolExecutor _toolExecutor;
  final ToolApprovalService _approvalService;

  ToolApiImpl({
    required ToolExecutor toolExecutor,
    required ToolApprovalService approvalService,
  })  : _toolExecutor = toolExecutor,
        _approvalService = approvalService;

  @override
  Future<FileOperationResult> call({
    required String callId,
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool requiresApproval,
  }) async {
    _logger.i('ToolApi.call: callId=$callId, toolName=$toolName, requiresApproval=$requiresApproval');

    try {
      // Создаем ToolCall объект
      final toolCall = ToolCall(
        callId: callId,
        toolName: toolName,
        arguments: arguments,
        requiresConfirmation: requiresApproval,
      );

      // Если требуется подтверждение, запрашиваем его у пользователя
      if (requiresApproval) {
        _logger.d('Requesting user approval for tool: $toolName');
        
        final approvalResult = await _approvalService.requestApproval(toolCall);
        
        switch (approvalResult) {
          case ToolApprovalResult.approved:
            _logger.i('User approved tool execution: $toolName');
            break;
          case ToolApprovalResult.rejected:
          case ToolApprovalResult.cancelled:
            _logger.w('User rejected tool execution: $toolName');
            throw ToolExecutionException.userRejected(toolName);
        }
      }

      // Выполняем tool call через ToolExecutor
      _logger.d('Executing tool: $toolName');
      final result = await _toolExecutor.executeToolCall(toolCall);
      
      _logger.i('Tool execution successful: $toolName');
      return result;
      
    } on ToolExecutionException catch (e) {
      _logger.e('Tool execution failed: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('Unexpected error during tool execution', error: e, stackTrace: stackTrace);
      throw ToolExecutionException.general(
        'Unexpected error during tool execution: $e',
        cause: e,
      );
    }
  }
}

/// Моковая реализация, для тестов/отладки, всегда выбрасывает ошибку
class ToolApiMock implements ToolApi {
  @override
  Future<FileOperationResult> call({
    required String callId,
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool requiresApproval,
  }) async {
    throw ToolExecutionException(
      code: 'mock_error',
      message: 'ToolApiMock: tool [$toolName] не реализован.',
    );
  }
}
