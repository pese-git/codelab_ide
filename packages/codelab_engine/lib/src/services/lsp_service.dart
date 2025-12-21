import 'dart:io';
import 'package:code_forge/code_forge.dart';
import 'package:codelab_core/codelab_core.dart';

class LspService {
  LspConfig? _lspConfig;
  bool _isInitialized = false;
  String? _workspacePath;

  /// Получить текущую конфигурацию LSP
  LspConfig? get config => _lspConfig;

  /// Проверить, инициализирован ли LSP
  bool get isInitialized => _isInitialized;

  /// Инициализировать LSP для рабочего пространства
  Future<void> initialize(String workspacePath) async {
    if (_isInitialized && workspacePath == _workspacePath) {
      codelabLogger.d(
        'LSP already initialized for workspace: $workspacePath',
        tag: 'lsp_service',
      );
      return;
    }

    try {
      codelabLogger.d(
        'Initializing LSP for workspace: $workspacePath',
        tag: 'lsp_service',
      );

      final dartPath = await _getDartSdkPath();
      if (dartPath == null) {
        codelabLogger.e(
          'Failed to find Dart SDK path',
          tag: 'lsp_service',
        );
        return;
      }

      codelabLogger.d(
        'Found Dart SDK at: $dartPath',
        tag: 'lsp_service',
      );

      _lspConfig = await LspStdioConfig.start(
        executable: '$dartPath/bin/dart',
        workspacePath: workspacePath,
        languageId: 'dart',
      );

      _isInitialized = true;
      _workspacePath = workspacePath;

      codelabLogger.d(
        'LSP initialized successfully',
        tag: 'lsp_service',
      );
    } catch (e, stack) {
      codelabLogger.e(
        'Error initializing LSP',
        tag: 'lsp_service',
        error: e,
        stackTrace: stack,
      );
      _isInitialized = false;
      _lspConfig = null;
    }
  }

  /// Найти путь к Dart SDK
  Future<String?> _getDartSdkPath() async {
    try {
      // Пробуем найти через flutter doctor
      final result = await Process.run('flutter', ['doctor', '-v']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'Dart SDK version: .* at ([^\n]+)').firstMatch(output);
        if (match != null) {
          final sdkPath = match.group(1)?.trim();
          codelabLogger.d(
            'Found Dart SDK through flutter doctor: $sdkPath',
            tag: 'lsp_service',
          );
          return sdkPath;
        }
      }

      // Запасной вариант - через which dart
      final dartResult = await Process.run('which', ['dart']);
      if (dartResult.exitCode == 0) {
        final dartPath = (dartResult.stdout as String).trim();
        if (dartPath.isNotEmpty) {
          final sdkPath = dartPath.substring(0, dartPath.lastIndexOf('/bin/dart'));
          codelabLogger.d(
            'Found Dart SDK through which: $sdkPath',
            tag: 'lsp_service',
          );
          return sdkPath;
        }
      }
    } catch (e, stack) {
      codelabLogger.e(
        'Error finding Dart SDK',
        tag: 'lsp_service',
        error: e,
        stackTrace: stack,
      );
    }
    return null;
  }

  /// Освободить ресурсы
  void dispose() {
    _lspConfig = null;
    _isInitialized = false;
    _workspacePath = null;
  }
}
