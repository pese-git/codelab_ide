import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:codelab_ai_assistant/src/ui/ai_assistant_panel.dart';
import 'package:codelab_ai_assistant/src/bloc/ai_agent_bloc.dart';
import 'package:codelab_ai_assistant/src/domain/agent_protocol_service.dart';
import 'package:codelab_ai_assistant/src/integration/tool_api.dart';
import 'package:codelab_ai_assistant/src/models/ws_message.dart';

// Моки
class MockAgentProtocolService extends Mock implements AgentProtocolService {}
class MockToolApi extends Mock implements ToolApi {}

void main() {
  setUpAll(() {
    // Регистрация fallback значений для mocktail
    registerFallbackValue(
      const WSMessage.userMessage(content: 'fallback', role: 'user'),
    );
  });

  group('AiAssistantPanel Widget Tests', () {
    late MockAgentProtocolService mockProtocol;
    late MockToolApi mockToolApi;
    late AiAgentBloc bloc;

    setUp(() {
      mockProtocol = MockAgentProtocolService();
      mockToolApi = MockToolApi();

      // Настройка базового поведения мока
      when(() => mockProtocol.messages).thenAnswer((_) => const Stream.empty());
      when(() => mockProtocol.connect()).thenReturn(null);
      when(() => mockProtocol.disconnect()).thenAnswer((_) async {});
      when(() => mockProtocol.sendUserMessage(any(), role: any(named: 'role')))
          .thenReturn(null);

      bloc = AiAgentBloc(protocol: mockProtocol, toolApi: mockToolApi);
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('renders initial state correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextBox), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(FluentIcons.send), findsOneWidget);
    });

    testWidgets('displays user message in chat history', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.sendUserMessage('Hello AI'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hello AI'), findsOneWidget);
    });

    testWidgets('displays assistant message in chat history', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.assistantMessage(content: 'Hello User', isFinal: true),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hello User'), findsOneWidget);
    });

    testWidgets('displays tool_call message with requiresApproval indicator', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.toolCall(
          callId: 'test-call-1',
          toolName: 'write_file',
          arguments: {'path': 'test.txt'},
          requiresApproval: true,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('write_file'), findsOneWidget);
      expect(find.textContaining('[requires approval]'), findsOneWidget);
    });

    testWidgets('displays tool_call message without requiresApproval indicator', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.toolCall(
          callId: 'test-call-2',
          toolName: 'read_file',
          arguments: {'path': 'test.txt'},
          requiresApproval: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('read_file'), findsOneWidget);
      expect(find.textContaining('[requires approval]'), findsNothing);
    });

    testWidgets('displays tool_result message', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.toolResult(
          callId: 'test-call-3',
          result: {'success': true, 'content': 'File content'},
        ),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('success'), findsOneWidget);
    });

    testWidgets('displays error message', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.error(content: 'Something went wrong'),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Ошибка'), findsOneWidget);
      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('sends user message when send button is pressed', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextBox), 'Test message');
      await tester.tap(find.byIcon(FluentIcons.send));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockProtocol.sendUserMessage('Test message', role: 'user')).called(1);
    });

    testWidgets('clears text field after sending message', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextBox), 'Test message');
      await tester.tap(find.byIcon(FluentIcons.send));
      await tester.pumpAndSettle();

      // Assert
      final textBox = tester.widget<TextBox>(find.byType(TextBox));
      expect(textBox.controller?.text, isEmpty);
    });

    testWidgets('does not send empty message', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(FluentIcons.send));
      await tester.pumpAndSettle();

      // Assert
      verifyNever(() => mockProtocol.sendUserMessage(any(), role: any(named: 'role')));
    });

    testWidgets('disables input when waiting for response', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.sendUserMessage('Test'));
      await tester.pumpAndSettle();

      // Assert
      final textBox = tester.widget<TextBox>(find.byType(TextBox));
      expect(textBox.enabled, isFalse);
    });

    testWidgets('shows progress ring when waiting for response', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.sendUserMessage('Test'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProgressRing), findsOneWidget);
      expect(find.byIcon(FluentIcons.send), findsNothing);
    });

    testWidgets('displays multiple messages in correct order', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.sendUserMessage('First message'));
      await tester.pumpAndSettle();

      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.assistantMessage(content: 'Second message', isFinal: true),
      ));
      await tester.pumpAndSettle();

      bloc.add(const AiAgentEvent.sendUserMessage('Third message'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message'), findsOneWidget);
      expect(find.text('Third message'), findsOneWidget);
    });

    testWidgets('user messages are aligned to the right', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.sendUserMessage('User message'));
      await tester.pumpAndSettle();

      // Assert
      final align = tester.widget<Align>(
        find.ancestor(
          of: find.text('User message'),
          matching: find.byType(Align),
        ).first,
      );
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('assistant messages are aligned to the left', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.assistantMessage(content: 'Assistant message', isFinal: true),
      ));
      await tester.pumpAndSettle();

      // Assert
      final align = tester.widget<Align>(
        find.ancestor(
          of: find.text('Assistant message'),
          matching: find.byType(Align),
        ).first,
      );
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('sends message on text field submit', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextBox), 'Submit test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockProtocol.sendUserMessage('Submit test', role: 'user')).called(1);
    });

    testWidgets('renders ListView with correct item count', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        FluentApp(
          home: ScaffoldPage(
            content: AiAssistantPanel(bloc: bloc),
          ),
        ),
      );

      // Act
      bloc.add(const AiAgentEvent.sendUserMessage('Message 1'));
      await tester.pumpAndSettle();

      bloc.add(const AiAgentEvent.messageReceived(
        WSMessage.assistantMessage(content: 'Message 2', isFinal: true),
      ));
      await tester.pumpAndSettle();

      bloc.add(const AiAgentEvent.sendUserMessage('Message 3'));
      await tester.pumpAndSettle();

      // Assert
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.semanticChildCount, 3);
    });
  });
}
