import 'package:fluent_ui/fluent_ui.dart';

class BottomPanel extends StatefulWidget {
  const BottomPanel({super.key});
  @override
  State<BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<BottomPanel> {
  int currentIndex = 2; // Terminal по умолчанию
  final List<String> tabTitles = const [
    'PROBLEMS',
    'OUTPUT',
    'TERMINAL',
    'TEST RESULTS',
    'PORTS',
    'DEBUG CONSOLE',
  ];

  @override
  Widget build(BuildContext context) {
    return TabView(
      tabWidthBehavior: TabWidthBehavior.sizeToContent,
      currentIndex: currentIndex,
      onChanged: (i) => setState(() => currentIndex = i),
      tabs: [
        for (final title in tabTitles)
          Tab(
            text: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            body: Center(
              child: Text(
                '$title\n(Здесь будет содержимое $title)',
                style: const TextStyle(fontSize: 16, color: Color(0xFF888888)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
