import 'package:fluent_ui/fluent_ui.dart';

class BottomPanel extends StatefulWidget {
  final Widget? problemsSlot;
  final Widget? outputSlot;
  final Widget? terminalSlot;
  final Widget? testResultsSlot;
  final Widget? portsSlot;
  final Widget? debugConsoleSlot;

  const BottomPanel({
    super.key,
    this.problemsSlot,
    this.outputSlot,
    this.terminalSlot,
    this.testResultsSlot,
    this.portsSlot,
    this.debugConsoleSlot,
  });

  @override
  State<BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<BottomPanel> {
  int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return TabView(
      tabWidthBehavior: TabWidthBehavior.sizeToContent,
      currentIndex: currentIndex,
      onChanged: (i) => setState(() => currentIndex = i),
      tabs: [
        Tab(
          text: const Text(
            'PROBLEMS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          body:
              widget.problemsSlot ??
              const Center(
                child: Text(
                  'PROBLEMS\n(Здесь будет содержимое PROBLEMS)',
                  style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
        Tab(
          text: const Text(
            'OUTPUT',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          body:
              widget.outputSlot ??
              const Center(
                child: Text(
                  'OUTPUT\n(Здесь будет содержимое OUTPUT)',
                  style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
        Tab(
          text: const Text(
            'TERMINAL',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          body:
              widget.terminalSlot ??
              const Center(
                child: Text(
                  'TERMINAL\n(Здесь будет содержимое TERMINAL)',
                  style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
        Tab(
          text: const Text(
            'TEST RESULTS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          body:
              widget.testResultsSlot ??
              const Center(
                child: Text(
                  'TEST RESULTS\n(Здесь будет содержимое TEST RESULTS)',
                  style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
        Tab(
          text: const Text(
            'PORTS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          body:
              widget.portsSlot ??
              const Center(
                child: Text(
                  'PORTS\n(Здесь будет содержимое PORTS)',
                  style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
        Tab(
          text: const Text(
            'DEBUG CONSOLE',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          body:
              widget.debugConsoleSlot ??
              const Center(
                child: Text(
                  'DEBUG CONSOLE\n(Здесь будет содержимое DEBUG CONSOLE)',
                  style: TextStyle(fontSize: 16, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ),
        ),
      ],
    );
  }
}
