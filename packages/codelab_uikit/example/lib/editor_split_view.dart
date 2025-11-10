import 'package:fluent_ui/fluent_ui.dart';
import 'editor_panel.dart';

class EditorSplitView extends StatefulWidget {
  final double splitFraction;
  final ValueChanged<double> onDrag;
  const EditorSplitView({
    super.key,
    required this.splitFraction,
    required this.onDrag,
  });

  @override
  State<EditorSplitView> createState() => _EditorSplitViewState();
}

class _EditorSplitViewState extends State<EditorSplitView> {
  double? _dragStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaWidth = constraints.maxWidth;
        final leftWidth = areaWidth * widget.splitFraction - 8;
        final rightWidth = areaWidth * (1 - widget.splitFraction);
        return Row(
          children: [
            SizedBox(
              width: leftWidth.clamp(100, areaWidth - 100),
              child: const EditorPanel(label: 'Editor 1'),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (details) {
                _dragStart = details.localPosition.dx;
              },
              onHorizontalDragUpdate: (details) {
                final d = details.localPosition.dx - (_dragStart ?? 0);
                final fraction = (widget.splitFraction + d / areaWidth).clamp(
                  0.15,
                  0.85,
                );
                widget.onDrag(fraction);
                _dragStart = details.localPosition.dx;
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 8,
                  color: Colors.grey[30],
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[110],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: rightWidth.clamp(100, areaWidth - 100),
              child: const EditorPanel(label: 'Editor 2'),
            ),
          ],
        );
      },
    );
  }
}


