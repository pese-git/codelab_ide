import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:codelab_core/src/utils/path_validator.dart';

void main() {
  late Directory tempDir;
  late PathValidator validator;

  setUp(() {
    // Создаем временную директорию для тестов
    tempDir = Directory.systemTemp.createTempSync('path_validator_test_');
    validator = PathValidator(workspaceRoot: tempDir.path);
  });

  tearDown(() {
    // Удаляем временную директорию после тестов
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PathValidator - текущая директория', () {
    test('путь "." должен быть валидным и указывать на workspace root', () {
      final result = validator.isPathSafe('.');
      
      expect(result.isValid, isTrue);
      expect(result.normalizedPath, equals('.'));
      // На macOS /var это символическая ссылка на /private/var
      // Поэтому сравниваем нормализованные пути
      expect(
        p.normalize(result.fullPath!),
        equals(p.normalize(Directory(tempDir.path).resolveSymbolicLinksSync())),
      );
    });

    test('validateAndGetFullPath для "." должен возвращать workspace root', () {
      final fullPath = validator.validateAndGetFullPath('.');
      final expectedPath = Directory(tempDir.path).resolveSymbolicLinksSync();
      
      expect(p.normalize(fullPath), equals(p.normalize(expectedPath)));
    });

    test('путь "./" должен быть валидным', () {
      final result = validator.isPathSafe('./');
      
      expect(result.isValid, isTrue);
    });
  });

  group('PathValidator - относительные пути', () {
    test('простой относительный путь должен быть валидным', () {
      final result = validator.isPathSafe('test.txt');
      
      expect(result.isValid, isTrue);
      expect(result.normalizedPath, equals('test.txt'));
    });

    test('путь с поддиректорией должен быть валидным', () {
      final result = validator.isPathSafe('src/main.dart');
      
      expect(result.isValid, isTrue);
      expect(result.normalizedPath, equals(p.normalize('src/main.dart')));
    });

    test('путь с префиксом ./ должен быть валидным', () {
      final result = validator.isPathSafe('./src/main.dart');
      
      expect(result.isValid, isTrue);
      expect(result.normalizedPath, equals(p.normalize('src/main.dart')));
    });
  });

  group('PathValidator - невалидные пути', () {
    test('пустой путь должен быть невалидным', () {
      final result = validator.isPathSafe('');
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('cannot be empty'));
    });

    test('абсолютный путь должен быть невалидным', () {
      final result = validator.isPathSafe('/absolute/path');
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('Absolute paths are not allowed'));
    });

    test('путь с .. должен быть невалидным', () {
      final result = validator.isPathSafe('../outside');
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('Path traversal (..) is not allowed'));
    });

    test('путь с null bytes должен быть невалидным', () {
      final result = validator.isPathSafe('test\x00.txt');
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('null bytes'));
    });
  });

  group('PathValidator - validateAndGetFullPath', () {
    test('должен выбрасывать исключение для невалидного пути', () {
      expect(
        () => validator.validateAndGetFullPath('../outside'),
        throwsA(isA<PathValidationException>()),
      );
    });

    test('должен возвращать полный путь для валидного пути', () {
      final fullPath = validator.validateAndGetFullPath('test.txt');
      final expectedPath = p.join(
        Directory(tempDir.path).resolveSymbolicLinksSync(),
        'test.txt',
      );
      
      expect(p.normalize(fullPath), equals(p.normalize(expectedPath)));
    });
  });

  group('PathValidator - edge cases', () {
    test('очень длинный путь должен быть невалидным', () {
      final longPath = 'a' * (PathValidator.maxPathLength + 1);
      final result = validator.isPathSafe(longPath);
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('exceeds maximum length'));
    });

    test('путь с множественными слешами должен быть нормализован', () {
      final result = validator.isPathSafe('src//main.dart');
      
      expect(result.isValid, isTrue);
      expect(result.normalizedPath, equals(p.normalize('src/main.dart')));
    });
  });
}
