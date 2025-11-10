import 'package:example/editor_panel.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'editor_split_view.dart';
import 'start_wizard.dart';

class MainPanelArea extends StatelessWidget {
  final bool projectOpened;
  final double editorSplitFraction;
  final ValueChanged<double> onEditorDrag;
  final void Function(String action) onWizardAction;
  const MainPanelArea({
    super.key,
    required this.projectOpened,
    required this.editorSplitFraction,
    required this.onEditorDrag,
    required this.onWizardAction,
  });

  @override
  Widget build(BuildContext context) {
    if (!projectOpened) {
      return StartWizard(onAction: onWizardAction);
    }
    return const EditorPanel(label: 'Editor 1');
  }
}
