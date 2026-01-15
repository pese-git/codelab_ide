// Domain entity для плана выполнения задачи
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'execution_plan.freezed.dart';

/// Статус подзадачи в плане выполнения
enum SubtaskStatus {
  /// Ожидает выполнения
  pending,

  /// Выполняется в данный момент
  inProgress,

  /// Успешно завершена
  completed,

  /// Завершена с ошибкой
  failed,

  /// Пропущена
  skipped,
}

/// Расширение для работы со статусами подзадач
extension SubtaskStatusX on SubtaskStatus {
  /// Проверка, завершена ли подзадача (успешно или с ошибкой)
  bool get isFinished =>
      this == SubtaskStatus.completed ||
      this == SubtaskStatus.failed ||
      this == SubtaskStatus.skipped;

  /// Проверка, выполняется ли подзадача
  bool get isActive => this == SubtaskStatus.inProgress;

  /// Проверка, ожидает ли подзадача выполнения
  bool get isPending => this == SubtaskStatus.pending;

  /// Иконка для статуса
  String get icon {
    switch (this) {
      case SubtaskStatus.pending:
        return '⏸️';
      case SubtaskStatus.inProgress:
        return '⚙️';
      case SubtaskStatus.completed:
        return '✅';
      case SubtaskStatus.failed:
        return '❌';
      case SubtaskStatus.skipped:
        return '⏭️';
    }
  }

  /// Название статуса на русском
  String get displayName {
    switch (this) {
      case SubtaskStatus.pending:
        return 'Ожидает';
      case SubtaskStatus.inProgress:
        return 'Выполняется';
      case SubtaskStatus.completed:
        return 'Завершена';
      case SubtaskStatus.failed:
        return 'Ошибка';
      case SubtaskStatus.skipped:
        return 'Пропущена';
    }
  }
}

/// Отдельная подзадача в плане выполнения
@freezed
abstract class Subtask with _$Subtask {
  const factory Subtask({
    /// Уникальный идентификатор подзадачи
    required String id,

    /// Описание задачи
    required String description,

    /// Агент, который должен выполнить задачу (coder, architect, debug, ask)
    required String agent,

    /// Оценка времени выполнения (например, "2 min", "5 min")
    required Option<String> estimatedTime,

    /// Текущий статус подзадачи
    required SubtaskStatus status,

    /// Результат выполнения (если завершена)
    required Option<String> result,

    /// Сообщение об ошибке (если failed)
    required Option<String> error,

    /// ID подзадач, которые должны быть выполнены перед этой
    required List<String> dependencies,
  }) = _Subtask;

  const Subtask._();

  /// Создать подзадачу со статусом pending
  factory Subtask.pending({
    required String id,
    required String description,
    required String agent,
    Option<String> estimatedTime = const None(),
    List<String> dependencies = const [],
  }) => Subtask(
    id: id,
    description: description,
    agent: agent,
    estimatedTime: estimatedTime,
    status: SubtaskStatus.pending,
    result: none(),
    error: none(),
    dependencies: dependencies,
  );

  /// Отметить подзадачу как выполняющуюся
  Subtask markInProgress() =>
      copyWith(status: SubtaskStatus.inProgress, error: none());

  /// Отметить подзадачу как завершенную
  Subtask markCompleted({Option<String> result = const None()}) =>
      copyWith(status: SubtaskStatus.completed, result: result, error: none());

  /// Отметить подзадачу как неудачную
  Subtask markFailed(String errorMessage) =>
      copyWith(status: SubtaskStatus.failed, error: some(errorMessage));

  /// Отметить подзадачу как пропущенную
  Subtask markSkipped() => copyWith(status: SubtaskStatus.skipped);

  /// Проверить, все ли зависимости выполнены
  bool areDependenciesMet(List<Subtask> allSubtasks) {
    if (dependencies.isEmpty) return true;

    for (final depId in dependencies) {
      final depSubtask = allSubtasks.firstWhere(
        (st) => st.id == depId,
        orElse: () => Subtask.pending(id: '', description: '', agent: ''),
      );

      if (depSubtask.id.isEmpty ||
          depSubtask.status != SubtaskStatus.completed) {
        return false;
      }
    }

    return true;
  }
}

/// План выполнения сложной задачи
@freezed
abstract class ExecutionPlan with _$ExecutionPlan {
  const factory ExecutionPlan({
    /// Уникальный идентификатор плана
    required String planId,

    /// ID сессии, к которой относится план
    required String sessionId,

    /// Исходная задача пользователя
    required String originalTask,

    /// Список подзадач для выполнения
    required List<Subtask> subtasks,

    /// Время создания плана
    required DateTime createdAt,

    /// Индекс текущей выполняющейся подзадачи
    required int currentSubtaskIndex,

    /// Флаг завершения всех подзадач
    required bool isComplete,

    /// Флаг ожидания подтверждения от пользователя
    required bool isPendingConfirmation,
  }) = _ExecutionPlan;

  const ExecutionPlan._();

  /// Создать новый план
  factory ExecutionPlan.create({
    required String planId,
    required String sessionId,
    required String originalTask,
    required List<Subtask> subtasks,
  }) => ExecutionPlan(
    planId: planId,
    sessionId: sessionId,
    originalTask: originalTask,
    subtasks: subtasks,
    createdAt: DateTime.now(),
    currentSubtaskIndex: 0,
    isComplete: false,
    isPendingConfirmation: true,
  );

  /// Подтвердить план (начать выполнение)
  ExecutionPlan approve() => copyWith(isPendingConfirmation: false);

  /// Получить текущую подзадачу
  Option<Subtask> get currentSubtask {
    if (currentSubtaskIndex >= 0 && currentSubtaskIndex < subtasks.length) {
      return some(subtasks[currentSubtaskIndex]);
    }
    return none();
  }

  /// Получить следующую подзадачу для выполнения
  Option<Subtask> getNextPendingSubtask() {
    for (var i = 0; i < subtasks.length; i++) {
      final subtask = subtasks[i];
      if (subtask.status == SubtaskStatus.pending &&
          subtask.areDependenciesMet(subtasks)) {
        return some(subtask);
      }
    }
    return none();
  }

  /// Обновить подзадачу в плане
  ExecutionPlan updateSubtask(Subtask updatedSubtask) {
    final updatedSubtasks = subtasks.map((st) {
      if (st.id == updatedSubtask.id) {
        return updatedSubtask;
      }
      return st;
    }).toList();

    // Проверяем, все ли подзадачи завершены
    final allFinished = updatedSubtasks.every((st) => st.status.isFinished);

    return copyWith(subtasks: updatedSubtasks, isComplete: allFinished);
  }

  /// Отметить подзадачу как выполняющуюся
  ExecutionPlan markSubtaskInProgress(String subtaskId) {
    final subtask = subtasks.firstWhere(
      (st) => st.id == subtaskId,
      orElse: () => Subtask.pending(id: '', description: '', agent: ''),
    );

    if (subtask.id.isEmpty) return this;

    final updatedSubtask = subtask.markInProgress();
    final index = subtasks.indexWhere((st) => st.id == subtaskId);

    return updateSubtask(
      updatedSubtask,
    ).copyWith(currentSubtaskIndex: index >= 0 ? index : currentSubtaskIndex);
  }

  /// Отметить подзадачу как завершенную
  ExecutionPlan markSubtaskCompleted(
    String subtaskId, {
    Option<String> result = const None(),
  }) {
    final subtask = subtasks.firstWhere(
      (st) => st.id == subtaskId,
      orElse: () => Subtask.pending(id: '', description: '', agent: ''),
    );

    if (subtask.id.isEmpty) return this;

    final updatedSubtask = subtask.markCompleted(result: result);
    return updateSubtask(updatedSubtask);
  }

  /// Отметить подзадачу как неудачную
  ExecutionPlan markSubtaskFailed(String subtaskId, String error) {
    final subtask = subtasks.firstWhere(
      (st) => st.id == subtaskId,
      orElse: () => Subtask.pending(id: '', description: '', agent: ''),
    );

    if (subtask.id.isEmpty) return this;

    final updatedSubtask = subtask.markFailed(error);
    return updateSubtask(updatedSubtask);
  }

  /// Отметить подзадачу как пропущенную
  ExecutionPlan markSubtaskSkipped(String subtaskId) {
    final subtask = subtasks.firstWhere(
      (st) => st.id == subtaskId,
      orElse: () => Subtask.pending(id: '', description: '', agent: ''),
    );

    if (subtask.id.isEmpty) return this;

    final updatedSubtask = subtask.markSkipped();
    return updateSubtask(updatedSubtask);
  }

  /// Получить прогресс выполнения (0.0 - 1.0)
  double get progress {
    if (subtasks.isEmpty) return 0.0;

    final completedCount = subtasks
        .where((st) => st.status == SubtaskStatus.completed)
        .length;

    return completedCount / subtasks.length;
  }

  /// Получить количество завершенных подзадач
  int get completedCount =>
      subtasks.where((st) => st.status == SubtaskStatus.completed).length;

  /// Получить количество неудачных подзадач
  int get failedCount =>
      subtasks.where((st) => st.status == SubtaskStatus.failed).length;

  /// Получить количество пропущенных подзадач
  int get skippedCount =>
      subtasks.where((st) => st.status == SubtaskStatus.skipped).length;

  /// Получить общее количество подзадач
  int get totalCount => subtasks.length;

  /// Получить оценку общего времени выполнения
  Option<String> get estimatedTotalTime {
    final times = subtasks
        .map((st) => st.estimatedTime)
        .where((time) => time.isSome())
        .map((time) => time.getOrElse(() => ''))
        .toList();

    if (times.isEmpty) return none();

    // Простая конкатенация времени (можно улучшить)
    int totalMinutes = 0;
    for (final time in times) {
      final match = RegExp(r'(\d+)\s*min').firstMatch(time);
      if (match != null) {
        totalMinutes += int.parse(match.group(1)!);
      }
    }

    if (totalMinutes == 0) return none();

    if (totalMinutes < 60) {
      return some('~$totalMinutes мин');
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return some('~$hours ч ${minutes > 0 ? "$minutes мин" : ""}');
    }
  }
}
