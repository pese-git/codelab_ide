import 'dart:async';
import 'package:test/test.dart';
import 'package:codelab_ai_assistant/src/services/tool_approval_service.dart';
import 'package:codelab_ai_assistant/src/models/tool_models.dart';

void main() {
  group('ToolApprovalServiceImpl', () {
    late ToolApprovalServiceImpl service;

    setUp(() {
      service = ToolApprovalServiceImpl();
    });

    tearDown(() {
      service.dispose();
    });

    test('creates approval request and emits to stream', () async {
      // Arrange
      final toolCall = ToolCall(
        callId: 'test-call-1',
        toolName: 'write_file',
        arguments: {'path': 'test.txt', 'content': 'Hello'},
        requiresConfirmation: true,
      );

      // Act & Assert
      final streamFuture = service.approvalRequests.first;
      final requestFuture = service.requestApproval(toolCall);

      final request = await streamFuture;
      expect(request.toolCall, equals(toolCall));
      expect(request.completer.isCompleted, isFalse);

      // Complete the request
      request.completer.complete(ToolApprovalResult.approved);
      final result = await requestFuture;
      expect(result, equals(ToolApprovalResult.approved));
    });

    test('handles approval result correctly', () async {
      // Arrange
      final toolCall = ToolCall(
        callId: 'test-call-2',
        toolName: 'write_file',
        arguments: {'path': 'test.txt'},
        requiresConfirmation: true,
      );

      // Act
      final streamSubscription = service.approvalRequests.listen((request) {
        request.completer.complete(ToolApprovalResult.approved);
      });

      final result = await service.requestApproval(toolCall);

      // Assert
      expect(result, equals(ToolApprovalResult.approved));

      await streamSubscription.cancel();
    });

    test('handles rejection result correctly', () async {
      // Arrange
      final toolCall = ToolCall(
        callId: 'test-call-3',
        toolName: 'write_file',
        arguments: {'path': 'test.txt'},
        requiresConfirmation: true,
      );

      // Act
      final streamSubscription = service.approvalRequests.listen((request) {
        request.completer.complete(ToolApprovalResult.rejected);
      });

      final result = await service.requestApproval(toolCall);

      // Assert
      expect(result, equals(ToolApprovalResult.rejected));

      await streamSubscription.cancel();
    });

    test('handles cancellation result correctly', () async {
      // Arrange
      final toolCall = ToolCall(
        callId: 'test-call-4',
        toolName: 'write_file',
        arguments: {'path': 'test.txt'},
        requiresConfirmation: true,
      );

      // Act
      final streamSubscription = service.approvalRequests.listen((request) {
        request.completer.complete(ToolApprovalResult.cancelled);
      });

      final result = await service.requestApproval(toolCall);

      // Assert
      expect(result, equals(ToolApprovalResult.cancelled));

      await streamSubscription.cancel();
    });

    test('handles multiple concurrent approval requests', () async {
      // Arrange
      final toolCall1 = ToolCall(
        callId: 'test-call-5',
        toolName: 'write_file',
        arguments: {'path': 'test1.txt'},
        requiresConfirmation: true,
      );

      final toolCall2 = ToolCall(
        callId: 'test-call-6',
        toolName: 'write_file',
        arguments: {'path': 'test2.txt'},
        requiresConfirmation: true,
      );

      final toolCall3 = ToolCall(
        callId: 'test-call-7',
        toolName: 'read_file',
        arguments: {'path': 'test3.txt'},
        requiresConfirmation: true,
      );

      // Act
      final requests = <ToolApprovalRequest>[];
      final streamSubscription = service.approvalRequests.listen((request) {
        requests.add(request);
      });

      final future1 = service.requestApproval(toolCall1);
      final future2 = service.requestApproval(toolCall2);
      final future3 = service.requestApproval(toolCall3);

      // Wait for all requests to be emitted
      await Future.delayed(Duration(milliseconds: 100));

      // Assert all requests were received
      expect(requests.length, equals(3));
      expect(requests[0].toolCall.callId, equals('test-call-5'));
      expect(requests[1].toolCall.callId, equals('test-call-6'));
      expect(requests[2].toolCall.callId, equals('test-call-7'));

      // Complete requests in different order
      requests[1].completer.complete(ToolApprovalResult.approved);
      requests[2].completer.complete(ToolApprovalResult.rejected);
      requests[0].completer.complete(ToolApprovalResult.cancelled);

      // Assert results match
      expect(await future1, equals(ToolApprovalResult.cancelled));
      expect(await future2, equals(ToolApprovalResult.approved));
      expect(await future3, equals(ToolApprovalResult.rejected));

      await streamSubscription.cancel();
    });

    test('stream is broadcast and supports multiple listeners', () async {
      // Arrange
      final toolCall = ToolCall(
        callId: 'test-call-8',
        toolName: 'write_file',
        arguments: {'path': 'test.txt'},
        requiresConfirmation: true,
      );

      final receivedRequests1 = <ToolApprovalRequest>[];
      final receivedRequests2 = <ToolApprovalRequest>[];

      // Act - Subscribe with two listeners
      final sub1 = service.approvalRequests.listen((request) {
        receivedRequests1.add(request);
      });

      final sub2 = service.approvalRequests.listen((request) {
        receivedRequests2.add(request);
        request.completer.complete(ToolApprovalResult.approved);
      });

      await service.requestApproval(toolCall);

      // Wait for events to propagate
      await Future.delayed(Duration(milliseconds: 50));

      // Assert both listeners received the request
      expect(receivedRequests1.length, equals(1));
      expect(receivedRequests2.length, equals(1));
      expect(receivedRequests1[0].toolCall.callId, equals('test-call-8'));
      expect(receivedRequests2[0].toolCall.callId, equals('test-call-8'));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('dispose closes the stream', () async {
      // Arrange
      var streamClosed = false;
      final subscription = service.approvalRequests.listen(
        (_) {},
        onDone: () {
          streamClosed = true;
        },
      );

      // Act
      service.dispose();

      // Wait for stream to close
      await Future.delayed(Duration(milliseconds: 50));

      // Assert
      expect(streamClosed, isTrue);

      await subscription.cancel();
    });

    test('requestApproval waits for completer to be completed', () async {
      // Arrange
      final toolCall = ToolCall(
        callId: 'test-call-9',
        toolName: 'write_file',
        arguments: {'path': 'test.txt'},
        requiresConfirmation: true,
      );

      var requestReceived = false;
      final subscription = service.approvalRequests.listen((request) {
        requestReceived = true;
        // Simulate delayed user response
        Future.delayed(Duration(milliseconds: 100), () {
          request.completer.complete(ToolApprovalResult.approved);
        });
      });

      // Act
      final startTime = DateTime.now();
      final result = await service.requestApproval(toolCall);
      final duration = DateTime.now().difference(startTime);

      // Assert
      expect(requestReceived, isTrue);
      expect(result, equals(ToolApprovalResult.approved));
      expect(duration.inMilliseconds, greaterThanOrEqualTo(100));

      await subscription.cancel();
    });

    test('multiple requests maintain separate completers', () async {
      // Arrange
      final toolCall1 = ToolCall(
        callId: 'test-call-10',
        toolName: 'write_file',
        arguments: {'path': 'test1.txt'},
        requiresConfirmation: true,
      );

      final toolCall2 = ToolCall(
        callId: 'test-call-11',
        toolName: 'write_file',
        arguments: {'path': 'test2.txt'},
        requiresConfirmation: true,
      );

      final requests = <ToolApprovalRequest>[];
      final subscription = service.approvalRequests.listen((request) {
        requests.add(request);
      });

      // Act
      final future1 = service.requestApproval(toolCall1);
      final future2 = service.requestApproval(toolCall2);

      await Future.delayed(Duration(milliseconds: 50));

      // Complete only the second request
      requests[1].completer.complete(ToolApprovalResult.approved);

      // Assert first request is still pending
      var future1Completed = false;
      future1.then((_) => future1Completed = true);
      await Future.delayed(Duration(milliseconds: 50));
      expect(future1Completed, isFalse);

      // Complete first request
      requests[0].completer.complete(ToolApprovalResult.rejected);
      
      // Assert both completed with correct results
      expect(await future1, equals(ToolApprovalResult.rejected));
      expect(await future2, equals(ToolApprovalResult.approved));

      await subscription.cancel();
    });
  });
}
