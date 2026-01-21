# CodeLab Engine

Движок редактора кода для CodeLab IDE. Предоставляет сервисы для управления редактором, синхронизации файлов и интеграции с Language Server Protocol (LSP).

**Версия**: 1.0.0  
**Дата обновления**: 21 января 2026

## 🎯 Возможности

### ✅ Реализованные функции

**Управление редактором:**
- Открытие и закрытие файлов
- Управление вкладками редактора
- Отслеживание активного файла
- Сохранение изменений

**Синхронизация файлов:**
- Автоматическая синхронизация изменений
- Отслеживание несохраненных изменений
- Обработка конфликтов
- Восстановление после сбоев

**Подсветка синтаксиса:**
- Поддержка 10+ языков программирования
- Автоматическое определение языка по расширению
- Кастомизируемые темы подсветки

### 🚧 В разработке

**LSP интеграция:**
- Language Server Protocol клиент
- Автодополнение кода
- Go to definition
- Find references
- Диагностика ошибок

## 🏗️ Архитектура

```
lib/
├── src/
│   ├── services/
│   │   ├── editor_manager_service.dart  # Управление редактором
│   │   ├── file_sync_service.dart       # Синхронизация файлов
│   │   └── lsp_service.dart             # LSP интеграция (в разработке)
│   ├── models/
│   │   ├── editor_state.dart            # Состояние редактора
│   │   └── file_change.dart             # Модель изменения файла
│   └── utils/
│       └── language_detector.dart       # Определение языка
└── codelab_engine.dart                  # Публичный API
```

## 📦 Зависимости

```yaml
dependencies:
  # Core
  codelab_core: any
  
  # Functional programming
  fpdart: ^1.2.0
  
  # State management
  flutter_bloc: ^9.1.1
  
  # Logging
  logger: ^2.6.2
  
  # File system
  file: ^7.0.1
  path: ^1.9.1
```

## 🚀 Использование

### EditorManagerService

```dart
import 'package:codelab_engine/codelab_engine.dart';

final editorManager = EditorManagerService();

// Открыть файл
await editorManager.openFile('/path/to/file.dart');

// Получить активный файл
final activeFile = editorManager.activeFile;

// Закрыть файл
await editorManager.closeFile('/path/to/file.dart');

// Сохранить файл
await editorManager.saveFile('/path/to/file.dart', content);

// Получить список открытых файлов
final openFiles = editorManager.openFiles;
```

### FileSyncService

```dart
import 'package:codelab_engine/codelab_engine.dart';

final syncService = FileSyncService();

// Начать отслеживание файла
syncService.watchFile('/path/to/file.dart');

// Подписаться на изменения
syncService.changes.listen((change) {
  print('Файл изменен: ${change.path}');
  print('Тип изменения: ${change.type}');
});

// Синхронизировать изменения
await syncService.syncChanges();

// Проверить наличие несохраненных изменений
final hasUnsaved = syncService.hasUnsavedChanges('/path/to/file.dart');
```

### LanguageDetector

```dart
import 'package:codelab_engine/codelab_engine.dart';

// Определить язык по расширению файла
final language = LanguageDetector.detectLanguage('main.dart');
// Вернет: 'dart'

// Получить конфигурацию подсветки
final highlightConfig = LanguageDetector.getHighlightConfig('dart');

// Проверить поддержку языка
final isSupported = LanguageDetector.isSupported('dart');
// Вернет: true
```

## 🎨 Поддерживаемые языки

| Язык | Расширения | Подсветка | LSP |
|------|-----------|-----------|-----|
| Dart | `.dart` | ✅ | 🚧 |
| Python | `.py` | ✅ | 🚧 |
| JavaScript | `.js`, `.jsx` | ✅ | 🚧 |
| TypeScript | `.ts`, `.tsx` | ✅ | 🚧 |
| Java | `.java` | ✅ | 🚧 |
| C/C++ | `.c`, `.cpp`, `.h` | ✅ | 🚧 |
| Go | `.go` | ✅ | 🚧 |
| Rust | `.rs` | ✅ | 🚧 |
| HTML | `.html`, `.htm` | ✅ | ❌ |
| CSS | `.css`, `.scss` | ✅ | ❌ |
| JSON | `.json` | ✅ | ❌ |
| YAML | `.yaml`, `.yml` | ✅ | ❌ |
| Markdown | `.md` | ✅ | ❌ |

## 🔧 Конфигурация

### Настройка EditorManager

```dart
final editorManager = EditorManagerService(
  maxOpenFiles: 20,           // Максимум открытых файлов
  autoSave: true,             // Автосохранение
  autoSaveInterval: Duration(seconds: 30),
  tabSize: 2,                 // Размер табуляции
  insertSpaces: true,         // Использовать пробелы вместо табов
);
```

### Настройка FileSyncService

```dart
final syncService = FileSyncService(
  syncInterval: Duration(seconds: 5),  // Интервал синхронизации
  conflictResolution: ConflictResolution.keepLocal,  // Стратегия разрешения конфликтов
  enableBackup: true,                  // Создавать резервные копии
);
```

## 🧪 Тестирование

```bash
# Запустить все тесты
flutter test

# Запустить конкретный тест
flutter test test/services/editor_manager_service_test.dart

# Запустить с coverage
flutter test --coverage
```

## 📚 API Reference

### EditorManagerService

| Метод | Описание | Возвращает |
|-------|----------|------------|
| `openFile(String path)` | Открывает файл | `Future<Either<AppError, void>>` |
| `closeFile(String path)` | Закрывает файл | `Future<Either<AppError, void>>` |
| `saveFile(String path, String content)` | Сохраняет файл | `Future<Either<AppError, void>>` |
| `getFileContent(String path)` | Получает содержимое | `Either<AppError, String>` |
| `isFileOpen(String path)` | Проверяет открыт ли файл | `bool` |

### FileSyncService

| Метод | Описание | Возвращает |
|-------|----------|------------|
| `watchFile(String path)` | Начинает отслеживание | `void` |
| `unwatchFile(String path)` | Прекращает отслеживание | `void` |
| `syncChanges()` | Синхронизирует изменения | `Future<void>` |
| `hasUnsavedChanges(String path)` | Проверяет несохраненные изменения | `bool` |
| `discardChanges(String path)` | Отменяет изменения | `Future<void>` |

### LanguageDetector

| Метод | Описание | Возвращает |
|-------|----------|------------|
| `detectLanguage(String filePath)` | Определяет язык | `String?` |
| `getHighlightConfig(String language)` | Получает конфигурацию подсветки | `HighlightConfig?` |
| `isSupported(String language)` | Проверяет поддержку | `bool` |
| `getSupportedLanguages()` | Список поддерживаемых языков | `List<String>` |

## 🛠️ Разработка

### Добавление поддержки нового языка

1. Обновите `LanguageDetector`:
```dart
class LanguageDetector {
  static const _languageMap = {
    // ... существующие языки
    '.mylang': 'mylanguage',
  };
  
  static HighlightConfig? getHighlightConfig(String language) {
    switch (language) {
      // ... существующие языки
      case 'mylanguage':
        return HighlightConfig(
          keywords: ['keyword1', 'keyword2'],
          builtins: ['builtin1', 'builtin2'],
          // ...
        );
    }
  }
}
```

2. Добавьте тесты:
```dart
test('should detect mylanguage', () {
  final language = LanguageDetector.detectLanguage('test.mylang');
  expect(language, 'mylanguage');
});
```

### Интеграция с LSP (в разработке)

```dart
// Будущий API для LSP
final lspService = LSPService();

// Инициализация LSP сервера
await lspService.initialize(
  serverPath: '/path/to/language-server',
  rootPath: '/path/to/project',
);

// Автодополнение
final completions = await lspService.getCompletions(
  filePath: 'main.dart',
  position: Position(line: 10, character: 5),
);

// Go to definition
final definition = await lspService.getDefinition(
  filePath: 'main.dart',
  position: Position(line: 10, character: 5),
);
```

## 🔍 Примеры использования

### Интеграция с UI

```dart
class EditorPage extends StatelessWidget {
  final EditorManagerService editorManager;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EditorState>(
      stream: editorManager.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        
        return Column(
          children: [
            // Вкладки открытых файлов
            TabBar(
              tabs: state.openFiles.map((file) => 
                Tab(text: basename(file))
              ).toList(),
            ),
            // Редактор
            Expanded(
              child: CodeEditor(
                content: state.activeFileContent,
                language: LanguageDetector.detectLanguage(
                  state.activeFile,
                ),
                onChanged: (content) {
                  editorManager.updateContent(
                    state.activeFile,
                    content,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

## 🐛 Известные проблемы

- LSP интеграция находится в разработке
- Автосохранение может конфликтовать с внешними изменениями файлов
- Большие файлы (>10MB) могут вызывать проблемы с производительностью

## 🗺️ Roadmap

### v1.1 (Q1 2026)
- [x] Базовое управление редактором
- [x] Синхронизация файлов
- [ ] LSP клиент
- [ ] Автодополнение кода

### v1.2 (Q2 2026)
- [ ] Go to definition
- [ ] Find references
- [ ] Rename refactoring
- [ ] Code formatting

### v2.0 (Q3-Q4 2026)
- [ ] Multi-cursor editing
- [ ] Snippets
- [ ] Code folding
- [ ] Minimap

## 📄 Лицензия

MIT License - см. [`../../LICENSE`](../../LICENSE)
