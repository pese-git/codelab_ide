import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codelab_ai_assistant/core/error/failures.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/agent.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/message.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/send_tool_result.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/middleware/message_handler_middleware.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/entities/tool_call.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/entities/tool_result.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/usecases/execute_tool.dart';

// Моки
class MockExecuteToolUseCase extends Mock implements ExecuteToolUseCase {}
class MockSendToolResultUseCase extends Mock implements SendToolResultUseCase {}
class MockLogger extends Mock implements Logger {}

// Fake классы
class FakeExecuteToolParams extends Fake implements ExecuteToolParams {}
class FakeSendToolResultParams extends Fake implements SendToolResultParams {}

void main() {
  late MessageHandlerMiddleware middleware;
  late MockExecuteToolUseCase mockExecuteTool;
  late MockSendToolResultUseCase mockSendToolResult;
  late MockLogger mockLogger;

  setUpAll(() {
    registerFallbackValue(FakeExecuteToolParams());
    registerFallbackValue(FakeSendToolResultParams());
  });

  setUp(() {
    mockExecuteTool = MockExecuteToolUseCase();
    mockSendToolResult = MockSendToolResultUseCase();
    mockLogger = MockLogger();

    middleware = MessageHandlerMiddleware(
      executeTool: mockExecuteTool,
      sendToolResult: mockSendToolResult,
      logger: mockLogger,
    );
  });

  group('MessageHandlerMiddleware', () {
    group('handleMessage - text messages', () {
      test('should handle text message without agent change', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.text(text: 'Hello', isFinal: true),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        // Act
        final result = await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Assert
        expect(result.isNone(), true);
      });
    });

    group('handleMessage - agent_switch messages', () {
      test('should extract new agent from agent_switch message', () async {
        // Arrange
        final message = Message(
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

        // Act
        final result = await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Assert
        expect(result.isSome(), true);
        result.fold(
          () => fail('Should return agent'),
          (agent) => expect(agent, AgentType.code),
        );
      });

      test('should return none when toAgent is empty', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.system,
          content: MessageContent.agentSwitch(
            fromAgent: AgentType.orchestrator,
            toAgent: '',
            reason: none(),
          ),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        // Act
        final result = await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Assert
        expect(result.isNone(), true);
      });
    });

    group('handleMessage - plan_approval_required messages', () {
      test('should call onPlanApproval callback', () async {
        // Arrange
        final message = Message(
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

        Message? callbackMessage;

        // Act
        await middleware.handleMessage(
          message: message,
          onPlanApproval: (msg) => callbackMessage = msg,
        );

        // Assert
        expect(callbackMessage, message);
      });
    });

    group('handleMessage - tool_call messages', () {
      test('should skip tool_call from history', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.toolCall(
            callId: 'call-123',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
          ),
          timestamp: DateTime.now(),
          metadata: some({'source': 'history'}),
        );

        // Act
        await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Assert
        verifyNever(() => mockExecuteTool(any()));
      });

      test('should execute tool_call from websocket', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.toolCall(
            callId: 'call-123',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
          ),
          timestamp: DateTime.now(),
          metadata: some({'source': 'websocket', 'requires_approval': false}),
        );

        final toolResult = ToolResult.success(
          callId: 'call-123',
          toolName: 'read_file',
          data: {'content': 'file content'},
          durationMs: 100,
          completedAt: DateTime.now(),
        );

        when(() => mockExecuteTool(any())).thenAnswer(
          (_) async => right(toolResult),
        );
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        // Act
        await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Wait for async execution
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        verify(() => mockExecuteTool(any())).called(1);
        verify(() => mockSendToolResult(any())).called(1);
      });

      test('should send error when tool execution fails', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.toolCall(
            callId: 'call-123',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
          ),
          timestamp: DateTime.now(),
          metadata: some({'source': 'websocket'}),
        );

        when(() => mockExecuteTool(any())).thenAnswer(
          (_) async => left(const Failure.unknown('Execution failed')),
        );
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        // Act
        await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Wait for async execution
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        verify(() => mockExecuteTool(any())).called(1);
        verify(() => mockSendToolResult(any())).called(1);
      });

      test('should extract requires_approval from metadata', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.toolCall(
            callId: 'call-123',
            toolName: 'write_file',
            arguments: {'path': 'test.txt', 'content': 'data'},
          ),
          timestamp: DateTime.now(),
          metadata: some({'requires_approval': true}),
        );

        final toolResult = ToolResult.success(
          callId: 'call-123',
          toolName: 'write_file',
          data: {'success': true},
          durationMs: 100,
          completedAt: DateTime.now(),
        );

        when(() => mockExecuteTool(any())).thenAnswer(
          (_) async => right(toolResult),
        );
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        // Act
        await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Wait for async execution
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final captured = verify(() => mockExecuteTool(captureAny())).captured;
        expect(captured.length, 1);
        final params = captured.first as ExecuteToolParams;
        expect(params.toolCall.requiresApproval, true);
      });

      test('should send tool result for successful execution', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.toolCall(
            callId: 'call-123',
            toolName: 'list_files',
            arguments: {'path': '.'},
          ),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        final toolResult = ToolResult.success(
          callId: 'call-123',
          toolName: 'list_files',
          data: {'files': ['file1.txt', 'file2.txt']},
          durationMs: 50,
          completedAt: DateTime.now(),
        );

        when(() => mockExecuteTool(any())).thenAnswer(
          (_) async => right(toolResult),
        );
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        // Act
        await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Wait for async execution
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        verify(() => mockSendToolResult(any())).called(1);
      });

      test('should send tool result for failed execution', () async {
        // Arrange
        final message = Message(
          id: '1',
          role: MessageRole.assistant,
          content: const MessageContent.toolCall(
            callId: 'call-123',
            toolName: 'read_file',
            arguments: {'path': 'missing.txt'},
          ),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        final toolResult = ToolResult.failure(
          callId: 'call-123',
          toolName: 'read_file',
          errorCode: 'file_not_found',
          errorMessage: 'File not found',
          details: none(),
          failedAt: DateTime.now(),
        );

        when(() => mockExecuteTool(any())).thenAnswer(
          (_) async => right(toolResult),
        );
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        // Act
        await middleware.handleMessage(
          message: message,
          onPlanApproval: (_) {},
        );

        // Wait for async execution
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        verify(() => mockSendToolResult(any())).called(1);
      });
    });

    group('handleMessage - multiple message types', () {
      test('should handle agent_switch with tool_call', () async {
        // Arrange - agent_switch message
        final agentSwitchMessage = Message(
          id: '1',
          role: MessageRole.system,
          content: MessageContent.agentSwitch(
            fromAgent: AgentType.orchestrator,
            toAgent: AgentType.code,
            reason: none(),
          ),
          timestamp: DateTime.now(),
          metadata: none(),
        );

        // Act
        final result = await middleware.handleMessage(
          message: agentSwitchMessage,
          onPlanApproval: (_) {},
        );

        // Assert
        expect(result.isSome(), true);
        result.fold(
          () => fail('Should return agent'),
          (agent) => expect(agent, AgentType.code),
        );
      });
    });
  });
}
