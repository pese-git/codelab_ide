import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'debug_console_bloc.dart';

class DebugConsoleWidget extends StatefulWidget {
  final String? projectDirectory;
  const DebugConsoleWidget({super.key, this.projectDirectory});

  @override
  State<DebugConsoleWidget> createState() => _DebugConsoleWidgetState();
}

class _DebugConsoleWidgetState extends State<DebugConsoleWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Инициализировать терминал с projectDirectory при создании
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final terminalBloc = context.read<DebugConsoleBloc>();
      terminalBloc.add(
        DebugConsoleEvent.clear(projectDirectory: widget.projectDirectory),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitCommand(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<DebugConsoleBloc>().add(
        DebugConsoleEvent.executeCommand(text),
      );
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebugConsoleBloc, DebugConsoleState>(
      listener: (BuildContext context, DebugConsoleState state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.topLeft,
                child: ListView(
                  controller: _scrollController,
                  children: state.output
                      .map(
                        (line) => Text(
                          line,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onSubmitted: (_) => _submitCommand(context),
                  ),
                ),
                /*
                  IconButton(
                    color: Colors.black,
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _submitCommand(context),
                  ),
                  IconButton(
                    color: Colors.black,
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      context.read<TerminalBloc>().add(
                        const TerminalEvent.clear(),
                      );
                    },
                  ),
                  */
              ],
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
