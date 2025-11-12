import 'package:fluent_ui/fluent_ui.dart';

class HorizontalSplitter extends StatelessWidget {
  final ValueChanged<double> onDrag;
  const HorizontalSplitter({required this.onDrag, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        onDrag(details.delta.dx);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 8,
          color: Colors.grey[30],
          alignment: Alignment.center,
          child: Container(
            height: 40,
            width: 4,
            decoration: BoxDecoration(
              color: Colors.grey[110],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
