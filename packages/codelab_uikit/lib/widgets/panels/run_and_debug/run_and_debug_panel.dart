import 'package:codelab_uikit/widgets/panels/run_and_debug/header_section.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../splitters/vertical_splitter.dart';
import 'variables_section.dart';
import 'watch_section.dart';
import 'call_stack_section.dart';
import 'breakpoints_section.dart';

class RunAndDebugPanel extends StatefulWidget {
  final Widget? headerSection;
  final Widget? variablesSection;
  final Widget? watchSection;
  final Widget? callStackSection;
  final Widget? breakpointsSection;

  const RunAndDebugPanel({
    super.key,
    this.headerSection,
    this.variablesSection,
    this.watchSection,
    this.callStackSection,
    this.breakpointsSection,
  });

  @override
  State<RunAndDebugPanel> createState() => _RunAndDebugPanelState();
}

class _RunAndDebugPanelState extends State<RunAndDebugPanel> {
  // Стейты секций
  bool _variablesExpanded = true;
  bool _watchExpanded = false;
  bool _callStackExpanded = false;

  double _variablesHeight = 100;
  double _watchHeight = 64;
  double _callStackHeight = 80;

  double _savedVariablesHeight = 100;
  double _savedWatchHeight = 64;
  double _savedCallStackHeight = 80;

  final double _minHeaderHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.grey[20],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (slot or default)
          widget.headerSection ?? const HeaderSection(),
          const Divider(style: DividerThemeData(thickness: 1)),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              children: [
                // VARIABLES (section slot)
                widget.variablesSection ??
                    VariablesSection(
                      expanded: _variablesExpanded,
                      height: _variablesHeight,
                      minHeaderHeight: _minHeaderHeight,
                      onExpandedChanged: (expanded) {
                        setState(() {
                          _variablesExpanded = expanded;
                          if (expanded) {
                            _variablesHeight = _savedVariablesHeight;
                          } else {
                            _savedVariablesHeight = _variablesHeight;
                            _variablesHeight = _minHeaderHeight;
                          }
                        });
                      },
                    ),
                VerticalSplitter(
                  onDrag: (delta) => setState(() {
                    _variablesHeight = (_variablesHeight + delta).clamp(
                      60.0,
                      300.0,
                    );
                  }),
                ),
                // WATCH (section slot)
                widget.watchSection ??
                    WatchSection(
                      expanded: _watchExpanded,
                      height: _watchHeight,
                      minHeaderHeight: _minHeaderHeight,
                      onExpandedChanged: (expanded) {
                        setState(() {
                          _watchExpanded = expanded;
                          if (expanded) {
                            _watchHeight = _savedWatchHeight;
                          } else {
                            _savedWatchHeight = _watchHeight;
                            _watchHeight = _minHeaderHeight;
                          }
                        });
                      },
                    ),
                VerticalSplitter(
                  onDrag: (delta) => setState(() {
                    _watchHeight = (_watchHeight + delta).clamp(40.0, 250.0);
                  }),
                ),
                // CALL STACK (section slot)
                widget.callStackSection ??
                    CallStackSection(
                      expanded: _callStackExpanded,
                      height: _callStackHeight,
                      minHeaderHeight: _minHeaderHeight,
                      onExpandedChanged: (expanded) {
                        setState(() {
                          _callStackExpanded = expanded;
                          if (expanded) {
                            _callStackHeight = _savedCallStackHeight;
                          } else {
                            _savedCallStackHeight = _callStackHeight;
                            _callStackHeight = _minHeaderHeight;
                          }
                        });
                      },
                    ),
                VerticalSplitter(
                  onDrag: (delta) => setState(() {
                    _callStackHeight = (_callStackHeight + delta).clamp(
                      40.0,
                      250.0,
                    );
                  }),
                ),
                // BREAKPOINTS (section slot)
                widget.breakpointsSection ?? const BreakpointsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// (ExpanderWithFlexibleHeight теперь внешний)
