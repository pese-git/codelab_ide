import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/widgets/plan_approval_dialog.dart';

void main() {
  group('PlanApprovalDialog', () {
    late Map<String, dynamic> testPlanSummary;

    setUp(() {
      testPlanSummary = {
        'goal': 'Создать новую функцию авторизации',
        'subtasks_count': 3,
        'total_estimated_time': '2 hours',
        'subtasks': [
          {
            'description': 'Создать UI для формы входа',
            'agent': 'code',
            'estimated_time': '30 min',
            'dependencies': [],
          },
          {
            'description': 'Реализовать логику авторизации',
            'agent': 'code',
            'estimated_time': '1 hour',
            'dependencies': ['subtask-1'],
          },
          {
            'description': 'Написать тесты',
            'agent': 'code',
            'estimated_time': '30 min',
            'dependencies': ['subtask-2'],
          },
        ],
      };
    });

    Widget createTestWidget(Widget child) {
      return FluentApp(
        home: ScaffoldPage(
          content: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => child,
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('отображает заголовок диалога', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('План выполнения задачи'), findsOneWidget);
    });

    testWidgets('отображает цель плана', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Цель'), findsOneWidget);
      expect(
        find.text('Создать новую функцию авторизации'),
        findsOneWidget,
      );
    });

    testWidgets('отображает количество подзадач', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Подзадач'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('отображает общее время выполнения', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Время'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);
    });

    testWidgets('отображает список подзадач', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Подзадачи'), findsOneWidget);
      expect(find.text('Создать UI для формы входа'), findsOneWidget);
      expect(find.text('Реализовать логику авторизации'), findsOneWidget);
      expect(find.text('Написать тесты'), findsOneWidget);
    });

    testWidgets('отображает кнопки действий', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Отклонить'), findsOneWidget);
      expect(find.text('Изменить план'), findsOneWidget);
      expect(find.text('Одобрить'), findsOneWidget);
    });

    testWidgets('вызывает callback при одобрении', (WidgetTester tester) async {
      String? receivedDecision;
      String? receivedFeedback;

      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (decision, feedback) {
              receivedDecision = decision;
              receivedFeedback = feedback;
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Одобрить'));
      await tester.pumpAndSettle();

      expect(receivedDecision, 'approve');
      expect(receivedFeedback, isNull);
    });

    testWidgets('вызывает callback при отклонении', (WidgetTester tester) async {
      String? receivedDecision;
      String? receivedFeedback;

      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (decision, feedback) {
              receivedDecision = decision;
              receivedFeedback = feedback;
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отклонить'));
      await tester.pumpAndSettle();

      expect(receivedDecision, 'reject');
      expect(receivedFeedback, isNull);
    });

    testWidgets('показывает поле feedback при нажатии "Изменить план"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Изначально поле feedback не видно
      expect(find.text('Комментарии к изменениям'), findsNothing);

      await tester.tap(find.text('Изменить план'));
      await tester.pumpAndSettle();

      // После нажатия поле feedback появляется
      expect(find.text('Комментарии к изменениям'), findsOneWidget);
      expect(find.text('Скрыть изменения'), findsOneWidget);
    });

    testWidgets('отправляет feedback при изменении плана',
        (WidgetTester tester) async {
      String? receivedDecision;
      String? receivedFeedback;

      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (decision, feedback) {
              receivedDecision = decision;
              receivedFeedback = feedback;
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Открываем поле feedback
      await tester.tap(find.text('Изменить план'));
      await tester.pumpAndSettle();

      // Вводим текст
      await tester.enterText(
        find.byType(TextBox),
        'Добавить больше тестов',
      );
      await tester.pumpAndSettle();

      // Одобряем с feedback
      await tester.tap(find.text('Одобрить'));
      await tester.pumpAndSettle();

      expect(receivedDecision, 'modify');
      expect(receivedFeedback, 'Добавить больше тестов');
    });

    testWidgets('обрабатывает пустой planSummary', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: {},
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('No goal specified'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('отображает зависимости подзадач', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          PlanApprovalDialog(
            approvalRequestId: 'test-approval-id',
            planId: 'test-plan-id',
            planSummary: testPlanSummary,
            onDecision: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Проверяем, что отображаются зависимости
      expect(find.text('1 deps'), findsNWidgets(2));
    });
  });
}
