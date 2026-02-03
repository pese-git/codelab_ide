import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:codelab_ai_assistant/core/error/failures.dart';
import 'package:codelab_ai_assistant/features/agent_chat/domain/usecases/send_tool_result.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/middleware/approval_middleware.dart';
import 'package:codelab_ai_assistant/features/approval/domain/entities/approval_decision.dart';
import 'package:codelab_ai_assistant/features/approval/domain/entities/approval_request.dart';
import 'package:codelab_ai_assistant/features/approval/domain/entities/approval_response.dart';
import 'package:codelab_ai_assistant/features/approval/domain/entities/approval_type.dart';
import 'package:codelab_ai_assistant/features/approval/domain/services/approval_service.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/entities/approval_request_with_completer.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/entities/tool_approval.dart'
    as tool_approval;
import 'package:codelab_ai_assistant/features/tool_execution/domain/entities/tool_call.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/entities/tool_result.dart';
import 'package:codelab_ai_assistant/features/tool_execution/domain/usecases/execute_tool.dart';

// Моки
class MockApprovalService extends Mock implements ApprovalService {}
class MockExecuteToolUseCase extends Mock implements ExecuteToolUseCase {}
class MockSendToolResultUseCase extends Mock implements SendToolResultUseCase {}
class MockLogger extends Mock implements Logger {}

// Fake классы
class FakeApprovalResponse extends Fake implements ApprovalResponse {}
class FakeExecuteToolParams extends Fake implements ExecuteToolParams {}
class FakeSendToolResultParams extends Fake implements SendToolResultParams {}

void main() {
  late ApprovalMiddleware middleware;
  late MockApprovalService mockApprovalService;
  late MockExecuteToolUseCase mockExecuteTool;
  late MockSendToolResultUseCase mockSendToolResult;
  late MockLogger mockLogger;

  setUpAll(() {
    registerFallbackValue(FakeApprovalResponse());
    registerFallbackValue(FakeExecuteToolParams());
    registerFallbackValue(FakeSendToolResultParams());
  });

  setUp(() {
    mockApprovalService = MockApprovalService();
    mockExecuteTool = MockExecuteToolUseCase();
    mockSendToolResult = MockSendToolResultUseCase();
    mockLogger = MockLogger();

    middleware = ApprovalMiddleware(
      approvalService: mockApprovalService,
      executeTool: mockExecuteTool,
      sendToolResult: mockSendToolResult,
      logger: mockLogger,
    );
  });

  tearDown(() async {
    await middleware.dispose();
  });

  group('ApprovalMiddleware', () {
    group('startListening', () {
      test('should subscribe to approval requests stream', () {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);

        // Act
        middleware.startListening(
          onToolApproval: (_) {},
        );

        // Assert
        verify(() => mockApprovalService.approvalRequests).called(1);
      });

      test('should call onToolApproval for tool approval requests', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);

        final toolApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.tool,
          data: {
            'call_id': 'call-789',
            'tool_name': 'read_file',
            'arguments': {'path': 'test.txt'},
          },
          requestedAt: DateTime.now(),
        );

        ApprovalRequestWithCompleter? capturedRequest;

        // Act
        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        controller.add(toolApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.toolCall.id, 'call-789');
        expect(capturedRequest!.toolCall.toolName, 'read_file');
      });

      test('should skip non-tool approval requests', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);

        final planApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.plan,
          data: {'plan_id': 'plan-789'},
          requestedAt: DateTime.now(),
        );

        ApprovalRequestWithCompleter? capturedRequest;

        // Act
        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        controller.add(planApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(capturedRequest, isNull);
      });
    });

    group('stopListening', () {
      test('should cancel approval subscription', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);

        middleware.startListening(
          onToolApproval: (_) {},
        );

        // Act
        await middleware.stopListening();

        // Assert - stream should be cancelled
        expect(controller.hasListener, false);
      });
    });

    group('restorePendingApprovals', () {
      test('should restore pending approvals from service', () async {
        // Arrange
        const sessionId = 'session-123';
        final approvals = [
          ApprovalRequest(
            approvalRequestId: 'req-1',
            type: ApprovalType.tool,
            data: {
              'call_id': 'call-1',
              'tool_name': 'read_file',
              'arguments': {'path': 'test.txt'},
            },
            requestedAt: DateTime.now(),
          ),
        ];

        when(() => mockApprovalService.restorePendingApprovals(any()))
            .thenAnswer((_) async => approvals);

        // Act
        final count = await middleware.restorePendingApprovals(sessionId);

        // Assert
        expect(count, 1);
        verify(() => mockApprovalService.restorePendingApprovals(sessionId))
            .called(1);
      });

      test('should return 0 when restore fails', () async {
        // Arrange
        const sessionId = 'session-123';
        when(() => mockApprovalService.restorePendingApprovals(any()))
            .thenThrow(Exception('Restore failed'));

        // Act
        final count = await middleware.restorePendingApprovals(sessionId);

        // Assert
        expect(count, 0);
      });
    });

    group('clearActiveCompleters', () {
      test('should clear completers in approval service', () {
        // Arrange
        when(() => mockApprovalService.clearActiveCompleters())
            .thenReturn(null);

        // Act
        middleware.clearActiveCompleters();

        // Assert
        verify(() => mockApprovalService.clearActiveCompleters()).called(1);
      });
    });

    group('approval decision processing', () {
      test('should execute tool when approved', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);
        when(() => mockApprovalService.sendDecision(any()))
            .thenAnswer((_) async => right(unit));

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

        ApprovalRequestWithCompleter? capturedRequest;

        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        final toolApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.tool,
          data: {
            'call_id': 'call-123',
            'tool_name': 'read_file',
            'arguments': {'path': 'test.txt'},
          },
          requestedAt: DateTime.now(),
        );

        // Act
        controller.add(toolApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        // Complete with approval
        capturedRequest!.completer.complete(
          const tool_approval.ApprovalDecision.approved(),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockApprovalService.sendDecision(any())).called(1);
        verify(() => mockExecuteTool(any())).called(1);
        verify(() => mockSendToolResult(any())).called(1);
      });

      test('should send rejection when rejected', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);
        when(() => mockApprovalService.sendDecision(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        ApprovalRequestWithCompleter? capturedRequest;

        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        final toolApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.tool,
          data: {
            'call_id': 'call-123',
            'tool_name': 'write_file',
            'arguments': {'path': 'test.txt', 'content': 'data'},
          },
          requestedAt: DateTime.now(),
        );

        // Act
        controller.add(toolApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        // Complete with rejection
        capturedRequest!.completer.complete(
          tool_approval.ApprovalDecision.rejected(reason: some('Too dangerous')),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockApprovalService.sendDecision(any())).called(1);
        verify(
          () => mockSendToolResult(
            SendToolResultParams(
              callId: 'call-123',
              toolName: 'write_file',
              error: 'User rejected: Too dangerous',
            ),
          ),
        ).called(1);
        verifyNever(() => mockExecuteTool(any()));
      });

      test('should execute modified tool when modified', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);
        when(() => mockApprovalService.sendDecision(any()))
            .thenAnswer((_) async => right(unit));

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

        ApprovalRequestWithCompleter? capturedRequest;

        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        final toolApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.tool,
          data: {
            'call_id': 'call-123',
            'tool_name': 'write_file',
            'arguments': {'path': 'test.txt', 'content': 'original'},
          },
          requestedAt: DateTime.now(),
        );

        // Act
        controller.add(toolApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        // Complete with modification
        capturedRequest!.completer.complete(
          tool_approval.ApprovalDecision.modified(
            modifiedArguments: {'path': 'test.txt', 'content': 'modified'},
            comment: some('Changed content'),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockApprovalService.sendDecision(any())).called(1);
        verify(() => mockExecuteTool(any())).called(1);
        
        // Verify modified arguments were used
        final captured = verify(() => mockExecuteTool(captureAny())).captured;
        final params = captured.first as ExecuteToolParams;
        expect(params.toolCall.arguments['content'], 'modified');
      });

      test('should send cancellation when cancelled', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);
        when(() => mockApprovalService.sendDecision(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        ApprovalRequestWithCompleter? capturedRequest;

        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        final toolApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.tool,
          data: {
            'call_id': 'call-123',
            'tool_name': 'execute_command',
            'arguments': {'command': 'rm -rf /'},
          },
          requestedAt: DateTime.now(),
        );

        // Act
        controller.add(toolApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        // Complete with cancellation
        capturedRequest!.completer.complete(
          const tool_approval.ApprovalDecision.cancelled(),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockApprovalService.sendDecision(any())).called(1);
        verify(
          () => mockSendToolResult(
            SendToolResultParams(
              callId: 'call-123',
              toolName: 'execute_command',
              error: 'User rejected: User cancelled',
            ),
          ),
        ).called(1);
        verifyNever(() => mockExecuteTool(any()));
      });
    });

    group('error handling', () {
      test('should handle tool execution failure after approval', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);
        when(() => mockApprovalService.sendDecision(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockExecuteTool(any())).thenAnswer(
          (_) async => left(const Failure.unknown('Execution failed')),
        );
        when(() => mockSendToolResult(any())).thenAnswer(
          (_) async => right(unit),
        );

        ApprovalRequestWithCompleter? capturedRequest;

        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        final toolApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.tool,
          data: {
            'call_id': 'call-123',
            'tool_name': 'read_file',
            'arguments': {'path': 'missing.txt'},
          },
          requestedAt: DateTime.now(),
        );

        // Act
        controller.add(toolApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        capturedRequest!.completer.complete(
          const tool_approval.ApprovalDecision.approved(),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(
          () => mockSendToolResult(
            SendToolResultParams(
              callId: 'call-123',
              toolName: 'read_file',
              error: 'Execution failed',
            ),
          ),
        ).called(1);
      });

      test('should handle tool result failure after approval', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);
        when(() => mockApprovalService.sendDecision(any()))
            .thenAnswer((_) async => right(unit));

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

        ApprovalRequestWithCompleter? capturedRequest;

        middleware.startListening(
          onToolApproval: (request) => capturedRequest = request,
        );

        final toolApprovalRequest = ApprovalRequest(
          approvalRequestId: 'req-123',
          type: ApprovalType.tool,
          data: {
            'call_id': 'call-123',
            'tool_name': 'read_file',
            'arguments': {'path': 'missing.txt'},
          },
          requestedAt: DateTime.now(),
        );

        // Act
        controller.add(toolApprovalRequest);
        await Future.delayed(const Duration(milliseconds: 100));

        capturedRequest!.completer.complete(
          const tool_approval.ApprovalDecision.approved(),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(
          () => mockSendToolResult(
            SendToolResultParams(
              callId: 'call-123',
              toolName: 'read_file',
              error: 'File not found',
            ),
          ),
        ).called(1);
      });
    });

    group('dispose', () {
      test('should stop listening and cleanup', () async {
        // Arrange
        final controller = StreamController<ApprovalRequest>();
        when(() => mockApprovalService.approvalRequests)
            .thenAnswer((_) => controller.stream);

        middleware.startListening(
          onToolApproval: (_) {},
        );

        // Act
        await middleware.dispose();

        // Assert
        expect(controller.hasListener, false);
      });
    });
  });
}
