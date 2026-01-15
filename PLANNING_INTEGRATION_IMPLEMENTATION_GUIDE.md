# Руководство по реализации полной интеграции системы планирования

## Статус: В процессе реализации

Этот документ содержит пошаговые инструкции для завершения интеграции системы планирования в codelab_ide.

---

## ✅ Уже реализовано

### 1. Domain Entities
- ✅ [`ExecutionPlan`](packages/codelab_ai_assistant/lib/features/agent_chat/domain/entities/execution_plan.dart) - план выполнения
- ✅ [`Subtask`](packages/codelab_ai_assistant/lib/features/agent_chat/domain/entities/execution_plan.dart) - подзадача
- ✅ [`SubtaskStatus`](packages/codelab_ai_assistant/lib/features/agent_chat/domain/entities/execution_plan.dart) - статусы подзадач

### 2. Use Cases (частично)
- ✅ [`ApprovePlanUseCase`](packages/codelab_ai_assistant/lib/features/agent_chat/domain/usecases/approve_plan.dart)
- ✅ [`RejectPlanUseCase`](packages/codelab_ai_assistant/lib/features/agent_chat/domain/usecases/reject_plan.dart)

### 3. Протокол WebSocket
- ✅ Все типы сообщений планирования поддерживаются
- ✅ Маппинг работает корректно

---

## 🔨 Требуется реализовать

### Шаг 1: Завершить Use Cases

#### 1.1 Создать GetActivePlanUseCase

```dart
// lib/features/agent_chat/domain/usecases/get_active_plan.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/execution_plan.dart';
import '../repositories/agent_repository.dart';

class GetActivePlanUseCase implements UseCase<Option<ExecutionPlan>, NoParams> {
  final AgentRepository _repository;
  
  const GetActivePlanUseCase(this._repository);
  
  @override
  Future<Either<Failure, Option<ExecutionPlan>>> call(NoParams params) async {
    return _repository.getActivePlan();
  }
}
```

### Шаг 2: Расширить AgentRepository

#### 2.1 Добавить методы в интерфейс

```dart
// lib/features/agent_chat/domain/repositories/agent_repository.dart

abstract class AgentRepository {
  // ... существующие методы
  
  /// Подтвердить план выполнения
  Future<Either<Failure, void>> approvePlan({
    required String planId,
    Option<String> feedback = const None(),
  });
  
  /// Отклонить план выполнения
  Future<Either<Failure, void>> rejectPlan({
    required String planId,
    required String reason,
  });
  
  /// Получить активный план (если есть)
  Future<Either<Failure, Option<ExecutionPlan>>> getActivePlan();
  
  /// Подписаться на обновления плана
  Stream<Either<Failure, ExecutionPlan>> watchPlanUpdates();
}
```

#### 2.2 Реализовать в AgentRepositoryImpl

```dart
// lib/features/agent_chat/data/repositories/agent_repository_impl.dart

@override
Future<Either<Failure, void>> approvePlan({
  required String planId,
  Option<String> feedback = const None(),
}) async {
  try {
    // Отправить plan_approval через WebSocket
    final message = {
      'type': 'plan_approval',
      'plan_id': planId,
      'decision': 'approve',
      'feedback': feedback.getOrElse(() => null),
    };
    
    await _webSocketDataSource.sendMessage(message);
    return right(null);
  } catch (e) {
    return left(ServerFailure('Failed to approve plan: $e'));
  }
}

@override
Future<Either<Failure, void>> rejectPlan({
  required String planId,
  required String reason,
}) async {
  try {
    final message = {
      'type': 'plan_approval',
      'plan_id': planId,
      'decision': 'reject',
      'feedback': reason,
    };
    
    await _webSocketDataSource.sendMessage(message);
    return right(null);
  } catch (e) {
    return left(ServerFailure('Failed to reject plan: $e'));
  }
}

@override
Future<Either<Failure, Option<ExecutionPlan>>> getActivePlan() async {
  // Получить из локального состояния или кэша
  return right(_activePlan);
}

@override
Stream<Either<Failure, ExecutionPlan>> watchPlanUpdates() {
  // Подписаться на обновления плана через WebSocket
  return _webSocketDataSource.messages
      .where((msg) => msg.type == 'plan_notification' || 
                      msg.type == 'plan_update' ||
                      msg.type == 'plan_progress')
      .map((msg) => _mapToPlan(msg))
      .map((plan) => right<Failure, ExecutionPlan>(plan));
}
```

### Шаг 3: Расширить AgentChatBloc

#### 3.1 Добавить поля в AgentChatState

```dart
// lib/features/agent_chat/presentation/bloc/agent_chat_bloc.dart

@freezed
abstract class AgentChatState with _$AgentChatState {
  const factory AgentChatState({
    required List<Message> messages,
    required bool isLoading,
    required bool isConnected,
    required String currentAgent,
    required Option<String> error,
    required Option<ApprovalRequestWithCompleter> pendingApproval,
    
    // Новые поля для планирования
    required Option<ExecutionPlan> activePlan,
    required bool isPlanPendingConfirmation,
  }) = _AgentChatState;

  factory AgentChatState.initial() => AgentChatState(
    messages: const [],
    isLoading: false,
    isConnected: false,
    currentAgent: AgentType.orchestrator,
    error: none(),
    pendingApproval: none(),
    activePlan: none(),
    isPlanPendingConfirmation: false,
  );
}
```

#### 3.2 Добавить события для планов

```dart
@freezed
class AgentChatEvent with _$AgentChatEvent {
  // ... существующие события
  
  const factory AgentChatEvent.planReceived(ExecutionPlan plan) = PlanReceivedEvent;
  const factory AgentChatEvent.approvePlan(String planId) = ApprovePlanEvent;
  const factory AgentChatEvent.rejectPlan(String planId, String reason) = RejectPlanEvent;
  const factory AgentChatEvent.planProgressUpdated(
    String planId,
    String subtaskId,
    SubtaskStatus status,
  ) = PlanProgressUpdatedEvent;
}
```

#### 3.3 Добавить обработчики событий

```dart
class AgentChatBloc extends Bloc<AgentChatEvent, AgentChatState> {
  final ApprovePlanUseCase _approvePlan;
  final RejectPlanUseCase _rejectPlan;
  final GetActivePlanUseCase _getActivePlan;
  
  AgentChatBloc({
    // ... существующие параметры
    required ApprovePlanUseCase approvePlan,
    required RejectPlanUseCase rejectPlan,
    required GetActivePlanUseCase getActivePlan,
  }) : _approvePlan = approvePlan,
       _rejectPlan = rejectPlan,
       _getActivePlan = getActivePlan,
       super(AgentChatState.initial()) {
    // ... существующие обработчики
    
    on<PlanReceivedEvent>(_onPlanReceived);
    on<ApprovePlanEvent>(_onApprovePlan);
    on<RejectPlanEvent>(_onRejectPlan);
    on<PlanProgressUpdatedEvent>(_onPlanProgressUpdated);
  }
  
  Future<void> _onPlanReceived(
    PlanReceivedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i('Plan received: ${event.plan.planId}');
    
    emit(state.copyWith(
      activePlan: some(event.plan),
      isPlanPendingConfirmation: event.plan.isPendingConfirmation,
    ));
  }
  
  Future<void> _onApprovePlan(
    ApprovePlanEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i('Approving plan: ${event.planId}');
    
    final result = await _approvePlan(
      ApprovePlanParams(planId: event.planId),
    );
    
    result.fold(
      (failure) {
        _logger.e('Failed to approve plan: ${failure.message}');
        emit(state.copyWith(error: some(failure.message)));
      },
      (_) {
        _logger.i('Plan approved successfully');
        
        // Обновить план в состоянии
        state.activePlan.fold(
          () => null,
          (plan) {
            final approvedPlan = plan.approve();
            emit(state.copyWith(
              activePlan: some(approvedPlan),
              isPlanPendingConfirmation: false,
            ));
          },
        );
      },
    );
  }
  
  Future<void> _onRejectPlan(
    RejectPlanEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    _logger.i('Rejecting plan: ${event.planId}, reason: ${event.reason}');
    
    final result = await _rejectPlan(
      RejectPlanParams(planId: event.planId, reason: event.reason),
    );
    
    result.fold(
      (failure) {
        _logger.e('Failed to reject plan: ${failure.message}');
        emit(state.copyWith(error: some(failure.message)));
      },
      (_) {
        _logger.i('Plan rejected successfully');
        
        // Очистить план из состояния
        emit(state.copyWith(
          activePlan: none(),
          isPlanPendingConfirmation: false,
        ));
      },
    );
  }
  
  Future<void> _onPlanProgressUpdated(
    PlanProgressUpdatedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    state.activePlan.fold(
      () => _logger.w('Plan progress update received but no active plan'),
      (plan) {
        if (plan.planId != event.planId) {
          _logger.w('Plan progress update for different plan');
          return;
        }
        
        // Обновить статус подзадачи
        ExecutionPlan updatedPlan;
        
        switch (event.status) {
          case SubtaskStatus.inProgress:
            updatedPlan = plan.markSubtaskInProgress(event.subtaskId);
            break;
          case SubtaskStatus.completed:
            updatedPlan = plan.markSubtaskCompleted(event.subtaskId);
            break;
          case SubtaskStatus.failed:
            updatedPlan = plan.markSubtaskFailed(event.subtaskId, 'Failed');
            break;
          default:
            updatedPlan = plan;
        }
        
        emit(state.copyWith(activePlan: some(updatedPlan)));
      },
    );
  }
  
  // Обновить _onMessageReceived для обработки сообщений планирования
  Future<void> _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    // ... существующий код
    
    // Проверить метаданные на наличие информации о плане
    event.message.metadata.fold(
      () => null,
      (meta) {
        if (meta.containsKey('plan_id')) {
          _handlePlanMetadata(meta, emit);
        }
      },
    );
  }
  
  void _handlePlanMetadata(
    Map<String, dynamic> meta,
    Emitter<AgentChatState> emit,
  ) {
    final planId = meta['plan_id'] as String?;
    if (planId == null) return;
    
    // Если это plan_notification, создать ExecutionPlan
    if (meta.containsKey('subtasks')) {
      final subtasksData = meta['subtasks'] as List<dynamic>;
      final subtasks = subtasksData.map((st) {
        final stMap = st as Map<String, dynamic>;
        return Subtask.pending(
          id: stMap['id'] as String,
          description: stMap['description'] as String,
          agent: stMap['agent'] as String,
          estimatedTime: stMap['estimated_time'] != null
              ? some(stMap['estimated_time'] as String)
              : none(),
          dependencies: (stMap['dependencies'] as List<dynamic>?)
                  ?.map((d) => d as String)
                  .toList() ??
              [],
        );
      }).toList();
      
      final plan = ExecutionPlan.create(
        planId: planId,
        sessionId: '', // Получить из контекста
        originalTask: meta['original_task'] as String? ?? '',
        subtasks: subtasks,
      );
      
      add(AgentChatEvent.planReceived(plan));
    }
    
    // Если это plan_progress, обновить статус
    if (meta.containsKey('step_id') && meta.containsKey('status')) {
      final stepId = meta['step_id'] as String;
      final statusStr = meta['status'] as String;
      
      SubtaskStatus status;
      switch (statusStr) {
        case 'in_progress':
          status = SubtaskStatus.inProgress;
          break;
        case 'completed':
          status = SubtaskStatus.completed;
          break;
        case 'failed':
          status = SubtaskStatus.failed;
          break;
        default:
          status = SubtaskStatus.pending;
      }
      
      add(AgentChatEvent.planProgressUpdated(planId, stepId, status));
    }
  }
}
```

### Шаг 4: Создать UI компоненты

#### 4.1 PlanOverviewWidget - обзор плана

```dart
// lib/features/agent_chat/presentation/widgets/plan_overview_widget.dart

import 'package:flutter/material.dart';
import '../../domain/entities/execution_plan.dart';

class PlanOverviewWidget extends StatelessWidget {
  final ExecutionPlan plan;
  final VoidCallback? onApprove;
  final ValueChanged<String>? onReject;
  
  const PlanOverviewWidget({
    Key? key,
    required this.plan,
    this.onApprove,
    this.onReject,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(Icons.assignment, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'План выполнения',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        plan.originalTask,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Прогресс
            if (!plan.isPendingConfirmation) ...[
              LinearProgressIndicator(value: plan.progress),
              const SizedBox(height: 8),
              Text(
                '${plan.completedCount}/${plan.totalCount} подзадач завершено',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            
            // Список подзадач
            ...plan.subtasks.asMap().entries.map((entry) {
              final index = entry.key;
              final subtask = entry.value;
              return SubtaskTile(
                subtask: subtask,
                index: index + 1,
              );
            }),
            
            const SizedBox(height: 16),
            
            // Информация о времени
            plan.estimatedTotalTime.fold(
              () => const SizedBox.shrink(),
              (time) => Text(
                'Оценка времени: $time',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            
            // Кнопки подтверждения (если ожидает)
            if (plan.isPendingConfirmation) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _showRejectDialog(context),
                    child: const Text('Отклонить'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Подтвердить'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить план'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Причина отклонения',
            hintText: 'Укажите, почему план не подходит',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                onReject?.call(reason);
                Navigator.pop(context);
              }
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }
}
```

#### 4.2 SubtaskTile - элемент подзадачи

```dart
// lib/features/agent_chat/presentation/widgets/subtask_tile.dart

import 'package:flutter/material.dart';
import '../../domain/entities/execution_plan.dart';

class SubtaskTile extends StatelessWidget {
  final Subtask subtask;
  final int index;
  
  const SubtaskTile({
    Key? key,
    required this.subtask,
    required this.index,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Иконка статуса
          Text(
            subtask.status.icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          
          // Содержимое
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Описание
                Text(
                  '$index. ${subtask.description}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: subtask.status.isActive
                        ? FontWeight.bold
                        : FontWeight.normal,
                    decoration: subtask.status == SubtaskStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Метаданные
                Wrap(
                  spacing: 12,
                  children: [
                    // Агент
                    _buildChip(
                      context,
                      icon: Icons.person,
                      label: subtask.agent,
                    ),
                    
                    // Время
                    subtask.estimatedTime.fold(
                      () => const SizedBox.shrink(),
                      (time) => _buildChip(
                        context,
                        icon: Icons.schedule,
                        label: time,
                      ),
                    ),
                    
                    // Статус
                    _buildChip(
                      context,
                      icon: Icons.info_outline,
                      label: subtask.status.displayName,
                      color: _getStatusColor(subtask.status),
                    ),
                  ],
                ),
                
                // Ошибка (если есть)
                subtask.error.fold(
                  () => const SizedBox.shrink(),
                  (error) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Ошибка: $error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                
                // Зависимости
                if (subtask.dependencies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Зависит от: ${subtask.dependencies.join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  Color? _getStatusColor(SubtaskStatus status) {
    switch (status) {
      case SubtaskStatus.completed:
        return Colors.green.shade100;
      case SubtaskStatus.failed:
        return Colors.red.shade100;
      case SubtaskStatus.inProgress:
        return Colors.blue.shade100;
      default:
        return null;
    }
  }
}
```

#### 4.3 PlanProgressIndicator - компактный индикатор

```dart
// lib/features/agent_chat/presentation/widgets/plan_progress_indicator.dart

import 'package:flutter/material.dart';
import '../../domain/entities/execution_plan.dart';

class PlanProgressIndicator extends StatelessWidget {
  final ExecutionPlan plan;
  final VoidCallback? onTap;
  
  const PlanProgressIndicator({
    Key? key,
    required this.plan,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выполнение плана',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: plan.progress),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.completedCount}/${plan.totalCount} подзадач',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
```

### Шаг 5: Интегрировать с UI чата

#### 5.1 Обновить ChatScreen

```dart
// lib/features/agent_chat/presentation/pages/chat_screen.dart

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('AI Assistant'),
    ),
    body: BlocBuilder<AgentChatBloc, AgentChatState>(
      builder: (context, state) {
        return Column(
          children: [
            // Индикатор активного плана (если есть)
            state.activePlan.fold(
              () => const SizedBox.shrink(),
              (plan) {
                if (plan.isPendingConfirmation) {
                  // Показать полный обзор плана для подтверждения
                  return PlanOverviewWidget(
                    plan: plan,
                    onApprove: () {
                      context.read<AgentChatBloc>().add(
                        AgentChatEvent.approvePlan(plan.planId),
                      );
                    },
                    onReject: (reason) {
                      context.read<AgentChatBloc>().add(
                        AgentChatEvent.rejectPlan(plan.planId, reason),
                      );
                    },
                  );
                } else if (!plan.isComplete) {
                  // Показать компактный индикатор прогресса
                  return PlanProgressIndicator(
                    plan: plan,
                    onTap: () => _showPlanDetails(context, plan),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            // Список сообщений
            Expanded(
              child: MessageList(messages: state.messages),
            ),
            
            // Поле ввода
            MessageInput(
              onSend: (text) {
                context.read<AgentChatBloc>().add(
                  AgentChatEvent.sendMessage(text),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}

void _showPlanDetails(BuildContext context, ExecutionPlan plan) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: PlanOverviewWidget(plan: plan),
      ),
    ),
  );
}
```

### Шаг 6: Обновить Dependency Injection

```dart
// lib/ai_assistent_module.dart

@module
abstract class AiAssistentModule {
  // ... существующие зависимости
  
  // Use cases для планирования
  @singleton
  ApprovePlanUseCase provideApprovePlanUseCase(AgentRepository repository) =>
      ApprovePlanUseCase(repository);
  
  @singleton
  RejectPlanUseCase provideRejectPlanUseCase(AgentRepository repository) =>
      RejectPlanUseCase(repository);
  
  @singleton
  GetActivePlanUseCase provideGetActivePlanUseCase(AgentRepository repository) =>
      GetActivePlanUseCase(repository);
  
  // Обновить AgentChatBloc
  @singleton
  AgentChatBloc provideAgentChatBloc(
    SendMessageUseCase sendMessage,
    SendToolResultUseCase sendToolResult,
    ReceiveMessagesUseCase receiveMessages,
    SwitchAgentUseCase switchAgent,
    LoadHistoryUseCase loadHistory,
    ConnectUseCase connect,
    ExecuteToolUseCase executeTool,
    ToolApprovalServiceImpl approvalService,
    ApprovePlanUseCase approvePlan,
    RejectPlanUseCase rejectPlan,
    GetActivePlanUseCase getActivePlan,
    Logger logger,
  ) =>
      AgentChatBloc(
        sendMessage: sendMessage,
        sendToolResult: sendToolResult,
        receiveMessages: receiveMessages,
        switchAgent: switchAgent,
        loadHistory: loadHistory,
        connect: connect,
        executeTool: executeTool,
        approvalService: approvalService,
        approvePlan: approvePlan,
        rejectPlan: rejectPlan,
        getActivePlan: getActivePlan,
        logger: logger,
      );
}
```

### Шаг 7: Добавить тесты

#### 7.1 Тесты для ExecutionPlan

```dart
// test/features/agent_chat/domain/entities/execution_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('ExecutionPlan', () {
    test('should create plan with pending subtasks', () {
      final plan = ExecutionPlan.create(
        planId: 'plan_1',
        sessionId: 'session_1',
        originalTask: 'Test task',
        subtasks: [
          Subtask.pending(
            id: 'subtask_1',
            description: 'First task',
            agent: 'coder',
          ),
        ],
      );
      
      expect(plan.subtasks.length, 1);
      expect(plan.subtasks[0].status, SubtaskStatus.pending);
      expect(plan.isPendingConfirmation, true);
    });
    
    test('should calculate progress correctly', () {
      final plan = ExecutionPlan.create(
        planId: 'plan_1',
        sessionId: 'session_1',
        originalTask: 'Test task',
        subtasks: [
          Subtask.pending(id: '1', description: 'Task 1', agent: 'coder')
              .markCompleted(),
          Subtask.pending(id: '2', description: 'Task 2', agent: 'coder'),
        ],
      );
      
      expect(plan.progress, 0.5);
      expect(plan.completedCount, 1);
      expect(plan.totalCount, 2);
    });
    
    test('should mark subtask as completed', () {
      final plan = ExecutionPlan.create(
        planId: 'plan_1',
        sessionId: 'session_1',
        originalTask: 'Test task',
        subtasks: [
          Subtask.pending(id: 'subtask_1', description: 'Task', agent: 'coder'),
        ],
      );
      
      final updated = plan.markSubtaskCompleted('subtask_1');
      
      expect(updated.subtasks[0].status, SubtaskStatus.completed);
    });
  });
}
```

#### 7.2 Тесты для Use Cases

```dart
// test/features/agent_chat/domain/usecases/approve_plan_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockAgentRepository extends Mock implements AgentRepository {}

void main() {
  late ApprovePlanUseCase useCase;
  late MockAgentRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAgentRepository();
    useCase = ApprovePlanUseCase(mockRepository);
  });
  
  test('should approve plan through repository', () async {
    // Arrange
    when(() => mockRepository.approvePlan(
      planId: any(named: 'planId'),
      feedback: any(named: 'feedback'),
    )).thenAnswer((_) async => right(null));
    
    // Act
    final result = await useCase(
      ApprovePlanParams(planId: 'plan_1'),
    );
    
    // Assert
    expect(result.isRight(), true);
    verify(() => mockRepository.approvePlan(
      planId: 'plan_1',
      feedback: const None(),
    )).called(1);
  });
}
```

---

## 📋 Чеклист реализации

- [x] Domain entities созданы
- [x] Use cases созданы (частично)
- [ ] AgentRepository расширен
- [ ] AgentRepositoryImpl реализован
- [ ] AgentChatBloc расширен
- [ ] UI компоненты созданы
- [ ] Интеграция с ChatScreen
- [ ] Dependency Injection обновлен
- [ ] Тесты добавлены
- [ ] Документация обновлена

---

## 🎯 Приоритеты

1. **Высокий**: Расширить AgentRepository и реализовать методы
2. **Высокий**: Расширить AgentChatBloc для обработки планов
3. **Средний**: Создать базовые UI компоненты
4. **Средний**: Интегрировать с ChatScreen
5. **Низкий**: Добавить тесты
6. **Низкий**: Улучшить UI/UX

---

## 📝 Примечания

- Все компоненты следуют Clean Architecture
- Используется freezed для immutable entities
- Используется fpdart для функционального программирования
- UI компоненты адаптивны и следуют Material Design
- Тесты покрывают основную функциональность

---

## 🔗 Связанные документы

- [Анализ поддержки планирования](../PLANNING_SUPPORT_ANALYSIS_CODELAB_IDE.md)
- [Руководство по системе планирования agent-runtime](../codelab-ai-service/agent-runtime/PLANNING_SYSTEM_GUIDE.md)
