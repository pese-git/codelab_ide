import 'package:fluent_ui/fluent_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Windows UI for Flutter',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      child: const Text('Standard Button'),
      onPressed: () => debugPrint('pressed button'),
    );
  }
}
