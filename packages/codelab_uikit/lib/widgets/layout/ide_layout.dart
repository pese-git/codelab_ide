import 'package:fluent_ui/fluent_ui.dart';

class IdeLayout extends StatelessWidget {
  final Widget? sidebarNavigation;
  final Widget? sidebarPanel;
  final double sidebarPanelWidth;
  final Widget? sidebarSplitter;
  final Widget centerPanel;
  final Widget? rightPanel;
  final Widget? rightPanelSplitter;
  final Widget? statusBar;
  final bool showSidebar;
  final bool showRightPanel;
  final double rightPanelWidth;

  const IdeLayout({
    super.key,
    this.sidebarNavigation,
    this.sidebarPanel,
    this.sidebarPanelWidth = 200,
    this.sidebarSplitter,
    required this.centerPanel,
    this.rightPanel,
    this.rightPanelWidth = 320,
    this.rightPanelSplitter,
    this.statusBar,
    this.showSidebar = true,
    this.showRightPanel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              if (sidebarNavigation != null) sidebarNavigation!,
              if (showSidebar && sidebarPanel != null)
                SizedBox(width: sidebarPanelWidth, child: sidebarPanel),
              if (showSidebar && sidebarSplitter != null) sidebarSplitter!,
              Expanded(child: centerPanel),
              if (showRightPanel && rightPanelSplitter != null)
                rightPanelSplitter!,
              if (showRightPanel && rightPanel != null)
                SizedBox(width: rightPanelWidth, child: rightPanel!),
            ],
          ),
        ),
        if (statusBar != null) statusBar!,
      ],
    );
  }
}
