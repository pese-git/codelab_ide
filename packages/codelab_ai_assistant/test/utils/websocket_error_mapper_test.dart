import 'package:test/test.dart';
import 'package:codelab_ai_assistant/src/utils/websocket_error_mapper.dart';
import 'package:codelab_ai_assistant/src/models/tool_models.dart';

void main() {
  group('WebSocketErrorMapper', () {
    test('maps fileNotFound exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.fileNotFound('/test.txt');
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[File not found]'));
      expect(result, contains('File not found: /test.txt'));
      expect(result, contains('path=/test.txt'));
    });

    test('maps permissionDenied exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.permissionDenied('/secret.txt');
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[Access denied]'));
      expect(result, contains('Permission denied: /secret.txt'));
      expect(result, contains('path=/secret.txt'));
    });

    test('maps invalidPath exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.invalidPath(
        '../outside.txt',
        'Path traversal detected',
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[Invalid path]'));
      expect(result, contains('Invalid path: ../outside.txt'));
      expect(result, contains('path=../outside.txt'));
      expect(result, contains('reason=Path traversal detected'));
    });

    test('maps fileTooLarge exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.fileTooLarge(
        '/large.bin',
        10485760, // 10MB
        5242880,  // 5MB max
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[File too large]'));
      expect(result, contains('File too large: /large.bin'));
      expect(result, contains('size=10485760'));
      expect(result, contains('max_size=5242880'));
    });

    test('maps encodingError exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.encodingError(
        '/binary.dat',
        FormatException('Invalid UTF-8'),
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[Encoding error]'));
      expect(result, contains('Encoding error for file: /binary.dat'));
      expect(result, contains('path=/binary.dat'));
    });

    test('maps userRejected exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.userRejected('write_file');
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[Operation rejected by user]'));
      expect(result, contains('User rejected operation: write_file'));
      expect(result, contains('operation=write_file'));
    });

    test('maps concurrentModification exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.concurrentModification('/modified.txt');
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[Concurrent modification]'));
      expect(result, contains('File was modified by another process: /modified.txt'));
      expect(result, contains('path=/modified.txt'));
    });

    test('maps general exception correctly', () {
      // Arrange
      final exception = ToolExecutionException.general(
        'Something went wrong',
        cause: Exception('Root cause'),
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[Tool execution failed]'));
      expect(result, contains('Something went wrong'));
    });

    test('maps unknown exception code correctly', () {
      // Arrange
      final exception = ToolExecutionException(
        code: 'unknown_code',
        message: 'Unknown error occurred',
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('[Unknown error]'));
      expect(result, contains('Unknown error occurred'));
    });

    test('formats error without details correctly', () {
      // Arrange
      final exception = ToolExecutionException(
        code: 'test_error',
        message: 'Test message',
        details: null,
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, isNot(contains('Details:')));
    });

    test('formats error with empty details correctly', () {
      // Arrange
      final exception = ToolExecutionException(
        code: 'test_error',
        message: 'Test message',
        details: {},
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, isNot(contains('Details:')));
    });

    test('formats error with multiple details correctly', () {
      // Arrange
      final exception = ToolExecutionException(
        code: 'test_error',
        message: 'Test message',
        details: {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 123,
        },
      );
      
      // Act
      final result = WebSocketErrorMapper.mapException(exception);
      
      // Assert
      expect(result, contains('Details:'));
      expect(result, contains('key1=value1'));
      expect(result, contains('key2=value2'));
      expect(result, contains('key3=123'));
    });
  });
}
