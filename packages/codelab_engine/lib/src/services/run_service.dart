import 'dart:io';
import 'dart:async';

import 'package:codelab_engine/src/services/file_service.dart';

abstract interface class RunService {
  Future<String> runCommand(String command, {String? workingDirectory});
  Future<Process> startProcess(String command, {String? workingDirectory});
  String getRunCommand(String filePath);
}

class RunServiceImpl implements RunService {
  final FileService _fileService;

  RunServiceImpl({required FileService fileService})
    : _fileService = fileService;

  @override
  Future<String> runCommand(String command, {String? workingDirectory}) async {
    try {
      final result = await Process.run(
        command.split(' ')[0],
        command.split(' ').sublist(1),
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        return result.stdout.toString();
      } else {
        return 'Error: ${result.stderr}';
      }
    } catch (e) {
      return 'Error running command: $e';
    }
  }

  @override
  Future<Process> startProcess(
    String command, {
    String? workingDirectory,
  }) async {
    final parts = command.split(' ');
    return await Process.start(
      parts[0],
      parts.sublist(1),
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }

  @override
  String getRunCommand(String filePath) {
    final extension = _fileService.getFileExtension(filePath);

    switch (extension) {
      case 'dart':
        return 'dart run $filePath';
      case 'py':
        return 'python $filePath';
      case 'js':
        return 'node $filePath';
      case 'java':
        final className = filePath.split('/').last.replaceAll('.java', '');
        return 'javac $filePath && java $className';
      case 'cpp':
        final outputName = filePath.replaceAll('.cpp', '');
        return 'g++ $filePath -o $outputName && ./$outputName';
      case 'c':
        final outputName = filePath.replaceAll('.c', '');
        return 'gcc $filePath -o $outputName && ./$outputName';
      default:
        return 'echo "Unsupported file type: .$extension"';
    }
  }
}
