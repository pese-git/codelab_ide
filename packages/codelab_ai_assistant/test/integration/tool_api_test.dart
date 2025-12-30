import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:codelab_ai_assistant/src/integration/tool_api.dart';
import 'package:codelab_ai_assistant/src/services/tool_executor.dart';
import 'package:codelab_ai_assistant/src/services/tool_approval_service.dart';
import 'package:codelab_ai_assistant/src/models/tool_models.dart';

// Моки
class MockToolExecutor extends Mock implements ToolExecutor {}
class MockToolApprovalService extends Mock implements ToolApprovalService {}

void main() {
  setUpAll(() {
    // Регистрация fallback значений для mocktail
    registerFallbackValue(
      ToolCall(
        callId: 'fallback',
        toolName: 'fallback',
        arguments: {},
      ),
    );
  });

  group('ToolApiImpl', () {
    late MockToolExecutor mockExecutor;
    late MockToolApprovalService mockApprovalService;
    late ToolApiImpl toolApi;

    setUp(() {
      mockExecutor = MockToolExecutor();
      mockApprovalService = MockToolApprovalService();
      toolApi = ToolApiImpl(
        toolExecutor: mockExecutor,
        approvalService: mockApprovalService,
      );
    });

    group('read_file without approval', () {
      test('executes successfully without requesting approval', () async {
        // Arrange
        final expectedResult = FileOperationResult.readSuccess(
          content: 'Hello, World!',
          linesRead: 1,
        );

        when(() => mockExecutor.executeToolCall(any()))
            .thenAnswer((_) async => expectedResult);

        // Act
        final result = await toolApi.call(
          callId: 'test-call-1',
          toolName: 'read_file',
          arguments: {'path': 'test.txt'},
          requiresApproval: false,
        );

        // Assert
        expect(result, equals(expectedResult));
        verify(() => mockExecutor.executeToolCall(any())).called(1);
        verifyNever(() => mockApprovalService.requestApproval(any()));
      });

      test('propagates ToolExecutionException from executor', () async {
        // Arrange
        final exception = ToolExecutionException.fileNotFound('test.txt');
        
        when(() => mockExecutor.executeToolCall(any()))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => toolApi.call(
            callId: 'test-call-2',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
            requiresApproval: false,
          ),
          throwsA(isA<ToolExecutionException>()
              .having((e) => e.code, 'code', 'file_not_found')
              .having((e) => e.message, 'message', contains('test.txt'))),
        );

        verify(() => mockExecutor.executeToolCall(any())).called(1);
      });
    });

    group('write_file with approval', () {
      test('executes successfully after user approval', () async {
        // Arrange
        final expectedResult = FileOperationResult.writeSuccess(
          bytesWritten: 13,
        );

        when(() => mockApprovalService.requestApproval(any()))
            .thenAnswer((_) async => ToolApprovalResult.approved);
        
        when(() => mockExecutor.executeToolCall(any()))
            .thenAnswer((_) async => expectedResult);

        // Act
        final result = await toolApi.call(
          callId: 'test-call-3',
          toolName: 'write_file',
          arguments: {'path': 'test.txt', 'content': 'Hello, World!'},
          requiresApproval: true,
        );

        // Assert
        expect(result, equals(expectedResult));
        verify(() => mockApprovalService.requestApproval(any())).called(1);
        verify(() => mockExecutor.executeToolCall(any())).called(1);
      });

      test('throws userRejected when user rejects', () async {
        // Arrange
        when(() => mockApprovalService.requestApproval(any()))
            .thenAnswer((_) async => ToolApprovalResult.rejected);

        // Act & Assert
        expect(
          () => toolApi.call(
            callId: 'test-call-4',
            toolName: 'write_file',
            arguments: {'path': 'test.txt', 'content': 'Hello'},
            requiresApproval: true,
          ),
          throwsA(isA<ToolExecutionException>()
              .having((e) => e.code, 'code', 'user_rejected')
              .having((e) => e.message, 'message', contains('write_file'))),
        );

        verify(() => mockApprovalService.requestApproval(any())).called(1);
        verifyNever(() => mockExecutor.executeToolCall(any()));
      });

      test('throws userRejected when user cancels', () async {
        // Arrange
        when(() => mockApprovalService.requestApproval(any()))
            .thenAnswer((_) async => ToolApprovalResult.cancelled);

        // Act & Assert
        expect(
          () => toolApi.call(
            callId: 'test-call-5',
            toolName: 'write_file',
            arguments: {'path': 'test.txt', 'content': 'Hello'},
            requiresApproval: true,
          ),
          throwsA(isA<ToolExecutionException>()
              .having((e) => e.code, 'code', 'user_rejected')),
        );

        verify(() => mockApprovalService.requestApproval(any())).called(1);
        verifyNever(() => mockExecutor.executeToolCall(any()));
      });
    });

    group('error handling', () {
      test('handles path validation errors', () async {
        // Arrange
        final exception = ToolExecutionException.invalidPath(
          '../outside.txt',
          'Path traversal detected',
        );
        
        when(() => mockExecutor.executeToolCall(any()))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => toolApi.call(
            callId: 'test-call-6',
            toolName: 'read_file',
            arguments: {'path': '../outside.txt'},
            requiresApproval: false,
          ),
          throwsA(isA<ToolExecutionException>()
              .having((e) => e.code, 'code', 'invalid_path')),
        );
      });

      test('handles permission denied errors', () async {
        // Arrange
        final exception = ToolExecutionException.permissionDenied('/secret.txt');
        
        when(() => mockExecutor.executeToolCall(any()))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => toolApi.call(
            callId: 'test-call-7',
            toolName: 'read_file',
            arguments: {'path': '/secret.txt'},
            requiresApproval: false,
          ),
          throwsA(isA<ToolExecutionException>()
              .having((e) => e.code, 'code', 'permission_denied')),
        );
      });

      test('handles file too large errors', () async {
        // Arrange
        final exception = ToolExecutionException.fileTooLarge(
          'large.bin',
          10485760,
          5242880,
        );
        
        when(() => mockExecutor.executeToolCall(any()))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => toolApi.call(
            callId: 'test-call-8',
            toolName: 'read_file',
            arguments: {'path': 'large.bin'},
            requiresApproval: false,
          ),
          throwsA(isA<ToolExecutionException>()
              .having((e) => e.code, 'code', 'file_too_large')),
        );
      });

      test('wraps unexpected errors in general exception', () async {
        // Arrange
        when(() => mockExecutor.executeToolCall(any()))
            .thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => toolApi.call(
            callId: 'test-call-9',
            toolName: 'read_file',
            arguments: {'path': 'test.txt'},
            requiresApproval: false,
          ),
          throwsA(isA<ToolExecutionException>()
              .having((e) => e.code, 'code', 'general_error')
              .having((e) => e.message, 'message', contains('Unexpected error'))),
        );
      });
    });

    group('ToolCall creation', () {
      test('creates ToolCall with correct parameters', () async {
        // Arrange
        ToolCall? capturedToolCall;
        
        when(() => mockExecutor.executeToolCall(any())).thenAnswer((invocation) {
          capturedToolCall = invocation.positionalArguments[0] as ToolCall;
          return Future.value(FileOperationResult.readSuccess(
            content: 'test',
            linesRead: 1,
          ));
        });

        // Act
        await toolApi.call(
          callId: 'test-call-10',
          toolName: 'read_file',
          arguments: {'path': 'test.txt', 'encoding': 'utf-8'},
          requiresApproval: false,
        );

        // Assert
        expect(capturedToolCall, isNotNull);
        expect(capturedToolCall!.callId, equals('test-call-10'));
        expect(capturedToolCall!.toolName, equals('read_file'));
        expect(capturedToolCall!.arguments['path'], equals('test.txt'));
        expect(capturedToolCall!.arguments['encoding'], equals('utf-8'));
        expect(capturedToolCall!.requiresConfirmation, isFalse);
      });

      test('sets requiresConfirmation correctly when approval needed', () async {
        // Arrange
        ToolCall? capturedToolCall;
        
        when(() => mockApprovalService.requestApproval(any())).thenAnswer((invocation) {
          capturedToolCall = invocation.positionalArguments[0] as ToolCall;
          return Future.value(ToolApprovalResult.approved);
        });
        
        when(() => mockExecutor.executeToolCall(any()))
            .thenAnswer((_) async => FileOperationResult.writeSuccess(
              bytesWritten: 5,
            ));

        // Act
        await toolApi.call(
          callId: 'test-call-11',
          toolName: 'write_file',
          arguments: {'path': 'test.txt', 'content': 'Hello'},
          requiresApproval: true,
        );

        // Assert
        expect(capturedToolCall, isNotNull);
        expect(capturedToolCall!.requiresConfirmation, isTrue);
      });
    });

    group('approval flow', () {
      test('does not request approval when requiresApproval is false', () async {
        // Arrange
        when(() => mockExecutor.executeToolCall(any()))
            .thenAnswer((_) async => FileOperationResult.writeSuccess(
              bytesWritten: 5,
            ));

        // Act
        await toolApi.call(
          callId: 'test-call-12',
          toolName: 'write_file',
          arguments: {'path': 'test.txt', 'content': 'Hello'},
          requiresApproval: false,
        );

        // Assert
        verifyNever(() => mockApprovalService.requestApproval(any()));
        verify(() => mockExecutor.executeToolCall(any())).called(1);
      });

      test('requests approval before execution when requiresApproval is true', () async {
        // Arrange
        var approvalRequested = false;
        var executionStarted = false;
        
        when(() => mockApprovalService.requestApproval(any())).thenAnswer((_) async {
          approvalRequested = true;
          expect(executionStarted, isFalse, reason: 'Approval should be requested before execution');
          return ToolApprovalResult.approved;
        });
        
        when(() => mockExecutor.executeToolCall(any())).thenAnswer((_) async {
          executionStarted = true;
          expect(approvalRequested, isTrue, reason: 'Execution should happen after approval');
          return FileOperationResult.writeSuccess(bytesWritten: 5);
        });

        // Act
        await toolApi.call(
          callId: 'test-call-13',
          toolName: 'write_file',
          arguments: {'path': 'test.txt', 'content': 'Hello'},
          requiresApproval: true,
        );

        // Assert
        expect(approvalRequested, isTrue);
        expect(executionStarted, isTrue);
      });

      test('does not execute when approval is rejected', () async {
        // Arrange
        when(() => mockApprovalService.requestApproval(any()))
            .thenAnswer((_) async => ToolApprovalResult.rejected);

        // Act & Assert
        await expectLater(
          toolApi.call(
            callId: 'test-call-14',
            toolName: 'write_file',
            arguments: {'path': 'test.txt', 'content': 'Hello'},
            requiresApproval: true,
          ),
          throwsA(isA<ToolExecutionException>()),
        );

        verify(() => mockApprovalService.requestApproval(any())).called(1);
        verifyNever(() => mockExecutor.executeToolCall(any()));
      });
    });

    group('multiple operations', () {
      test('handles multiple sequential operations', () async {
        // Arrange
        when(() => mockExecutor.executeToolCall(any()))
            .thenAnswer((_) async => FileOperationResult.readSuccess(
              content: 'test',
              linesRead: 1,
            ));

        // Act
        await toolApi.call(
          callId: 'test-call-15',
          toolName: 'read_file',
          arguments: {'path': 'test1.txt'},
          requiresApproval: false,
        );

        await toolApi.call(
          callId: 'test-call-16',
          toolName: 'read_file',
          arguments: {'path': 'test2.txt'},
          requiresApproval: false,
        );

        await toolApi.call(
          callId: 'test-call-17',
          toolName: 'read_file',
          arguments: {'path': 'test3.txt'},
          requiresApproval: false,
        );

        // Assert
        verify(() => mockExecutor.executeToolCall(any())).called(3);
      });

      test('handles mixed approval and non-approval operations', () async {
        // Arrange
        when(() => mockExecutor.executeToolCall(any()))
            .thenAnswer((_) async => FileOperationResult.readSuccess(
              content: 'test',
              linesRead: 1,
            ));
        
        when(() => mockApprovalService.requestApproval(any()))
            .thenAnswer((_) async => ToolApprovalResult.approved);

        // Act
        await toolApi.call(
          callId: 'test-call-18',
          toolName: 'read_file',
          arguments: {'path': 'test1.txt'},
          requiresApproval: false,
        );

        await toolApi.call(
          callId: 'test-call-19',
          toolName: 'write_file',
          arguments: {'path': 'test2.txt', 'content': 'Hello'},
          requiresApproval: true,
        );

        await toolApi.call(
          callId: 'test-call-20',
          toolName: 'read_file',
          arguments: {'path': 'test3.txt'},
          requiresApproval: false,
        );

        // Assert
        verify(() => mockExecutor.executeToolCall(any())).called(3);
        verify(() => mockApprovalService.requestApproval(any())).called(1);
      });
    });
  });
}
