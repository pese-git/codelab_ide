// Unit тесты для ExecutionPlan и Subtask entities
import 'package:codelab_ai_assistant/features/agent_chat/domain/entities/execution_plan.dart';
import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';

void main() {
  group('SubtaskStatus', () {
    test('isFinished возвращает true для completed', () {
      expect(SubtaskStatus.completed.isFinished, true);
    });

    test('isFinished возвращает true для failed', () {
      expect(SubtaskStatus.failed.isFinished, true);
    });

    test('isFinished возвращает true для skipped', () {
      expect(SubtaskStatus.skipped.isFinished, true);
    });

    test('isFinished возвращает false для pending', () {
      expect(SubtaskStatus.pending.isFinished, false);
    });

    test('isFinished возвращает false для inProgress', () {
      expect(SubtaskStatus.inProgress.isFinished, false);
    });

    test('isActive возвращает true только для inProgress', () {
      expect(SubtaskStatus.inProgress.isActive, true);
      expect(SubtaskStatus.pending.isActive, false);
      expect(SubtaskStatus.completed.isActive, false);
    });

    test('isPending возвращает true только для pending', () {
      expect(SubtaskStatus.pending.isPending, true);
      expect(SubtaskStatus.inProgress.isPending, false);
      expect(SubtaskStatus.completed.isPending, false);
    });

    test('icon возвращает правильные иконки', () {
      expect(SubtaskStatus.pending.icon, '⏸️');
      expect(SubtaskStatus.inProgress.icon, '⚙️');
      expect(SubtaskStatus.completed.icon, '✅');
      expect(SubtaskStatus.failed.icon, '❌');
      expect(SubtaskStatus.skipped.icon, '⏭️');
    });

    test('displayName возвращает правильные названия', () {
      expect(SubtaskStatus.pending.displayName, 'Ожидает');
      expect(SubtaskStatus.inProgress.displayName, 'Выполняется');
      expect(SubtaskStatus.completed.displayName, 'Завершена');
      expect(SubtaskStatus.failed.displayName, 'Ошибка');
      expect(SubtaskStatus.skipped.displayName, 'Пропущена');
    });
  });

  group('Subtask', () {
    test('pending создает подзадачу со статусом pending', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
      );

      expect(subtask.id, 'task-1');
      expect(subtask.description, 'Test task');
      expect(subtask.agent, 'coder');
      expect(subtask.status, SubtaskStatus.pending);
      expect(subtask.result.isNone(), true);
      expect(subtask.error.isNone(), true);
      expect(subtask.dependencies, isEmpty);
    });

    test('pending создает подзадачу с estimatedTime', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
        estimatedTime: some('5 min'),
      );

      expect(subtask.estimatedTime.isSome(), true);
      expect(subtask.estimatedTime.getOrElse(() => ''), '5 min');
    });

    test('pending создает подзадачу с dependencies', () {
      final subtask = Subtask.pending(
        id: 'task-2',
        description: 'Test task',
        agent: 'coder',
        dependencies: ['task-1'],
      );

      expect(subtask.dependencies, ['task-1']);
    });

    test('markInProgress изменяет статус на inProgress', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
      );

      final updated = subtask.markInProgress();

      expect(updated.status, SubtaskStatus.inProgress);
      expect(updated.error.isNone(), true);
    });

    test('markCompleted изменяет статус на completed', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
      );

      final updated = subtask.markCompleted();

      expect(updated.status, SubtaskStatus.completed);
      expect(updated.error.isNone(), true);
    });

    test('markCompleted сохраняет результат', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
      );

      final updated = subtask.markCompleted(result: some('Success'));

      expect(updated.status, SubtaskStatus.completed);
      expect(updated.result.isSome(), true);
      expect(updated.result.getOrElse(() => ''), 'Success');
    });

    test('markFailed изменяет статус на failed и сохраняет ошибку', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
      );

      final updated = subtask.markFailed('Error occurred');

      expect(updated.status, SubtaskStatus.failed);
      expect(updated.error.isSome(), true);
      expect(updated.error.getOrElse(() => ''), 'Error occurred');
    });

    test('markSkipped изменяет статус на skipped', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
      );

      final updated = subtask.markSkipped();

      expect(updated.status, SubtaskStatus.skipped);
    });

    test('areDependenciesMet возвращает true если нет зависимостей', () {
      final subtask = Subtask.pending(
        id: 'task-1',
        description: 'Test task',
        agent: 'coder',
      );

      expect(subtask.areDependenciesMet([]), true);
    });

    test('areDependenciesMet возвращает true если все зависимости completed', () {
      final dep1 = Subtask.pending(
        id: 'task-1',
        description: 'Dependency 1',
        agent: 'coder',
      ).markCompleted();

      final subtask = Subtask.pending(
        id: 'task-2',
        description: 'Test task',
        agent: 'coder',
        dependencies: ['task-1'],
      );

      expect(subtask.areDependenciesMet([dep1]), true);
    });

    test('areDependenciesMet возвращает false если зависимость pending', () {
      final dep1 = Subtask.pending(
        id: 'task-1',
        description: 'Dependency 1',
        agent: 'coder',
      );

      final subtask = Subtask.pending(
        id: 'task-2',
        description: 'Test task',
        agent: 'coder',
        dependencies: ['task-1'],
      );

      expect(subtask.areDependenciesMet([dep1]), false);
    });

    test('areDependenciesMet возвращает false если зависимость не найдена', () {
      final subtask = Subtask.pending(
        id: 'task-2',
        description: 'Test task',
        agent: 'coder',
        dependencies: ['task-1'],
      );

      expect(subtask.areDependenciesMet([]), false);
    });
  });

  group('ExecutionPlan', () {
    late List<Subtask> testSubtasks;

    setUp(() {
      testSubtasks = [
        Subtask.pending(
          id: 'task-1',
          description: 'First task',
          agent: 'coder',
          estimatedTime: some('2 min'),
        ),
        Subtask.pending(
          id: 'task-2',
          description: 'Second task',
          agent: 'architect',
          estimatedTime: some('3 min'),
          dependencies: ['task-1'],
        ),
      ];
    });

    test('create создает новый план с правильными параметрами', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      expect(plan.planId, 'plan-1');
      expect(plan.sessionId, 'session-1');
      expect(plan.originalTask, 'Build a feature');
      expect(plan.subtasks.length, 2);
      expect(plan.currentSubtaskIndex, 0);
      expect(plan.isComplete, false);
      expect(plan.isPendingConfirmation, true);
    });

    test('approve изменяет isPendingConfirmation на false', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final approved = plan.approve();

      expect(approved.isPendingConfirmation, false);
    });

    test('currentSubtask возвращает текущую подзадачу', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final current = plan.currentSubtask;

      expect(current.isSome(), true);
      current.fold(
        () => fail('Should have current subtask'),
        (subtask) => expect(subtask.id, 'task-1'),
      );
    });

    test('currentSubtask возвращает none если индекс вне диапазона', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      ).copyWith(currentSubtaskIndex: 10);

      expect(plan.currentSubtask.isNone(), true);
    });

    test('getNextPendingSubtask возвращает первую pending подзадачу', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final next = plan.getNextPendingSubtask();

      expect(next.isSome(), true);
      next.fold(
        () => fail('Should have next subtask'),
        (subtask) => expect(subtask.id, 'task-1'),
      );
    });

    test('getNextPendingSubtask пропускает задачи с невыполненными зависимостями', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      // task-2 имеет зависимость от task-1, который еще pending
      // Поэтому должна вернуться task-1
      final next = plan.getNextPendingSubtask();

      expect(next.isSome(), true);
      next.fold(
        () => fail('Should have next subtask'),
        (subtask) => expect(subtask.id, 'task-1'),
      );
    });

    test('getNextPendingSubtask возвращает none если нет pending задач', () {
      final completedSubtasks = testSubtasks
          .map((st) => st.markCompleted())
          .toList();

      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: completedSubtasks,
      );

      expect(plan.getNextPendingSubtask().isNone(), true);
    });

    test('updateSubtask обновляет подзадачу в плане', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final updatedSubtask = testSubtasks[0].markCompleted();
      final updatedPlan = plan.updateSubtask(updatedSubtask);

      expect(updatedPlan.subtasks[0].status, SubtaskStatus.completed);
    });

    test('updateSubtask устанавливает isComplete когда все задачи завершены', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      var updatedPlan = plan.updateSubtask(testSubtasks[0].markCompleted());
      expect(updatedPlan.isComplete, false);

      updatedPlan = updatedPlan.updateSubtask(testSubtasks[1].markCompleted());
      expect(updatedPlan.isComplete, true);
    });

    test('markSubtaskInProgress обновляет статус и индекс', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final updated = plan.markSubtaskInProgress('task-1');

      expect(updated.subtasks[0].status, SubtaskStatus.inProgress);
      expect(updated.currentSubtaskIndex, 0);
    });

    test('markSubtaskInProgress возвращает неизмененный план для несуществующей задачи', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final updated = plan.markSubtaskInProgress('non-existent');

      expect(updated, plan);
    });

    test('markSubtaskCompleted обновляет статус', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final updated = plan.markSubtaskCompleted('task-1');

      expect(updated.subtasks[0].status, SubtaskStatus.completed);
    });

    test('markSubtaskCompleted сохраняет результат', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final updated = plan.markSubtaskCompleted('task-1', result: some('Done'));

      expect(updated.subtasks[0].status, SubtaskStatus.completed);
      expect(updated.subtasks[0].result.getOrElse(() => ''), 'Done');
    });

    test('markSubtaskFailed обновляет статус и ошибку', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final updated = plan.markSubtaskFailed('task-1', 'Error occurred');

      expect(updated.subtasks[0].status, SubtaskStatus.failed);
      expect(updated.subtasks[0].error.getOrElse(() => ''), 'Error occurred');
    });

    test('markSubtaskSkipped обновляет статус', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final updated = plan.markSubtaskSkipped('task-1');

      expect(updated.subtasks[0].status, SubtaskStatus.skipped);
    });

    test('progress возвращает 0.0 для пустого плана', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: [],
      );

      expect(plan.progress, 0.0);
    });

    test('progress возвращает правильное значение', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      expect(plan.progress, 0.0);

      final updated = plan.markSubtaskCompleted('task-1');
      expect(updated.progress, 0.5);

      final completed = updated.markSubtaskCompleted('task-2');
      expect(completed.progress, 1.0);
    });

    test('completedCount возвращает количество завершенных задач', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      expect(plan.completedCount, 0);

      final updated = plan.markSubtaskCompleted('task-1');
      expect(updated.completedCount, 1);
    });

    test('failedCount возвращает количество неудачных задач', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      expect(plan.failedCount, 0);

      final updated = plan.markSubtaskFailed('task-1', 'Error');
      expect(updated.failedCount, 1);
    });

    test('skippedCount возвращает количество пропущенных задач', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      expect(plan.skippedCount, 0);

      final updated = plan.markSubtaskSkipped('task-1');
      expect(updated.skippedCount, 1);
    });

    test('totalCount возвращает общее количество задач', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      expect(plan.totalCount, 2);
    });

    test('estimatedTotalTime возвращает none для пустого плана', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: [],
      );

      expect(plan.estimatedTotalTime.isNone(), true);
    });

    test('estimatedTotalTime возвращает none если нет оценок времени', () {
      final subtasksNoTime = [
        Subtask.pending(
          id: 'task-1',
          description: 'First task',
          agent: 'coder',
        ),
      ];

      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: subtasksNoTime,
      );

      expect(plan.estimatedTotalTime.isNone(), true);
    });

    test('estimatedTotalTime суммирует время в минутах', () {
      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: testSubtasks,
      );

      final time = plan.estimatedTotalTime;
      expect(time.isSome(), true);
      expect(time.getOrElse(() => ''), '~5 мин');
    });

    test('estimatedTotalTime конвертирует в часы и минуты', () {
      final subtasksLongTime = [
        Subtask.pending(
          id: 'task-1',
          description: 'First task',
          agent: 'coder',
          estimatedTime: some('30 min'),
        ),
        Subtask.pending(
          id: 'task-2',
          description: 'Second task',
          agent: 'architect',
          estimatedTime: some('45 min'),
        ),
      ];

      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: subtasksLongTime,
      );

      final time = plan.estimatedTotalTime;
      expect(time.isSome(), true);
      expect(time.getOrElse(() => ''), '~1 ч 15 мин');
    });

    test('estimatedTotalTime конвертирует ровные часы', () {
      final subtasksExactHour = [
        Subtask.pending(
          id: 'task-1',
          description: 'First task',
          agent: 'coder',
          estimatedTime: some('60 min'),
        ),
      ];

      final plan = ExecutionPlan.create(
        planId: 'plan-1',
        sessionId: 'session-1',
        originalTask: 'Build a feature',
        subtasks: subtasksExactHour,
      );

      final time = plan.estimatedTotalTime;
      expect(time.isSome(), true);
      expect(time.getOrElse(() => ''), '~1 ч ');
    });
  });
}
