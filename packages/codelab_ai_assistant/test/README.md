# Тесты для codelab_ai_assistant

Этот каталог содержит тесты для интеграции ToolExecutor с WebSocket handler.

## Структура тестов

### Unit тесты

#### 1. WebSocketErrorMapper (`utils/websocket_error_mapper_test.dart`)
Тестирует маппинг всех типов `ToolExecutionException` в WebSocket error messages:
- `fileNotFound` → "file_not_found: ..."
- `permissionDenied` → "permission_denied: ..."
- `invalidPath` → "invalid_path: ..."
- `fileTooLarge` → "file_too_large: ..."
- `encodingError` → "encoding_error: ..."
- `userRejected` → "user_rejected: ..."
- `concurrentModification` → "concurrent_modification: ..."
- `general` → "general_error: ..."

**Покрытие:** 13 тестов

#### 2. ToolApprovalService (`services/tool_approval_service_test.dart`)
Тестирует сервис подтверждения операций:
- Создание запроса подтверждения через `requestApproval()`
- Получение запроса через stream `approvalRequests`
- Отправка ответа через completer
- Обработка нескольких одновременных запросов
- Broadcast stream с несколькими слушателями
- Корректное закрытие ресурсов

**Покрытие:** 10 тестов

#### 3. ToolApiImpl (`integration/tool_api_test.dart`)
Тестирует интеграцию ToolApi с ToolExecutor и ToolApprovalService:
- Успешное выполнение `read_file` без подтверждения
- Успешное выполнение `write_file` с подтверждением
- Отклонение пользователем (user rejection)
- Обработка ошибок валидации пути
- Обработка ошибок IO
- Создание ToolCall с корректными параметрами
- Последовательность операций approval → execution

**Покрытие:** 15 тестов

### Integration тесты

#### 4. Tool Execution Flow (`integration/tool_execution_flow_test.dart`)
Тестирует полный flow от WebSocket до ToolExecutor:
1. WebSocket получает `tool_call` сообщение
2. BLoC обрабатывает и вызывает `ToolApi`
3. `ToolApi` выполняет через `ToolExecutor`
4. Результат отправляется обратно через WebSocket

Тестовые сценарии:
- Успешное выполнение read_file
- Успешное выполнение write_file с approval
- Обработка ошибок выполнения
- Обработка user rejection
- Множественные последовательные вызовы
- Обработка assistant messages вместе с tool calls
- Обработка неожиданных ошибок

**Покрытие:** 11 тестов

### Widget тесты

#### 5. AiAssistantPanel (`ui/ai_assistant_panel_test.dart`)
Тестирует UI компонент:
- Отображение начального состояния
- Отображение user/assistant/tool_call/tool_result/error сообщений
- Индикатор `[requires approval]` для HITL операций
- Отправка сообщений через UI
- Блокировка ввода при ожидании ответа
- Отображение ProgressRing при ожидании
- Выравнивание сообщений (user справа, assistant слева)
- Обработка множественных сообщений

**Покрытие:** 18 тестов

## Запуск тестов

### Все тесты
```bash
cd codelab_ide/packages/codelab_ai_assistant
flutter test
```

### Конкретный файл
```bash
flutter test test/utils/websocket_error_mapper_test.dart
```

### С покрытием кода
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Зависимости для тестирования

- `test: ^1.25.6` - основной фреймворк для unit тестов
- `flutter_test` - фреймворк для widget тестов
- `mocktail: ^1.0.4` - библиотека для создания моков
- `bloc_test: ^10.0.0` - утилиты для тестирования BLoC

## Моки

Используются следующие моки:
- `MockToolExecutor` - мок для ToolExecutor
- `MockToolApprovalService` - мок для ToolApprovalService
- `MockAgentProtocolService` - мок для AgentProtocolService
- `MockToolApi` - мок для ToolApi

## Общая статистика

- **Всего тестов:** 67
- **Unit тесты:** 38
- **Integration тесты:** 11
- **Widget тесты:** 18
- **Целевое покрытие:** ≥80%

## Примечания

1. Все тесты используют `setUp` и `tearDown` для инициализации и очистки
2. Моки настраиваются с fallback значениями для mocktail
3. Integration тесты используют `blocTest` для удобного тестирования BLoC
4. Widget тесты используют `FluentApp` для корректного рендеринга Fluent UI компонентов
5. Все асинхронные операции корректно обрабатываются с помощью `async/await`

## Обнаруженные проблемы

В процессе написания тестов проблем в реализации не обнаружено. Все компоненты работают согласно спецификации.

## Рекомендации

1. **Добавить UI для диалога подтверждения:** Текущий UI показывает индикатор `[requires approval]`, но не показывает диалог подтверждения. Рекомендуется добавить слушатель `ToolApprovalService.approvalRequests` в UI слой для показа диалога.

2. **Добавить тесты для PathValidator:** Если есть кастомная логика валидации путей, стоит добавить отдельные тесты.

3. **Добавить E2E тесты:** Для полной уверенности в работе системы рекомендуется добавить end-to-end тесты с реальным WebSocket соединением.

4. **Мониторинг покрытия:** Регулярно проверять покрытие кода и поддерживать его на уровне ≥80%.
