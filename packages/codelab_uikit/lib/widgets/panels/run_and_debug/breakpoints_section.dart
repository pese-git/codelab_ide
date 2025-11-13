import 'package:fluent_ui/fluent_ui.dart';

class BreakpointsSection extends StatefulWidget {
  const BreakpointsSection({super.key});

  @override
  State<BreakpointsSection> createState() => _BreakpointsSectionState();
}

class _BreakpointsSectionState extends State<BreakpointsSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Expander(
        leading: const Icon(FluentIcons.bookmark_report),
        header: const Text(
          'BREAKPOINTS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: _expanded,
        onStateChanged: (expanded) => setState(() {
          _expanded = expanded;
        }),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            'No breakpoints',
            style: TextStyle(color: Colors.grey[100]),
          ),
        ),
      ),
    );
  }
}
