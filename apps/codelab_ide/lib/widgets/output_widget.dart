// packages/codelab_terminal/lib/src/widgets/output_widget.dart
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class OutputWidget extends StatefulWidget {
  /// Если terminal не задан — будет создан новый.
  final Terminal? terminal;
  const OutputWidget({super.key, this.terminal});

  @override
  State<OutputWidget> createState() => _OutputWidgetState();
}

class _OutputWidgetState extends State<OutputWidget> {
  late Terminal _terminal;
  late TerminalController _controller;

  @override
  void initState() {
    super.initState();
    _terminal = widget.terminal ?? Terminal(maxLines: 10000);
    _controller = TerminalController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Простой Header для контекста
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.bug_report, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Output',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                tooltip: 'Clear output',
                onPressed: () => _terminal.deleteLines(10000),
              ),
            ],
          ),
        ),
        // Scrollable только для вывода
        Expanded(
          child: TerminalView(
            _terminal,
            controller: _controller,
            autofocus: false,
            readOnly: true, // Запрет на ввод
            backgroundOpacity: 1.0,
          ),
        ),
      ],
    );
  }

  /// Для удобства, можно дать способ получить terminal
  Terminal get terminal => _terminal;
}
