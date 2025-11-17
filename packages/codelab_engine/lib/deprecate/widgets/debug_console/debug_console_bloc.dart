import 'package:codelab_core/codelab_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'debug_console_bloc.freezed.dart';

@freezed
class DebugConsoleEvent with _$DebugConsoleEvent {
  /// Выполнить новую команду (пользовательский ввод)
  const factory DebugConsoleEvent.executeCommand(String command) =
      ExecuteCommand;

  /// Добавить строку вывода (stdout/stderr)
  const factory DebugConsoleEvent.appendOutput(String output) = AppendOutput;

  /// Очистить терминал
  const factory DebugConsoleEvent.clear({String? projectDirectory}) =
      ClearTerminal;

  /// Сообщить о завершении процесса
  const factory DebugConsoleEvent.processExited(int exitCode) = ProcessExited;
}

@freezed
abstract class DebugConsoleState with _$DebugConsoleState {
  const factory DebugConsoleState({
    @Default(<String>[]) List<String> output,
    @Default(false) bool isRunning,
    String? lastCommand,
    int? lastExitCode,
  }) = _TerminalState;
}

class DebugConsoleBloc extends Bloc<DebugConsoleEvent, DebugConsoleState> {
  final RunService _runService;

  DebugConsoleBloc({required RunService runService})
    : _runService = runService,
      super(const DebugConsoleState()) {
    on<ExecuteCommand>((event, emit) async {
      var output = List<String>.from(state.output);

      if (event.command.trim().isEmpty) return;

      if (event.command.trim() == 'clear') {
        output.clear();
        output.add('Terminal cleared');
        output.add('');
        emit(state.copyWith(output: output));
        return;
      }

      output.add('\$ ${event.command}');
      output.add('Executing...');
      emit(state.copyWith(output: output));

      final result = await _runService
          .runCommand(
            event.command,
            //workingDirectory: event.workingDirectory,
          )
          .run();

      result.match(
        (error) {
          final updatedOutput = List<String>.from(output);
          if (updatedOutput.isNotEmpty &&
              updatedOutput.last == 'Executing...') {
            updatedOutput.removeLast();
          }
          updatedOutput.add(error.toString());
          updatedOutput.add('');
          emit(state.copyWith(output: updatedOutput));
        },
        (result) {
          final updatedOutput = List<String>.from(output);
          if (updatedOutput.isNotEmpty &&
              updatedOutput.last == 'Executing...') {
            updatedOutput.removeLast();
          }
          updatedOutput.add(result);
          updatedOutput.add('');
          emit(state.copyWith(output: updatedOutput));
        },
      );
    });

    on<AppendOutput>((event, emit) {
      final updated = List<String>.from(state.output)..add(event.output);
      emit(state.copyWith(output: updated));
    });

    on<ClearTerminal>((event, emit) {
      final output = List<String>.from(<String>[])
        ..add('Welcome to CodeLab IDE Debug Console')
        ..add('Working directory: ${event.projectDirectory ?? 'Not set'}')
        ..add('Type commands and press Enter to execute')
        ..add('');
      emit(state.copyWith(output: output));
      if (event.projectDirectory != null) {
        add(DebugConsoleEvent.executeCommand("cd ${event.projectDirectory}"));
      }
    });

    on<ProcessExited>((event, emit) {
      emit(state.copyWith(isRunning: false, lastExitCode: event.exitCode));
    });
  }
}
