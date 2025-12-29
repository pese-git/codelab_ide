import 'dart:async';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:codelab_ai_assistant/src/bloc/ai_agent_bloc.dart';
import 'package:codelab_ai_assistant/src/domain/agent_protocol_service.dart';
import 'package:codelab_ai_assistant/src/integration/tool_api.dart';
import 'package:codelab_ai_assistant/src/models/ws_message.dart';
import 'package:codelab_ai_assistant/src/models/tool_models.dart';

// Моки
class MockAgentProtocolService extends Mock implements AgentProtocolService {}
class MockToolApi extends Mock implements ToolApi {}

void main() {
  setUpAll(() {
    // Регистрация fallback значений для mocktail
    registerFallbackValue(
      const WSMessage.userMessage(content: 'fallback', role: 'user'),
    );
    registerFallbackValue(
      const WSMessage.toolResult(callId: 'fallback'),
    );
  });

  group('Tool Execution Flow Integration Tests', () {
    late MockAgentProtocolService mockProtocol;
    late MockToolApi mockToolApi;
    late StreamController<WSMessage> messageController;

    setUp(() {
      mockProtocol = MockAgentProtocolService();
      mockToolApi = MockToolApi();
      messageController = StreamController<WSMessage>.broadcast();

      // Настройка базового поведения мока
      when(() => mockProtocol.messages).thenAnswer((_) => messageController.stream);
      when(() => mockProtocol.connect()).thenReturn(null);
      when(() => mockProtocol.disconnect()).thenAnswer((_) async {});
      when(() => mockProtocol.sendUserMessage(any(), role: any(named: 'role')))
          .thenReturn(null);
      when(() => mockProtocol.sendToolResult(
        callId: any(named: 'callId'),
        result: any(named: 'result'),
        error: any(named: 'error'),
      )).thenReturn(null);
    });

    tearDown(() {
      messageController.close();
    });

    blocTest<AiAgentBloc, AiAgentState>(
      'successfully executes read_file tool call and sends result back',
      build: () {
        // Arrange
        final expectedResult = FileOperationResult.readSuccess(
          content: 'Hello, World!',
          linesRead: 1,
        );

        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenAnswer((_) async => expectedResult);

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) {
        // Simulate receiving a tool_call message
        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-1',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
            requiresApproval: false,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        // Verify tool was executed
        verify(() => mockToolApi.call(
          callId: 'test-call-1',
          toolName: 'read_file',
          arguments: {'path': 'test.txt'},
          requiresApproval: false,
        )).called(1);

        // Verify result was sent back
        verify(() => mockProtocol.sendToolResult(
          callId: 'test-call-1',
          result: any(named: 'result'),
        )).called(1);
      },
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'successfully executes write_file tool call with approval',
      build: () {
        // Arrange
        final expectedResult = FileOperationResult.writeSuccess(
          bytesWritten: 13,
        );

        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenAnswer((_) async => expectedResult);

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) {
        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-2',
            toolName: 'write_file',
            arguments: {'path': 'test.txt', 'content': 'Hello, World!'},
            requiresApproval: true,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockToolApi.call(
          callId: 'test-call-2',
          toolName: 'write_file',
          arguments: {'path': 'test.txt', 'content': 'Hello, World!'},
          requiresApproval: true,
        )).called(1);

        verify(() => mockProtocol.sendToolResult(
          callId: 'test-call-2',
          result: any(named: 'result'),
        )).called(1);
      },
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'handles tool execution error and sends error back',
      build: () {
        // Arrange
        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenThrow(ToolExecutionException.fileNotFound('test.txt'));

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) {
        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-3',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
            requiresApproval: false,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockToolApi.call(
          callId: 'test-call-3',
          toolName: 'read_file',
          arguments: {'path': 'test.txt'},
          requiresApproval: false,
        )).called(1);

        // Verify error was sent back
        verify(() => mockProtocol.sendToolResult(
          callId: 'test-call-3',
          error: any(named: 'error'),
        )).called(1);
      },
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'handles user rejection and sends error back',
      build: () {
        // Arrange
        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenThrow(ToolExecutionException.userRejected('write_file'));

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) {
        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-4',
            toolName: 'write_file',
            arguments: {'path': 'test.txt', 'content': 'Hello'},
            requiresApproval: true,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockToolApi.call(
          callId: 'test-call-4',
          toolName: 'write_file',
          arguments: {'path': 'test.txt', 'content': 'Hello'},
          requiresApproval: true,
        )).called(1);

        verify(() => mockProtocol.sendToolResult(
          callId: 'test-call-4',
          error: any(named: 'error'),
        )).called(1);
      },
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'handles multiple sequential tool calls',
      build: () {
        // Arrange
        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenAnswer((_) async => FileOperationResult.readSuccess(
          content: 'test',
          linesRead: 1,
        ));

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) async {
        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-5',
            toolName: 'read_file',
            arguments: {'path': 'test1.txt'},
            requiresApproval: false,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-6',
            toolName: 'read_file',
            arguments: {'path': 'test2.txt'},
            requiresApproval: false,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-7',
            toolName: 'read_file',
            arguments: {'path': 'test3.txt'},
            requiresApproval: false,
          ),
        );
      },
      wait: const Duration(milliseconds: 200),
      verify: (_) {
        verify(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: 'read_file',
          arguments: any(named: 'arguments'),
          requiresApproval: false,
        )).called(3);

        verify(() => mockProtocol.sendToolResult(
          callId: any(named: 'callId'),
          result: any(named: 'result'),
        )).called(3);
      },
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'updates chat state with tool_call message',
      build: () {
        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenAnswer((_) async => FileOperationResult.readSuccess(
          content: 'test',
          linesRead: 1,
        ));

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) {
        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-8',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
            requiresApproval: false,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.history.length, 'history length', 1)
            .having((s) => s.history.first, 'first message', isA<WSToolCall>()),
      ],
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'handles assistant messages alongside tool calls',
      build: () {
        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenAnswer((_) async => FileOperationResult.readSuccess(
          content: 'test',
          linesRead: 1,
        ));

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) async {
        messageController.add(
          const WSMessage.assistantMessage(
            content: 'Let me read that file for you.',
            isFinal: false,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-9',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
            requiresApproval: false,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        messageController.add(
          const WSMessage.assistantMessage(
            content: 'Here is the content.',
            isFinal: true,
          ),
        );
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<ChatState>().having((s) => s.history.length, 'history length', 1),
        isA<ChatState>().having((s) => s.history.length, 'history length', 2),
        isA<ChatState>().having((s) => s.history.length, 'history length', 3),
      ],
      verify: (_) {
        verify(() => mockToolApi.call(
          callId: 'test-call-9',
          toolName: 'read_file',
          arguments: {'path': 'test.txt'},
          requiresApproval: false,
        )).called(1);
      },
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'handles unexpected errors during tool execution',
      build: () {
        // Arrange
        when(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        )).thenThrow(Exception('Unexpected error'));

        return AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
      },
      act: (bloc) {
        messageController.add(
          const WSMessage.toolCall(
            callId: 'test-call-10',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
            requiresApproval: false,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        // Verify error was sent back
        verify(() => mockProtocol.sendToolResult(
          callId: 'test-call-10',
          error: any(named: 'error'),
        )).called(1);
      },
    );

    blocTest<AiAgentBloc, AiAgentState>(
      'sends user message through protocol',
      build: () => AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi),
      act: (bloc) => bloc.add(const AiAgentEvent.sendUserMessage('Hello AI')),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => mockProtocol.sendUserMessage('Hello AI', role: 'user')).called(1);
      },
      expect: () => [
        isA<ChatState>()
            .having((s) => s.history.length, 'history length', 1)
            .having((s) => s.waitingResponse, 'waiting response', true),
      ],
    );

    test('bloc connects to protocol on initialization', () {
      // Act
      final bloc = AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);

      // Assert
      verify(() => mockProtocol.connect()).called(1);

      // Cleanup
      bloc.close();
    });

    test('bloc disconnects from protocol on close', () async {
      // Arrange
      final bloc = AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);

      // Act
      await bloc.close();

      // Assert
      verify(() => mockProtocol.disconnect()).called(1);
    });

    blocTest<AiAgentBloc, AiAgentState>(
      'ignores non-tool-call messages in tool execution flow',
      build: () => AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi),
      act: (bloc) {
        messageController.add(
          const WSMessage.assistantMessage(
            content: 'Hello',
            isFinal: false,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        // Tool API should not be called for assistant messages
        verifyNever(() => mockToolApi.call(
          callId: any(named: 'callId'),
          toolName: any(named: 'toolName'),
          arguments: any(named: 'arguments'),
          requiresApproval: any(named: 'requiresApproval'),
        ));
      },
    );
  });
}
