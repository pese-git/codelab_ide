import 'package:fluent_ui/fluent_ui.dart';

class StatusBar extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;
  final Widget? middle; // опционально, если нужно больше областей

  const StatusBar({super.key, this.leading, this.trailing, this.middle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: const Color(0xFFf2f2f2),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (leading != null) leading!,
          const Spacer(),
          if (middle != null) middle!,
          if (trailing != null) ...[
            // Основной статус справа по умолчанию
            trailing!,
          ] else
            const Text(
              'Ln 1, Col 1   Spaces: 2   UTF-8',
              style: TextStyle(fontSize: 13, color: Color(0xFF4e4e4e)),
            ),
        ],
      ),
    );
  }
}
