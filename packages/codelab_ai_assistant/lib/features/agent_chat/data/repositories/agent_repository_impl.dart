// Реализация AgentRepository (Data слой)
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';
import '../datasources/agent_remote_datasource.dart';
import '../models/message_model.dart';
import '../../../../src/api/gateway_api.dart';
import '../../../../src/utils/message_mapper.dart';
import '../../../../src/models/ws_message.dart';

/// Реализация репозитория для работы с агентами
///
/// Координирует работу с WebSocket data source и REST API.
/// Конвертирует exceptions в failures и возвращает Either<Failure, T>.
class AgentRepositoryImpl implements AgentRepository {
  final AgentRemoteDataSource _remoteDataSource;
  final GatewayApi _gatewayApi;
  
  AgentRepositoryImpl({
    required AgentRemoteDataSource remoteDataSource,
    required GatewayApi gatewayApi,
  }) : _remoteDataSource = remoteDataSource,
       _gatewayApi = gatewayApi;
  
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
      return left(Failure.network(e.message));
    } catch (e) {
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
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Failed to send tool result: $e'));
    }
  }
  
  @override
  Stream<Either<Failure, Message>> receiveMessages() {
    try {
      return _remoteDataSource.receiveMessages()
        .map((model) => right<Failure, Message>(model.toEntity()))
        .handleError((error) {
          if (error is WebSocketException) {
            return left<Failure, Message>(Failure.network(error.message));
          }
          if (error is ParseException) {
            return left<Failure, Message>(Failure.server(error.message));
          }
          return left<Failure, Message>(Failure.unknown('Stream error: $error'));
        });
    } catch (e) {
      return Stream.value(left(Failure.unknown('Failed to receive messages: $e')));
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
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Failed to switch agent: $e'));
    }
  }
  
  @override
  Future<Either<Failure, List<Message>>> loadHistory(LoadHistoryParams params) async {
    try {
      // Загружаем историю через REST API
      final sessionHistory = await _gatewayApi.getSessionHistory(params.sessionId);
      
      // Конвертируем ChatMessage в Message entities через WSMessage
      final messages = sessionHistory.messages
          .map((chatMsg) {
            final wsMsg = _chatMessageToWSMessage(chatMsg);
            return MessageMapper.fromWSMessage(wsMsg);
          })
          .toList();
      
      return right(messages);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return left(Failure.notFound('Session not found'));
      }
      return left(Failure.server('Failed to load history: ${e.message}'));
    } catch (e) {
      return left(Failure.server('Failed to load history: $e'));
    }
  }
  
  /// Конвертирует ChatMessage в WSMessage
  WSMessage _chatMessageToWSMessage(dynamic chatMsg) {
    // TODO: Implement proper conversion
    return WSMessage.assistantMessage(content: chatMsg.content ?? '', isFinal: true);
  }
  
  @override
  Future<Either<Failure, List<Agent>>> getAvailableAgents() async {
    try {
      // Список агентов загружается через REST API
      // Пока возвращаем предопределенный список
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
      return left(Failure.server('Failed to get agents: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Agent>> getCurrentAgent() async {
    try {
      // Текущий агент определяется из последнего agent_switched сообщения
      // Пока возвращаем orchestrator по умолчанию
      return right(Agent(
        id: AgentType.orchestrator,
        name: 'Orchestrator',
        description: 'Координирует работу других агентов',
        icon: '🪃',
        capabilities: ['routing', 'coordination'],
      ));
    } catch (e) {
      return left(Failure.server('Failed to get current agent: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> connect(String sessionId) async {
    try {
      await _remoteDataSource.connect(sessionId);
      return right(unit);
    } on WebSocketException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Failed to connect: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> disconnect() async {
    try {
      await _remoteDataSource.disconnect();
      return right(unit);
    } on WebSocketException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Failed to disconnect: $e'));
    }
  }
  
  @override
  bool get isConnected => _remoteDataSource.isConnected;
}
