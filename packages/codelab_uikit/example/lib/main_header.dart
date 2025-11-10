import 'package:fluent_ui/fluent_ui.dart';

class MainHeader extends StatelessWidget {
  const MainHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Codelab IDE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        IconButton(icon: const Icon(FluentIcons.save), onPressed: () {}),
        IconButton(icon: const Icon(FluentIcons.play), onPressed: () {}),
        IconButton(icon: const Icon(FluentIcons.settings), onPressed: () {}),
      ],
    );
  }
}
