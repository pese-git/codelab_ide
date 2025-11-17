import 'package:codelab_engine/deprecate/widgets/debug_console/debug_console_widget.dart';
import 'package:flutter/material.dart';

@Deprecated('old code')
class DevToolsWidget extends StatelessWidget {
  const DevToolsWidget({super.key});

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
                onPressed: () {},
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: DebugConsoleWidget()),
      ],
    );
  }
}
