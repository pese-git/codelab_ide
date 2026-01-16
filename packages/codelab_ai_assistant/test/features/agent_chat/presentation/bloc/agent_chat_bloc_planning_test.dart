// Unit тесты для AgentChatBloc - функциональность планирования
import 'package:bloc_test/bloc_test.dart';
import 'package:codelab_ai_assistant/core/error/failures.dart';
import 'package:codelab_ai_assistant/core/usecases/usecase.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/execution_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/message.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/approve_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/connect.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/get_active_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/load_history.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/receive_messages.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/reject_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/send_message.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/send_tool_result.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/switch_agent.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/watch_plan_updates.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/bloc/agent_chat_bloc.dart';
import 'package:codelab_ai_assistant/features/tool_execution/data/services/tool_approval_service_impl.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/usecases/execute_tool.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Моки для use cases
class MockSendMessageUseCase extends Mock implements SendMessageUseCase {}
class MockSendToolResultUseCase extends Mock implements SendToolResultUseCase {}
class MockReceiveMessagesUseCase extends Mock implements ReceiveMessagesUseCase {}
class MockSwitchAgentUseCase extends Mock implements SwitchAgentUseCase {}
class MockLoadHistoryUseCase extends Mock implements LoadHistoryUseCase {}
class MockConnectUseCase extends Mock implements ConnectUseCase {}
class MockExecuteToolUseCase extends Mock implements ExecuteToolUseCase {}
class MockToolApprovalService extends Mock implements ToolApprovalServiceImpl {}
class MockApprovePlanUseCase extends Mock implements ApprovePlanUseCase {}
class MockRejectPlanUseCase extends Mock implements RejectPlanUseCase {}
class MockGetActivePlanUseCase extends Mock implements GetActivePlanUseCase {}
class MockWatchPlanUpdatesUseCase extends Mock implements WatchPlanUpdatesUseCase {}
class MockLogger extends Mock implements Logger {}

void main() {
  late MockSendMessageUseCase mockSendMessage;
  late MockSendToolResultUseCase mockSendToolResult;
  late MockReceiveMessagesUseCase mockReceiveMessages;
  late MockSwitchAgentUseCase mockSwitchAgent;
  late MockLoadHistoryUseCase mockLoadHistory;
  late MockConnectUseCase mockConnect;
  late MockExecuteToolUseCase mockExecuteTool;
  late MockToolApprovalService mockApprovalService;
  late MockApprovePlanUseCase mockApprovePlan;
  late MockRejectPlanUseCase mockRejectPlan;
  late MockGetActivePlanUseCase mockGetActivePlan;
  late MockWatchPlanUpdatesUseCase mockWatchPlanUpdates;
  late MockLogger mockLogger;

  setUp(() {
    mockSendMessage = MockSendMessageUseCase();
    mockSendToolResult = MockSendToolResultUseCase();
    mockReceiveMessages = MockReceiveMessagesUseCase();
    mockSwitchAgent = MockSwitchAgentUseCase();
    mockLoadHistory = MockLoadHistoryUseCase();
    mockConnect = MockConnectUseCase();
    mockExecuteTool = MockExecuteToolUseCase();
    mockApprovalService = MockToolApprovalService();
    mockApprovePlan = MockApprovePlanUseCase();
    mockRejectPlan = MockRejectPlanUseCase();
    mockGetActivePlan = MockGetActivePlanUseCase();
    mockWatchPlanUpdates = MockWatchPlanUpdatesUseCase();
    mockLogger = MockLogger();

    // Настройка fallback значений для mocktail
    registerFallbackValue(const NoParams());
    registerFallbackValue(SendMessageParams(text: '', metadata: none()));
    registerFallbackValue(ApprovePlanParams(planId: ''));
    registerFallbackValue(RejectPlanParams(planId: '', reason: ''));

    // Настройка дефолтных ответов
    when(() => mockApprovalService.approvalRequests).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => mockWatchPlanUpdates(any())).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => mockLogger.d(any())).thenReturn(null);
    when(() => mockLogger.i(any())).thenReturn(null);
    when(() => mockLogger.e(any())).thenReturn(null);
    when(() => mockLogger.w(any())).thenReturn(null);
  });

  AgentChatBloc createBloc() {
    return AgentChatBloc(
      sendMessage: mockSendMessage,
      sendToolResult: mockSendToolResult,
      receiveMessages: mockReceiveMessages,
      switchAgent: mockSwitchAgent,
      loadHistory: mockLoadHistory,
      connect: mockConnect,
      executeTool: mockExecuteTool,
      approvalService: mockApprovalService,
      approvePlan: mockApprovePlan,
      rejectPlan: mockRejectPlan,
      getActivePlan: mockGetActivePlan,
      watchPlanUpdates: mockWatchPlanUpdates,
      logger: mockLogger,
    );
  }

  group('AgentChatBloc - Planning', () {
    test('начальное состояние не содержит активного плана', () {
      final bloc = createBloc();
      
      expect(bloc.state.activePlan.isNone(), true);
      expect(bloc.state.isPlanPendingConfirmation, false);
      
      bloc.close();
    });

    blocTest<AgentChatBloc, AgentChatState>(
      'PlanReceivedEvent устанавливает активный план',
      build: createBloc,
      act: (bloc) {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        bloc.add(AgentChatEvent.planReceived(plan));
      },
      expect: () => [
        predicate<AgentChatState>((state) {
          return state.activePlan.isSome() &&
                 state.isPlanPendingConfirmation == true;
        }),
      ],
      verify: (bloc) {
        expect(bloc.state.activePlan.isSome(), true);
        bloc.state.activePlan.fold(
          () => fail('Should have active plan'),
          (plan) {
            expect(plan.planId, 'plan-123');
            expect(plan.subtasks.length, 1);
            expect(plan.isPendingConfirmation, true);
          },
        );
      },
    );

    blocTest<AgentChatBloc, AgentChatState>(
      'ApprovePlanEvent вызывает use case и обновляет состояние',
      build: createBloc,
      setUp: () {
        when(() => mockApprovePlan(any()))
            .thenAnswer((_) async => right(unit));
      },
      seed: () {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        return AgentChatState.initial().copyWith(
          activePlan: some(plan),
          isPlanPendingConfirmation: true,
        );
      },
      act: (bloc) {
        bloc.add(const AgentChatEvent.approvePlan('plan-123'));
      },
      expect: () => [
        // isLoading = true
        predicate<AgentChatState>((state) => state.isLoading == true),
        // isLoading = false, plan approved
        predicate<AgentChatState>((state) {
          return state.isLoading == false &&
                 state.isPlanPendingConfirmation == false;
        }),
      ],
      verify: (bloc) {
        verify(() => mockApprovePlan(any())).called(1);
        
        expect(bloc.state.isPlanPendingConfirmation, false);
      },
    );

    blocTest<AgentChatBloc, AgentChatState>(
      'ApprovePlanEvent с feedback передает его в use case',
      build: createBloc,
      setUp: () {
        when(() => mockApprovePlan(any()))
            .thenAnswer((_) async => right(unit));
      },
      seed: () {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        return AgentChatState.initial().copyWith(
          activePlan: some(plan),
          isPlanPendingConfirmation: true,
        );
      },
      act: (bloc) {
        bloc.add(const AgentChatEvent.approvePlan(
          'plan-123',
          feedback: Some('Looks good'),
        ));
      },
      verify: (bloc) {
        verify(() => mockApprovePlan(any())).called(1);
      },
    );

    blocTest<AgentChatBloc, AgentChatState>(
      'ApprovePlanEvent обрабатывает ошибку',
      build: createBloc,
      setUp: () {
        when(() => mockApprovePlan(any()))
            .thenAnswer((_) async => left(Failure.network('Connection failed')));
      },
      seed: () {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        return AgentChatState.initial().copyWith(
          activePlan: some(plan),
          isPlanPendingConfirmation: true,
        );
      },
      act: (bloc) {
        bloc.add(const AgentChatEvent.approvePlan('plan-123'));
      },
      expect: () => [
        // isLoading = true
        predicate<AgentChatState>((state) => state.isLoading == true),
        // isLoading = false, error set
        predicate<AgentChatState>((state) {
          return state.isLoading == false &&
                 state.error.isSome();
        }),
      ],
      verify: (bloc) {
        expect(bloc.state.error.isSome(), true);
        bloc.state.error.fold(
          () => fail('Should have error'),
          (error) => expect(error, contains('Connection failed')),
        );
      },
    );

    blocTest<AgentChatBloc, AgentChatState>(
      'RejectPlanEvent вызывает use case и очищает план',
      build: createBloc,
      setUp: () {
        when(() => mockRejectPlan(any()))
            .thenAnswer((_) async => right(unit));
      },
      seed: () {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        return AgentChatState.initial().copyWith(
          activePlan: some(plan),
          isPlanPendingConfirmation: true,
        );
      },
      act: (bloc) {
        bloc.add(const AgentChatEvent.rejectPlan('plan-123', 'Too complex'));
      },
      expect: () => [
        // isLoading = true
        predicate<AgentChatState>((state) => state.isLoading == true),
        // isLoading = false, plan cleared
        predicate<AgentChatState>((state) {
          return state.isLoading == false &&
                 state.activePlan.isNone() &&
                 state.isPlanPendingConfirmation == false;
        }),
      ],
      verify: (bloc) {
        verify(() => mockRejectPlan(any())).called(1);
        
        expect(bloc.state.activePlan.isNone(), true);
        expect(bloc.state.isPlanPendingConfirmation, false);
      },
    );

    blocTest<AgentChatBloc, AgentChatState>(
      'RejectPlanEvent обрабатывает ошибку',
      build: createBloc,
      setUp: () {
        when(() => mockRejectPlan(any()))
            .thenAnswer((_) async => left(Failure.server('Server error')));
      },
      seed: () {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        return AgentChatState.initial().copyWith(
          activePlan: some(plan),
          isPlanPendingConfirmation: true,
        );
      },
      act: (bloc) {
        bloc.add(const AgentChatEvent.rejectPlan('plan-123', 'Too complex'));
      },
      expect: () => [
        // isLoading = true
        predicate<AgentChatState>((state) => state.isLoading == true),
        // isLoading = false, error set
        predicate<AgentChatState>((state) {
          return state.isLoading == false &&
                 state.error.isSome();
        }),
      ],
      verify: (bloc) {
        expect(bloc.state.error.isSome(), true);
        bloc.state.error.fold(
          () => fail('Should have error'),
          (error) => expect(error, contains('Server error')),
        );
      },
    );

    blocTest<AgentChatBloc, AgentChatState>(
      'PlanProgressUpdatedEvent обновляет план',
      build: createBloc,
      seed: () {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        return AgentChatState.initial().copyWith(
          activePlan: some(plan),
        );
      },
      act: (bloc) {
        final updatedPlan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ).markCompleted(),
          ],
        );
        
        bloc.add(AgentChatEvent.planProgressUpdated(updatedPlan));
      },
      expect: () => [
        predicate<AgentChatState>((state) {
          return state.activePlan.isSome();
        }),
      ],
      verify: (bloc) {
        bloc.state.activePlan.fold(
          () => fail('Should have active plan'),
          (plan) {
            expect(plan.subtasks[0].status, SubtaskStatus.completed);
            expect(plan.progress, 1.0);
          },
        );
      },
    );

    blocTest<AgentChatBloc, AgentChatState>(
      'PlanProgressUpdatedEvent обновляет isPendingConfirmation',
      build: createBloc,
      seed: () {
        final plan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        );
        
        return AgentChatState.initial().copyWith(
          activePlan: some(plan),
          isPlanPendingConfirmation: true,
        );
      },
      act: (bloc) {
        final approvedPlan = ExecutionPlan.create(
          planId: 'plan-123',
          sessionId: 'session-1',
          originalTask: 'Build feature',
          subtasks: [
            Subtask.pending(
              id: 'task-1',
              description: 'First task',
              agent: 'coder',
            ),
          ],
        ).approve();
        
        bloc.add(AgentChatEvent.planProgressUpdated(approvedPlan));
      },
      verify: (bloc) {
        expect(bloc.state.isPlanPendingConfirmation, false);
      },
    );
  });
}
