import 'package:fluent_ui/fluent_ui.dart';

class StartWizard extends StatelessWidget {
  final void Function(String action) onAction;
  const StartWizard({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 480,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.product, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Codelab IDE!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Get started by creating or opening a project.',
                    style: TextStyle(color: Color(0xFF888888))),
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      child: const Text('Open Project'),
                      onPressed: () => onAction('open'),
                    ),
                    const SizedBox(height: 12),
                    Button(
                      child: const Text('Create New Project'),
                      onPressed: () => onAction('create'),
                    ),
                    const SizedBox(height: 12),
                    Button(
                      child: const Text('Clone from Git'),
                      onPressed: () => onAction('clone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
