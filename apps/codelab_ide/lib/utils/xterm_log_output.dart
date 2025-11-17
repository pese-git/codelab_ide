import 'package:logger/logger.dart';
import 'package:xterm/xterm.dart';
//import 'package:ansicolor/ansicolor.dart';

String cleanLogLine(String input) {
  // Удаляет стандартные ANSI escape
  final ansiEscape = RegExp(r'(\x1B\[|\[)[0-9;]*m');
  return input.replaceAll(ansiEscape, '');
}

class FlatLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return ["[${event.level.name[0].toUpperCase()}] ${event.message}"];
  }
}

class XtermLogOutput extends LogOutput {
  final Terminal terminal;
  XtermLogOutput(this.terminal);

  @override
  void output(OutputEvent event) {
    final clean = cleanLogLine(event.origin.message).trim();
    terminal.write('$clean\r\n');
  }
}
