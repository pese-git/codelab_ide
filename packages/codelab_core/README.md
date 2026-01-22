# CodeLab Core

Основной пакет CodeLab IDE, предоставляющий базовые сервисы, модели данных и утилиты для работы с файловой системой, проектами и выполнением команд.

**Версия**: 1.0.0  
**Дата обновления**: 21 января 2026

## 🎯 Возможности

### ✅ Реализованные функции

**Файловая система:**
- Чтение и запись файлов
- Навигация по дереву файлов
- Рекурсивное сканирование директорий
- Фильтрация системных и скрытых файлов
- Определение типов файлов по расширению

**Управление проектами:**
- Загрузка проектов из директории
- Конфигурация проекта
- Контекст проекта (текущий файл, рабочая директория)
- Валидация путей

**Выполнение команд:**
- Запуск команд в терминале
- Определение интерпретатора по типу файла
- Поддержка различных языков программирования
- Обработка вывода команд

**Модели данных:**
- `FileNode` - Узел дерева файлов
- `ProjectConfig` - Конфигурация проекта
- `AppError` - Типизированные ошибки
- `ProjectContext` - Контекст выполнения

## 🏗️ Архитектура

```
lib/
├── src/
│   ├── services/
│   │   ├── file_service.dart       # Работа с файловой системой
│   │   ├── project_service.dart    # Управление проектами
│   │   └── run_service.dart        # Выполнение команд
│   ├── models/
│   │   ├── file_node.dart          # Модель узла файлового дерева
│   │   └── project_config.dart     # Конфигурация проекта
│   ├── errors/
│   │   ├── app_error.dart          # Базовые ошибки приложения
│   │   └── file_error.dart         # Ошибки файловой системы
│   └── utils/
│       ├── logger.dart             # Логирование
│       ├── project_context.dart    # Контекст проекта
│       └── path_validator.dart     # Валидация путей
└── codelab_core.dart               # Публичный API
```

## 📦 Зависимости

```yaml
dependencies:
  # Файловая система
  file: ^7.0.1
  path: ^1.9.1
  
  # Выполнение команд
  process_run: ^1.2.4
  
  # Функциональное программирование
  fpdart: ^1.2.0
  
  # Логирование
  logger: ^2.6.2
```

## 🚀 Использование

### FileService

```dart
import 'package:codelab_core/codelab_core.dart';

final fileService = FileService();

// Чтение файла
final content = await fileService.readFile('/path/to/file.dart');

// Запись файла
await fileService.writeFile('/path/to/file.dart', 'content');

// Загрузка дерева файлов
final fileTree = await fileService.loadFileTree('/path/to/project');

// Список файлов в директории
final files = await fileService.listFiles('/path/to/directory');
```

### ProjectService

```dart
import 'package:codelab_core/codelab_core.dart';

final projectService = ProjectService();

// Загрузка проекта
final project = await projectService.loadProject('/path/to/project');

// Получение конфигурации
final config = projectService.getProjectConfig(projectPath);

// Валидация проекта
final isValid = await projectService.validateProject(projectPath);
```

### RunService

```dart
import 'package:codelab_core/codelab_core.dart';

final runService = RunService();

// Выполнение файла
final result = await runService.runFile('/path/to/script.py');

// Выполнение команды
final output = await runService.executeCommand(
  'flutter test',
  workingDirectory: '/path/to/project',
);

// Определение интерпретатора
final interpreter = runService.getInterpreter('script.py');
// Вернет: 'python'
```

### FileNode

```dart
import 'package:codelab_core/codelab_core.dart';

// Создание узла файла
final fileNode = FileNode(
  name: 'main.dart',
  path: '/project/lib/main.dart',
  isDirectory: false,
  children: [],
);

// Создание узла директории
final dirNode = FileNode(
  name: 'lib',
  path: '/project/lib',
  isDirectory: true,
  children: [fileNode],
);

// Проверка типа
if (fileNode.isFile) {
  print('Это файл');
}

// Получение расширения
final extension = fileNode.extension; // '.dart'
```

### Обработка ошибок

```dart
import 'package:codelab_core/codelab_core.dart';
import 'package:fpdart/fpdart.dart';

// Использование Either для обработки ошибок
final result = await fileService.readFile('/path/to/file.dart');

result.fold(
  (error) => print('Ошибка: ${error.message}'),
  (content) => print('Содержимое: $content'),
);

// Использование TaskEither для асинхронных операций
final task = TaskEither<AppError, String>.tryCatch(
  () => fileService.readFile('/path/to/file.dart'),
  (error, stackTrace) => FileError(
    message: 'Не удалось прочитать файл',
    path: '/path/to/file.dart',
  ),
);

final result = await task.run();
```

## 🔧 Поддерживаемые языки

RunService поддерживает автоматическое определение интерпретатора для:

- **Dart** (`.dart`) → `dart`
- **Python** (`.py`) → `python` / `python3`
- **JavaScript** (`.js`) → `node`
- **TypeScript** (`.ts`) → `ts-node`
- **Java** (`.java`) → `java`
- **C/C++** (`.c`, `.cpp`) → `gcc` / `g++`
- **Go** (`.go`) → `go run`
- **Rust** (`.rs`) → `rustc`
- **Ruby** (`.rb`) → `ruby`
- **PHP** (`.php`) → `php`
- **Shell** (`.sh`) → `bash`

## 🧪 Тестирование

```bash
# Запустить все тесты
flutter test

# Запустить конкретный тест
flutter test test/services/file_service_test.dart

# Запустить с coverage
flutter test --coverage
```

## 📚 API Reference

### FileService

| Метод | Описание | Возвращает |
|-------|----------|------------|
| `readFile(String path)` | Читает содержимое файла | `Future<Either<FileError, String>>` |
| `writeFile(String path, String content)` | Записывает содержимое в файл | `Future<Either<FileError, void>>` |
| `loadFileTree(String path)` | Загружает дерево файлов | `Future<Either<FileError, FileNode>>` |
| `listFiles(String path)` | Список файлов в директории | `Future<Either<FileError, List<FileNode>>>` |
| `deleteFile(String path)` | Удаляет файл | `Future<Either<FileError, void>>` |
| `createDirectory(String path)` | Создает директорию | `Future<Either<FileError, void>>` |

### ProjectService

| Метод | Описание | Возвращает |
|-------|----------|------------|
| `loadProject(String path)` | Загружает проект | `Future<Either<AppError, Project>>` |
| `getProjectConfig(String path)` | Получает конфигурацию | `ProjectConfig` |
| `validateProject(String path)` | Валидирует проект | `Future<bool>` |
| `saveProjectConfig(ProjectConfig config)` | Сохраняет конфигурацию | `Future<Either<AppError, void>>` |

### RunService

| Метод | Описание | Возвращает |
|-------|----------|------------|
| `runFile(String path)` | Выполняет файл | `Future<Either<AppError, String>>` |
| `executeCommand(String command, {String? workingDirectory})` | Выполняет команду | `Future<Either<AppError, String>>` |
| `getInterpreter(String filePath)` | Определяет интерпретатор | `String?` |

## 🛠️ Разработка

### Добавление нового сервиса

1. Создайте файл в `lib/src/services/`:
```dart
class MyNewService {
  Future<Either<AppError, Result>> doSomething() async {
    try {
      // Реализация
      return right(result);
    } catch (e) {
      return left(AppError(message: e.toString()));
    }
  }
}
```

2. Экспортируйте в `lib/codelab_core.dart`:
```dart
export 'src/services/my_new_service.dart';
```

### Добавление новой модели

1. Создайте файл в `lib/src/models/`:
```dart
class MyModel {
  final String id;
  final String name;
  
  MyModel({required this.id, required this.name});
}
```

2. Экспортируйте в `lib/codelab_core.dart`

## 🗺️ Roadmap

### v1.1 (Q1 2026)
- [ ] Поддержка file watchers
- [ ] Кэширование файлового дерева
- [ ] Асинхронное сканирование больших проектов

### v1.2 (Q2 2026)
- [ ] Поддержка виртуальных файловых систем
- [ ] Расширенная валидация проектов
- [ ] Метрики производительности

## 📄 Лицензия

MIT License - см. [`../../LICENSE`](../../LICENSE)
