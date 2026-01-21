# CodeLab UIKit

Библиотека переиспользуемых UI компонентов для CodeLab IDE, построенная на основе Fluent UI. Предоставляет готовые виджеты для создания современного интерфейса IDE.

**Версия**: 1.0.0  
**Дата обновления**: 21 января 2026

## 🎯 Возможности

### ✅ Реализованные компоненты

**Основной layout:**
- `IDELayout` - Главный layout IDE с панелями
- `MainHeader` - Верхняя панель навигации
- `SidebarNavigation` - Боковая панель навигации
- `StatusBar` - Нижняя строка состояния

**Панели:**
- `ExplorerPanel` - Панель проводника файлов
- `SidebarPanel` - Базовая боковая панель
- `MainPanelArea` - Основная рабочая область
- `RunAndDebugPanel` - Панель запуска и отладки
  - `HeaderSection` - Заголовок с кнопками управления
  - `VariablesSection` - Просмотр переменных
  - `CallStackSection` - Стек вызовов
  - `BreakpointsSection` - Точки останова
  - `WatchSection` - Отслеживаемые выражения

**Редактор:**
- `EditorTabView` - Вкладки редактора
- Поддержка множественных вкладок
- Закрытие вкладок

**AI Assistant UI:**
- `AIAssistantUI` - Полный интерфейс AI ассистента
- `AIAssistantHeader` - Заголовок с индикатором агента
- `AIAssistantMessageList` - Список сообщений
- `AIAssistantMessageBubble` - Пузырь сообщения
- `AIAssistantInputBar` - Поле ввода сообщений
- `AgentIndicator` - Индикатор текущего агента
- `AgentSelector` - Выбор агента

**Диалоги:**
- `ToolApprovalDialog` - Диалог подтверждения операций

**Splitters:**
- `HorizontalSplitter` - Горизонтальный разделитель
- `VerticalSplitter` - Вертикальный разделитель

**Placeholder виджеты:**
- `SidebarPlaceholder` - Заглушка для боковой панели
- `StartWizard` - Мастер начала работы

## 🏗️ Архитектура

```
lib/
├── models/
│   ├── agent_info.dart         # Информация об агентах
│   ├── editor_tab.dart         # Модель вкладки редактора
│   └── file_node.dart          # Узел файлового дерева
├── widgets/
│   ├── layout/
│   │   └── ide_layout.dart     # Главный layout
│   ├── navigation/
│   │   ├── main_header.dart    # Верхняя панель
│   │   └── sidebar_navigation.dart
│   ├── panels/
│   │   ├── explorer_panel.dart
│   │   ├── sidebar_panel.dart
│   │   ├── main_panel_area.dart
│   │   └── run_and_debug/      # Компоненты отладки
│   ├── editor/
│   │   └── editor_tab_view.dart
│   ├── ai_assistant_ui/
│   │   ├── ai_assistant_ui.dart
│   │   ├── ai_assistant_header.dart
│   │   ├── ai_assistant_message_list.dart
│   │   ├── ai_assistant_message_bubble.dart
│   │   ├── ai_assistant_input_bar.dart
│   │   ├── agent_indicator.dart
│   │   └── agent_selector.dart
│   ├── dialogs/
│   │   └── tool_approval_dialog.dart
│   ├── splitters/
│   │   ├── horizontal_splitter.dart
│   │   └── vertical_splitter.dart
│   ├── status/
│   │   └── status_bar.dart
│   └── placeholder/
│       ├── sidebar_placeholder.dart
│       └── start_wizard.dart
└── codelab_uikit.dart          # Публичный API
```

## 📦 Зависимости

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI Framework
  fluent_ui: ^4.13.0
  
  # Icons
  cupertino_icons: ^1.0.8
```

## 🚀 Использование

### IDELayout

```dart
import 'package:codelab_uikit/codelab_uikit.dart';

class MyIDEPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IDELayout(
      header: MainHeader(
        title: 'CodeLab IDE',
        onMenuPressed: () {},
      ),
      sidebar: SidebarNavigation(
        selectedIndex: 0,
        onItemSelected: (index) {},
      ),
      mainPanel: MainPanelArea(
        child: EditorTabView(
          tabs: [
            EditorTab(id: '1', title: 'main.dart', content: 'code'),
          ],
          onTabClose: (id) {},
        ),
      ),
      bottomPanel: StatusBar(
        leftItems: [Text('Ready')],
        rightItems: [Text('Ln 1, Col 1')],
      ),
    );
  }
}
```

### AI Assistant UI

```dart
import 'package:codelab_uikit/codelab_uikit.dart';

class ChatPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AIAssistantUI(
      messages: [
        Message(
          id: '1',
          role: MessageRole.user,
          content: 'Привет!',
        ),
        Message(
          id: '2',
          role: MessageRole.assistant,
          content: 'Здравствуйте! Чем могу помочь?',
          agentType: AgentType.orchestrator,
        ),
      ],
      currentAgent: AgentType.orchestrator,
      onSendMessage: (text) {
        print('Отправка: $text');
      },
      onAgentSelected: (agent) {
        print('Выбран агент: $agent');
      },
      onClear: () {
        print('Очистка чата');
      },
    );
  }
}
```

### Agent Indicator

```dart
import 'package:codelab_uikit/codelab_uikit.dart';

// Простой индикатор
AgentIndicator(
  currentAgent: AgentType.coder,
)

// С возможностью клика
AgentIndicator(
  currentAgent: AgentType.coder,
  onTap: () {
    // Показать меню выбора агента
  },
)
```

### Agent Selector

```dart
import 'package:codelab_uikit/codelab_uikit.dart';

AgentSelector(
  currentAgent: AgentType.orchestrator,
  onAgentSelected: (agent) {
    print('Выбран: ${agent.displayName}');
  },
)
```

### Tool Approval Dialog

```dart
import 'package:codelab_uikit/codelab_uikit.dart';

showDialog(
  context: context,
  builder: (context) => ToolApprovalDialog(
    toolName: 'write_file',
    arguments: {
      'path': 'main.dart',
      'content': 'void main() {}',
    },
    onApprove: () {
      Navigator.pop(context);
      // Выполнить операцию
    },
    onReject: () {
      Navigator.pop(context);
      // Отменить операцию
    },
  ),
);
```

### Splitters

```dart
import 'package:codelab_uikit/codelab_uikit.dart';

// Горизонтальный разделитель
HorizontalSplitter(
  left: ExplorerPanel(),
  right: EditorPanel(),
  initialLeftWidth: 250,
)

// Вертикальный разделитель
VerticalSplitter(
  top: EditorPanel(),
  bottom: TerminalPanel(),
  initialTopHeight: 400,
)
```

## 🎨 Темы и стили

### Использование Fluent UI тем

```dart
import 'package:fluent_ui/fluent_ui.dart';

FluentApp(
  theme: FluentThemeData(
    brightness: Brightness.light,
    accentColor: Colors.blue,
  ),
  darkTheme: FluentThemeData(
    brightness: Brightness.dark,
    accentColor: Colors.blue,
  ),
  home: MyIDEPage(),
)
```

### Цвета агентов

```dart
// Каждый агент имеет свой цвет
AgentType.orchestrator.color  // Красный
AgentType.coder.color         // Синий
AgentType.architect.color     // Зеленый
AgentType.debug.color         // Оранжевый
AgentType.ask.color           // Фиолетовый
```

## 🧪 Тестирование

```bash
# Запустить все тесты
flutter test

# Запустить пример приложения
cd example
flutter run
```

## 📱 Пример приложения

В директории `example/` находится полнофункциональное демо-приложение, демонстрирующее все компоненты UIKit.

```bash
cd example
flutter run -d macos  # или windows, linux
```

## 🛠️ Разработка

### Добавление нового компонента

1. Создайте файл в соответствующей директории `lib/widgets/`:
```dart
class MyNewWidget extends StatelessWidget {
  final String title;
  
  const MyNewWidget({
    super.key,
    required this.title,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(title),
    );
  }
}
```

2. Экспортируйте в `lib/codelab_uikit.dart`:
```dart
export 'widgets/my_category/my_new_widget.dart';
```

### Стандарты кодирования

- Используйте `const` конструкторы где возможно
- Следуйте Fluent UI design guidelines
- Все виджеты должны быть responsive
- Поддержка темной и светлой темы обязательна

## 📚 Компоненты

### AgentType enum

```dart
enum AgentType {
  orchestrator,  // 🎭 Координатор
  coder,         // 💻 Программист
  architect,     // 🏗️ Архитектор
  debug,         // 🐛 Отладчик
  ask,           // 💬 Консультант
}
```

Каждый тип имеет:
- `displayName` - Отображаемое имя
- `icon` - Эмодзи иконка
- `color` - Цвет для UI

### EditorTab model

```dart
class EditorTab {
  final String id;
  final String title;
  final String? content;
  final bool isModified;
  final String? filePath;
}
```

### FileNode model

```dart
class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;
}
```

## 🗺️ Roadmap

### v1.1 (Q1 2026)
- [ ] Дополнительные темы оформления
- [ ] Анимации переходов
- [ ] Accessibility улучшения

### v1.2 (Q2 2026)
- [ ] Кастомизируемые панели
- [ ] Drag & drop для вкладок
- [ ] Расширенные диалоги

## 📄 Лицензия

MIT License - см. [`../../LICENSE`](../../LICENSE)
