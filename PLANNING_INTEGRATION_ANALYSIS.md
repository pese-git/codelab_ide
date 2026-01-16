# Анализ интеграции системы планирования в CodeLab IDE

## Введение

На основе анализа файла `AGENT_RUNTIME_ALGORITHM.md` и текущей реализации IDE в `codelab_ide`, требуется доработать IDE для полной поддержки мультиагентной системы планирования.

## Текущая реализация в IDE

### Поддерживаемые возможности
- ✅ Базовый WebSocket протокол (websocket-protocol.md)
- ✅ Поддержка agent_switched сообщений
- ✅ HITL (Human-in-the-Loop) для tool approvals
- ✅ UI компоненты для индикации агентов (agent_indicator.dart, agent_selector.dart)
- ✅ Диалоги подтверждения инструментов (tool_approval_dialog.dart)

### Отсутствующие возможности планирования

#### 1. Типы сообщений протокола
Отсутствуют типы сообщений для планирования:
- `plan_notification` - показ плана пользователю для подтверждения
- `plan_update` - обновление статуса плана
- `plan_progress` - прогресс по отдельным шагам плана

#### 2. Состояния сессии
В AgentChatBloc отсутствует поддержка состояний:
- `PLAN_PENDING_CONFIRMATION` - план создан, ожидается подтверждение
- `PLAN_EXECUTING` - план выполняется
- `PLAN_COMPLETED` - план завершен

#### 3. UI компоненты планирования
Отсутствуют:
- Диалог показа и подтверждения плана
- Панель отображения прогресса планирования (ReasoningPanel)
- Визуализация цепочки агентов при планировании

## Рекомендации по доработке

### 1. Расширение протокола WebSocket

#### Добавить типы сообщений в `ws_message.dart`:
```dart
const factory WSMessage.planNotification({
  @JsonKey(name: 'plan_id') required String planId,
  required String content,
  required Map<String, dynamic> metadata,
}) = WSPlanNotification;

const factory WSMessage.planUpdate({
  @JsonKey(name: 'plan_id') required String planId,
  required List<Map<String, dynamic>> steps,
  String? currentStep,
}) = WSPlanUpdate;

const factory WSMessage.planProgress({
  @JsonKey(name: 'plan_id') required String planId,
  @JsonKey(name: 'step_id') required String stepId,
  String? result,
  required String status,
}) = WSPlanProgress;
```

#### Добавить сообщение подтверждения плана:
```dart
const factory WSMessage.planApproval({
  @JsonKey(name: 'plan_id') required String planId,
  required String decision, // "approve", "reject"
  String? feedback,
}) = WSPlanApproval;
```

### 2. Обновление BLoC состояния

#### Добавить состояния планирования в AgentChatState:
```dart
const factory AgentChatState.planPendingConfirmation({
  required String planId,
  required String planContent,
  required List<Map<String, dynamic>> steps,
}) = PlanPendingConfirmation;

const factory AgentChatState.planExecuting({
  required String planId,
  required List<Map<String, dynamic>> steps,
  required String currentStep,
}) = PlanExecuting;
```

#### Добавить события для работы с планами:
```dart
const factory AgentChatEvent.planNotificationReceived({
  required String planId,
  required String content,
  required Map<String, dynamic> metadata,
}) = PlanNotificationReceived;

const factory AgentChatEvent.approvePlan(String planId) = ApprovePlan;
const factory AgentChatEvent.rejectPlan(String planId, String feedback) = RejectPlan;
```

### 3. Создание UI компонентов

#### PlanNotificationDialog
Диалог для показа плана пользователю:
- Отображение текста плана
- Список шагов с описаниями
- Кнопки Approve/Reject

#### ReasoningPanel
Панель отображения прогресса:
- Список шагов плана с статусами (pending/running/done/error)
- Текущий активный шаг
- Цепочка агентов при мультиагентном выполнении

### 4. Интеграция с существующей архитектурой

#### Обновление MessageModel
Добавить обработку новых типов сообщений в `_parseContent()`:
```dart
case 'plan_notification':
  return MessageContent.planNotification(
    planId: planId,
    content: content,
    metadata: metadata,
  );

case 'plan_update':
  return MessageContent.planUpdate(
    planId: planId,
    steps: steps,
    currentStep: currentStep,
  );
```

#### Обновление AgentChatBloc
- Обработка входящих plan_notification
- Отправка подтверждений планов
- Управление состоянием планирования

### 5. Архитектурные решения

#### Состояние сессии
Использовать отдельное состояние для отслеживания фазы планирования:
- NEW_SESSION → обычный чат
- PLAN_PENDING_CONFIRMATION → показ диалога плана
- PLAN_EXECUTING → отображение прогресса
- PLAN_COMPLETED → обычный чат

#### Управление планами
- Хранить текущий активный план в состоянии BLoC
- Поддерживать историю планов в сессии
- Синхронизировать состояние с сервером

## План реализации

### Этап 1: Протокол (1-2 дня)
1. Добавить типы сообщений в ws_message.dart
2. Обновить MessageModel для обработки планов
3. Протестировать сериализацию/десериализацию

### Этап 2: BLoC логика (2-3 дня)
1. Добавить состояния планирования
2. Реализовать обработку событий планов
3. Добавить отправку подтверждений

### Этап 3: UI компоненты (3-4 дня)
1. Создать PlanNotificationDialog
2. Создать ReasoningPanel
3. Интегрировать в AI Assistant Panel

### Этап 4: Интеграция и тестирование (2-3 дня)
1. Связать UI с BLoC логикой
2. Протестировать полный флоу планирования
3. Обработать edge cases

## Риски и зависимости

### Риски
- Несоответствие протокола между IDE и agent-runtime
- Сложность управления состоянием при мультиагентном выполнении
- UX проблемы с отображением сложных планов

### Зависимости
- Требуется обновление agent-runtime для отправки plan_notification
- Возможны изменения в формате сообщений планирования

## Заключение

Текущая реализация IDE имеет хорошую базу для интеграции планирования. Основные доработки требуются в:
1. Расширении протокола сообщений
2. Добавлении состояний планирования в BLoC
3. Создании UI компонентов для отображения планов

Рекомендуется начать с расширения протокола и постепенно добавлять UI компоненты.