import 'package:cherrypick/cherrypick.dart';
import 'package:codelab_engine/src/services/run_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'terminal_bloc.dart';

class TerminalWidget extends StatefulWidget {
  final String? projectDirectory;
  const TerminalWidget({super.key, this.projectDirectory});

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitCommand(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<TerminalBloc>().add(TerminalEvent.executeCommand(text));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TerminalBloc(
        runService: CherryPick.openRootScope().resolve<RunService>(),
      )..add(TerminalEvent.clear(projectDirectory: widget.projectDirectory)),
      child: BlocConsumer<TerminalBloc, TerminalState>(
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
        listener: (BuildContext context, TerminalState state) {
          _scrollToBottom();
        },
      ),
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
