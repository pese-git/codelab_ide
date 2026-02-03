// Реализация AgentRepository (Data слой) - Refactored version
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';
import '../datasources/agent_remote_datasource.dart';
import '../models/message_model.dart';
import '../models/ws_message.dart';
import '../datasources/gateway_api.dart';
import '../mappers/message_mapper.dart';
import '../../../session_management/data/models/session_models.dart';

/// Реализация репозитория для работы с агентами (улучшенная версия)
///
/// Координирует работу с WebSocket data source и REST API.
/// Конвертирует exceptions в failures и возвращает Either<Failure, T>.
///
/// Улучшения:
/// - Использует Logger вместо print()
/// - Улучшенная обработка ошибок
/// - Более чистый код
class AgentRepositoryImplRefactored implements AgentRepository {
  final AgentRemoteDataSource _remoteDataSource;
  final GatewayApi _gatewayApi;
  final Logger _logger;

  AgentRepositoryImplRefactored({
    required AgentRemoteDataSource remoteDataSource,
    required GatewayApi gatewayApi,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _gatewayApi = gatewayApi,
        _logger = logger;

  @override
  Future<Either<Failure, Unit>> sendMessage(SendMessageParams params) async {
    try {
      final model = MessageModel(
        type: 'user_message',
        content: params.text,
        role: 'user',
        metadata: params.metadata?.toNullable(),
      );

      await _remoteDataSource.sendMessage(model);
      return right(unit);
    } on WebSocketException catch (e) {
      _logger.e('Failed to send message', error: e);
      return left(Failure.network(e.message));
    } catch (e) {
      _logger.e('Unexpected error sending message', error: e);
      return left(Failure.unknown('Failed to send message: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendToolResult({
    required String callId,
    required String toolName,
    Map<String, dynamic>? result,
    String? error,
  }) async {
    try {
      final model = MessageModel(
        type: 'tool_result',
        callId: callId,
        toolName: toolName,
        result: result,
        error: error,
      );

      await _remoteDataSource.sendMessage(model);
      return right(unit);
    } on WebSocketException catch (e) {
      _logger.e('Failed to send tool result', error: e);
      return left(Failure.network(e.message));
    } catch (e) {
      _logger.e('Unexpected error sending tool result', error: e);
      return left(Failure.unknown('Failed to send tool result: $e'));
    }
  }

  @override
  Stream<Either<Failure, Message>> receiveMessages() {
    try {
      return _remoteDataSource
          .receiveMessages()
          .map((model) => right<Failure, Message>(model.toEntity()))
          .handleError((error) {
        if (error is WebSocketException) {
          _logger.e('WebSocket error in message stream', error: error);
          return left<Failure, Message>(Failure.network(error.message));
        }
        if (error is ParseException) {
          _logger.e('Parse error in message stream', error: error);
          return left<Failure, Message>(Failure.server(error.message));
        }
        _logger.e('Unknown error in message stream', error: error);
        return left<Failure, Message>(
          Failure.unknown('Stream error: $error'),
        );
      });
    } catch (e) {
      _logger.e('Failed to create message stream', error: e);
      return Stream.value(
        left(Failure.unknown('Failed to receive messages: $e')),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> switchAgent(SwitchAgentParams params) async {
    try {
      final model = MessageModel(
        type: 'switch_agent',
        agentType: params.agentType,
        content: params.content,
        reason: params.reason?.toNullable(),
      );

      await _remoteDataSource.sendMessage(model);
      return right(unit);
    } on WebSocketException catch (e) {
      _logger.e('Failed to switch agent', error: e);
      return left(Failure.network(e.message));
    } catch (e) {
      _logger.e('Unexpected error switching agent', error: e);
      return left(Failure.unknown('Failed to switch agent: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> loadHistory(
    LoadHistoryParams params,
  ) async {
    try {
      _logger.d('Loading history for session: ${params.sessionId}');
      
      // Загружаем историю через REST API
      final sessionHistory = await _gatewayApi.getSessionHistory(
        params.sessionId,
      );
      
      _logger.d('Got ${sessionHistory.messages.length} messages from API');

      // Конвертируем ChatMessage в Message entities через WSMessage
      final messages = sessionHistory.messages
          .map((chatMsg) {
            try {
              final contentPreview =
                  chatMsg.content != null && chatMsg.content!.length > 50
                  ? '${chatMsg.content!.substring(0, 50)}...'
                  : chatMsg.content ?? 'null';
              
              _logger.d('Converting message: role=${chatMsg.role}, content=$contentPreview');
              
              final wsMsg = _chatMessageToWSMessage(chatMsg);
              final message = MessageMapper.fromWSMessage(wsMsg);

              // BUGFIX: Помечаем все сообщения из истории флагом 'source: history'
              // Это предотвращает автоматическое выполнение tool_calls из истории
              // при перезапуске сессии (они уже обработаны или будут восстановлены
              // через restorePendingApprovals() если еще не обработаны)
              final existingMetadata = (message.metadata ?? none()).fold(
                () => <String, dynamic>{},
                (meta) => Map<String, dynamic>.from(meta),
              );

              final messageWithSource = message.copyWith(
                metadata: some({...existingMetadata, 'source': 'history'}),
              );

              // TRACE: Логируем помеченные tool_calls для отладки
              message.content.maybeWhen(
                toolCall: (callId, toolName, _) {
                  _logger.d(
                    'Marked historical tool_call: $callId ($toolName) with source=history',
                  );
                },
                orElse: () {},
              );

              return messageWithSource;
            } catch (e, stackTrace) {
              // Пропускаем сообщения, которые не удалось конвертировать
              _logger.w('Failed to convert message', error: e, stackTrace: stackTrace);
              return null;
            }
          })
          .whereType<Message>()
          .toList();

      _logger.d('Converted ${messages.length} messages successfully');
      return right(messages);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger.d('Session not found (404), returning empty history');
        // Если сессия не найдена, возвращаем пустую историю вместо ошибки
        // Это позволит начать новый диалог
        return right([]);
      }
      _logger.e('Dio error loading history', error: e);
      return left(Failure.server('Failed to load history: ${e.message}'));
    } catch (e) {
      _logger.e('Unexpected error loading history', error: e);
      return left(Failure.server('Failed to load history: $e'));
    }
  }

  /// Конвертирует ChatMessage в WSMessage
  WSMessage _chatMessageToWSMessage(ChatMessage chatMsg) {
    // Обрабатываем tool calls
    if (chatMsg.toolCalls != null && chatMsg.toolCalls!.isNotEmpty) {
      final toolCall = chatMsg.toolCalls!.first;
      final function = toolCall['function'] as Map<String, dynamic>?;

      // arguments может быть String (JSON) или Map
      dynamic rawArguments = function?['arguments'];
      Map<String, dynamic> arguments = {};

      if (rawArguments is String) {
        // Если это JSON string, парсим его
        try {
          final parsed = jsonDecode(rawArguments);
          if (parsed is Map) {
            arguments = Map<String, dynamic>.from(parsed);
          } else {
            _logger.w(
              'Parsed arguments is not a Map, got ${parsed.runtimeType}',
            );
            // Сохраняем исходную строку для отладки
            arguments = {'_raw': rawArguments, '_parse_error': 'Not a Map'};
          }
        } catch (e, stackTrace) {
          _logger.e(
            'Failed to parse arguments JSON',
            error: e,
            stackTrace: stackTrace,
          );
          _logger.d('Raw arguments: $rawArguments');
          // Сохраняем ошибку и исходные данные
          arguments = {'_raw': rawArguments, '_parse_error': e.toString()};
        }
      } else if (rawArguments is Map) {
        arguments = Map<String, dynamic>.from(rawArguments);
      } else if (rawArguments != null) {
        _logger.w(
          'Unexpected arguments type: ${rawArguments.runtimeType}',
        );
        arguments = {
          '_raw': rawArguments.toString(),
          '_parse_error': 'Unexpected type',
        };
      }

      return WSMessage.toolCall(
        callId: toolCall['id'] as String? ?? '',
        toolName: function?['name'] as String? ?? '',
        arguments: arguments,
      );
    }

    // Обрабатываем tool result
    if (chatMsg.toolCallId != null) {
      // content может быть String (JSON) или обычный текст
      Map<String, dynamic>? result;
      if (chatMsg.content != null) {
        try {
          final parsed = jsonDecode(chatMsg.content!);
          if (parsed is Map) {
            result = Map<String, dynamic>.from(parsed);
          } else {
            result = {'content': chatMsg.content};
          }
        } catch (e) {
          // Если не JSON, просто оборачиваем в Map
          result = {'content': chatMsg.content};
        }
      }

      return WSMessage.toolResult(
        callId: chatMsg.toolCallId!,
        toolName: chatMsg.name,
        result: result,
      );
    }

    // Обрабатываем сообщения пользователя
    if (chatMsg.role == 'user') {
      return WSMessage.userMessage(
        content: chatMsg.content ?? '',
        role: chatMsg.role,
      );
    }

    // Обрабатываем системные сообщения (agent_switched, error и т.д.)
    if (chatMsg.role == 'system') {
      // Проверяем, есть ли информация о переключении агента в name поле
      if (chatMsg.name != null && chatMsg.name!.contains('agent_switched')) {
        // Пытаемся извлечь информацию из content
        final content = chatMsg.content ?? '';
        return WSMessage.agentSwitched(
          content: content,
          fromAgent: null, // Информация может быть в content
          toAgent: null,
          reason: null,
        );
      }

      // Если это ошибка
      if (chatMsg.content != null &&
          chatMsg.content!.toLowerCase().contains('error')) {
        return WSMessage.error(content: chatMsg.content);
      }

      // Другие системные сообщения показываем как assistant message
      return WSMessage.assistantMessage(
        content: chatMsg.content,
        isFinal: true,
      );
    }

    // Обрабатываем сообщения ассистента
    return WSMessage.assistantMessage(content: chatMsg.content, isFinal: true);
  }

  @override
  Future<Either<Failure, List<Agent>>> getAvailableAgents() async {
    try {
      // TODO: Загружать агентов с сервера через API
      // Временно возвращаем предопределенный список
      final agents = [
        Agent(
          id: AgentType.orchestrator,
          name: 'Orchestrator',
          description: 'Координирует работу других агентов',
          icon: '🪃',
          capabilities: ['routing', 'coordination'],
        ),
        Agent(
          id: AgentType.code,
          name: 'Coder',
          description: 'Пишет и редактирует код',
          icon: '💻',
          capabilities: ['coding', 'refactoring'],
        ),
        Agent(
          id: AgentType.architect,
          name: 'Architect',
          description: 'Проектирует архитектуру',
          icon: '🏗️',
          capabilities: ['design', 'planning'],
        ),
        Agent(
          id: AgentType.debug,
          name: 'Debugger',
          description: 'Отлаживает код',
          icon: '🪲',
          capabilities: ['debugging', 'troubleshooting'],
        ),
        Agent(
          id: AgentType.ask,
          name: 'Ask',
          description: 'Отвечает на вопросы',
          icon: '❓',
          capabilities: ['qa', 'explanation'],
        ),
      ];

      return right(agents);
    } catch (e) {
      _logger.e('Failed to get available agents', error: e);
      return left(Failure.server('Failed to get agents: $e'));
    }
  }

  @override
  Future<Either<Failure, Agent>> getCurrentAgent() async {
    try {
      // TODO: Получать текущего агента из API
      // Текущий агент определяется из последнего agent_switched сообщения
      // Пока возвращаем orchestrator по умолчанию
      return right(
        Agent(
          id: AgentType.orchestrator,
          name: 'Orchestrator',
          description: 'Координирует работу других агентов',
          icon: '🪃',
          capabilities: ['routing', 'coordination'],
        ),
      );
    } catch (e) {
      _logger.e('Failed to get current agent', error: e);
      return left(Failure.server('Failed to get current agent: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> connect(String sessionId) async {
    try {
      _logger.d('Connecting to session: $sessionId');
      await _remoteDataSource.connect(sessionId);
      _logger.i('Successfully connected to session: $sessionId');
      return right(unit);
    } on WebSocketException catch (e) {
      _logger.e('Failed to connect to WebSocket', error: e);
      return left(Failure.network(e.message));
    } catch (e) {
      _logger.e('Unexpected error connecting', error: e);
      return left(Failure.unknown('Failed to connect: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> disconnect() async {
    try {
      _logger.d('Disconnecting from WebSocket');
      await _remoteDataSource.disconnect();
      _logger.i('Successfully disconnected');
      return right(unit);
    } on WebSocketException catch (e) {
      _logger.e('Failed to disconnect from WebSocket', error: e);
      return left(Failure.network(e.message));
    } catch (e) {
      _logger.e('Unexpected error disconnecting', error: e);
      return left(Failure.unknown('Failed to disconnect: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPlanDecision(
    SendPlanDecisionParams params,
  ) async {
    try {
      if (!_remoteDataSource.isConnected) {
        _logger.w('Attempted to send plan decision while not connected');
        return left(Failure.network('WebSocket not connected'));
      }

      // Создаем MessageModel с правильной структурой для plan_decision
      final model = MessageModel(
        type: 'plan_decision',
        approvalRequestId: params.approvalRequestId,
        planId: params.planId,
        decision: params.decision,
        feedback: params.feedback,
      );

      _logger.d('Sending plan_decision', error: {
        'approval_request_id': params.approvalRequestId,
        'plan_id': params.planId,
        'decision': params.decision,
      });

      await _remoteDataSource.sendMessage(model);
      _logger.i('Plan decision sent successfully');
      return right(unit);
    } on WebSocketException catch (e) {
      _logger.e('Failed to send plan decision', error: e);
      return left(Failure.network(e.message));
    } catch (e) {
      _logger.e('Unexpected error sending plan decision', error: e);
      return left(Failure.unknown('Failed to send plan decision: $e'));
    }
  }

  @override
  bool get isConnected => _remoteDataSource.isConnected;
}
