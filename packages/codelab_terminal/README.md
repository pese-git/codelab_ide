# CodeLab Terminal

Пакет интеграции терминала для CodeLab IDE. Предоставляет полнофункциональный эмулятор терминала с поддержкой PTY, выполнения команд и управления состоянием через BLoC.

**Версия**: 1.0.0  
**Дата обновления**: 21 января 2026

## 🎯 Возможности

### ✅ Реализованные функции

**Эмуляция терминала:**
- Полноценный эмулятор терминала на основе xterm
- Поддержка ANSI escape codes
- Цветной вывод
- Прокрутка истории
- Копирование/вставка

**PTY поддержка:**
- Псевдотерминал (PTY) для нативного выполнения команд
- Поддержка интерактивных программ
- Правильная обработка сигналов (Ctrl+C, Ctrl+D)
- Изменение размера терминала

**Управление состоянием:**
- BLoC pattern для управления терминалом
- Множественные терминальные сессии
- История команд
- Сохранение вывода

**Кроссплатформенность:**
- Windows (через flutter_pty)
- macOS (через flutter_pty)
- Linux (через flutter_pty)

## 🏗️ Архитектура

```
lib/
├── src/
│   ├── widgets/
│   │   ├── terminal_widget.dart    # Основной виджет терминала
│   │   └── terminal_bloc.dart      # BLoC для управления состоянием
│   └── codelab_terminal_base.dart  # Базовые классы
└── codelab_terminal.dart           # Публичный API
```

## 📦 Зависимости

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Эмуляция терминала
  xterm: ^4.0.0
  
  # PTY поддержка
  flutter_pty: ^0.4.2
  
  # State management
  flutter_bloc: ^9.1.1
  bloc: ^9.1.0
  
  # Цвета ANSI
  ansicolor: ^2.0.3
  
  # Логирование
  logger: ^2.6.2
```

## 🚀 Использование

### Базовое использование

```dart
import 'package:codelab_terminal/codelab_terminal.dart';

class TerminalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TerminalBloc(),
      child: TerminalWidget(),
    );
  }
}
```

### С кастомной конфигурацией

```dart
import 'package:codelab_terminal/codelab_terminal.dart';
import 'package:xterm/xterm.dart';

class CustomTerminalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TerminalBloc(
        initialDirectory: '/path/to/project',
        shell: '/bin/zsh',  // Кастомный shell
      ),
      child: TerminalWidget(
        theme: TerminalTheme(
          cursor: Color(0xFF00FF00),
          selection: Color(0xFF3366FF),
          foreground: Color(0xFFFFFFFF),
          background: Color(0xFF1E1E1E),
        ),
      ),
    );
  }
}
```

### Выполнение команд программно

```dart
import 'package:codelab_terminal/codelab_terminal.dart';

// Получить BLoC
final terminalBloc = context.read<TerminalBloc>();

// Выполнить команду
terminalBloc.add(TerminalEvent.executeCommand('ls -la'));

// Очистить терминал
terminalBloc.add(TerminalEvent.clear());

// Изменить рабочую директорию
terminalBloc.add(TerminalEvent.changeDirectory('/new/path'));
```

### Обработка событий терминала

```dart
BlocListener<TerminalBloc, TerminalState>(
  listener: (context, state) {
    state.when(
      idle: () => print('Терминал готов'),
      executing: (command) => print('Выполняется: $command'),
      completed: (exitCode) => print('Завершено с кодом: $exitCode'),
      error: (message) => print('Ошибка: $message'),
    );
  },
  child: TerminalWidget(),
)
```

## 🎨 Кастомизация

### Темы терминала

```dart
// Светлая тема
final lightTheme = TerminalTheme(
  cursor: Colors.black,
  selection: Colors.blue.withOpacity(0.3),
  foreground: Colors.black,
  background: Colors.white,
  black: Colors.black,
  red: Colors.red,
  green: Colors.green,
  yellow: Colors.yellow,
  blue: Colors.blue,
  magenta: Colors.purple,
  cyan: Colors.cyan,
  white: Colors.white,
);

// Темная тема (по умолчанию)
final darkTheme = TerminalTheme(
  cursor: Color(0xFF00FF00),
  selection: Color(0xFF3366FF),
  foreground: Color(0xFFFFFFFF),
  background: Color(0xFF1E1E1E),
  // ... остальные цвета
);
```

### Размер и шрифт

```dart
TerminalWidget(
  style: TerminalStyle(
    fontSize: 14.0,
    fontFamily: 'Courier New',
    lineHeight: 1.2,
  ),
)
```

## 🔧 Конфигурация

### Настройка PTY

```dart
TerminalBloc(
  ptyConfig: PtyConfig(
    executable: '/bin/bash',  // Shell для запуска
    arguments: ['-l'],         // Аргументы shell
    environment: {             // Переменные окружения
      'TERM': 'xterm-256color',
      'COLORTERM': 'truecolor',
    },
    workingDirectory: '/home/user',
  ),
)
```

### История команд

```dart
TerminalBloc(
  historySize: 1000,  // Количество строк истории
  saveHistory: true,  // Сохранять историю между сессиями
)
```

## 🧪 Тестирование

```bash
# Запустить все тесты
flutter test

# Запустить конкретный тест
flutter test test/terminal_bloc_test.dart

# Запустить с coverage
flutter test --coverage
```

## 📚 API Reference

### TerminalBloc

#### События

```dart
sealed class TerminalEvent {
  const factory TerminalEvent.executeCommand(String command) = ExecuteCommand;
  const factory TerminalEvent.clear() = ClearTerminal;
  const factory TerminalEvent.changeDirectory(String path) = ChangeDirectory;
  const factory TerminalEvent.resize(int cols, int rows) = ResizeTerminal;
  const factory TerminalEvent.sendInput(String input) = SendInput;
}
```

#### Состояния

```dart
sealed class TerminalState {
  const factory TerminalState.idle() = Idle;
  const factory TerminalState.executing(String command) = Executing;
  const factory TerminalState.completed(int exitCode) = Completed;
  const factory TerminalState.error(String message) = Error;
}
```

### TerminalWidget

| Параметр | Тип | Описание |
|----------|-----|----------|
| `theme` | `TerminalTheme?` | Тема оформления терминала |
| `style` | `TerminalStyle?` | Стиль шрифта и размеры |
| `readOnly` | `bool` | Только для чтения (по умолчанию false) |
| `autofocus` | `bool` | Автофокус при создании (по умолчанию true) |

## 🛠️ Разработка

### Добавление новой команды

```dart
class TerminalBloc extends Bloc<TerminalEvent, TerminalState> {
  void _onExecuteCommand(ExecuteCommand event, Emitter<TerminalState> emit) {
    final command = event.command;
    
    // Обработка специальных команд
    if (command == 'clear') {
      _terminal.clear();
      emit(const TerminalState.idle());
      return;
    }
    
    // Выполнение через PTY
    _pty.write(utf8.encode('$command\n'));
    emit(TerminalState.executing(command));
  }
}
```

### Обработка вывода PTY

```dart
_pty.output.listen((data) {
  // Декодировать данные
  final text = utf8.decode(data);
  
  // Записать в терминал
  _terminal.write(text);
  
  // Обновить состояние
  emit(const TerminalState.idle());
});
```

## 🔍 Примеры использования

### Интеграция с редактором

```dart
class IDEPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: CodeEditor(),
        ),
        Expanded(
          flex: 1,
          child: TerminalWidget(),
        ),
      ],
    );
  }
}
```

### Множественные терминалы

```dart
class MultiTerminalPage extends StatefulWidget {
  @override
  State<MultiTerminalPage> createState() => _MultiTerminalPageState();
}

class _MultiTerminalPageState extends State<MultiTerminalPage> {
  final List<TerminalBloc> _terminals = [];
  int _activeIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Вкладки терминалов
        Row(
          children: _terminals.asMap().entries.map((entry) {
            return Tab(
              text: 'Terminal ${entry.key + 1}',
              isActive: entry.key == _activeIndex,
              onTap: () => setState(() => _activeIndex = entry.key),
            );
          }).toList(),
        ),
        // Активный терминал
        Expanded(
          child: BlocProvider.value(
            value: _terminals[_activeIndex],
            child: TerminalWidget(),
          ),
        ),
      ],
    );
  }
}
```

## 🐛 Известные проблемы

- На Windows могут быть проблемы с некоторыми интерактивными программами
- Emoji могут отображаться некорректно в зависимости от шрифта
- Копирование/вставка работает только через контекстное меню

## 🗺️ Roadmap

### v1.1 (Q1 2026)
- [ ] Поддержка split терминалов
- [ ] Улучшенная обработка Unicode
- [ ] Горячие клавиши (Ctrl+C, Ctrl+V)

### v1.2 (Q2 2026)
- [ ] Поиск по выводу терминала
- [ ] Экспорт вывода в файл
- [ ] Профили терминалов

## 📄 Лицензия

MIT License - см. [`../../LICENSE`](../../LICENSE)
