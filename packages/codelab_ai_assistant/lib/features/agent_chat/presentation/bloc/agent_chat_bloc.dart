// BLoC для чата с агентом (Presentation слой)
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/agent.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/switch_agent.dart';
import '../../domain/usecases/load_history.dart';
import '../../domain/usecases/send_plan_decision.dart';
import '../../../tool_execution/domain/entities/tool_approval.dart' as tool_approval;
import '../../../tool_execution/domain/entities/approval_request_with_completer.dart';
import '../middleware/connection_middleware.dart';
import '../middleware/message_handler_middleware.dart';
import '../middleware/approval_middleware.dart';

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
  const factory AgentChatEvent.approvalRequested(
    ApprovalRequestWithCompleter request,
  ) = ApprovalRequestedEvent;
  const factory AgentChatEvent.approveToolCall() = ApproveToolCallEvent;
  const factory AgentChatEvent.rejectToolCall(String reason) =
      RejectToolCallEvent;
  const factory AgentChatEvent.cancelToolCall() = CancelToolCallEvent;
  const factory AgentChatEvent.sendPlanDecision({
    required String approvalRequestId,
    required String planId,
    required String decision,
    String? feedback,
  }) = SendPlanDecisionEvent;
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
    required Option<ApprovalRequestWithCompleter> pendingApproval,
    required Option<Message> pendingPlanApproval,
  }) = _AgentChatState;

  factory AgentChatState.initial() => AgentChatState(
    messages: const [],
    isLoading: false,
    isConnected: false,
    currentAgent: AgentType.orchestrator,
    error: none(),
    pendingApproval: none(),
    pendingPlanApproval: none(),
  );
}

/// BLoC для чата с AI агентом с использованием Middleware Pattern
///
/// Этот BLoC использует Middleware Pattern для делегирования логики:
/// - ConnectionMiddleware: управление WebSocket подключением
/// - MessageHandlerMiddleware: обработка входящих сообщений
/// - ApprovalMiddleware: управление подтверждениями (tool и plan)
///
/// BLoC фокусируется только на state management и координации middleware.
class AgentChatBloc extends Bloc<AgentChatEvent, AgentChatState> {
  final ConnectionMiddleware _connectionMiddleware;
  final MessageHandlerMiddleware _messageHandlerMiddleware;
  final ApprovalMiddleware _approvalMiddleware;
  final SendMessageUseCase _sendMessage;
  final SwitchAgentUseCase _switchAgent;
  final LoadHistoryUseCase _loadHistory;
  final SendPlanDecisionUseCase _sendPlanDecision;
  final Logger _logger;

  AgentChatBloc({
    required ConnectionMiddleware connectionMiddleware,
    required MessageHandlerMiddleware messageHandlerMiddleware,
    required ApprovalMiddleware approvalMiddleware,
    required SendMessageUseCase sendMessage,
    required SwitchAgentUseCase switchAgent,
    required LoadHistoryUseCase loadHistory,
    required SendPlanDecisionUseCase sendPlanDecision,
    required Logger logger,
  }) : _connectionMiddleware = connectionMiddleware,
       _messageHandlerMiddleware = messageHandlerMiddleware,
       _approvalMiddleware = approvalMiddleware,
       _sendMessage = sendMessage,
       _switchAgent = switchAgent,
       _loadHistory = loadHistory,
       _sendPlanDecision = sendPlanDecision,
       _logger = logger,
       super(AgentChatState.initial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<SwitchAgentEvent>(_onSwitchAgent);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<ConnectEvent>(_onConnect);
    on<DisconnectEvent>(_onDisconnect);
    on<ErrorEvent>(_onError);
    on<ApprovalRequestedEvent>(_onApprovalRequested);
    on<ApproveToolCallEvent>(_onApproveToolCall);
    on<RejectToolCallEvent>(_onRejectToolCall);
    on<CancelToolCallEvent>(_onCancelToolCall);
    on<SendPlanDecisionEvent>(_onSendPlanDecision);

    // Подписываемся на approval requests через middleware
    _approvalMiddleware.startListening(
      onToolApproval: (request) => add(AgentChatEvent.approvalRequested(request)),
    );
  }

  /// Отправить сообщение пользователя
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d(
      '[AgentChatBloc] 📤 Sending message: "${event.text.substring(0, event.text.length > 50 ? 50 : event.text.length)}..."',
    );

    // Добавляем сообщение пользователя в историю
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: MessageContent.text(text: event.text, isFinal: true),
      timestamp: DateTime.now(),
      metadata: none(),
    );

    _logger.d(
      '[AgentChatBloc] 📝 Adding user message to state, total messages: ${state.messages.length + 1}',
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
        _logger.e(
          '[AgentChatBloc] ❌ Failed to send message: ${failure.message}',
        );
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) {
        _logger.i('[AgentChatBloc] ✅ Message sent successfully');
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  /// Обработать полученное сообщение
  ///
  /// Делегирует обработку MessageHandlerMiddleware
  Future<void> _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d('[AgentChatBloc] 📨 Message received: ${event.message.role}');

    // Проверяем, является ли это session_info сообщением
    final isSessionInfo = event.message.content.maybeWhen(
      sessionInfo: (_, __) => true,
      orElse: () => false,
    );

    // Проверяем, является ли это plan approval сообщением
    final isPlanApproval = event.message.content.maybeWhen(
      planApprovalRequired: (_, __, ___, ____) => true,
      orElse: () => false,
    );

    // Проверяем, является ли это error сообщением
    final isError = event.message.content.maybeWhen(
      error: (_) => true,
      orElse: () => false,
    );

    // Обрабатываем сообщение через MessageHandlerMiddleware
    final newAgent = await _messageHandlerMiddleware.handleMessage(
      message: event.message,
      onPlanApproval: (message) {
        _logger.i('[AgentChatBloc] 📋 Plan approval required');
        // НЕ вызываем add() здесь - это создает бесконечный цикл!
        // State будет обновлен ниже через emit
      },
      onSessionInfo: (sessionId) {
        _logger.i('[AgentChatBloc] 🆔 Session ID received: $sessionId');
        // Session ID будет обработан в ConnectionMiddleware
      },
    );

    // Session info сообщения не добавляем в историю
    if (isSessionInfo) {
      _logger.d('[AgentChatBloc] Skipping session_info message in history');
      return;
    }

    // Обновляем state
    emit(
      state.copyWith(
        messages: [...state.messages, event.message],
        currentAgent: newAgent.fold(() => state.currentAgent, (agent) => agent),
        isLoading: false,
        pendingPlanApproval: isPlanApproval ? some(event.message) : state.pendingPlanApproval,
        // Очищаем error state если это не error сообщение
        error: isError ? state.error : none(),
      ),
    );
  }

  /// Переключить агента
  Future<void> _onSwitchAgent(
    SwitchAgentEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d('[AgentChatBloc] 🔄 Switching agent to: ${event.agentType}');
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
        _logger.e('[AgentChatBloc] ❌ Failed to switch agent: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) {
        _logger.i('[AgentChatBloc] ✅ Agent switch requested: ${event.agentType}');
        emit(state.copyWith(isLoading: false, currentAgent: event.agentType));
      },
    );
  }

  /// Загрузить историю сообщений
  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d(
      '[AgentChatBloc] 📜 Loading history for session: ${event.sessionId}',
    );
    emit(state.copyWith(isLoading: true, error: none()));

    final result = await _loadHistory(
      LoadHistoryParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) {
        _logger.e('[AgentChatBloc] ❌ Failed to load history: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (messages) {
        _logger.i('[AgentChatBloc] ✅ Loaded ${messages.length} messages');
        emit(
          state.copyWith(messages: messages, isLoading: false, error: none()),
        );
      },
    );
  }

  /// Подключиться к WebSocket
  ///
  /// Делегирует подключение ConnectionMiddleware и восстановление approvals ApprovalMiddleware
  Future<void> _onConnect(
    ConnectEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d('[AgentChatBloc] 🔌 Connecting to session: ${event.sessionId}');
    emit(state.copyWith(isLoading: true, error: none()));

    // Подключаемся через ConnectionMiddleware
    final result = await _connectionMiddleware.connect(
      sessionId: event.sessionId,
      onMessage: (message) => add(AgentChatEvent.messageReceived(message)),
      onError: (failure) => add(AgentChatEvent.error(failure)),
    );

    await result.fold(
      (failure) async {
        _logger.e('[AgentChatBloc] ❌ Failed to connect: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) async {
        _logger.i('[AgentChatBloc] ✅ Connected to WebSocket: ${event.sessionId}');

        // Восстанавливаем pending approvals только для реальных session_id
        // Временные ID (new_*) пропускаем, т.к. сессия еще не создана на сервере
        if (!event.sessionId.startsWith('new_')) {
          try {
            final restoredCount = await _approvalMiddleware.restorePendingApprovals(event.sessionId);
            _logger.i('[AgentChatBloc] ✅ Restored $restoredCount pending approvals');
          } catch (e) {
            _logger.e('[AgentChatBloc] ⚠️ Failed to restore pending approvals: $e');
            // Не блокируем подключение из-за ошибки восстановления
          }
        } else {
          _logger.d('[AgentChatBloc] ⏭️ Skipping approval restoration for temporary session_id: ${event.sessionId}');
        }

        emit(state.copyWith(isConnected: true, isLoading: false));
      },
    );
  }

  /// Отключиться от WebSocket
  ///
  /// Делегирует отключение ConnectionMiddleware и очистку ApprovalMiddleware
  Future<void> _onDisconnect(
    DisconnectEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d('[AgentChatBloc] 🔌 Disconnecting from chat');

    // Отключаемся через middleware
    await _connectionMiddleware.disconnect();
    _approvalMiddleware.clearActiveCompleters();

    emit(
      state.copyWith(
        isConnected: false,
        messages: const [],
        isLoading: false,
        error: none(),
        pendingApproval: none(),
        pendingPlanApproval: none(),
      ),
    );

    _logger.i('[AgentChatBloc] ✅ Disconnected from chat');
  }

  /// Обработать ошибку
  Future<void> _onError(ErrorEvent event, Emitter<AgentChatState> emit) async {
    _logger.e('[AgentChatBloc] ❌ Chat error: ${event.failure.message}');
    emit(state.copyWith(error: some(event.failure.message), isLoading: false));
  }

  /// Обработать запрос подтверждения tool
  Future<void> _onApprovalRequested(
    ApprovalRequestedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i(
      '[AgentChatBloc] 🔔 Tool approval requested: ${event.request.toolCall.toolName}',
    );
    emit(state.copyWith(pendingApproval: some(event.request)));
  }

  /// Подтвердить выполнение tool
  Future<void> _onApproveToolCall(
    ApproveToolCallEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    state.pendingApproval.fold(
      () => _logger.w('[AgentChatBloc] ⚠️ No pending approval to approve'),
      (request) {
        _logger.i(
          '[AgentChatBloc] ✅ Tool call approved: ${request.toolCall.toolName}',
        );
        request.completer.complete(const tool_approval.ApprovalDecision.approved());
        emit(state.copyWith(pendingApproval: none()));
      },
    );
  }

  /// Отклонить выполнение tool
  Future<void> _onRejectToolCall(
    RejectToolCallEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    state.pendingApproval.fold(
      () => _logger.w('[AgentChatBloc] ⚠️ No pending approval to reject'),
      (request) {
        _logger.i(
          '[AgentChatBloc] ❌ Tool call rejected: ${request.toolCall.toolName}, reason: ${event.reason}',
        );
        request.completer.complete(
          tool_approval.ApprovalDecision.rejected(reason: some(event.reason)),
        );
        emit(state.copyWith(pendingApproval: none()));
      },
    );
  }

  /// Отменить выполнение tool
  Future<void> _onCancelToolCall(
    CancelToolCallEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    state.pendingApproval.fold(
      () => _logger.w('[AgentChatBloc] ⚠️ No pending approval to cancel'),
      (request) {
        _logger.i(
          '[AgentChatBloc] 🚫 Tool call cancelled: ${request.toolCall.toolName}',
        );
        request.completer.complete(const tool_approval.ApprovalDecision.cancelled());
        emit(state.copyWith(pendingApproval: none()));
      },
    );
  }

  /// Отправить решение по плану
  Future<void> _onSendPlanDecision(
    SendPlanDecisionEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i(
      '[AgentChatBloc] 📤 Sending plan decision: ${event.decision} for plan ${event.planId}',
    );

    emit(state.copyWith(isLoading: true));

    final result = await _sendPlanDecision(
      SendPlanDecisionParams(
        approvalRequestId: event.approvalRequestId,
        planId: event.planId,
        decision: event.decision,
        feedback: event.feedback,
      ),
    );

    result.fold(
      (failure) {
        _logger.e('[AgentChatBloc] ❌ Failed to send plan decision: ${failure.message}');
        emit(state.copyWith(
          isLoading: false,
          error: some(failure.message),
        ));
      },
      (_) {
        _logger.i('[AgentChatBloc] ✅ Plan decision sent successfully: ${event.decision}');
        emit(state.copyWith(
          isLoading: false,
          pendingPlanApproval: none(),
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    _logger.d('[AgentChatBloc] 🔒 Closing bloc');
    await _connectionMiddleware.dispose();
    await _approvalMiddleware.dispose();
    return super.close();
  }
}
