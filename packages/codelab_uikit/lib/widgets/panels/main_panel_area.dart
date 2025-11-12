import 'editor_panel.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../placeholder/start_wizard.dart';

class MainPanelArea extends StatelessWidget {
  final GlobalKey<EditorPanelState> editorPanelKey;
  final bool projectOpened;
  final double editorSplitFraction;
  final ValueChanged<double> onEditorDrag;
  final void Function(String action) onWizardAction;
  const MainPanelArea({
    super.key,
    required this.editorPanelKey,
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
    return EditorPanel(key: editorPanelKey, label: 'Editor 1');
  }
}
