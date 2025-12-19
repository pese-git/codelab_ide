// lib/ai_agent/bloc/ai_agent_bloc.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/ws_message.dart';
import '../domain/agent_protocol_service.dart';
import '../integration/tool_api.dart';

part 'ai_agent_bloc.freezed.dart';
//part 'ai_agent_bloc.g.dart';

@freezed
class AiAgentEvent with _$AiAgentEvent {
  const factory AiAgentEvent.connected() = AgentConnected;
  const factory AiAgentEvent.disconnected() = AgentDisconnected;
  const factory AiAgentEvent.sendUserMessage(String text) = SendUserMessage;
  const factory AiAgentEvent.messageReceived(WSMessage message) =
      MessageReceived;
  // ...добавить при необходимости дополнительные ивенты
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
  }) = ChatState;
}

/// BLoC AI ассистента: роутинг сообщений, обработка user/tools, хранение истории
class AiAgentBloc extends Bloc<AiAgentEvent, AiAgentState> {
  final AgentProtocolService protocol;
  final ToolApi toolApi;
  late final Stream<WSMessage> _msgSub;

  AiAgentBloc({required this.protocol, required this.toolApi})
    : super(const InitialState()) {
    on<AgentConnected>((event, emit) => emit(const ConnectedState()));
    on<AgentDisconnected>((event, emit) => emit(const InitialState()));
    on<SendUserMessage>(_onUserMessage);
    on<MessageReceived>(_onMessageReceived);
    // подписка на стрим AI
    protocol.connect();
    _msgSub = protocol.messages;
    _msgSub.listen((msg) => add(AiAgentEvent.messageReceived(msg)));
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

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<AiAgentState> emit,
  ) async {
    final msg = event.message;
    final chatState = state is ChatState ? state as ChatState : null;
    // обработка tool_call через ToolApi
    await msg.maybeWhen(
      toolCall: (callId, toolName, arguments) async {
        try {
          final result = await toolApi.call(toolName, arguments);
          protocol.sendToolResult(callId: callId, result: result);
        } catch (e) {
          protocol.sendToolResult(callId: callId, error: e.toString());
        }
      },
      orElse: () {},
    );
    // добавить пришедший ответ в чат
    emit(
      ChatState(
        history: [...(chatState?.history ?? []), msg],
        waitingResponse: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await protocol.disconnect();
    return super.close();
  }
}
