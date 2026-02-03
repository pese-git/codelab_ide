import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codelab_ai_assistant/core/error/exceptions.dart';
import 'package:codelab_ai_assistant/core/error/failures.dart';
import 'package:codelab_ai_assistant/features/agent_chat/data/datasources/agent_remote_datasource.dart';
import 'package:codelab_ai_assistant/features/agent_chat/data/datasources/gateway_api.dart';
import 'package:codelab_ai_assistant/features/agent_chat/data/models/message_model.dart';
import 'package:codelab_ai_assistant/features/agent_chat/data/repositories/agent_repository_impl.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/agent.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/message.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/repositories/agent_repository.dart';
import 'package:codelab_ai_assistant/features/session_management/data/models/session_models.dart';

// Моки
class MockAgentRemoteDataSource extends Mock implements AgentRemoteDataSource {}
class MockGatewayApi extends Mock implements GatewayApi {}

// Fake для регистрации
class FakeMessageModel extends Fake implements MessageModel {}

void main() {
  late AgentRepository repository;
  late MockAgentRemoteDataSource mockRemoteDataSource;
  late MockGatewayApi mockGatewayApi;

  setUpAll(() {
    registerFallbackValue(FakeMessageModel());
  });

  setUp(() {
    mockRemoteDataSource = MockAgentRemoteDataSource();
    mockGatewayApi = MockGatewayApi();

    repository = AgentRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      gatewayApi: mockGatewayApi,
    );
  });

  group('AgentRepositoryImpl', () {
    group('sendMessage', () {
      const testText = 'Test message';
      final testParams = SendMessageParams(text: testText, metadata: none());

      test('returns Right(unit) when message is sent successfully', () async {
        // Arrange
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendMessage(testParams);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.sendMessage(any())).called(1);
      });

      test('returns Left(Failure.network) when WebSocketException occurs',
          () async {
        // Arrange
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenThrow(WebSocketException('Connection lost'));

        // Act
        final result = await repository.sendMessage(testParams);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<Failure>());
            expect(failure.message, contains('Connection lost'));
          },
          (_) => fail('Should return Left'),
        );
      });

      test('returns Left(Failure.unknown) when unknown exception occurs',
          () async {
        // Arrange
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenThrow(Exception('Unknown error'));

        // Act
        final result = await repository.sendMessage(testParams);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<Failure>());
            expect(failure.message, contains('Failed to send message'));
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('sendToolResult', () {
      const testCallId = 'call-123';
      const testToolName = 'read_file';
      final testResult = {'content': 'file content'};

      test('returns Right(unit) when tool result is sent successfully',
          () async {
        // Arrange
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendToolResult(
          callId: testCallId,
          toolName: testToolName,
          result: testResult,
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.sendMessage(any())).called(1);
      });

      test('sends error when error parameter is provided', () async {
        // Arrange
        const testError = 'File not found';
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendToolResult(
          callId: testCallId,
          toolName: testToolName,
          error: testError,
        );

        // Assert
        expect(result.isRight(), true);
        final captured = verify(
          () => mockRemoteDataSource.sendMessage(captureAny()),
        ).captured;
        final sentModel = captured.first as MessageModel;
        expect(sentModel.error, testError);
      });
    });

    group('receiveMessages', () {
      test('returns stream of Right(Message) when messages are received',
          () async {
        // Arrange
        final testMessageModel = MessageModel(
          type: 'assistant_message',
          content: 'Test response',
          isFinal: true,
        );

        when(() => mockRemoteDataSource.receiveMessages())
            .thenAnswer((_) => Stream.value(testMessageModel));

        // Act
        final stream = repository.receiveMessages();

        // Assert
        await expectLater(
          stream,
          emits(
            predicate<Either<Failure, Message>>((either) {
              return either.isRight();
            }),
          ),
        );
      });

      test('returns stream of Left(Failure) when WebSocketException occurs',
          () async {
        // Arrange
        when(() => mockRemoteDataSource.receiveMessages()).thenAnswer(
          (_) => Stream.error(WebSocketException('Connection error')),
        );

        // Act
        final stream = repository.receiveMessages();

        // Assert
        await expectLater(
          stream,
          emits(
            predicate<Either<Failure, Message>>((either) {
              return either.isLeft();
            }),
          ),
        );
      });
    });

    group('switchAgent', () {
      const testAgentType = AgentType.code;
      const testContent = 'Switch to coder';
      final testParams = SwitchAgentParams(
        agentType: testAgentType,
        content: testContent,
        reason: none(),
      );

      test('returns Right(unit) when agent is switched successfully', () async {
        // Arrange
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.switchAgent(testParams);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.sendMessage(any())).called(1);
      });
    });

    group('loadHistory', () {
      const testSessionId = 'session-123';
      final testParams = LoadHistoryParams(sessionId: testSessionId);

      test('returns Right(List<Message>) when history is loaded successfully',
          () async {
        // Arrange
        final testHistory = SessionHistory(
          sessionId: testSessionId,
          messageCount: 2,
          messages: [
            const ChatMessage(
              role: 'user',
              content: 'Hello',
            ),
            const ChatMessage(
              role: 'assistant',
              content: 'Hi!',
            ),
          ],
        );

        when(() => mockGatewayApi.getSessionHistory(testSessionId))
            .thenAnswer((_) async => testHistory);

        // Act
        final result = await repository.loadHistory(testParams);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (messages) {
            expect(messages.length, 2);
            expect(messages[0].role, MessageRole.user);
            expect(messages[1].role, MessageRole.assistant);
          },
        );
      });

      test('returns Right(empty list) when session is not found (404)',
          () async {
        // Arrange
        when(() => mockGatewayApi.getSessionHistory(testSessionId))
            .thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 404,
            ),
          ),
        );

        // Act
        final result = await repository.loadHistory(testParams);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (messages) => expect(messages, isEmpty),
        );
      });

      test('returns Left(Failure.server) when other error occurs', () async {
        // Arrange
        when(() => mockGatewayApi.getSessionHistory(testSessionId))
            .thenThrow(Exception('Server error'));

        // Act
        final result = await repository.loadHistory(testParams);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<Failure>());
            expect(failure.message, contains('Failed to load history'));
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('getAvailableAgents', () {
      test('returns Right(List<Agent>) with predefined agents', () async {
        // Act
        final result = await repository.getAvailableAgents();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (agents) {
            expect(agents.length, 5);
            expect(agents.any((a) => a.id == AgentType.orchestrator), true);
            expect(agents.any((a) => a.id == AgentType.code), true);
            expect(agents.any((a) => a.id == AgentType.architect), true);
            expect(agents.any((a) => a.id == AgentType.debug), true);
            expect(agents.any((a) => a.id == AgentType.ask), true);
          },
        );
      });
    });

    group('getCurrentAgent', () {
      test('returns Right(Agent) with orchestrator as default', () async {
        // Act
        final result = await repository.getCurrentAgent();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (agent) {
            expect(agent.id, AgentType.orchestrator);
          },
        );
      });
    });

    group('connect', () {
      const testSessionId = 'session-123';

      test('returns Right(unit) when connection succeeds', () async {
        // Arrange
        when(() => mockRemoteDataSource.connect(testSessionId))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.connect(testSessionId);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.connect(testSessionId)).called(1);
      });

      test('returns Left(Failure.network) when connection fails', () async {
        // Arrange
        when(() => mockRemoteDataSource.connect(testSessionId))
            .thenThrow(WebSocketException('Connection timeout'));

        // Act
        final result = await repository.connect(testSessionId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<Failure>());
            expect(failure.message, contains('Connection timeout'));
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('disconnect', () {
      test('returns Right(unit) when disconnection succeeds', () async {
        // Arrange
        when(() => mockRemoteDataSource.disconnect())
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.disconnect();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.disconnect()).called(1);
      });
    });

    group('sendPlanDecision', () {
      const testApprovalRequestId = 'req-123';
      const testPlanId = 'plan-456';
      const testDecision = 'approve';
      final testParams = SendPlanDecisionParams(
        approvalRequestId: testApprovalRequestId,
        planId: testPlanId,
        decision: testDecision,
      );

      test('returns Right(unit) when plan decision is sent successfully',
          () async {
        // Arrange
        when(() => mockRemoteDataSource.isConnected).thenReturn(true);
        when(() => mockRemoteDataSource.sendMessage(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendPlanDecision(testParams);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.sendMessage(any())).called(1);
      });

      test('returns Left(Failure.network) when WebSocket is not connected',
          () async {
        // Arrange
        when(() => mockRemoteDataSource.isConnected).thenReturn(false);

        // Act
        final result = await repository.sendPlanDecision(testParams);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<Failure>());
            expect(failure.message, contains('not connected'));
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('isConnected', () {
      test('returns true when remote data source is connected', () {
        // Arrange
        when(() => mockRemoteDataSource.isConnected).thenReturn(true);

        // Act
        final result = repository.isConnected;

        // Assert
        expect(result, true);
      });

      test('returns false when remote data source is not connected', () {
        // Arrange
        when(() => mockRemoteDataSource.isConnected).thenReturn(false);

        // Act
        final result = repository.isConnected;

        // Assert
        expect(result, false);
      });
    });
  });
}
