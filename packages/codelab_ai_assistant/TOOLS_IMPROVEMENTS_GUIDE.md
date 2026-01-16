# Руководство по улучшениям системы Tools

**Дата:** 15 января 2026  
**Версия:** 1.0.0  
**Статус:** ✅ Реализовано

---

## Обзор

Реализованы три ключевых улучшения для системы tools в `codelab_ai_assistant`:

1. ✅ **Mapping таблица** - централизованная спецификация всех tools
2. ✅ **Интеграционные тесты** - автоматическая проверка совместимости
3. ✅ **Мониторинг использования** - сбор метрик и анализ паттернов

---

## 1. Mapping таблица tools

### Описание

Централизованный реестр всех tools с полной спецификацией параметров, который служит источником истины для проверки совместимости между agent-runtime и IDE.

### Файл

[`lib/features/tool_execution/data/config/tools_mapping.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/config/tools_mapping.dart)

### Использование

```dart
import 'package:codelab_ai_assistant/features/tool_execution/data/config/tools_mapping.dart';

// Получить спецификацию tool
final readFileTool = ToolsRegistry.getToolByName('read_file');
print(readFileTool?.description);

// Проверить, поддерживается ли tool в IDE
final isSupported = ToolsRegistry.isToolSupportedInIde('write_file');
print('write_file supported: $isSupported'); // true

// Проверить, требует ли tool подтверждения
final requiresApproval = ToolsRegistry.doesToolRequireApproval('execute_command');
print('execute_command requires approval: $requiresApproval'); // true

// Получить все IDE tools
final ideTools = ToolsRegistry.getIdeTools;
print('IDE tools count: ${ideTools.length}'); // 6

// Получить все локальные tools
final localTools = ToolsRegistry.getLocalTools;
print('Local tools count: ${localTools.length}'); // 4

// Получить tools, требующие подтверждения
final approvalTools = ToolsRegistry.getToolsRequiringApproval;
for (final tool in approvalTools) {
  print('Requires approval: ${tool.name}');
}

// Экспортировать в JSON
final json = ToolsRegistry.toJson();
print('Total tools: ${json['total_tools']}'); // 10
```

### Структура данных

```dart
class ToolSpec {
  final String name;                          // Имя tool
  final String description;                   // Описание
  final List<ToolParameterSpec> parameters;   // Параметры
  final ToolExecutionLocation executionLocation; // Где выполняется
  final bool requiresApproval;                // Требует подтверждения
  final String? agentRuntimeFile;             // Ссылка на файл в agent-runtime
  final String? ideImplementationFile;        // Ссылка на реализацию в IDE
}

class ToolParameterSpec {
  final String name;           // Имя параметра
  final String type;           // Тип (string, integer, boolean, array, object)
  final bool required;         // Обязательный
  final dynamic defaultValue;  // Значение по умолчанию
  final String? description;   // Описание
  final List<String>? enumValues; // Возможные значения (для enum)
  final int? minimum;          // Минимальное значение (для integer)
  final int? maximum;          // Максимальное значение (для integer)
}
```

### Преимущества

- 📋 **Единый источник истины** для спецификаций tools
- 🔍 **Автоматическая проверка** совместимости
- 📚 **Документация** встроена в код
- 🔗 **Ссылки на реализацию** для быстрой навигации
- 📤 **JSON экспорт** для внешних инструментов

---

## 2. Интеграционные тесты

### Описание

Автоматические тесты для проверки совместимости параметров tools между agent-runtime и IDE реализацией.

### Файл

[`test/features/tool_execution/tools_compatibility_test.dart`](codelab_ide/packages/codelab_ai_assistant/test/features/tool_execution/tools_compatibility_test.dart)

### Запуск тестов

```bash
cd codelab_ide/packages/codelab_ai_assistant
flutter test test/features/tool_execution/tools_compatibility_test.dart
```

### Что тестируется

#### 1. Регистрация IDE Tools
- ✅ Все IDE tools из registry поддерживаются executor
- ✅ Executor не поддерживает tools, не указанные в registry
- ✅ Все IDE tools имеют ссылку на файл реализации

#### 2. Валидация параметров
- ✅ `read_file` имеет все требуемые параметры
- ✅ `write_file` имеет все требуемые параметры
- ✅ `execute_command` имеет все требуемые параметры
- ✅ `search_in_code` имеет все требуемые параметры

#### 3. Место выполнения
- ✅ Локальные tools помечены как agent-runtime execution
- ✅ IDE tools помечены как IDE execution

#### 4. HITL требования
- ✅ Опасные tools требуют подтверждения
- ✅ Безопасные tools не требуют подтверждения
- ✅ Helper методы корректно определяют требования

#### 5. Консистентность
- ✅ Все tools имеют уникальные имена
- ✅ Все tools имеют непустые описания
- ✅ Все tools имеют хотя бы один параметр
- ✅ Обязательные параметры идут перед опциональными

### Пример вывода

```
✓ all IDE tools from registry are supported by executor
✓ executor does not support tools not in registry
✓ all IDE tools have implementation file reference
✓ read_file has all required parameters
✓ write_file has all required parameters
✓ execute_command has all required parameters
✓ search_in_code has all required parameters
✓ local tools are marked as agent-runtime execution
✓ IDE tools are marked as IDE execution
✓ dangerous tools require approval
✓ safe tools do not require approval

All tests passed! ✅
```

---

## 3. Мониторинг использования tools

### Описание

Система сбора метрик использования tools для анализа паттернов, выявления проблем и оптимизации производительности.

### Файл

[`lib/features/tool_execution/data/services/tool_usage_monitor.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/services/tool_usage_monitor.dart)

### Использование

#### Создание монитора

```dart
import 'package:codelab_ai_assistant/features/tool_execution/data/services/tool_usage_monitor.dart';
import 'package:logger/logger.dart';

final monitor = ToolUsageMonitor(
  logger: Logger(),
  maxRecords: 1000,        // Максимум записей в памяти
  verboseLogging: true,    // Детальное логирование
);
```

#### Интеграция с ToolExecutor

```dart
final executor = ToolExecutorDataSourceImpl(
  fileSystem: fileSystemDataSource,
  monitor: monitor,  // Передаем монитор
);

// Теперь все вызовы tools автоматически логируются
```

#### Получение статистики

```dart
// Статистика для конкретного tool
final readFileStats = monitor.getStatsForTool('read_file');
if (readFileStats != null) {
  print('Total calls: ${readFileStats.totalCalls}');
  print('Success rate: ${(readFileStats.successRate * 100).toStringAsFixed(1)}%');
  print('Average duration: ${readFileStats.averageDurationMs.toStringAsFixed(0)}ms');
}

// Статистика для всех tools
final allStats = monitor.getAllStats();
for (final entry in allStats.entries) {
  print('${entry.key}: ${entry.value.totalCalls} calls');
}

// Топ используемых tools
final topUsed = monitor.getTopUsedTools(5);
for (var i = 0; i < topUsed.length; i++) {
  print('${i + 1}. ${topUsed[i].key}: ${topUsed[i].value} calls');
}

// Самые медленные tools
final slowest = monitor.getSlowestTools(5);
for (var i = 0; i < slowest.length; i++) {
  print('${i + 1}. ${slowest[i].key}: ${slowest[i].value.toStringAsFixed(0)}ms avg');
}

// Tools с наибольшим количеством ошибок
final mostErrors = monitor.getToolsWithMostErrors(5);
for (var i = 0; i < mostErrors.length; i++) {
  print('${i + 1}. ${mostErrors[i].key}: ${mostErrors[i].value} errors');
}
```

#### Stream событий

```dart
// Подписка на события использования tools
monitor.recordsStream.listen((record) {
  print('Tool used: ${record.toolName} (${record.durationMs}ms)');
  if (!record.success) {
    print('Error: ${record.errorCode} - ${record.errorMessage}');
  }
});
```

#### Экспорт статистики

```dart
// Экспорт в JSON
final stats = monitor.exportStats();
print(stats['overall']['total_calls']);
print(stats['by_tool']['read_file']['success_rate']);

// Вывод отчета в лог
monitor.logReport();
```

### Пример отчета

```
═══════════════════════════════════════════════════
📊 Tool Usage Report
═══════════════════════════════════════════════════
Total calls: 156
Success rate: 94.2%
Unique tools: 6
Average duration: 45ms

🔥 Top Used Tools:
  1. read_file: 67 calls
  2. list_files: 34 calls
  3. search_in_code: 23 calls
  4. write_file: 18 calls
  5. execute_command: 14 calls

🐌 Slowest Tools:
  1. execute_command: 234ms avg
  2. search_in_code: 89ms avg
  3. write_file: 56ms avg
  4. read_file: 23ms avg
  5. list_files: 12ms avg

⚠️  Tools with Most Errors:
  1. execute_command: 5 errors
  2. write_file: 4 errors

═══════════════════════════════════════════════════
```

### Собираемые метрики

#### Для каждого tool:
- 📊 Общее количество вызовов
- ✅ Успешные вызовы
- ❌ Неудачные вызовы
- 📈 Success rate (процент успешных)
- ⏱️ Общее время выполнения
- ⏱️ Среднее время выполнения
- ⏱️ Минимальное время
- ⏱️ Максимальное время
- 📅 Первое использование
- 📅 Последнее использование
- 🐛 Количество ошибок по типам

#### Общая статистика:
- Всего вызовов
- Уникальных tools
- Общий success rate
- Среднее время выполнения
- Топ используемых tools
- Самые медленные tools
- Tools с наибольшим количеством ошибок

---

## Интеграция в существующий код

### Обновление DI контейнера

```dart
// В ai_assistent_module.dart или где настраивается DI

import 'package:codelab_ai_assistant/features/tool_execution/data/services/tool_usage_monitor.dart';

// Создаем singleton монитора
final toolUsageMonitor = ToolUsageMonitor(
  logger: Logger(),
  maxRecords: 1000,
  verboseLogging: false, // true для разработки
);

// Передаем в ToolExecutorDataSource
final toolExecutor = ToolExecutorDataSourceImpl(
  fileSystem: fileSystemDataSource,
  monitor: toolUsageMonitor,
);
```

### Периодический вывод отчетов

```dart
// Настроить периодический вывод отчетов (например, каждые 5 минут)
Timer.periodic(Duration(minutes: 5), (_) {
  toolUsageMonitor.logReport();
});
```

### Экспорт статистики при закрытии

```dart
// При закрытии приложения или сессии
@override
void dispose() {
  // Экспортируем финальную статистику
  final stats = toolUsageMonitor.exportStats();
  
  // Можно сохранить в файл или отправить на сервер
  saveStatsToFile(stats);
  
  toolUsageMonitor.dispose();
  super.dispose();
}
```

---

## Примеры использования

### Анализ производительности

```dart
// Найти самые медленные операции
final slowest = monitor.getSlowestTools(10);
for (final entry in slowest) {
  if (entry.value > 1000) { // Больше 1 секунды
    print('⚠️  Slow tool detected: ${entry.key} (${entry.value}ms)');
    // Можно отправить алерт или начать оптимизацию
  }
}
```

### Выявление проблемных tools

```dart
// Найти tools с низким success rate
final allStats = monitor.getAllStats();
for (final entry in allStats.entries) {
  if (entry.value.successRate < 0.9) { // Меньше 90%
    print('⚠️  Low success rate: ${entry.key} (${(entry.value.successRate * 100).toStringAsFixed(1)}%)');
    print('   Errors: ${entry.value.errorCounts}');
  }
}
```

### Анализ паттернов использования

```dart
// Получить записи за последний час
final oneHourAgo = DateTime.now().subtract(Duration(hours: 1));
final recentRecords = monitor.getRecordsSince(oneHourAgo);

// Анализ частоты использования
final toolCounts = <String, int>{};
for (final record in recentRecords) {
  toolCounts[record.toolName] = (toolCounts[record.toolName] ?? 0) + 1;
}

print('Tools used in last hour:');
for (final entry in toolCounts.entries) {
  print('  ${entry.key}: ${entry.value} times');
}
```

---

## Тестирование

### Запуск всех тестов совместимости

```bash
cd codelab_ide/packages/codelab_ai_assistant
flutter test test/features/tool_execution/tools_compatibility_test.dart
```

### Запуск конкретной группы тестов

```bash
# Только тесты регистрации
flutter test test/features/tool_execution/tools_compatibility_test.dart --name "IDE Tools Registration"

# Только тесты параметров
flutter test test/features/tool_execution/tools_compatibility_test.dart --name "Tool Parameters Validation"

# Только тесты HITL
flutter test test/features/tool_execution/tools_compatibility_test.dart --name "HITL Approval Requirements"
```

### Continuous Integration

Добавьте в CI/CD pipeline:

```yaml
# .github/workflows/test.yml
- name: Run tools compatibility tests
  run: |
    cd codelab_ide/packages/codelab_ai_assistant
    flutter test test/features/tool_execution/tools_compatibility_test.dart
```

---

## Мониторинг в production

### Настройка для production

```dart
final monitor = ToolUsageMonitor(
  logger: Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: false, // Отключить цвета для production логов
    ),
  ),
  maxRecords: 500,      // Меньше записей для экономии памяти
  verboseLogging: false, // Отключить детальное логирование
);
```

### Периодическая очистка

```dart
// Очищать старые записи каждый час
Timer.periodic(Duration(hours: 1), (_) {
  final stats = monitor.exportStats();
  
  // Сохранить статистику перед очисткой
  saveStatsToAnalytics(stats);
  
  // Очистить записи
  monitor.clear();
});
```

### Алерты на аномалии

```dart
// Проверка на аномалии каждые 5 минут
Timer.periodic(Duration(minutes: 5), (_) {
  final stats = monitor.getAllStats();
  
  for (final entry in stats.entries) {
    // Алерт на низкий success rate
    if (entry.value.successRate < 0.8 && entry.value.totalCalls > 10) {
      sendAlert(
        'Low success rate for ${entry.key}: ${(entry.value.successRate * 100).toStringAsFixed(1)}%',
      );
    }
    
    // Алерт на медленное выполнение
    if (entry.value.averageDurationMs > 5000) { // Больше 5 секунд
      sendAlert(
        'Slow tool detected: ${entry.key} (${entry.value.averageDurationMs.toStringAsFixed(0)}ms avg)',
      );
    }
  }
});
```

---

## Отладка и диагностика

### Включение детального логирования

```dart
// Для разработки и отладки
final monitor = ToolUsageMonitor(
  verboseLogging: true, // Включить детальное логирование
);

// Теперь каждый вызов tool будет логироваться с metadata
```

### Анализ конкретной проблемы

```dart
// Получить все неудачные вызовы конкретного tool
final writeFileRecords = monitor.getRecordsForTool('write_file');
final failures = writeFileRecords.where((r) => !r.success);

for (final failure in failures) {
  print('Failed at: ${failure.timestamp}');
  print('Error: ${failure.errorCode} - ${failure.errorMessage}');
  print('Metadata: ${failure.metadata}');
  print('---');
}
```

### Экспорт для внешнего анализа

```dart
import 'dart:convert';
import 'dart:io';

// Экспорт всех записей в JSON файл
Future<void> exportRecordsToFile(ToolUsageMonitor monitor) async {
  final records = monitor.getAllRecords();
  final json = records.map((r) => r.toJson()).toList();
  
  final file = File('tool_usage_records.json');
  await file.writeAsString(jsonEncode(json));
  
  print('Exported ${records.length} records to tool_usage_records.json');
}

// Экспорт статистики
Future<void> exportStatsToFile(ToolUsageMonitor monitor) async {
  final stats = monitor.exportStats();
  
  final file = File('tool_usage_stats.json');
  await file.writeAsString(jsonEncode(stats));
  
  print('Exported stats to tool_usage_stats.json');
}
```

---

## Best Practices

### 1. Мониторинг

- ✅ Всегда передавайте монитор в ToolExecutor
- ✅ Периодически выводите отчеты для анализа
- ✅ Экспортируйте статистику перед закрытием приложения
- ✅ Настройте алерты на аномалии в production

### 2. Тестирование

- ✅ Запускайте compatibility тесты при каждом изменении tools
- ✅ Добавляйте тесты для новых tools в registry
- ✅ Проверяйте совместимость параметров с agent-runtime

### 3. Документация

- ✅ Используйте ToolsRegistry как источник истины
- ✅ Обновляйте спецификации при изменении tools
- ✅ Документируйте новые параметры в ToolParameterSpec

---

## Troubleshooting

### Проблема: Тесты падают после добавления нового tool

**Решение:**
1. Добавьте tool в [`tools_mapping.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/config/tools_mapping.dart)
2. Добавьте tool в [`tool_executor_datasource.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/datasources/tool_executor_datasource.dart) `_supportedTools`
3. Реализуйте метод `_execute{ToolName}` в том же файле
4. Запустите тесты для проверки

### Проблема: Монитор не логирует события

**Решение:**
1. Проверьте, что монитор передан в ToolExecutor
2. Проверьте уровень логирования Logger
3. Включите `verboseLogging: true` для отладки

### Проблема: Статистика показывает неожиданные результаты

**Решение:**
1. Проверьте, не достигнут ли `maxRecords` (старые записи удаляются)
2. Используйте `exportStats()` для детального анализа
3. Проверьте временные метки записей

---

## Roadmap

### Планируемые улучшения

- [ ] Персистентное хранение статистики (SQLite)
- [ ] Dashboard для визуализации метрик
- [ ] Автоматические рекомендации по оптимизации
- [ ] Интеграция с системой аналитики
- [ ] A/B тестирование различных реализаций tools
- [ ] Предиктивный анализ для предотвращения ошибок

---

## Связанные файлы

### Основные компоненты
- [`tools_mapping.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/config/tools_mapping.dart) - Mapping таблица
- [`tool_usage_monitor.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/services/tool_usage_monitor.dart) - Мониторинг
- [`tool_executor_datasource.dart`](codelab_ide/packages/codelab_ai_assistant/lib/features/tool_execution/data/datasources/tool_executor_datasource.dart) - Executor с мониторингом

### Тесты
- [`tools_compatibility_test.dart`](codelab_ide/packages/codelab_ai_assistant/test/features/tool_execution/tools_compatibility_test.dart) - Интеграционные тесты

### Документация
- [`TOOLS_IMPLEMENTATION_ANALYSIS.md`](../../../TOOLS_IMPLEMENTATION_ANALYSIS.md) - Анализ реализации

---

**Автор:** AI Development Team  
**Дата:** 15 января 2026  
**Версия:** 1.0.0
