import 'package:fluent_ui/fluent_ui.dart';
import '../splitters/vertical_splitter.dart';

class RunAndDebugPanel extends StatefulWidget {
  const RunAndDebugPanel({super.key});

  @override
  State<RunAndDebugPanel> createState() => _RunAndDebugPanelState();
}

class _RunAndDebugPanelState extends State<RunAndDebugPanel> {
  bool _variablesExpanded = true;
  bool _watchExpanded = false;
  bool _callStackExpanded = false;
  bool _breakpointsExpanded = true;

  // Контролируемые высоты секций для вертикальных сплиттеров
  // Высоты секций (текущие)
  double variablesHeight = 100;
  double watchHeight = 64;
  double callStackHeight = 80;

  // Сохраняем "preferred" (расширенные) высоты,
  // чтобы возвращать их при повторном раскрытии
  double savedVariablesHeight = 100;
  double savedWatchHeight = 64;
  double savedCallStackHeight = 80;

  final double minHeaderHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.grey[20],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'RUN AND DEBUG',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.play),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(FluentIcons.stop),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(style: DividerThemeData(thickness: 1)),
          // Dropdown for launch configs (заглушка)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ComboBox<String>(
              placeholder: const Text('Select configuration'),
              items: const [
                ComboBoxItem(child: Text('Launch main.dart'), value: 'main'),
              ],
              onChanged: (val) {},
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              children: [
                // VARIABLES
                _ExpanderWithFlexibleHeight(
                  expanded: _variablesExpanded,
                  expandedHeight: variablesHeight,
                  minHeaderHeight: minHeaderHeight,
                  child: Expander(
                    leading: const Icon(FluentIcons.variable_group),
                    header: const Text(
                      'VARIABLES',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _variablesExpanded,
                    onStateChanged: (expanded) => setState(() {
                      _variablesExpanded = expanded;
                      if (expanded) {
                        variablesHeight = savedVariablesHeight;
                      } else {
                        savedVariablesHeight = variablesHeight;
                        variablesHeight = minHeaderHeight;
                      }
                    }),
                    content: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'No variables to show',
                        style: TextStyle(color: Colors.grey[100]),
                      ),
                    ),
                  ),
                ),
                VerticalSplitter(
                  onDrag: (delta) => setState(() {
                    variablesHeight = (variablesHeight + delta).clamp(
                      60.0,
                      300.0,
                    );
                  }),
                ),
                // WATCH
                _ExpanderWithFlexibleHeight(
                  expanded: _watchExpanded,
                  expandedHeight: watchHeight,
                  minHeaderHeight: minHeaderHeight,
                  child: Expander(
                    leading: const Icon(FluentIcons.view),
                    header: const Text(
                      'WATCH',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _watchExpanded,
                    onStateChanged: (expanded) => setState(() {
                      _watchExpanded = expanded;
                      if (expanded) {
                        watchHeight = savedWatchHeight;
                      } else {
                        savedWatchHeight = watchHeight;
                        watchHeight = minHeaderHeight;
                      }
                    }),
                    content: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'No watch expressions',
                        style: TextStyle(color: Colors.grey[100]),
                      ),
                    ),
                  ),
                ),
                VerticalSplitter(
                  onDrag: (delta) => setState(() {
                    watchHeight = (watchHeight + delta).clamp(40.0, 250.0);
                  }),
                ),
                // CALL STACK
                _ExpanderWithFlexibleHeight(
                  expanded: _callStackExpanded,
                  expandedHeight: callStackHeight,
                  minHeaderHeight: minHeaderHeight,
                  child: Expander(
                    leading: const Icon(FluentIcons.bug),
                    header: const Text(
                      'CALL STACK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _callStackExpanded,
                    onStateChanged: (expanded) => setState(() {
                      _callStackExpanded = expanded;
                      if (expanded) {
                        callStackHeight = savedCallStackHeight;
                      } else {
                        savedCallStackHeight = callStackHeight;
                        callStackHeight = minHeaderHeight;
                      }
                    }),
                    content: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'Not running',
                        style: TextStyle(color: Colors.grey[100]),
                      ),
                    ),
                  ),
                ),
                VerticalSplitter(
                  onDrag: (delta) => setState(() {
                    callStackHeight = (callStackHeight + delta).clamp(
                      40.0,
                      250.0,
                    );
                  }),
                ),
                // BREAKPOINTS
                Expanded(
                  child: Expander(
                    leading: const Icon(FluentIcons.bookmark_report),
                    header: const Text(
                      'BREAKPOINTS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: _breakpointsExpanded,
                    onStateChanged: (expanded) =>
                        setState(() => _breakpointsExpanded = expanded),
                    content: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'No breakpoints',
                        style: TextStyle(color: Colors.grey[100]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpanderWithFlexibleHeight extends StatelessWidget {
  final bool expanded;
  final double expandedHeight;
  final double minHeaderHeight;
  final Widget child;

  const _ExpanderWithFlexibleHeight({
    required this.expanded,
    required this.expandedHeight,
    required this.minHeaderHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return SizedBox(height: expandedHeight, child: child);
    } else {
      // minHeaderHeight "страхует" если Expander не может ужаться меньше header
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeaderHeight),
        child: child,
      );
    }
  }
}
