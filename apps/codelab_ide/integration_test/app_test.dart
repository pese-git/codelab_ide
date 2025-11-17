import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:codelab_ide/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Smoke test: app launches and shows root page', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    // Проверяем наличие заголовка или ключевого текста/виджета
    expect(
      find.text('Codelab IDE'),
      findsWidgets,
    ); // Исправьте, если нужен другой текст на главном экране
  });
}
