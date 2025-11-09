import 'package:codelab_terminal/codelab_terminal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalWidget', () {
    testWidgets('creates terminal widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TerminalWidget(),
          ),
        ),
      );

      expect(find.byType(TerminalWidget), findsOneWidget);
    });

    testWidgets('creates terminal widget with project directory', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TerminalWidget(projectDirectory: '/test'),
          ),
        ),
      );

      expect(find.byType(TerminalWidget), findsOneWidget);
    });
  });
}