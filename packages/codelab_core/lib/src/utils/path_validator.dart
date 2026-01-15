import 'dart:io';
import 'package:path/path.dart' as p;

/// Валидатор путей для обеспечения безопасности файловых операций
class PathValidator {
  /// Максимальная длина пути
  static const int maxPathLength = 4096;

  /// Системные директории, доступ к которым запрещен
  static final List<String> _forbiddenDirs = [
    '/System',
    '/Library',
    '/bin',
    '/sbin',
    '/usr/bin',
    '/usr/sbin',
    '/etc',
    'C:\\Windows',
    'C:\\Program Files',
    'C:\\Program Files (x86)',
  ];
  
  /// Системные директории, которые разрешены (исключения)
  static final List<String> _allowedSystemDirs = [
    '/var/folders', // Временные директории на macOS
    '/tmp',
    '/private/tmp',
    '/private/var/folders',
  ];

  /// Рабочая директория проекта
  final String workspaceRoot;

  PathValidator({required this.workspaceRoot});

  /// Проверяет безопасность пути
  /// 
  /// Возвращает [PathValidationResult] с результатом проверки.
  /// Если путь безопасен, [PathValidationResult.isValid] будет true,
  /// и [PathValidationResult.normalizedPath] будет содержать нормализованный путь.
  PathValidationResult isPathSafe(String path) {
    // Проверка на пустой путь
    if (path.isEmpty) {
      return PathValidationResult.invalid('Path cannot be empty');
    }

    // Проверка на null bytes
    if (path.contains('\x00')) {
      return PathValidationResult.invalid('Path contains null bytes');
    }

    // Проверка длины пути
    if (path.length > maxPathLength) {
      return PathValidationResult.invalid(
        'Path exceeds maximum length of $maxPathLength characters',
      );
    }

    // Проверка на абсолютные пути
    if (p.isAbsolute(path)) {
      return PathValidationResult.invalid(
        'Absolute paths are not allowed. Use relative paths only.',
      );
    }

    // Проверка на path traversal (..)
    final parts = p.split(path);
    if (parts.contains('..')) {
      return PathValidationResult.invalid(
        'Path traversal (..) is not allowed',
      );
    }

    // Удаляем префикс ./ если есть
    String cleanPath = path;
    if (cleanPath.startsWith('./')) {
      cleanPath = cleanPath.substring(2);
    } else if (cleanPath == '.') {
      cleanPath = '';
    }
    
    // Нормализация пути
    final normalizedPath = cleanPath.isEmpty ? '.' : p.normalize(cleanPath);

    // Построение полного пути
    // Если normalizedPath это '.', используем workspaceRoot напрямую
    final fullPath = normalizedPath == '.'
        ? workspaceRoot
        : p.join(workspaceRoot, normalizedPath);
    final canonicalPath = _getCanonicalPath(fullPath);

    // Проверка, что путь находится внутри workspace
    if (!_isWithinWorkspace(canonicalPath)) {
      return PathValidationResult.invalid(
        'Path is outside workspace directory',
      );
    }

    // Проверка на системные директории
    if (_isSystemDirectory(canonicalPath)) {
      return PathValidationResult.invalid(
        'Access to system directories is forbidden',
      );
    }

    // Проверка на символические ссылки вне workspace
    if (_isSymlinkOutsideWorkspace(fullPath)) {
      return PathValidationResult.invalid(
        'Symbolic links outside workspace are not allowed',
      );
    }

    return PathValidationResult.valid(normalizedPath, canonicalPath);
  }

  /// Получает канонический путь (разрешает символические ссылки)
  String _getCanonicalPath(String path) {
    try {
      // Сначала пытаемся разрешить как файл
      final file = File(path);
      if (file.existsSync()) {
        return file.resolveSymbolicLinksSync();
      }
      
      // Затем как директорию
      final dir = Directory(path);
      if (dir.existsSync()) {
        return dir.resolveSymbolicLinksSync();
      }
      
      // Если не существует, разрешаем родительскую директорию
      // и добавляем имя файла
      var parentPath = p.dirname(path);
      final fileName = p.basename(path);
      
      // Рекурсивно ищем существующую родительскую директорию
      while (parentPath != p.dirname(parentPath)) {
        final parentDir = Directory(parentPath);
        if (parentDir.existsSync()) {
          final resolvedParent = parentDir.resolveSymbolicLinksSync();
          // Восстанавливаем полный путь
          final remainingPath = p.relative(path, from: parentPath);
          return p.normalize(p.join(resolvedParent, remainingPath));
        }
        parentPath = p.dirname(parentPath);
      }
      
      // Если ничего не нашли, возвращаем нормализованный путь
      return p.normalize(path);
    } catch (e) {
      // Если не удается разрешить, используем нормализованный путь
      return p.normalize(path);
    }
  }

  /// Проверяет, находится ли путь внутри workspace
  bool _isWithinWorkspace(String canonicalPath) {
    try {
      // Разрешаем workspace root
      final workspaceDir = Directory(workspaceRoot);
      final workspaceCanonical = workspaceDir.existsSync()
          ? workspaceDir.resolveSymbolicLinksSync()
          : p.normalize(workspaceRoot);
      
      final normalizedCanonical = p.normalize(canonicalPath);
      final normalizedWorkspace = p.normalize(workspaceCanonical);
      
      return p.isWithin(normalizedWorkspace, normalizedCanonical) ||
          normalizedCanonical == normalizedWorkspace;
    } catch (e) {
      // В случае ошибки используем простую нормализацию
      final normalizedCanonical = p.normalize(canonicalPath);
      final normalizedWorkspace = p.normalize(workspaceRoot);
      
      return p.isWithin(normalizedWorkspace, normalizedCanonical) ||
          normalizedCanonical == normalizedWorkspace;
    }
  }

  /// Проверяет, является ли путь системной директорией
  bool _isSystemDirectory(String path) {
    // Сначала проверяем разрешенные директории
    for (final allowedDir in _allowedSystemDirs) {
      if (path.startsWith(allowedDir)) {
        return false;
      }
    }
    
    // Затем проверяем запрещенные директории
    for (final forbiddenDir in _forbiddenDirs) {
      if (path.startsWith(forbiddenDir)) {
        return true;
      }
    }
    return false;
  }

  /// Проверяет, является ли путь символической ссылкой вне workspace
  bool _isSymlinkOutsideWorkspace(String path) {
    try {
      final link = Link(path);
      if (link.existsSync()) {
        final target = link.targetSync();
        final targetCanonical = _getCanonicalPath(target);
        return !_isWithinWorkspace(targetCanonical);
      }
      return false;
    } catch (e) {
      // Если не удается проверить, считаем безопасным
      return false;
    }
  }

  /// Валидирует путь и возвращает полный путь к файлу
  /// 
  /// Выбрасывает [PathValidationException] если путь небезопасен.
  String validateAndGetFullPath(String path) {
    print('[PathValidator] Validating path: "$path"');
    print('[PathValidator] Workspace root: "$workspaceRoot"');
    
    final result = isPathSafe(path);
    
    if (!result.isValid) {
      print('[PathValidator] Validation failed: ${result.error}');
      throw PathValidationException(result.error!);
    }
    
    print('[PathValidator] Validation successful');
    print('[PathValidator] Normalized path: "${result.normalizedPath}"');
    print('[PathValidator] Full path: "${result.fullPath}"');
    
    return result.fullPath!;
  }
}

/// Результат валидации пути
class PathValidationResult {
  /// Является ли путь валидным
  final bool isValid;

  /// Нормализованный относительный путь (если валиден)
  final String? normalizedPath;

  /// Полный канонический путь (если валиден)
  final String? fullPath;

  /// Сообщение об ошибке (если не валиден)
  final String? error;

  const PathValidationResult._({
    required this.isValid,
    this.normalizedPath,
    this.fullPath,
    this.error,
  });

  /// Создает результат для валидного пути
  factory PathValidationResult.valid(
    String normalizedPath,
    String fullPath,
  ) {
    return PathValidationResult._(
      isValid: true,
      normalizedPath: normalizedPath,
      fullPath: fullPath,
    );
  }

  /// Создает результат для невалидного пути
  factory PathValidationResult.invalid(String error) {
    return PathValidationResult._(
      isValid: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (isValid) {
      return 'PathValidationResult(valid: $normalizedPath)';
    } else {
      return 'PathValidationResult(invalid: $error)';
    }
  }
}

/// Исключение валидации пути
class PathValidationException implements Exception {
  final String message;

  const PathValidationException(this.message);

  @override
  String toString() => 'PathValidationException: $message';
}
