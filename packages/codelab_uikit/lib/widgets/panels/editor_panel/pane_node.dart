// pane_node.dart

import 'package:codelab_uikit/models/editor_tab.dart';

/// Абстрактный основной тип для элементов панели редактора
abstract class PaneNode {}

/// Одна группа вкладок редактора
class EditorTabsPane extends PaneNode {
  List<EditorTab> tabs;
  int selectedIndex;
  EditorTabsPane({required this.tabs, this.selectedIndex = 0});
}

/// Сплит-панель (split view)
class SplitPane extends PaneNode {
  bool isVertical;
  double fraction;
  PaneNode first;
  PaneNode second;
  SplitPane({
    required this.isVertical,
    required this.fraction,
    required this.first,
    required this.second,
  });
}
