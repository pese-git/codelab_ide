import 'package:codelab_uikit/widgets/placeholder/start_wizard.dart';
import 'package:fluent_ui/fluent_ui.dart';

class StartWizardPanel extends StatelessWidget {
  final void Function(String action) onAction;

  const StartWizardPanel({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return StartWizard(onAction: onAction);
  }
}
