import 'package:fluent_ui/fluent_ui.dart';

class IdeLayout extends StatelessWidget {
  final Widget? sidebarNavigation;
  final Widget? sidebarPanel;
  final double sidebarPanelWidth;
  final Widget? sidebarSplitter;
  final Widget centerPanel;
  final Widget? aiPanel;
  final Widget? aiSplitter;
  final Widget? statusBar;
  final bool showSidebar;
  final bool showAiPanel;
  final double aiPanelWidth;

  const IdeLayout({
    super.key,
    this.sidebarNavigation,
    this.sidebarPanel,
    this.sidebarPanelWidth = 200,
    this.sidebarSplitter,
    required this.centerPanel,
    this.aiPanel,
    this.aiPanelWidth = 320,
    this.aiSplitter,
    this.statusBar,
    this.showSidebar = true,
    this.showAiPanel = false,
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
              if (showAiPanel && aiSplitter != null) aiSplitter!,
              if (showAiPanel && aiPanel != null)
                SizedBox(width: aiPanelWidth, child: aiPanel!),
            ],
          ),
        ),
        if (statusBar != null) statusBar!,
      ],
    );
  }
}
