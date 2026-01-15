// Widget тесты для компонентов планирования
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/execution_plan.dart';
import 'package:codelab_ai_assistant/features/agent_chat/presentation/organisms/plan_overview_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('PlanOverviewWidget', () {
    late ExecutionPlan testPlan;

    setUp(() {
      testPlan = ExecutionPlan.create(
        planId: 'plan-123',
        sessionId: 'session-1',
        originalTask: 'Build a new feature',
        subtasks: [
          Subtask.pending(
            id: 'task-1',
            description: 'Analyze requirements',
            agent: 'architect',
            estimatedTime: some('2 min'),
          ),
          Subtask.pending(
            id: 'task-2',
            description: 'Implement feature',
            agent: 'coder',
            estimatedTime: some('5 min'),
            dependencies: ['task-1'],
          ),
          Subtask.pending(
            id: 'task-3',
            description: 'Write tests',
            agent: 'coder',
            estimatedTime: some('3 min'),
            dependencies: ['task-2'],
          ),
        ],
      );
    });

    Widget createTestWidget({
      required ExecutionPlan plan,
      VoidCallback? onApprove,
      ValueChanged<String>? onReject,
    }) {
      return FluentApp(
        home: ScaffoldPage(
          content: PlanOverviewWidget(
            plan: plan,
            onApprove: onApprove,
            onReject: onReject,
          ),
        ),
      );
    }

    testWidgets('отображает заголовок плана', (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      expect(find.text('План выполнения'), findsOneWidget);
    });

    testWidgets('отображает исходную задачу', (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      expect(find.text('Build a new feature'), findsOneWidget);
    });

    testWidgets('отображает все подзадачи', (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      expect(find.text('Analyze requirements'), findsOneWidget);
      expect(find.text('Implement feature'), findsOneWidget);
      expect(find.text('Write tests'), findsOneWidget);
    });

    testWidgets('отображает агентов для каждой подзадачи', (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      expect(find.textContaining('architect'), findsOneWidget);
      expect(find.textContaining('coder'), findsNWidgets(2));
    });

    testWidgets('отображает оценку времени', (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      expect(find.textContaining('2 min'), findsOneWidget);
      expect(find.textContaining('5 min'), findsOneWidget);
      expect(find.textContaining('3 min'), findsOneWidget);
    });

    testWidgets('отображает общее время выполнения', (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      // 2 + 5 + 3 = 10 минут
      expect(find.textContaining('10 мин'), findsOneWidget);
    });

    testWidgets('отображает прогресс выполнения', (tester) async {
      final planWithProgress = testPlan.markSubtaskCompleted('task-1');
      
      await tester.pumpWidget(createTestWidget(plan: planWithProgress));

      // 1 из 3 задач завершено = 33%
      expect(find.textContaining('1'), findsWidgets);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('отображает кнопки подтверждения когда план ожидает подтверждения',
      (tester) async {
      // testPlan создается с isPendingConfirmation = true по умолчанию
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      expect(find.text('Подтвердить план'), findsOneWidget);
      expect(find.text('Отклонить'), findsOneWidget);
    });

    testWidgets('не отображает кнопки когда план подтвержден',
      (tester) async {
      final approvedPlan = testPlan.approve();
      
      await tester.pumpWidget(createTestWidget(plan: approvedPlan));

      expect(find.text('Подтвердить план'), findsNothing);
      expect(find.text('Отклонить'), findsNothing);
    });

    testWidgets('вызывает onApprove при нажатии кнопки подтверждения',
      (tester) async {
      bool approveCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        plan: testPlan,
        onApprove: () => approveCalled = true,
      ));

      await tester.tap(find.text('Подтвердить план'));
      await tester.pumpAndSettle();

      expect(approveCalled, true);
    });

    testWidgets('вызывает onReject при нажатии кнопки отклонения',
      (tester) async {
      String? rejectReason;
      
      await tester.pumpWidget(createTestWidget(
        plan: testPlan,
        onReject: (reason) => rejectReason = reason,
      ));

      await tester.tap(find.text('Отклонить'));
      await tester.pumpAndSettle();

      // Должен открыться диалог для ввода причины
      expect(find.byType(ContentDialog), findsOneWidget);
    });

    testWidgets('отображает статус pending для незавершенных задач', 
      (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      // Иконка pending
      expect(find.text('⏸️'), findsNWidgets(3));
    });

    testWidgets('отображает статус completed для завершенных задач', 
      (tester) async {
      final completedPlan = testPlan.markSubtaskCompleted('task-1');
      
      await tester.pumpWidget(createTestWidget(plan: completedPlan));

      // Иконка completed
      expect(find.text('✅'), findsOneWidget);
      // Остальные pending
      expect(find.text('⏸️'), findsNWidgets(2));
    });

    testWidgets('отображает статус inProgress для выполняющихся задач', 
      (tester) async {
      final inProgressPlan = testPlan.markSubtaskInProgress('task-1');
      
      await tester.pumpWidget(createTestWidget(plan: inProgressPlan));

      // Иконка inProgress
      expect(find.text('⚙️'), findsOneWidget);
    });

    testWidgets('отображает статус failed для неудачных задач', 
      (tester) async {
      final failedPlan = testPlan.markSubtaskFailed('task-1', 'Error occurred');
      
      await tester.pumpWidget(createTestWidget(plan: failedPlan));

      // Иконка failed
      expect(find.text('❌'), findsOneWidget);
    });

    testWidgets('отображает статус skipped для пропущенных задач', 
      (tester) async {
      final skippedPlan = testPlan.markSubtaskSkipped('task-1');
      
      await tester.pumpWidget(createTestWidget(plan: skippedPlan));

      // Иконка skipped
      expect(find.text('⏭️'), findsOneWidget);
    });

    testWidgets('отображает зависимости между задачами', (tester) async {
      await tester.pumpWidget(createTestWidget(plan: testPlan));

      // task-2 зависит от task-1
      // task-3 зависит от task-2
      // Проверяем, что информация о зависимостях отображается
      expect(find.textContaining('task-1'), findsWidgets);
      expect(find.textContaining('task-2'), findsWidgets);
    });

    testWidgets('отображает сообщение об ошибке для failed задач', 
      (tester) async {
      final failedPlan = testPlan.markSubtaskFailed('task-1', 'Network error');
      
      await tester.pumpWidget(createTestWidget(plan: failedPlan));

      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('отображает результат для completed задач', 
      (tester) async {
      final completedPlan = testPlan.markSubtaskCompleted(
        'task-1',
        result: some('Analysis complete'),
      );
      
      await tester.pumpWidget(createTestWidget(plan: completedPlan));

      expect(find.textContaining('Analysis complete'), findsOneWidget);
    });

    testWidgets('отображает прогресс-бар с правильным значением', 
      (tester) async {
      final planWithProgress = testPlan
          .markSubtaskCompleted('task-1')
          .markSubtaskCompleted('task-2');
      
      await tester.pumpWidget(createTestWidget(plan: planWithProgress));

      // 2 из 3 = 66.6%
      final progressBar = tester.widget<ProgressBar>(
        find.byType(ProgressBar),
      );
      
      expect(progressBar.value, closeTo(66.6, 0.1));
    });

    testWidgets('отображает индикатор завершения когда все задачи выполнены', 
      (tester) async {
      final completedPlan = testPlan
          .markSubtaskCompleted('task-1')
          .markSubtaskCompleted('task-2')
          .markSubtaskCompleted('task-3');
      
      await tester.pumpWidget(createTestWidget(plan: completedPlan));

      expect(completedPlan.isComplete, true);
      expect(find.textContaining('Завершено'), findsOneWidget);
    });

    testWidgets('корректно отображает план без оценки времени', 
      (tester) async {
      final planNoTime = ExecutionPlan.create(
        planId: 'plan-123',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: [
          Subtask.pending(
            id: 'task-1',
            description: 'Task without time',
            agent: 'coder',
          ),
        ],
      );
      
      await tester.pumpWidget(createTestWidget(plan: planNoTime));

      expect(find.text('Task without time'), findsOneWidget);
    });

    testWidgets('корректно отображает пустой план', (tester) async {
      final emptyPlan = ExecutionPlan.create(
        planId: 'plan-123',
        sessionId: 'session-1',
        originalTask: 'Empty task',
        subtasks: [],
      );
      
      await tester.pumpWidget(createTestWidget(plan: emptyPlan));

      expect(find.text('Empty task'), findsOneWidget);
      expect(find.text('Нет подзадач'), findsOneWidget);
    });
  });
}
