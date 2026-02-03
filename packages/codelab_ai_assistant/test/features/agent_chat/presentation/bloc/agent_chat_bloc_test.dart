import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codelab_ai_assistant/core/error/failures.dart';
import 'package:codelab_ai_assistant/core/usecases/usecase.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/agent.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/message.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/load_history.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/send_message.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/send_plan_decision.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/switch_agent.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/bloc/agent_chat_bloc.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/middleware/connection_middleware.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/middleware/message_handler_middleware.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/middleware/approval_middleware.dart';

// Моки для middleware
class MockConnectionMiddleware extends Mock implements ConnectionMiddleware {}
class MockMessageHandlerMiddleware extends Mock implements MessageHandlerMiddleware {}
class MockApprovalMiddleware extends Mock implements ApprovalMiddleware {}

// Моки для use cases
class MockSendMessageUseCase extends Mock implements SendMessageUseCase {}
class MockSwitchAgentUseCase extends Mock implements SwitchAgentUseCase {}
class MockLoadHistoryUseCase extends Mock implements LoadHistoryUseCase {}
class MockSendPlanDecisionUseCase extends Mock implements SendPlanDecisionUseCase {}
class MockLogger extends Mock implements Logger {}

// Fake классы для регистрации fallback значений
class FakeSendMessageParams extends Fake implements SendMessageParams {}
class FakeSwitchAgentParams extends Fake implements SwitchAgentParams {}
class FakeLoadHistoryParams extends Fake implements LoadHistoryParams {}
class FakeSendPlanDecisionParams extends Fake implements SendPlanDecisionParams {}
class FakeMessage extends Fake implements Message {}

void main() {
  late AgentChatBloc bloc;
  late MockConnectionMiddleware mockConnectionMiddleware;
  late MockMessageHandlerMiddleware mockMessageHandlerMiddleware;
  late MockApprovalMiddleware mockApprovalMiddleware;
  late MockSendMessageUseCase mockSendMessage;
  late MockSwitchAgentUseCase mockSwitchAgent;
  late MockLoadHistoryUseCase mockLoadHistory;
  late MockSendPlanDecisionUseCase mockSendPlanDecision;
  late MockLogger mockLogger;

  setUpAll(() {
    // Регистрируем fallback значения для всех Params классов
    registerFallbackValue(FakeSendMessageParams());
    registerFallbackValue(FakeSwitchAgentParams());
    registerFallbackValue(FakeLoadHistoryParams());
    registerFallbackValue(FakeSendPlanDecisionParams());
    registerFallbackValue(FakeMessage());
  });

  setUp(() {
    mockConnectionMiddleware = MockConnectionMiddleware();
    mockMessageHandlerMiddleware = MockMessageHandlerMiddleware();
    mockApprovalMiddleware = MockApprovalMiddleware();
    mockSendMessage = MockSendMessageUseCase();
    mockSwitchAgent = MockSwitchAgentUseCase();
    mockLoadHistory = MockLoadHistoryUseCase();
    mockSendPlanDecision = MockSendPlanDecisionUseCase();
    mockLogger = MockLogger();

    // Настройка дефолтных моков для middleware
    when(() => mockApprovalMiddleware.startListening(
      onToolApproval: any(named: 'onToolApproval'),
    )).thenReturn(null);
    
    when(() => mockConnectionMiddleware.dispose())
        .thenAnswer((_) async => {});
    when(() => mockApprovalMiddleware.dispose())
        .thenAnswer((_) async => {});

    bloc = AgentChatBloc(
      connectionMiddleware: mockConnectionMiddleware,
      messageHandlerMiddleware: mockMessageHandlerMiddleware,
      approvalMiddleware: mockApprovalMiddleware,
      sendMessage: mockSendMessage,
      switchAgent: mockSwitchAgent,
      loadHistory: mockLoadHistory,
      sendPlanDecision: mockSendPlanDecision,
      logger: mockLogger,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AgentChatBloc', () {
    group('initial state', () {
      test('should have correct initial state', () {
        expect(bloc.state.messages, isEmpty);
        expect(bloc.state.isLoading, false);
        expect(bloc.state.isConnected, false);
        expect(bloc.state.currentAgent, AgentType.orchestrator);
        expect(bloc.state.error.isNone(), true);
        expect(bloc.state.pendingApproval.isNone(), true);
        expect(bloc.state.pendingPlanApproval.isNone(), true);
      });

      test('should start listening for approvals on initialization', () {
        verify(() => mockApprovalMiddleware.startListening(
          onToolApproval: any(named: 'onToolApproval'),
        )).called(1);
      });
    });

    group('SendMessageEvent', () {
      const testMessage = 'Test message';

      blocTest<AgentChatBloc, AgentChatState>(
        'emits loading and success states when message is sent successfully',
        build: () {
          when(() => mockSendMessage(any())).thenAnswer(
            (_) async => right(unit),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AgentChatEvent.sendMessage(testMessage)),
        expect: () => [
          // Состояние с добавленным сообщением пользователя и loading
          predicate<AgentChatState>((state) {
            return state.messages.length == 1 &&
                state.messages.first.role == MessageRole.user &&
                state.isLoading == true;
          }),
          // Состояние после успешной отправки
          predicate<AgentChatState>((state) {
            return state.messages.length == 1 &&
                state.isLoading == false &&
                state.error.isNone();
          }),
        ],
        verify: (_) {
          verify(() => mockSendMessage(any())).called(1);
        },
      );

      blocTest<AgentChatBloc, AgentChatState>(
        'emits error state when message sending fails',
        build: () {
          when(() => mockSendMessage(any())).thenAnswer(
            (_) async => left(const Failure.network('Connection failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AgentChatEvent.sendMessage(testMessage)),
        expect: () => [
          // Состояние с loading
          predicate<AgentChatState>((state) => state.isLoading == true),
          // Состояние с ошибкой
          predicate<AgentChatState>((state) {
            return state.isLoading == false &&
                state.error.isSome() &&
                state.error.toNullable()!.contains('Connection failed');
          }),
        ],
      );
    });

    group('ConnectEvent', () {
      const testSessionId = 'test-session-123';

      blocTest<AgentChatBloc, AgentChatState>(
        'emits connected state when connection succeeds',
        build: () {
          when(() => mockConnectionMiddleware.connect(
            sessionId: any(named: 'sessionId'),
            onMessage: any(named: 'onMessage'),
            onError: any(named: 'onError'),
          )).thenAnswer((_) async => right(unit));
          
          when(() => mockApprovalMiddleware.restorePendingApprovals(any()))
              .thenAnswer((_) async => 0);
          
          return bloc;
        },
        act: (bloc) => bloc.add(const AgentChatEvent.connect(testSessionId)),
        expect: () => [
          // Loading state
          predicate<AgentChatState>((state) => state.isLoading == true),
          // Connected state
          predicate<AgentChatState>((state) {
            return state.isConnected == true && state.isLoading == false;
          }),
        ],
        verify: (_) {
          verify(() => mockConnectionMiddleware.connect(
            sessionId: testSessionId,
            onMessage: any(named: 'onMessage'),
            onError: any(named: 'onError'),
          )).called(1);
          verify(() => mockApprovalMiddleware.restorePendingApprovals(testSessionId))
              .called(1);
        },
      );

      blocTest<AgentChatBloc, AgentChatState>(
        'emits error state when connection fails',
        build: () {
          when(() => mockConnectionMiddleware.connect(
            sessionId: any(named: 'sessionId'),
            onMessage: any(named: 'onMessage'),
            onError: any(named: 'onError'),
          )).thenAnswer(
            (_) async => left(const Failure.network('Connection timeout')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AgentChatEvent.connect(testSessionId)),
        expect: () => [
          predicate<AgentChatState>((state) => state.isLoading == true),
          predicate<AgentChatState>((state) {
            return state.isLoading == false &&
                state.error.isSome() &&
                state.error.toNullable()!.contains('Connection timeout');
          }),
        ],
      );
    });

    group('LoadHistoryEvent', () {
      const testSessionId = 'test-session-123';

      blocTest<AgentChatBloc, AgentChatState>(
        'loads history successfully',
        build: () {
          final testMessages = [
            Message(
              id: '1',
              role: MessageRole.user,
              content: const MessageContent.text(text: 'Hello', isFinal: true),
              timestamp: DateTime.now(),
              metadata: none(),
            ),
            Message(
              id: '2',
              role: MessageRole.assistant,
              content: const MessageContent.text(text: 'Hi!', isFinal: true),
              timestamp: DateTime.now(),
              metadata: none(),
            ),
          ];

          when(() => mockLoadHistory(any())).thenAnswer(
            (_) async => right(testMessages),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AgentChatEvent.loadHistory(testSessionId)),
        expect: () => [
          predicate<AgentChatState>((state) => state.isLoading == true),
          predicate<AgentChatState>((state) {
            return state.messages.length == 2 &&
                state.isLoading == false &&
                state.error.isNone();
          }),
        ],
      );

      blocTest<AgentChatBloc, AgentChatState>(
        'handles history loading failure',
        build: () {
          when(() => mockLoadHistory(any())).thenAnswer(
            (_) async => left(const Failure.server('Failed to load history')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AgentChatEvent.loadHistory(testSessionId)),
        expect: () => [
          predicate<AgentChatState>((state) => state.isLoading == true),
          predicate<AgentChatState>((state) {
            return state.isLoading == false && state.error.isSome();
          }),
        ],
      );
    });

    group('SwitchAgentEvent', () {
      const testAgentType = AgentType.code;
      const testContent = 'Switch to coder';

      blocTest<AgentChatBloc, AgentChatState>(
        'switches agent successfully',
        build: () {
          when(() => mockSwitchAgent(any())).thenAnswer(
            (_) async => right(unit),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AgentChatEvent.switchAgent(testAgentType, testContent),
        ),
        expect: () => [
          predicate<AgentChatState>((state) => state.isLoading == true),
          predicate<AgentChatState>((state) {
            return state.currentAgent == testAgentType &&
                state.isLoading == false;
          }),
        ],
      );
    });

    group('DisconnectEvent', () {
      blocTest<AgentChatBloc, AgentChatState>(
        'disconnects and clears state',
        build: () {
          when(() => mockConnectionMiddleware.disconnect())
              .thenAnswer((_) async => {});
          when(() => mockApprovalMiddleware.clearActiveCompleters())
              .thenReturn(null);
          return bloc;
        },
        seed: () => AgentChatState(
          messages: [
            Message(
              id: '1',
              role: MessageRole.user,
              content: const MessageContent.text(text: 'Test', isFinal: true),
              timestamp: DateTime.now(),
              metadata: none(),
            ),
          ],
          isLoading: false,
          isConnected: true,
          currentAgent: AgentType.orchestrator,
          error: none(),
          pendingApproval: none(),
          pendingPlanApproval: none(),
        ),
        act: (bloc) => bloc.add(const AgentChatEvent.disconnect()),
        expect: () => [
          predicate<AgentChatState>((state) {
            return state.isConnected == false &&
                state.messages.isEmpty &&
                state.pendingApproval.isNone();
          }),
        ],
        verify: (_) {
          verify(() => mockConnectionMiddleware.disconnect()).called(1);
          verify(() => mockApprovalMiddleware.clearActiveCompleters()).called(1);
        },
      );
    });

    group('MessageReceivedEvent', () {
      test('updates current agent on agent_switched message', () async {
        final agentSwitchMessage = Message(
          id: '1',
          role: MessageRole.system,
          content: MessageContent.agentSwitch(
            fromAgent: AgentType.orchestrator,
            toAgent: AgentType.code,
            reason: some('User requested'),
          ),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        when(() => mockMessageHandlerMiddleware.handleMessage(
          message: any(named: 'message'),
          onPlanApproval: any(named: 'onPlanApproval'),
        )).thenAnswer((_) async => some(AgentType.code));

        bloc.add(AgentChatEvent.messageReceived(agentSwitchMessage));

        await expectLater(
          bloc.stream,
          emits(
            predicate<AgentChatState>((state) {
              return state.currentAgent == AgentType.code &&
                  state.messages.length == 1;
            }),
          ),
        );
      });

      test('sets pending plan approval on plan_approval_required', () async {
        final planApprovalMessage = Message(
          id: '1',
          role: MessageRole.system,
          content: const MessageContent.planApprovalRequired(
            approvalRequestId: 'req-123',
            planId: 'plan-456',
            planSummary: {'title': 'Test Plan'},
            content: 'Please approve',
          ),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        when(() => mockMessageHandlerMiddleware.handleMessage(
          message: any(named: 'message'),
          onPlanApproval: any(named: 'onPlanApproval'),
        )).thenAnswer((_) async => none());

        bloc.add(AgentChatEvent.messageReceived(planApprovalMessage));

        await expectLater(
          bloc.stream,
          emits(
            predicate<AgentChatState>((state) {
              return state.pendingPlanApproval.isSome();
            }),
          ),
        );
      });
    });

    group('SendPlanDecisionEvent', () {
      const testApprovalRequestId = 'req-123';
      const testPlanId = 'plan-456';
      const testDecision = 'approve';

      blocTest<AgentChatBloc, AgentChatState>(
        'sends plan decision successfully',
        build: () {
          when(() => mockSendPlanDecision(any())).thenAnswer(
            (_) async => right(unit),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AgentChatEvent.sendPlanDecision(
            approvalRequestId: testApprovalRequestId,
            planId: testPlanId,
            decision: testDecision,
          ),
        ),
        expect: () => [
          predicate<AgentChatState>((state) => state.isLoading == true),
          predicate<AgentChatState>((state) {
            return state.isLoading == false &&
                state.pendingPlanApproval.isNone();
          }),
        ],
        verify: (_) {
          verify(
            () => mockSendPlanDecision(
              SendPlanDecisionParams(
                approvalRequestId: testApprovalRequestId,
                planId: testPlanId,
                decision: testDecision,
                feedback: null,
              ),
            ),
          ).called(1);
        },
      );
    });
  });
}
