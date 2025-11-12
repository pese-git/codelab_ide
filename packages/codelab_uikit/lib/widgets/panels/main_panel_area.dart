import 'package:flutter/widgets.dart';

class MainPanelArea extends StatelessWidget {
  final bool projectOpened;
  final Widget? workspaceSlot;
  final Widget? emptySlot;

  const MainPanelArea({
    super.key,
    required this.projectOpened,
    this.workspaceSlot,
    this.emptySlot,
  });

  @override
  Widget build(BuildContext context) {
    if (projectOpened) {
      return workspaceSlot ?? const SizedBox.shrink();
    } else {
      return emptySlot ?? const SizedBox.shrink();
    }
  }
}
