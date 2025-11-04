import 'dart:io';
import 'dart:async';
import 'file_service.dart';

class RunService {
  static Future<String> runCommand(String command, {String? workingDirectory}) async {
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

  static Future<Process> startProcess(String command, {String? workingDirectory}) async {
    final parts = command.split(' ');
    return await Process.start(
      parts[0],
      parts.sublist(1),
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }

  static String getRunCommand(String filePath) {
    final extension = FileService.getFileExtension(filePath);
    
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
