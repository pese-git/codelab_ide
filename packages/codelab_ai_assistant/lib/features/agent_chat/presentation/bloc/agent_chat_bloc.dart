// BLoC для чата с агентом (Presentation слой)
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/agent.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/send_tool_result.dart';
import '../../domain/usecases/receive_messages.dart';
import '../../domain/usecases/switch_agent.dart';
import '../../domain/usecases/load_history.dart';
import '../../domain/usecases/connect.dart';
import '../../../tool_execution/domain/usecases/execute_tool.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_result.dart';

part 'agent_chat_bloc.freezed.dart';

/// События для AgentChatBloc
@freezed
class AgentChatEvent with _$AgentChatEvent {
  const factory AgentChatEvent.sendMessage(String text) = SendMessageEvent;
  const factory AgentChatEvent.messageReceived(Message message) =
      MessageReceivedEvent;
  const factory AgentChatEvent.switchAgent(String agentType, String content) =
      SwitchAgentEvent;
  const factory AgentChatEvent.loadHistory(String sessionId) = LoadHistoryEvent;
  const factory AgentChatEvent.connect(String sessionId) = ConnectEvent;
  const factory AgentChatEvent.disconnect() = DisconnectEvent;
  const factory AgentChatEvent.error(Failure failure) = ErrorEvent;
}

/// Состояния для AgentChatBloc
@freezed
abstract class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required bool isLoading,
    required bool isConnected,
    required String currentAgent,
    required Option<String> error,
  }) = _AgentChatState;

  factory AgentChatState.initial() => AgentChatState(
    messages: const [],
    isLoading: false,
    isConnected: false,
    currentAgent: AgentType.orchestrator,
    error: none(),
  );
}

/// BLoC для чата с AI агентом с использованием Use Cases
///
/// Этот BLoC использует Clean Architecture подход:
/// - Не содержит бизнес-логики (она в Use Cases)
/// - Работает только с domain entities
/// - Обрабатывает Either<Failure, T> из use cases
class AgentChatBloc extends Bloc<AgentChatEvent, AgentChatState> {
  final SendMessageUseCase _sendMessage;
  final SendToolResultUseCase _sendToolResult;
  final ReceiveMessagesUseCase _receiveMessages;
  final SwitchAgentUseCase _switchAgent;
  final LoadHistoryUseCase _loadHistory;
  final ConnectUseCase _connect;
  final ExecuteToolUseCase _executeTool;
  final Logger _logger;

  StreamSubscription<Either<Failure, Message>>? _messageSubscription;

  AgentChatBloc({
    required SendMessageUseCase sendMessage,
    required SendToolResultUseCase sendToolResult,
    required ReceiveMessagesUseCase receiveMessages,
    required SwitchAgentUseCase switchAgent,
    required LoadHistoryUseCase loadHistory,
    required ConnectUseCase connect,
    required ExecuteToolUseCase executeTool,
    required Logger logger,
  }) : _sendMessage = sendMessage,
       _sendToolResult = sendToolResult,
       _receiveMessages = receiveMessages,
       _switchAgent = switchAgent,
       _loadHistory = loadHistory,
       _connect = connect,
       _executeTool = executeTool,
       _logger = logger,
       super(AgentChatState.initial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<SwitchAgentEvent>(_onSwitchAgent);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<ConnectEvent>(_onConnect);
    on<DisconnectEvent>(_onDisconnect);
    on<ErrorEvent>(_onError);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    // Добавляем сообщение пользователя в историю
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: MessageContent.text(text: event.text, isFinal: true),
      timestamp: DateTime.now(),
      metadata: none(),
    );

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        error: none(),
      ),
    );

    // Отправляем через use case
    final result = await _sendMessage(
      SendMessageParams(text: event.text, metadata: none()),
    );

    result.fold(
      (failure) {
        _logger.e('Failed to send message: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) {
        _logger.i('Message sent successfully');
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  Future<void> _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d('Message received: ${event.message.role}');

    // Обновляем текущего агента если это agent_switched
    String newAgent = state.currentAgent;
    event.message.content.maybeWhen(
      agentSwitch: (from, to, reason) {
        newAgent = to;
        _logger.i('Agent switched: $from → $to');
      },
      orElse: () {},
    );

    emit(
      state.copyWith(
        messages: [...state.messages, event.message],
        currentAgent: newAgent,
        isLoading: false,
      ),
    );
    
    // Автоматически выполняем tool calls
    await event.message.content.maybeWhen(
      toolCall: (callId, toolName, arguments) async {
        _logger.i('Executing tool: $toolName');
        
        // Проверяем, требует ли инструмент подтверждения
        // Критичные операции: write_file, execute_command, create_directory
        final criticalTools = ['write_file', 'write_to_file', 'execute_command', 'run_command', 'create_directory'];
        final requiresApproval = criticalTools.contains(toolName);
        
        final toolCall = ToolCall(
          id: callId,
          toolName: toolName,
          arguments: arguments,
          requiresApproval: requiresApproval,
          createdAt: DateTime.now(),
        );
        
        final result = await _executeTool(ExecuteToolParams(toolCall: toolCall));
        
        result.fold(
          (failure) async {
            _logger.e('Tool execution failed: ${failure.message}');
            // Send error result back to server using dedicated use case
            await _sendToolResult(SendToolResultParams(
              callId: callId,
              toolName: toolName,
              error: failure.message,
            ));
          },
          (toolResult) async {
            _logger.i('Tool executed successfully: $toolName');
            // Send result back to server using when for exhaustive matching
            await toolResult.when(
              success: (id, name, data, duration, time) async {
                await _sendToolResult(SendToolResultParams(
                  callId: callId,
                  toolName: toolName,
                  result: data,
                ));
              },
              failure: (id, name, code, msg, details, time) async {
                await _sendToolResult(SendToolResultParams(
                  callId: callId,
                  toolName: toolName,
                  error: msg,
                ));
              },
            );
          },
        );
      },
      orElse: () async {},
    );
  }

  Future<void> _onSwitchAgent(
    SwitchAgentEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: none()));

    final result = await _switchAgent(
      SwitchAgentParams(
        agentType: event.agentType,
        content: event.content,
        reason: none(),
      ),
    );

    result.fold(
      (failure) {
        _logger.e('Failed to switch agent: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) {
        _logger.i('Agent switch requested: ${event.agentType}');
        emit(state.copyWith(isLoading: false, currentAgent: event.agentType));
      },
    );
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: none()));

    final result = await _loadHistory(
      LoadHistoryParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) {
        _logger.e('Failed to load history: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (messages) {
        _logger.i('Loaded ${messages.length} messages');
        emit(
          state.copyWith(messages: messages, isLoading: false, error: none()),
        );
      },
    );
  }

  Future<void> _onConnect(
    ConnectEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: none()));

    // Подключаемся к WebSocket через use case
    final connectResult = await _connect(ConnectParams(sessionId: event.sessionId));
    
    connectResult.fold(
      (failure) {
        _logger.e('Failed to connect: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
        return;
      },
      (_) {
        _logger.i('Connected to WebSocket: ${event.sessionId}');
        
        // Подписываемся на поток сообщений
        _messageSubscription?.cancel();
        _messageSubscription = _receiveMessages(const NoParams()).listen((either) {
          either.fold(
            (failure) => add(AgentChatEvent.error(failure)),
            (message) => add(AgentChatEvent.messageReceived(message)),
          );
        });

        emit(state.copyWith(isConnected: true, isLoading: false));
      },
    );
  }

  Future<void> _onDisconnect(
    DisconnectEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;

    emit(state.copyWith(isConnected: false, messages: const []));

    _logger.i('Disconnected from chat');
  }

  Future<void> _onError(ErrorEvent event, Emitter<AgentChatState> emit) async {
    _logger.e('Chat error: ${event.failure.message}');
    emit(state.copyWith(error: some(event.failure.message), isLoading: false));
  }

  @override
  Future<void> close() async {
    await _messageSubscription?.cancel();
    return super.close();
  }
}
