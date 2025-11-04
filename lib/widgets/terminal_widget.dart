import 'package:flutter/material.dart';
import '../services/run_service.dart';

class TerminalWidget extends StatefulWidget {
  final String? workingDirectory;

  const TerminalWidget({
    Key? key,
    this.workingDirectory,
  }) : super(key: key);

  @override
  _TerminalWidgetState createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  final TextEditingController _commandController = TextEditingController();
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _output.add('Welcome to CodeLab IDE Terminal');
    _output.add('Working directory: ${widget.workingDirectory ?? 'Not set'}');
    _output.add('Type commands and press Enter to execute');
    _output.add('');
  }

  void _executeCommand(String command) {
    if (command.trim().isEmpty) return;

    _output.add('\$ $command');
    
    if (command == 'clear') {
      setState(() {
        _output.clear();
        _output.add('Terminal cleared');
        _output.add('');
      });
      _scrollToBottom();
      return;
    }

    // Show loading
    _output.add('Executing...');
    _scrollToBottom();

    // Execute the command
    RunService.runCommand(command, workingDirectory: widget.workingDirectory)
        .then((result) {
      setState(() {
        _output.removeLast(); // Remove "Executing..."
        _output.add(result);
        _output.add('');
      });
      _scrollToBottom();
    }).catchError((error) {
      setState(() {
        _output.removeLast(); // Remove "Executing..."
        _output.add('Error: $error');
        _output.add('');
      });
      _scrollToBottom();
    });

    _commandController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.terminal, size: 16),
              const SizedBox(width: 8),
              Text(
                'Terminal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _output.clear();
                    _output.add('Terminal cleared');
                    _output.add('');
                  });
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _output.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _output[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[700]!)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '\$ ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _commandController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type command...',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          onSubmitted: _executeCommand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
