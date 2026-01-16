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
import '../../domain/entities/execution_plan.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/send_tool_result.dart';
import '../../domain/usecases/receive_messages.dart';
import '../../domain/usecases/switch_agent.dart';
import '../../domain/usecases/load_history.dart';
import '../../domain/usecases/connect.dart';
import '../../domain/usecases/approve_plan.dart';
import '../../domain/usecases/reject_plan.dart';
import '../../domain/usecases/get_active_plan.dart';
import '../../domain/usecases/watch_plan_updates.dart';
import '../../../tool_execution/domain/usecases/execute_tool.dart';
import '../../../tool_execution/domain/entities/tool_call.dart';
import '../../../tool_execution/domain/entities/tool_result.dart';
import '../../../tool_execution/domain/entities/tool_approval.dart';
import '../../../tool_execution/data/services/tool_approval_service_impl.dart';

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

  // События планирования
  const factory AgentChatEvent.planReceived(ExecutionPlan plan) =
      PlanReceivedEvent;
  const factory AgentChatEvent.approvePlan(
    String planId, {
    @Default(None()) Option<String> feedback,
  }) = ApprovePlanEvent;
  const factory AgentChatEvent.rejectPlan(String planId, String reason) =
      RejectPlanEvent;
  const factory AgentChatEvent.planProgressUpdated(ExecutionPlan plan) =
      PlanProgressUpdatedEvent;
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
    required Option<ExecutionPlan> activePlan,
    required bool isPlanPendingConfirmation,
  }) = _AgentChatState;

  factory AgentChatState.initial() => AgentChatState(
    messages: const [],
    isLoading: false,
    isConnected: false,
    currentAgent: AgentType.orchestrator,
    error: none(),
    pendingApproval: none(),
    activePlan: none(),
    isPlanPendingConfirmation: false,
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
  final ToolApprovalServiceImpl _approvalService;
  final ApprovePlanUseCase _approvePlan;
  final RejectPlanUseCase _rejectPlan;
  final GetActivePlanUseCase _getActivePlan;
  final WatchPlanUpdatesUseCase _watchPlanUpdates;
  final Logger _logger;

  StreamSubscription<Either<Failure, Message>>? _messageSubscription;
  StreamSubscription<ApprovalRequestWithCompleter>? _approvalSubscription;
  StreamSubscription<Either<Failure, ExecutionPlan>>? _planUpdatesSubscription;

  AgentChatBloc({
    required SendMessageUseCase sendMessage,
    required SendToolResultUseCase sendToolResult,
    required ReceiveMessagesUseCase receiveMessages,
    required SwitchAgentUseCase switchAgent,
    required LoadHistoryUseCase loadHistory,
    required ConnectUseCase connect,
    required ExecuteToolUseCase executeTool,
    required ToolApprovalServiceImpl approvalService,
    required ApprovePlanUseCase approvePlan,
    required RejectPlanUseCase rejectPlan,
    required GetActivePlanUseCase getActivePlan,
    required WatchPlanUpdatesUseCase watchPlanUpdates,
    required Logger logger,
  }) : _sendMessage = sendMessage,
       _sendToolResult = sendToolResult,
       _receiveMessages = receiveMessages,
       _switchAgent = switchAgent,
       _loadHistory = loadHistory,
       _connect = connect,
       _executeTool = executeTool,
       _approvalService = approvalService,
       _approvePlan = approvePlan,
       _rejectPlan = rejectPlan,
       _getActivePlan = getActivePlan,
       _watchPlanUpdates = watchPlanUpdates,
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
    on<PlanReceivedEvent>(_onPlanReceived);
    on<ApprovePlanEvent>(_onApprovePlan);
    on<RejectPlanEvent>(_onRejectPlan);
    on<PlanProgressUpdatedEvent>(_onPlanProgressUpdated);

    // Подписываемся на запросы подтверждения
    _approvalSubscription = _approvalService.approvalRequests.listen((request) {
      add(AgentChatEvent.approvalRequested(request));
    });

    // Устанавливаем callback для выполнения восстановленных tool
    _approvalService.onExecuteRestoredTool = _executeRestoredTool;

    // Устанавливаем callback для отправки rejection на сервер
    _approvalService.onRejectRestoredTool = _rejectRestoredTool;

    // Подписываемся на обновления планов
    _initializePlanUpdates();
  }

  /// Инициализирует подписку на обновления планов
  void _initializePlanUpdates() {
    // Получаем repository для подписки на планы
    // Подписка будет установлена после connect
    _logger.d(
      '[AgentChatBloc] Plan updates subscription will be initialized after connect',
    );
  }

  /// Отправить rejection для восстановленного tool на сервер
  Future<void> _rejectRestoredTool(ToolCall toolCall, String reason) async {
    _logger.i('Rejecting restored tool: ${toolCall.toolName}, reason: $reason');

    // Отправляем rejection на сервер
    await _sendToolResult(
      SendToolResultParams(
        callId: toolCall.id,
        toolName: toolCall.toolName,
        error: 'User rejected: $reason',
      ),
    );

    // Добавляем сообщение об отклонении в UI
    final rejectionMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: MessageContent.toolResult(
        callId: toolCall.id,
        toolName: toolCall.toolName,
        result: none(),
        error: some('User rejected: $reason'),
      ),
      timestamp: DateTime.now(),
      metadata: none(),
    );

    add(AgentChatEvent.messageReceived(rejectionMessage));
  }

  /// Выполнить восстановленный tool после approve
  Future<ToolResult> _executeRestoredTool(ToolCall toolCall) async {
    _logger.i('Executing restored tool: ${toolCall.toolName}');

    // Выполняем tool (без повторного запроса подтверждения)
    final result = await _executeTool(
      ExecuteToolParams(toolCall: toolCall.copyWith(requiresApproval: false)),
    );

    return result.fold(
      (failure) async {
        _logger.e('Restored tool execution failed: ${failure.message}');

        // Отправляем ошибку на сервер
        await _sendToolResult(
          SendToolResultParams(
            callId: toolCall.id,
            toolName: toolCall.toolName,
            error: failure.message,
          ),
        );

        return ToolResult.failure(
          callId: toolCall.id,
          toolName: toolCall.toolName,
          errorCode: 'execution_failed',
          errorMessage: failure.message,
          details: none(),
          failedAt: DateTime.now(),
        );
      },
      (toolResult) async {
        _logger.i('Restored tool executed successfully: ${toolCall.toolName}');

        // Добавляем результат в UI сразу
        final resultMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          content: toolResult.when(
            success: (id, name, data, duration, time) =>
                MessageContent.toolResult(
                  callId: id,
                  toolName: name,
                  result: some(data),
                  error: none(),
                ),
            failure: (id, name, code, msg, details, time) =>
                MessageContent.toolResult(
                  callId: id,
                  toolName: name,
                  result: none(),
                  error: some(msg),
                ),
          ),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        // Добавляем сообщение в чат
        add(AgentChatEvent.messageReceived(resultMessage));

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

        return toolResult;
      },
    );
  }

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

  Future<void> _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d(
      '[AgentChatBloc] 📨 Message received: ${event.message.role}, content type: ${event.message.content.runtimeType}',
    );

    // Обновляем текущего агента если это agent_switched
    String newAgent = state.currentAgent;
    event.message.content.maybeWhen(
      agentSwitch: (from, to, reason) {
        // Проверяем, что toAgent не пустой
        if (to.isNotEmpty) {
          newAgent = to;
          _logger.i(
            'Agent switched: ${from.isNotEmpty ? from : "unknown"} → $to',
          );
        } else {
          _logger.w('Agent switch message received but toAgent is empty');
        }
      },
      orElse: () {},
    );

    // Проверяем, есть ли метаданные планирования
    final isPlanNotification = _handlePlanMetadata(event.message);

    emit(
      state.copyWith(
        messages: [...state.messages, event.message],
        currentAgent: newAgent,
        isLoading: false,
      ),
    );

    // Если получен план, вызываем событие planReceived
    if (isPlanNotification) {
      _logger.i('[AgentChatBloc] 📋 Triggering planReceived event');
      // План уже сохранен в repository, получаем его
      final planResult = await _getActivePlan(const NoParams());
      planResult.fold(
        (failure) => _logger.e(
          '[AgentChatBloc] Failed to get active plan: ${failure.message}',
        ),
        (planOption) => planOption.fold(
          () => _logger.w('[AgentChatBloc] No active plan found'),
          (plan) => add(AgentChatEvent.planReceived(plan)),
        ),
      );
    }

    // Автоматически выполняем tool calls
    await event.message.content.maybeWhen(
      toolCall: (callId, toolName, arguments) async {
        _logger.i('Executing tool: $toolName');

        // Получаем флаг requiresApproval из сообщения
        // Проверяем WSMessage для получения фактического значения
        bool requiresApproval = false;

        // Пытаемся получить requiresApproval из metadata сообщения
        event.message.metadata?.fold(() => null, (meta) {
          if (meta.containsKey('requires_approval')) {
            requiresApproval = meta['requires_approval'] as bool? ?? false;
          }
        });

        final toolCall = ToolCall(
          id: callId,
          toolName: toolName,
          arguments: arguments,
          requiresApproval: requiresApproval,
          createdAt: DateTime.now(),
        );

        final result = await _executeTool(
          ExecuteToolParams(toolCall: toolCall),
        );

        result.fold(
          (failure) async {
            _logger.e('Tool execution failed: ${failure.message}');
            // Send error result back to server using dedicated use case
            await _sendToolResult(
              SendToolResultParams(
                callId: callId,
                toolName: toolName,
                error: failure.message,
              ),
            );
          },
          (toolResult) async {
            _logger.i('Tool executed successfully: $toolName');
            // Send result back to server using when for exhaustive matching
            await toolResult.when(
              success: (id, name, data, duration, time) async {
                await _sendToolResult(
                  SendToolResultParams(
                    callId: callId,
                    toolName: toolName,
                    result: data,
                  ),
                );
              },
              failure: (id, name, code, msg, details, time) async {
                await _sendToolResult(
                  SendToolResultParams(
                    callId: callId,
                    toolName: toolName,
                    error: msg,
                  ),
                );
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
    _logger.d(
      '[AgentChatBloc] 📜 Loading history for session: ${event.sessionId}',
    );
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
    _logger.d('[AgentChatBloc] 🔌 Connecting to session: ${event.sessionId}');
    emit(state.copyWith(isLoading: true, error: none()));

    // Подключаемся к WebSocket через use case
    final connectResult = await _connect(
      ConnectParams(sessionId: event.sessionId),
    );

    await connectResult.fold(
      (failure) async {
        _logger.e('Failed to connect: ${failure.message}');
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
        return;
      },
      (_) async {
        _logger.i('Connected to WebSocket: ${event.sessionId}');

        // Подписываемся на поток сообщений
        _messageSubscription?.cancel();
        _messageSubscription = _receiveMessages(const NoParams()).listen((
          either,
        ) {
          either.fold(
            (failure) => add(AgentChatEvent.error(failure)),
            (message) => add(AgentChatEvent.messageReceived(message)),
          );
        });

        // ВАЖНО: Восстанавливаем ожидающие подтверждения с сервера
        // Это позволяет продолжить работу после перезапуска/переустановки IDE
        try {
          await _approvalService.restorePendingApprovals(event.sessionId);
          _logger.i('Pending approvals restored successfully');
        } catch (e) {
          _logger.e('Failed to restore pending approvals: $e');
          // Не блокируем подключение из-за ошибки восстановления
        }

        // Подписываемся на обновления планов
        _planUpdatesSubscription?.cancel();
        _planUpdatesSubscription = _watchPlanUpdates(const NoParams()).listen((either) {
          either.fold(
            (failure) => _logger.e(
              '[AgentChatBloc] Plan update error: ${failure.message}',
            ),
            (plan) {
              _logger.i(
                '[AgentChatBloc] Plan update received: ${plan.planId}',
              );
              add(AgentChatEvent.planReceived(plan));
            },
          );
        });
        _logger.i('[AgentChatBloc] Subscribed to plan updates');

        emit(state.copyWith(isConnected: true, isLoading: false));
      },
    );
  }

  Future<void> _onDisconnect(
    DisconnectEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d('[AgentChatBloc] 🔌 Disconnecting from chat');
    await _messageSubscription?.cancel();
    _messageSubscription = null;

    emit(
      state.copyWith(
        isConnected: false,
        messages: const [],
        isLoading: false,
        error: none(),
        pendingApproval: none(),
      ),
    );

    _logger.i('[AgentChatBloc] ✅ Disconnected from chat');
  }

  Future<void> _onError(ErrorEvent event, Emitter<AgentChatState> emit) async {
    _logger.e('Chat error: ${event.failure.message}');
    emit(state.copyWith(error: some(event.failure.message), isLoading: false));
  }

  Future<void> _onApprovalRequested(
    ApprovalRequestedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i(
      '[AgentChatBloc] 🔔 Tool approval requested: ${event.request.toolCall.toolName}',
    );
    emit(state.copyWith(pendingApproval: some(event.request)));
  }

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
        request.completer.complete(const ApprovalDecision.approved());
        emit(state.copyWith(pendingApproval: none()));
      },
    );
  }

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
          ApprovalDecision.rejected(reason: some(event.reason)),
        );
        emit(state.copyWith(pendingApproval: none()));
      },
    );
  }

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
        request.completer.complete(const ApprovalDecision.cancelled());
        emit(state.copyWith(pendingApproval: none()));
      },
    );
  }

  /// Обрабатывает метаданные планирования из сообщения
  /// Возвращает true если это plan_notification
  bool _handlePlanMetadata(Message message) {
    return message.metadata?.fold(() => false, (meta) {
          // Проверяем, есть ли информация о плане
          // Backend отправляет plan_id и subtasks в metadata
          if (meta.containsKey('plan_id') && meta.containsKey('subtasks')) {
            _logger.i(
              '[AgentChatBloc] 📋 Plan notification detected: plan_id=${meta['plan_id']}, subtasks=${(meta['subtasks'] as List?)?.length ?? 0}',
            );
            return true;
          }
          return false;
        }) ??
        false;
  }

  Future<void> _onPlanReceived(
    PlanReceivedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i(
      '[AgentChatBloc] 📋 Plan received: ${event.plan.planId} with ${event.plan.subtasks.length} subtasks',
    );

    emit(
      state.copyWith(
        activePlan: some(event.plan),
        isPlanPendingConfirmation: event.plan.isPendingConfirmation,
      ),
    );
  }

  Future<void> _onApprovePlan(
    ApprovePlanEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i('[AgentChatBloc] ✅ Approving plan: ${event.planId}');

    emit(state.copyWith(isLoading: true));

    final result = await _approvePlan(
      ApprovePlanParams(
        planId: event.planId,
        feedback: event.feedback ?? none(),
      ),
    );

    result.fold(
      (failure) {
        _logger.e(
          '[AgentChatBloc] ❌ Failed to approve plan: ${failure.message}',
        );
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) {
        _logger.i('[AgentChatBloc] ✅ Plan approved successfully');

        // Обновляем локальное состояние плана
        final updatedPlan = state.activePlan.map((plan) => plan.approve());

        emit(
          state.copyWith(
            isLoading: false,
            activePlan: updatedPlan,
            isPlanPendingConfirmation: false,
          ),
        );
      },
    );
  }

  Future<void> _onRejectPlan(
    RejectPlanEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i(
      '[AgentChatBloc] ❌ Rejecting plan: ${event.planId}, reason: ${event.reason}',
    );

    emit(state.copyWith(isLoading: true));

    final result = await _rejectPlan(
      RejectPlanParams(planId: event.planId, reason: event.reason),
    );

    result.fold(
      (failure) {
        _logger.e(
          '[AgentChatBloc] ❌ Failed to reject plan: ${failure.message}',
        );
        emit(state.copyWith(isLoading: false, error: some(failure.message)));
      },
      (_) {
        _logger.i('[AgentChatBloc] ✅ Plan rejected successfully');

        // Очищаем план
        emit(
          state.copyWith(
            isLoading: false,
            activePlan: none(),
            isPlanPendingConfirmation: false,
          ),
        );
      },
    );
  }

  Future<void> _onPlanProgressUpdated(
    PlanProgressUpdatedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.d(
      '[AgentChatBloc] 📊 Plan progress updated: ${event.plan.progress * 100}%',
    );

    emit(
      state.copyWith(
        activePlan: some(event.plan),
        isPlanPendingConfirmation: event.plan.isPendingConfirmation,
      ),
    );
  }

  @override
  Future<void> close() async {
    _logger.d('[AgentChatBloc] 🔒 Closing bloc');
    await _messageSubscription?.cancel();
    await _approvalSubscription?.cancel();
    await _planUpdatesSubscription?.cancel();
    return super.close();
  }
}
