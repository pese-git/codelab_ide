import 'package:fluent_ui/fluent_ui.dart';

class ExpanderWithFlexibleHeight extends StatelessWidget {
  final bool expanded;
  final double expandedHeight;
  final double minHeaderHeight;
  final Widget child;

  const ExpanderWithFlexibleHeight({
    required this.expanded,
    required this.expandedHeight,
    required this.minHeaderHeight,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return SizedBox(height: expandedHeight, child: child);
    } else {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeaderHeight),
        child: child,
      );
    }
  }
}
