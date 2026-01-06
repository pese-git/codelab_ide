# Руководство по реализации рефакторинга UI

## Обзор

Этот документ описывает реализованную новую архитектуру UI слоя модуля `codelab_ai_assistant` с применением современных подходов и паттернов проектирования.

## Что было реализовано

### ✅ Этап 1: Система тем и базовые компоненты

#### 1. Централизованная система тем

**Файлы:**
- [`app_colors.dart`](lib/features/shared/presentation/theme/app_colors.dart) - Цветовая палитра
- [`app_typography.dart`](lib/features/shared/presentation/theme/app_typography.dart) - Типографика
- [`app_spacing.dart`](lib/features/shared/presentation/theme/app_spacing.dart) - Отступы и размеры
- [`app_theme.dart`](lib/features/shared/presentation/theme/app_theme.dart) - Главный файл темы

**Преимущества:**
- ✅ Нет хардкода цветов и размеров
- ✅ Консистентный дизайн во всем приложении
- ✅ Легко изменить тему глобально
- ✅ Типобезопасный доступ к стилям

**Пример использования:**
```dart
import 'package:codelab_ai_assistant/features/shared/presentation/theme/app_theme.dart';

// Цвета
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
  ),
);

// Отступы
Padding(
  padding: AppSpacing.paddingLg,
  child: Column(
    children: [
      Text('Item 1'),
      AppSpacing.gapVerticalMd,
      Text('Item 2'),
    ],
  ),
);

// Цвета агентов
Container(
  color: AppColors.getAgentColor('orchestrator'),
);
```

#### 2. Утилиты и форматтеры

**Файлы:**
- [`date_formatter.dart`](lib/features/shared/utils/formatters/date_formatter.dart) - Форматирование дат
- [`agent_formatter.dart`](lib/features/shared/utils/formatters/agent_formatter.dart) - Форматирование агентов
- [`context_extensions.dart`](lib/features/shared/utils/extensions/context_extensions.dart) - Расширения для BuildContext

**Пример использования:**
```dart
// Форматирование дат
final dateStr = DateFormatter.formatRelative(DateTime.now()); // "Just now"
final shortDate = DateFormatter.formatShort(DateTime.now()); // "05/01/2026"

// Форматирование агентов
final agentName = AgentFormatter.formatAgentName('orchestrator'); // "🪃 Orchestrator"
final emoji = AgentFormatter.getAgentEmoji('coder'); // "💻"

// Расширения контекста
context.showSuccess('Operation completed!');
context.showError('Something went wrong');
final confirmed = await context.showConfirmDialog(
  title: 'Delete item?',
  content: 'This action cannot be undone',
);
```

#### 3. Базовые атомы (Atoms)

**Файлы:**
- [`primary_button.dart`](lib/features/shared/presentation/atoms/buttons/primary_button.dart) - Основная кнопка

**Пример использования:**
```dart
PrimaryButton(
  onPressed: () => print('Clicked'),
  child: const Text('Submit'),
  isLoading: false,
  size: ButtonSize.medium,
);
```

#### 4. Молекулы (Molecules)

**Файлы:**
- [`text_input_field.dart`](lib/features/shared/presentation/molecules/inputs/text_input_field.dart) - Поле ввода текста
- [`password_input_field.dart`](lib/features/shared/presentation/molecules/inputs/password_input_field.dart) - Поле ввода пароля
- [`base_card.dart`](lib/features/shared/presentation/molecules/cards/base_card.dart) - Базовая карточка
- [`empty_state.dart`](lib/features/shared/presentation/molecules/feedback/empty_state.dart) - Пустое состояние

**Пример использования:**
```dart
// Поле ввода
TextInputField(
  controller: _controller,
  label: 'Username',
  placeholder: 'Enter your username',
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
  onSubmitted: (value) => _handleSubmit(),
);

// Поле пароля
PasswordInputField(
  controller: _passwordController,
  label: 'Password',
  placeholder: 'Enter password',
);

// Карточка
BaseCard(
  selected: isSelected,
  onPressed: () => _handleTap(),
  child: Text('Card content'),
);

// Пустое состояние
EmptyState(
  icon: FluentIcons.chat,
  title: 'No messages yet',
  description: 'Start a conversation with AI',
  action: PrimaryButton(
    onPressed: () => _startChat(),
    child: const Text('Start Chat'),
  ),
);
```

## Структура проекта

```
lib/features/
├── shared/                          # ✅ Реализовано
│   ├── presentation/
│   │   ├── theme/                   # ✅ Система тем
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_spacing.dart
│   │   │   └── app_theme.dart
│   │   ├── atoms/                   # ✅ Базовые компоненты
│   │   │   └── buttons/
│   │   │       └── primary_button.dart
│   │   └── molecules/               # ✅ Составные компоненты
│   │       ├── inputs/
│   │       │   ├── text_input_field.dart
│   │       │   └── password_input_field.dart
│   │       ├── cards/
│   │       │   └── base_card.dart
│   │       └── feedback/
│   │           └── empty_state.dart
│   └── utils/                       # ✅ Утилиты
│       ├── formatters/
│       │   ├── date_formatter.dart
│       │   └── agent_formatter.dart
│       └── extensions/
│           └── context_extensions.dart
│
├── authentication/                  # ⏳ Следующий этап
│   └── presentation/
│       └── widgets/
│           └── login_form.dart      # Требует рефакторинга
│
├── agent_chat/                      # ⏳ Следующий этап
│   └── presentation/
│       └── widgets/
│           ├── chat_view.dart       # Требует рефакторинга
│           └── ai_assistant_panel.dart
│
├── session_management/              # ⏳ Следующий этап
│   └── presentation/
│       └── widgets/
│           └── session_list_view.dart  # Требует рефакторинга
│
└── tool_execution/                  # ⏳ Следующий этап
    └── presentation/
        └── widgets/
            └── tool_approval_dialog.dart  # Требует рефакторинга
```

## Следующие шаги

### Этап 2: Рефакторинг authentication

**Задачи:**
1. Создать `AuthUIModel` для UI состояния
2. Разбить `LoginForm` на компоненты:
   ```dart
   // Вместо монолитного LoginForm (188 строк)
   LoginPage(
     child: AuthTemplate(
       header: AuthHeader(title: 'Авторизация'),
       content: LoginFormContent(
         usernameField: TextInputField(...),
         passwordField: PasswordInputField(...),
         submitButton: PrimaryButton(...),
       ),
     ),
   );
   ```

**Преимущества:**
- Каждый компонент < 50 строк
- Легко тестировать
- Переиспользуемые поля ввода

### Этап 3: Рефакторинг agent_chat

**Задачи:**
1. Создать UI модели:
   ```dart
   @freezed
   class MessageUIModel with _$MessageUIModel {
     const factory MessageUIModel({
       required String id,
       required String content,
       required MessageType type,
       required Color backgroundColor,
       required Color borderColor,
       required String? senderName,
     }) = _MessageUIModel;
   }
   ```

2. Разбить `ChatView` (417 строк) на компоненты:
   - `ChatHeader` - заголовок с кнопкой назад и селектором агента
   - `MessageList` - список сообщений
   - `MessageBubble` - отдельное сообщение
   - `ChatInputBar` - поле ввода с кнопкой отправки
   - `ToolApprovalCard` - карточка подтверждения инструмента

**Пример:**
```dart
ChatPage(
  child: ChatTemplate(
    header: ChatHeader(
      onBack: () => _goBack(),
      currentAgent: 'orchestrator',
      onAgentChanged: (agent) => _switchAgent(agent),
    ),
    messages: MessageList(
      messages: messages.map((m) => MessageBubble(message: m)).toList(),
    ),
    inputBar: ChatInputBar(
      controller: _controller,
      onSend: (text) => _sendMessage(text),
      enabled: !isLoading,
    ),
  ),
);
```

### Этап 4: Рефакторинг session_management

**Задачи:**
1. Создать `SessionUIModel`
2. Разбить `SessionListView` (440 строк) на:
   - `SessionHeader` - заголовок с кнопкой обновления
   - `SessionList` - список сессий
   - `SessionCard` - карточка сессии (использует `BaseCard`)
   - `SessionActions` - действия над сессией

### Этап 5: Рефакторинг tool_execution

**Задачи:**
1. Создать `ToolUIModel`
2. Разбить `ToolApprovalDialog` на:
   - `ToolInfoCard` - информация об инструменте
   - `ToolArgumentsView` - просмотр/редактирование аргументов
   - `ToolApprovalActions` - кнопки approve/reject

## Принципы разработки

### 1. Single Responsibility
Каждый компонент отвечает за одну задачу:
```dart
// ❌ Плохо - делает слишком много
class ChatView extends StatefulWidget {
  // 417 строк: UI + логика + форматирование + стилизация
}

// ✅ Хорошо - каждый компонент делает одно
class MessageBubble extends StatelessWidget {
  // 30 строк: только отображение сообщения
}

class ChatInputBar extends StatelessWidget {
  // 40 строк: только ввод текста
}
```

### 2. Composition over Inheritance
```dart
// ✅ Композиция компонентов
class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatHeader(...),
        Expanded(child: MessageList(...)),
        ChatInputBar(...),
      ],
    );
  }
}
```

### 3. Dependency Inversion
```dart
// ❌ Плохо - зависимость от конкретной реализации
class ChatView extends StatelessWidget {
  final AgentChatBloc bloc;
}

// ✅ Хорошо - зависимость от абстракции
class ChatView extends StatelessWidget {
  final void Function(String) onSendMessage;
  final List<MessageUIModel> messages;
  final bool isLoading;
}
```

### 4. Использование темы
```dart
// ❌ Плохо - хардкод
Container(
  color: Colors.blue.withOpacity(0.1),
  padding: const EdgeInsets.all(16),
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  ),
);

// ✅ Хорошо - использование темы
Container(
  color: AppColors.primary.withOpacity(0.1),
  padding: AppSpacing.paddingLg,
  child: Text(
    'Hello',
    style: AppTypography.labelMedium,
  ),
);
```

## Миграция существующего кода

### Шаг 1: Добавить импорт темы
```dart
import 'package:codelab_ai_assistant/features/shared/presentation/theme/app_theme.dart';
```

### Шаг 2: Заменить хардкод на тему
```dart
// Было
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
  ),
);

// Стало
Container(
  padding: AppSpacing.paddingLg,
  decoration: BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    borderRadius: AppSpacing.borderRadiusMd,
  ),
);
```

### Шаг 3: Использовать готовые компоненты
```dart
// Было
TextFormBox(
  controller: _controller,
  placeholder: 'Enter text',
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
);

// Стало
TextInputField(
  controller: _controller,
  placeholder: 'Enter text',
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
);
```

### Шаг 4: Использовать форматтеры
```dart
// Было
String _formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    // ... много кода
  } catch (e) {
    return isoDate;
  }
}

// Стало
final formatted = DateFormatter.formatIsoRelative(isoDate);
```

## Тестирование

### Unit тесты для форматтеров
```dart
test('DateFormatter formats relative dates correctly', () {
  final now = DateTime.now();
  final twoHoursAgo = now.subtract(Duration(hours: 2));
  
  expect(DateFormatter.formatRelative(twoHoursAgo), '2h ago');
});
```

### Widget тесты для компонентов
```dart
testWidgets('PrimaryButton shows loading indicator', (tester) async {
  await tester.pumpWidget(
    FluentApp(
      home: PrimaryButton(
        onPressed: () {},
        isLoading: true,
        child: const Text('Submit'),
      ),
    ),
  );
  
  expect(find.byType(ProgressRing), findsOneWidget);
  expect(find.text('Submit'), findsNothing);
});
```

## Метрики успеха

### Текущий прогресс
- [x] Система тем создана
- [x] Утилиты и форматтеры реализованы
- [x] Базовые атомы созданы
- [x] Основные молекулы реализованы
- [ ] Рефакторинг authentication (0%)
- [ ] Рефакторинг agent_chat (0%)
- [ ] Рефакторинг session_management (0%)
- [ ] Рефакторинг tool_execution (0%)

### Целевые метрики
- [ ] Средний размер виджета < 150 строк
- [ ] Покрытие тестами > 80%
- [ ] Переиспользование компонентов > 70%
- [ ] Нет хардкода цветов и размеров
- [ ] Все форматирование через утилиты

## Дополнительные ресурсы

- [План рефакторинга](UI_REFACTORING_PLAN.md) - Полный план с деталями
- [Atomic Design](https://bradfrost.com/blog/post/atomic-web-design/) - Методология
- [Flutter Best Practices](https://flutter.dev/docs/development/ui/layout) - Официальная документация

## Заключение

Реализованная архитектура предоставляет:
- ✅ **Переиспользуемые компоненты** - можно использовать в разных местах
- ✅ **Консистентный дизайн** - единая тема во всем приложении
- ✅ **Легкая поддержка** - понятная структура и маленькие файлы
- ✅ **Простое тестирование** - каждый компонент тестируется отдельно
- ✅ **Масштабируемость** - легко добавлять новые features

Следующий шаг - начать рефакторинг существующих виджетов, начиная с `LoginForm` как самого простого примера.
