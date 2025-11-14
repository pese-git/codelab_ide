import 'package:codelab_uikit/codelab_uikit.dart' as uikit;
import 'package:fluent_ui/fluent_ui.dart';

import '../../widgets/editor_panel_wrapper.dart';

class EditorPanel extends StatelessWidget {
  final GlobalKey<uikit.EditorPanelState> editorPanelKey;

  const EditorPanel({super.key, required this.editorPanelKey});

  @override
  Widget build(BuildContext context) {
    return EditorPanelWrapper(key: editorPanelKey);
  }
}
