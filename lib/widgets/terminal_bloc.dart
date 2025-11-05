import 'package:codelab_ide/services/run_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'terminal_bloc.freezed.dart';

@freezed
class TerminalEvent with _$TerminalEvent {
  /// Выполнить новую команду (пользовательский ввод)
  const factory TerminalEvent.executeCommand(String command) = ExecuteCommand;

  /// Добавить строку вывода (stdout/stderr)
  const factory TerminalEvent.appendOutput(String output) = AppendOutput;

  /// Очистить терминал
  const factory TerminalEvent.clear({String? projectDirectory}) = ClearTerminal;

  /// Сообщить о завершении процесса
  const factory TerminalEvent.processExited(int exitCode) = ProcessExited;
}

@freezed
class TerminalState with _$TerminalState {
  const factory TerminalState({
    @Default(<String>[]) List<String> output,
    @Default(false) bool isRunning,
    String? lastCommand,
    int? lastExitCode,
  }) = _TerminalState;
}

class TerminalBloc extends Bloc<TerminalEvent, TerminalState> {
  TerminalBloc() : super(const TerminalState()) {
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

      try {
        final result = await RunService.runCommand(
          event.command,
          //workingDirectory: event.workingDirectory,
        );
        output = List<String>.from(state.output);
        if (output.isNotEmpty && output.last == 'Executing...') {
          output.removeLast();
        }
        output.add(result);
        output.add('');
        emit(state.copyWith(output: output));
      } catch (e) {
        output = List<String>.from(state.output);
        if (output.isNotEmpty && output.last == 'Executing...') {
          output.removeLast();
        }
        output.add('Error: $e');
        output.add('');
        emit(state.copyWith(output: output));
      }
    });

    on<AppendOutput>((event, emit) {
      final updated = List<String>.from(state.output)..add(event.output);
      emit(state.copyWith(output: updated));
    });

    on<ClearTerminal>((event, emit) {
      final output = List<String>.from(<String>[])
        ..add('Welcome to CodeLab IDE Terminal')
        ..add('Working directory: ${event.projectDirectory ?? 'Not set'}')
        ..add('Type commands and press Enter to execute')
        ..add('');
      emit(state.copyWith(output: output));
      if (event.projectDirectory != null) {
        add(TerminalEvent.executeCommand("cd ${event.projectDirectory}"));
      }
    });

    on<ProcessExited>((event, emit) {
      emit(state.copyWith(isRunning: false, lastExitCode: event.exitCode));
    });
  }
}
