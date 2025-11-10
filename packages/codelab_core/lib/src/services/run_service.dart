import 'dart:io';
import 'package:codelab_core/codelab_core.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class RunService {
  TaskEither<CommandError, String> runCommand(String command, {String? workingDirectory});
  TaskEither<CommandError, Process> startProcess(String command, {String? workingDirectory});
  Either<CommandError, String> getRunCommand(String filePath);
}

class RunServiceImpl implements RunService {
  final FileService _fileService;

  RunServiceImpl({required FileService fileService})
    : _fileService = fileService;

  @override
  TaskEither<CommandError, String> runCommand(String command, {String? workingDirectory}) {
    return TaskEither<CommandError, String>.tryCatch(
      () async {
        final result = await Process.run(
          command.split(' ')[0],
          command.split(' ').sublist(1),
          workingDirectory: workingDirectory,
          runInShell: true,
        );

        if (result.exitCode == 0) {
          return result.stdout.toString();
        } else {
          throw CommandError.executionFailed(
            command, 
            result.exitCode, 
            result.stderr.toString()
          );
        }
      },
      (error, stackTrace) {
        if (error is CommandError) return error;
        return CommandError.processError(command, error);
      },
    );
  }

  @override
  TaskEither<CommandError, Process> startProcess(
    String command, {
    String? workingDirectory,
  }) {
    return TaskEither<CommandError, Process>.tryCatch(
      () async {
        final parts = command.split(' ');
        return await Process.start(
          parts[0],
          parts.sublist(1),
          workingDirectory: workingDirectory,
          runInShell: true,
        );
      },
      (error, stackTrace) => CommandError.processError(command, error),
    );
  }

  @override
  Either<CommandError, String> getRunCommand(String filePath) {
    final extension = _fileService.getFileExtension(filePath);

    switch (extension) {
      case 'dart':
        return Right('dart run $filePath');
      case 'py':
        return Right('python $filePath');
      case 'js':
        return Right('node $filePath');
      case 'java':
        final className = filePath.split('/').last.replaceAll('.java', '');
        return Right('javac $filePath && java $className');
      case 'cpp':
        final outputName = filePath.replaceAll('.cpp', '');
        return Right('g++ $filePath -o $outputName && ./$outputName');
      case 'c':
        final outputName = filePath.replaceAll('.c', '');
        return Right('gcc $filePath -o $outputName && ./$outputName');
      default:
        return Left(CommandError.unsupportedFileType(extension));
    }
  }
}
