// Реализация ToolRepository (Data слой)
import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_result.dart';
import '../../domain/entities/tool_approval.dart';
import '../../domain/repositories/tool_repository.dart';
import '../datasources/tool_executor_datasource.dart';
import '../models/tool_call_model.dart';

/// Реализация репозитория для выполнения инструментов
/// 
/// Координирует работу между tool executor и approval service.
/// Конвертирует exceptions в failures и возвращает Either<Failure, T>.
class ToolRepositoryImpl implements ToolRepository {
  final ToolExecutorDataSource _executor;
  final ToolApprovalService _approvalService;
  
  ToolRepositoryImpl({
    required ToolExecutorDataSource executor,
    required ToolApprovalService approvalService,
  }) : _executor = executor,
       _approvalService = approvalService;
  
  @override
  Future<Either<Failure, ToolResult>> executeToolCall(ExecuteToolParams params) async {
    try {
      // Конвертируем entity в model
      final model = ToolCallModel.fromEntity(params.toolCall);
      
      // Выполняем через data source
      final resultModel = await _executor.execute(model);
      
      // Конвертируем model в entity
      final result = resultModel.toEntity();
      
      return right(result);
    } on ToolExecutionException catch (e) {
      return left(Failure.toolExecution(
        code: e.code,
        message: e.message,
      ));
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error executing tool: $e'));
    }
  }
  
  @override
  Future<Either<Failure, ApprovalDecision>> requestApproval(
    RequestApprovalParams params,
  ) async {
    try {
      // Создаем запрос на подтверждение
      final request = params.toolCall;
      
      // Запрашиваем подтверждение через сервис
      final decision = await _approvalService.requestApproval(request);
      
      return right(decision);
    } on TimeoutException {
      return right(const ApprovalDecision.cancelled());
    } catch (e) {
      return left(Failure.server('Approval request failed: $e'));
    }
  }
  
  @override
  Either<Failure, Unit> validateSafety(ValidateSafetyParams params) {
    try {
      final toolCall = params.toolCall;
      
      // Проверка поддерживаемых инструментов
      final supportedTools = _executor.getSupportedTools();
      if (!supportedTools.contains(toolCall.toolName)) {
        return left(Failure.validation(
          'Unsupported tool: ${toolCall.toolName}',
        ));
      }
      
      // Проверка аргументов
      if (toolCall.arguments.isEmpty && _requiresArguments(toolCall.toolName)) {
        return left(Failure.validation(
          'Tool ${toolCall.toolName} requires arguments',
        ));
      }
      
      // Специфичная валидация для разных инструментов
      final validationResult = _validateToolSpecific(toolCall);
      if (validationResult.isLeft()) {
        return validationResult;
      }
      
      return right(unit);
    } catch (e) {
      return left(Failure.validation('Validation failed: $e'));
    }
  }
  
  @override
  bool requiresApproval(ToolCall toolCall) {
    // Критичные операции требуют подтверждения
    const criticalTools = [
      'write_file',
      'run_command',
      'create_directory',
    ];
    
    return criticalTools.contains(toolCall.toolName) || toolCall.requiresApproval;
  }
  
  @override
  Future<Either<Failure, List<String>>> getSupportedTools() async {
    try {
      final tools = _executor.getSupportedTools();
      return right(tools);
    } catch (e) {
      return left(Failure.server('Failed to get supported tools: $e'));
    }
  }
  
  /// Проверяет, требует ли инструмент аргументы
  bool _requiresArguments(String toolName) {
    const noArgsTools = <String>[];
    return !noArgsTools.contains(toolName);
  }
  
  /// Специфичная валидация для разных инструментов
  Either<Failure, Unit> _validateToolSpecific(ToolCall toolCall) {
    switch (toolCall.toolName) {
      case 'read_file':
      case 'write_file':
        return _validateFilePath(toolCall.arguments['path']);
        
      case 'list_files':
      case 'create_directory':
        return _validateDirectoryPath(toolCall.arguments['path']);
        
      case 'run_command':
        return _validateCommand(toolCall.arguments['command']);
        
      case 'search_in_code':
        return _validateSearchQuery(toolCall.arguments['query']);
        
      default:
        return right(unit);
    }
  }
  
  /// Валидирует путь к файлу
  Either<Failure, Unit> _validateFilePath(dynamic path) {
    if (path == null || path is! String || path.isEmpty) {
      return left(Failure.validation('File path is required'));
    }
    
    // Проверка на опасные паттерны
    if (path.contains('..') || path.startsWith('/etc') || path.startsWith('/sys')) {
      return left(Failure.validation('Unsafe file path: $path'));
    }
    
    return right(unit);
  }
  
  /// Валидирует путь к директории
  Either<Failure, Unit> _validateDirectoryPath(dynamic path) {
    if (path == null || path is! String || path.isEmpty) {
      return left(Failure.validation('Directory path is required'));
    }
    
    if (path.contains('..')) {
      return left(Failure.validation('Unsafe directory path: $path'));
    }
    
    return right(unit);
  }
  
  /// Валидирует команду
  Either<Failure, Unit> _validateCommand(dynamic command) {
    if (command == null || command is! String || command.isEmpty) {
      return left(Failure.validation('Command is required'));
    }
    
    return right(unit);
  }
  
  /// Валидирует поисковый запрос
  Either<Failure, Unit> _validateSearchQuery(dynamic query) {
    if (query == null || query is! String || query.isEmpty) {
      return left(Failure.validation('Search query is required'));
    }
    
    if (query.length > 1000) {
      return left(Failure.validation('Search query too long'));
    }
    
    return right(unit);
  }
}

/// Интерфейс сервиса для запроса подтверждения
/// 
/// Это адаптер к существующему ToolApprovalService
abstract class ToolApprovalService {
  Future<ApprovalDecision> requestApproval(ToolCall toolCall);
}
