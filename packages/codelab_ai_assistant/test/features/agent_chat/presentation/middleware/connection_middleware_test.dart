import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codelab_ai_assistant/core/error/failures.dart';
import 'package:codelab_ai_assistant/core/usecases/usecase.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/message.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/connect.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/receive_messages.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/middleware/connection_middleware.dart';

// Моки
class MockConnectUseCase extends Mock implements ConnectUseCase {}
class MockReceiveMessagesUseCase extends Mock implements ReceiveMessagesUseCase {}
class MockLogger extends Mock implements Logger {}

// Fake классы
class FakeConnectParams extends Fake implements ConnectParams {}
class FakeNoParams extends Fake implements NoParams {}

void main() {
  late ConnectionMiddleware middleware;
  late MockConnectUseCase mockConnect;
  late MockReceiveMessagesUseCase mockReceiveMessages;
  late MockLogger mockLogger;

  setUpAll(() {
    registerFallbackValue(FakeConnectParams());
    registerFallbackValue(FakeNoParams());
  });

  setUp(() {
    mockConnect = MockConnectUseCase();
    mockReceiveMessages = MockReceiveMessagesUseCase();
    mockLogger = MockLogger();

    middleware = ConnectionMiddleware(
      connect: mockConnect,
      receiveMessages: mockReceiveMessages,
      logger: mockLogger,
    );
  });

  tearDown(() async {
    await middleware.dispose();
  });

  group('ConnectionMiddleware', () {
    group('connect', () {
      const testSessionId = 'test-session-123';

      test('should successfully connect to WebSocket', () async {
        // Arrange
        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => const Stream.empty(),
        );

        final messages = <Message>[];
        final failures = <Failure>[];

        // Act
        final result = await middleware.connect(
          sessionId: testSessionId,
          onMessage: messages.add,
          onError: failures.add,
        );

        // Assert
        expect(result.isRight(), true);
        expect(middleware.isConnected, true);
        verify(() => mockConnect(any())).called(1);
        verify(() => mockReceiveMessages(any())).called(1);
      });

      test('should return failure when connection fails', () async {
        // Arrange
        const failure = Failure.network('Connection timeout');
        when(() => mockConnect(any())).thenAnswer((_) async => left(failure));

        final messages = <Message>[];
        final failures = <Failure>[];

        // Act
        final result = await middleware.connect(
          sessionId: testSessionId,
          onMessage: messages.add,
          onError: failures.add,
        );

        // Assert
        expect(result.isLeft(), true);
        expect(middleware.isConnected, false);
        result.fold(
          (f) => expect(f, failure),
          (_) => fail('Should return failure'),
        );
      });

      test('should call onMessage callback when message is received', () async {
        // Arrange
        final testMessage = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.text(text: 'Hello', isFinal: true),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => Stream.value(right(testMessage)),
        );

        final messages = <Message>[];
        final failures = <Failure>[];

        // Act
        await middleware.connect(
          sessionId: testSessionId,
          onMessage: messages.add,
          onError: failures.add,
        );

        // Wait for stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(messages, [testMessage]);
        expect(failures, isEmpty);
      });

      test('should call onError callback when stream emits failure', () async {
        // Arrange
        const failure = Failure.network('Stream error');

        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => Stream.value(left(failure)),
        );

        final messages = <Message>[];
        final failures = <Failure>[];

        // Act
        await middleware.connect(
          sessionId: testSessionId,
          onMessage: messages.add,
          onError: failures.add,
        );

        // Wait for stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(messages, isEmpty);
        expect(failures, [failure]);
      });

      test('should cancel previous subscription when connecting again', () async {
        // Arrange
        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => const Stream.empty(),
        );

        final messages = <Message>[];
        final failures = <Failure>[];

        // Act
        await middleware.connect(
          sessionId: testSessionId,
          onMessage: messages.add,
          onError: failures.add,
        );

        await middleware.connect(
          sessionId: 'another-session',
          onMessage: messages.add,
          onError: failures.add,
        );

        // Assert
        verify(() => mockConnect(any())).called(2);
        verify(() => mockReceiveMessages(any())).called(2);
      });
    });

    group('disconnect', () {
      test('should disconnect and reset connection state', () async {
        // Arrange
        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => const Stream.empty(),
        );

        await middleware.connect(
          sessionId: 'test-session',
          onMessage: (_) {},
          onError: (_) {},
        );

        expect(middleware.isConnected, true);

        // Act
        await middleware.disconnect();

        // Assert
        expect(middleware.isConnected, false);
      });

      test('should be safe to call disconnect multiple times', () async {
        // Act & Assert - should not throw
        await middleware.disconnect();
        await middleware.disconnect();
        await middleware.disconnect();

        expect(middleware.isConnected, false);
      });
    });

    group('dispose', () {
      test('should disconnect and cleanup resources', () async {
        // Arrange
        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => const Stream.empty(),
        );

        await middleware.connect(
          sessionId: 'test-session',
          onMessage: (_) {},
          onError: (_) {},
        );

        expect(middleware.isConnected, true);

        // Act
        await middleware.dispose();

        // Assert
        expect(middleware.isConnected, false);
      });
    });

    group('isConnected', () {
      test('should return false initially', () {
        expect(middleware.isConnected, false);
      });

      test('should return true after successful connection', () async {
        // Arrange
        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => const Stream.empty(),
        );

        // Act
        await middleware.connect(
          sessionId: 'test-session',
          onMessage: (_) {},
          onError: (_) {},
        );

        // Assert
        expect(middleware.isConnected, true);
      });

      test('should return false after failed connection', () async {
        // Arrange
        when(() => mockConnect(any())).thenAnswer(
          (_) async => left(const Failure.network('Failed')),
        );

        // Act
        await middleware.connect(
          sessionId: 'test-session',
          onMessage: (_) {},
          onError: (_) {},
        );

        // Assert
        expect(middleware.isConnected, false);
      });

      test('should return false after disconnect', () async {
        // Arrange
        when(() => mockConnect(any())).thenAnswer((_) async => right(unit));
        when(() => mockReceiveMessages(any())).thenAnswer(
          (_) => const Stream.empty(),
        );

        await middleware.connect(
          sessionId: 'test-session',
          onMessage: (_) {},
          onError: (_) {},
        );

        // Act
        await middleware.disconnect();

        // Assert
        expect(middleware.isConnected, false);
      });
    });
  });
}
