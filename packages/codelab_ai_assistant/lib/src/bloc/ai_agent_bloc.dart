// lib/ai_agent/bloc/ai_agent_bloc.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../models/ws_message.dart';
import '../models/tool_models.dart';
import '../models/session_models.dart';
import '../domain/agent_protocol_service.dart';
import '../integration/tool_api.dart';
import '../utils/websocket_error_mapper.dart';
import '../services/tool_approval_service.dart';

part 'ai_agent_bloc.freezed.dart';
//part 'ai_agent_bloc.g.dart';

final _logger = Logger();

@freezed
class AiAgentEvent with _$AiAgentEvent {
  const factory AiAgentEvent.connected() = AgentConnected;
  const factory AiAgentEvent.disconnected() = AgentDisconnected;
  const factory AiAgentEvent.sendUserMessage(String text) = SendUserMessage;
  const factory AiAgentEvent.switchAgent(String agentType, String content) = SwitchAgent;
  const factory AiAgentEvent.messageReceived(WSMessage message) =
      MessageReceived;
  const factory AiAgentEvent.approveToolCall() = ApproveToolCall;
  const factory AiAgentEvent.rejectToolCall() = RejectToolCall;
  const factory AiAgentEvent.toolApprovalRequested(ToolApprovalRequest request) = ToolApprovalRequested;
  const factory AiAgentEvent.loadHistory(SessionHistory history) = LoadHistory;
}

@freezed
class AiAgentState with _$AiAgentState {
  const factory AiAgentState.initial() = InitialState;
  const factory AiAgentState.connected() = ConnectedState;
  const factory AiAgentState.loading() = LoadingState;
  const factory AiAgentState.error(String message) = ErrorState;
  const factory AiAgentState.chat({
    required List<WSMessage> history,
    @Default(false) bool waitingResponse,
    ToolApprovalRequest? pendingApproval,
    @Default('orchestrator') String currentAgent,
  }) = ChatState;
}

/// BLoC AI ассистента: роутинг сообщений, обработка user/tools, хранение истории
class AiAgentBloc extends Bloc<AiAgentEvent, AiAgentState> {
  final AgentProtocolService protocol;
  final ToolApi toolApi;
  final ToolApprovalService approvalService;
  late final Stream<WSMessage> _msgSub;
  bool _isConnected = false;

  AiAgentBloc({
    required this.protocol,
    required this.toolApi,
    required this.approvalService,
  }) : super(const InitialState()) {
    on<AgentConnected>((event, emit) => emit(const ConnectedState()));
    on<AgentDisconnected>((event, emit) => emit(const InitialState()));
    on<SendUserMessage>(_onUserMessage);
    on<SwitchAgent>(_onSwitchAgent);
    on<MessageReceived>(_onMessageReceived);
    on<ApproveToolCall>(_onApproveToolCall);
    on<RejectToolCall>(_onRejectToolCall);
    on<ToolApprovalRequested>(_onToolApprovalRequested);
    on<LoadHistory>(_onLoadHistory);
    
    // НЕ подключаемся автоматически - подключение происходит при loadHistory
    // с конкретным session_id
    
    // подписка на запросы подтверждения
    approvalService.approvalRequests.listen((request) {
      add(AiAgentEvent.toolApprovalRequested(request));
    });
  }
  
  void _ensureConnected() {
    if (!_isConnected) {
      _msgSub = protocol.messages;
      _msgSub.listen((msg) => add(AiAgentEvent.messageReceived(msg)));
      _isConnected = true;
    }
  }

  Future<void> _onUserMessage(
    SendUserMessage event,
    Emitter<AiAgentState> emit,
  ) async {
    protocol.sendUserMessage(event.text);
    final chatState = state is ChatState ? state as ChatState : null;
    emit(
      ChatState(
        history: [
          ...(chatState?.history ?? []),
          WSMessage.userMessage(content: event.text, role: 'user'),
        ],
        waitingResponse: true,
      ),
    );
  }

  Future<void> _onSwitchAgent(
    SwitchAgent event,
    Emitter<AiAgentState> emit,
  ) async {
    protocol.sendSwitchAgent(event.agentType, event.content);
    final chatState = state is ChatState ? state as ChatState : null;
    emit(
      ChatState(
        history: chatState?.history ?? [],
        waitingResponse: true,
        currentAgent: event.agentType,
      ),
    );
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<AiAgentState> emit,
  ) async {
    final msg = event.message;
    final chatState = state is ChatState ? state as ChatState : null;
    
    // Log received message for debugging
    _logger.d('Received message: type=${msg.runtimeType}, content=${msg.maybeWhen(
      assistantMessage: (content, isFinal) => 'assistant: $content (final: $isFinal)',
      userMessage: (content, role) => 'user: $content',
      error: (content) => 'error: $content',
      orElse: () => 'other',
    )}');
    
    // Обработка agentSwitched для обновления currentAgent
    String? newAgent;
    msg.maybeWhen(
      agentSwitched: (content, fromAgent, toAgent, reason, confidence) {
        newAgent = toAgent;
        _logger.i('Agent switched: $fromAgent → $toAgent (reason: $reason)');
      },
      orElse: () {},
    );
    
    // обработка tool_call через ToolApi
    await msg.maybeWhen(
      toolCall: (callId, toolName, arguments, requiresApproval) async {
        _logger.d('Received tool call: $toolName (callId: $callId, requiresApproval: $requiresApproval)');
        
        try {
          final result = await toolApi.call(
            callId: callId,
            toolName: toolName,
            arguments: arguments,
            requiresApproval: requiresApproval,
          );
          
          _logger.i('Tool call successful: $toolName');
          protocol.sendToolResult(
            callId: callId,
            toolName: toolName,
            result: result.toJson(),
          );
        } on ToolExecutionException catch (e) {
          _logger.e('Tool execution failed: ${e.code} - ${e.message}');
          final errorMsg = WebSocketErrorMapper.mapException(e);
          protocol.sendToolResult(
            callId: callId,
            toolName: toolName,
            error: errorMsg,
          );
        } catch (e, stackTrace) {
          _logger.e('Unexpected error in tool call', error: e, stackTrace: stackTrace);
          protocol.sendToolResult(
            callId: callId,
            toolName: toolName,
            error: 'Unexpected error: $e',
          );
        }
      },
      orElse: () {},
    );
    
    // добавить пришедший ответ в чат
    final newHistory = [...(chatState?.history ?? []), msg];
    _logger.d('Updating chat state: history length=${newHistory.length}, waitingResponse=false');
    
    emit(
      ChatState(
        history: newHistory,
        waitingResponse: false,
        pendingApproval: chatState?.pendingApproval,
        currentAgent: newAgent ?? chatState?.currentAgent ?? 'orchestrator',
      ),
    );
    
    _logger.i('Chat state updated successfully');
  }

  Future<void> _onToolApprovalRequested(
    ToolApprovalRequested event,
    Emitter<AiAgentState> emit,
  ) async {
    final chatState = state is ChatState ? state as ChatState : null;
    
    emit(
      ChatState(
        history: chatState?.history ?? [],
        waitingResponse: chatState?.waitingResponse ?? false,
        pendingApproval: event.request,
      ),
    );
  }

  Future<void> _onApproveToolCall(
    ApproveToolCall event,
    Emitter<AiAgentState> emit,
  ) async {
    final chatState = state is ChatState ? state as ChatState : null;
    final pendingApproval = chatState?.pendingApproval;
    
    if (pendingApproval != null) {
      _logger.i('User approved tool call: ${pendingApproval.toolCall.toolName}');
      
      // Send HITL decision to backend
      protocol.sendHITLDecision(
        callId: pendingApproval.toolCall.callId,
        decision: 'approve',
      );
      
      // Complete local approval
      pendingApproval.completer.complete(ToolApprovalResult.approved);
      
      emit(
        ChatState(
          history: chatState?.history ?? [],
          waitingResponse: true, // Waiting for backend response
          pendingApproval: null,
        ),
      );
    }
  }

  Future<void> _onRejectToolCall(
    RejectToolCall event,
    Emitter<AiAgentState> emit,
  ) async {
    final chatState = state is ChatState ? state as ChatState : null;
    final pendingApproval = chatState?.pendingApproval;
    
    if (pendingApproval != null) {
      _logger.w('User rejected tool call: ${pendingApproval.toolCall.toolName}');
      
      // Send HITL decision to backend
      protocol.sendHITLDecision(
        callId: pendingApproval.toolCall.callId,
        decision: 'reject',
        feedback: 'User rejected this operation',
      );
      
      // Complete local approval
      pendingApproval.completer.complete(ToolApprovalResult.rejected);
      
      emit(
        ChatState(
          history: chatState?.history ?? [],
          waitingResponse: true, // Waiting for backend response
          pendingApproval: null,
        ),
      );
    }
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<AiAgentState> emit,
  ) async {
    _logger.i('Loading history: ${event.history.messageCount} messages for session ${event.history.sessionId}');
    
    // Переподключить WebSocket с новым session_id
    try {
      _logger.d('Reconnecting WebSocket with session_id: ${event.history.sessionId}');
      protocol.reconnect(event.history.sessionId);
      
      // Убедиться что подписка на сообщения активна
      _ensureConnected();
      
      _logger.i('WebSocket reconnected successfully');
    } catch (e) {
      _logger.e('Failed to reconnect WebSocket', error: e);
      emit(ErrorState('Failed to connect to session: $e'));
      return;
    }
    
    // Конвертировать ChatMessage в WSMessage
    final wsMessages = <WSMessage>[];
    for (final msg in event.history.messages) {
      if (msg.role == 'user') {
        wsMessages.add(WSMessage.userMessage(
          content: msg.content ?? '',
          role: 'user',
        ));
      } else if (msg.role == 'assistant') {
        wsMessages.add(WSMessage.assistantMessage(
          content: msg.content,
          isFinal: true,
        ));
      } else if (msg.role == 'tool') {
        wsMessages.add(WSMessage.toolResult(
          callId: msg.toolCallId ?? '',
          toolName: msg.name ?? '',
          result: msg.content != null ? {'result': msg.content} : null,
          error: null,
        ));
      }
    }
    
    emit(ChatState(
      history: wsMessages,
      waitingResponse: false,
      currentAgent: event.history.currentAgent ?? 'orchestrator',
    ));
    
    _logger.i('History loaded: ${wsMessages.length} messages');
  }

  @override
  Future<void> close() async {
    await protocol.disconnect();
    return super.close();
  }
}
