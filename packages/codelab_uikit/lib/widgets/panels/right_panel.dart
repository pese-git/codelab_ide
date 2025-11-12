import 'package:flutter/widgets.dart';

class RightPanel extends StatelessWidget {
  final Widget? aiSlot;
  const RightPanel({super.key, this.aiSlot});

  @override
  Widget build(BuildContext context) {
    return aiSlot ?? const SizedBox.shrink();
  }
}
