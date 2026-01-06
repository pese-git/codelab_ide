# План рефакторинга UI слоя codelab_ai_assistant

## Анализ текущего состояния

### Проблемы текущей архитектуры:

1. **Монолитные виджеты**: 
   - `ChatView` (417 строк)
   - `SessionListView` (440 строк)
   - `LoginForm` (188 строк)
   - Слишком большие, сложные для поддержки
2. **Дублирование кода**: 
   - Повторяющаяся логика стилизации (цвета, отступы)
   - Дублирование форматирования (даты, агенты)
   - Повторяющиеся паттерны валидации форм
3. **Жесткая связанность**: 
   - Прямые зависимости между виджетами и блоками
   - Сложно переиспользовать компоненты
4. **Отсутствие переиспользуемых компонентов**: 
   - Каждый виджет создает свои UI элементы
   - Нет общих кнопок, полей ввода, карточек
5. **Смешение ответственности**: 
   - Бизнес-логика и UI логика в одном месте
   - Форматирование данных в виджетах
6. **Отсутствие тематизации**: 
   - Хардкод цветов (`Colors.blue.withOpacity(0.1)`)
   - Хардкод размеров и отступов
   - Нет централизованной системы стилей
7. **Сложное тестирование**: 
   - Большие виджеты сложно тестировать
   - Много зависимостей в одном месте

### Преимущества текущей архитектуры:

1. ✅ Clean Architecture на уровне domain/data
2. ✅ BLoC паттерн для управления состоянием
3. ✅ Freezed для immutable моделей
4. ✅ Разделение на features

## Современные подходы для рефакторинга

### 1. Atomic Design Pattern
Разделение UI на уровни:
- **Atoms** (атомы): Базовые UI элементы (кнопки, иконки, текст)
- **Molecules** (молекулы): Комбинации атомов (карточка сообщения, поле ввода)
- **Organisms** (организмы): Сложные компоненты (список сообщений, панель инструментов)
- **Templates** (шаблоны): Макеты страниц
- **Pages** (страницы): Конкретные экраны

### 2. Composition over Inheritance
- Использование композиции виджетов вместо наследования
- Builder паттерн для гибкого создания UI
- Dependency Injection для слабой связанности

### 3. Theme System
- Централизованная система тем
- Типобезопасные цвета и стили
- Поддержка светлой/темной темы

### 4. Presentation Models
- Отделение UI логики от виджетов
- ViewModel для каждого экрана
- Маппинг domain entities в UI models

### 5. Responsive Design
- Адаптивные компоненты
- Breakpoints для разных размеров экрана

## Новая структура

```
lib/features/
├── shared/                          # Общие UI компоненты
│   ├── presentation/
│   │   ├── theme/                   # Система тем
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── app_spacing.dart
│   │   ├── atoms/                   # Базовые компоненты
│   │   │   ├── buttons/
│   │   │   │   ├── primary_button.dart
│   │   │   │   ├── secondary_button.dart
│   │   │   │   └── icon_button_widget.dart
│   │   │   ├── text/
│   │   │   │   ├── heading_text.dart
│   │   │   │   ├── body_text.dart
│   │   │   │   └── caption_text.dart
│   │   │   ├── icons/
│   │   │   │   └── app_icon.dart
│   │   │   └── indicators/
│   │   │       ├── loading_indicator.dart
│   │   │       └── status_badge.dart
│   │   ├── molecules/               # Составные компоненты
│   │   │   ├── cards/
│   │   │   │   ├── base_card.dart
│   │   │   │   └── info_card.dart
│   │   │   ├── inputs/
│   │   │   │   ├── text_input_field.dart
│   │   │   │   ├── password_input_field.dart
│   │   │   │   └── search_field.dart
│   │   │   └── feedback/
│   │   │       ├── error_message.dart
│   │   │       ├── success_message.dart
│   │   │       └── empty_state.dart
│   │   └── organisms/               # Сложные компоненты
│   │       ├── headers/
│   │       │   └── app_header.dart
│   │       └── lists/
│   │           └── scrollable_list.dart
│   └── utils/
│       ├── formatters/
│       │   ├── date_formatter.dart
│       │   └── text_formatter.dart
│       ├── validators/
│       │   ├── email_validator.dart
│       │   └── password_validator.dart
│       └── extensions/
│           ├── context_extensions.dart
│           └── color_extensions.dart
│
├── authentication/
│   └── presentation/
│       ├── models/
│       │   └── auth_ui_model.dart
│       ├── widgets/
│       │   ├── atoms/
│       │   │   ├── password_visibility_toggle.dart
│       │   │   └── auth_error_badge.dart
│       │   ├── molecules/
│       │   │   ├── username_field.dart
│       │   │   ├── password_field.dart
│       │   │   └── login_button.dart
│       │   ├── organisms/
│       │   │   ├── login_form_content.dart
│       │   │   └── auth_header.dart
│       │   └── templates/
│       │       └── auth_template.dart
│       └── pages/
│           └── login_page.dart
│
├── agent_chat/
│   └── presentation/
│       ├── models/                  # UI модели
│       │   ├── chat_ui_state.dart
│       │   └── message_ui_model.dart
│       ├── widgets/
│       │   ├── atoms/
│       │   │   ├── agent_avatar.dart
│       │   │   └── message_status_icon.dart
│       │   ├── molecules/
│       │   │   ├── message_bubble.dart
│       │   │   ├── message_input.dart
│       │   │   ├── agent_selector.dart
│       │   │   └── tool_approval_card.dart
│       │   ├── organisms/
│       │   │   ├── chat_header.dart
│       │   │   ├── message_list.dart
│       │   │   └── chat_input_bar.dart
│       │   └── templates/
│       │       └── chat_template.dart
│       └── pages/
│           └── chat_page.dart
│
├── session_management/
│   └── presentation/
│       ├── models/
│       │   └── session_ui_model.dart
│       ├── widgets/
│       │   ├── molecules/
│       │   │   ├── session_card.dart
│       │   │   └── session_actions.dart
│       │   ├── organisms/
│       │   │   ├── session_list.dart
│       │   │   └── session_header.dart
│       │   └── templates/
│       │       └── session_list_template.dart
│       └── pages/
│           └── session_list_page.dart
│
└── tool_execution/
    └── presentation/
        ├── models/
        │   └── tool_ui_model.dart
        └── widgets/
            ├── molecules/
            │   ├── tool_info_card.dart
            │   └── tool_arguments_view.dart
            └── organisms/
                └── tool_approval_panel.dart
```

## Этапы реализации

### Этап 1: Создание системы тем и базовых компонентов
1. Создать `AppTheme` с цветами, типографикой, отступами
2. Реализовать atoms: кнопки, текст, иконки, индикаторы
3. Создать утилиты и расширения (форматтеры, валидаторы)

### Этап 2: Создание переиспользуемых molecules
1. Карточки (BaseCard, InfoCard)
2. Поля ввода (TextInputField, PasswordInputField, SearchField)
3. Feedback компоненты (ErrorMessage, EmptyState)

### Этап 3: Рефакторинг authentication
1. Создать AuthUIModel
2. Разбить LoginForm на атомы/молекулы/организмы:
   - UsernameField, PasswordField (molecules)
   - LoginFormContent (organism)
   - AuthTemplate (template)
3. Создать переиспользуемые компоненты валидации

### Этап 4: Рефакторинг agent_chat
1. Создать UI модели (MessageUIModel)
2. Разбить ChatView на атомы/молекулы/организмы
3. Создать ChatTemplate и ChatPage

### Этап 5: Рефакторинг session_management
1. Создать SessionUIModel
2. Разбить SessionListView на компоненты
3. Создать SessionListTemplate и SessionListPage

### Этап 6: Рефакторинг tool_execution
1. Создать ToolUIModel
2. Разбить ToolApprovalDialog на компоненты
3. Создать ToolApprovalPanel

### Этап 7: Тестирование и документация
1. Unit тесты для UI моделей
2. Widget тесты для компонентов
3. Документация по использованию

## Ключевые принципы

### 1. Single Responsibility
Каждый виджет отвечает за одну задачу:
- `MessageBubble` - только отображение сообщения
- `ChatInputBar` - только ввод текста
- `MessageList` - только список сообщений
- `UsernameField` - только поле ввода имени пользователя

### 2. Dependency Inversion
Виджеты зависят от абстракций, а не от конкретных реализаций:
```dart
// Плохо
class ChatView extends StatelessWidget {
  final AgentChatBloc bloc;
}

// Хорошо
class ChatView extends StatelessWidget {
  final void Function(String) onSendMessage;
  final List<MessageUIModel> messages;
}
```

### 3. Composition
Сложные виджеты собираются из простых:
```dart
class ChatTemplate extends StatelessWidget {
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

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthTemplate(
      header: AuthHeader(...),
      content: LoginFormContent(
        usernameField: UsernameField(...),
        passwordField: PasswordField(...),
        loginButton: LoginButton(...),
      ),
    );
  }
}
```

### 4. Immutability
Все UI модели immutable с помощью Freezed:
```dart
@freezed
class MessageUIModel with _$MessageUIModel {
  const factory MessageUIModel({
    required String id,
    required String content,
    required MessageType type,
    required Color backgroundColor,
    required Color borderColor,
  }) = _MessageUIModel;
}

@freezed
class AuthUIModel with _$AuthUIModel {
  const factory AuthUIModel({
    required String username,
    required bool isLoading,
    required Option<String> error,
  }) = _AuthUIModel;
}
```

### 5. Testability
Каждый компонент легко тестируется:
```dart
testWidgets('MessageBubble displays text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MessageBubble(
        message: MessageUIModel(...),
      ),
    ),
  );
  expect(find.text('Hello'), findsOneWidget);
});

testWidgets('UsernameField validates empty input', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: UsernameField(
        controller: TextEditingController(),
      ),
    ),
  );
  // Test validation logic
});
```

## Примеры рефакторинга

### До: LoginForm (монолитный)
```dart
class LoginForm extends StatefulWidget {
  // 188 строк кода
  // Смешаны: UI, валидация, стилизация, бизнес-логика
}
```

### После: Композиция компонентов
```dart
// atoms/password_visibility_toggle.dart (15 строк)
class PasswordVisibilityToggle extends StatelessWidget {
  final bool obscureText;
  final VoidCallback onToggle;
}

// molecules/username_field.dart (30 строк)
class UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
}

// molecules/password_field.dart (35 строк)
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
}

// organisms/login_form_content.dart (50 строк)
class LoginFormContent extends StatelessWidget {
  final UsernameField usernameField;
  final PasswordField passwordField;
  final LoginButton loginButton;
}

// pages/login_page.dart (40 строк)
class LoginPage extends StatelessWidget {
  // Композиция всех компонентов
}
```

## Преимущества новой архитектуры

1. **Переиспользуемость**: Компоненты можно использовать в разных местах
   - `PasswordField` можно использовать в форме регистрации, смены пароля
   - `BaseCard` используется для сессий, сообщений, инструментов
2. **Тестируемость**: Маленькие компоненты легко тестировать
   - Каждый компонент тестируется отдельно
   - Меньше mock объектов
3. **Поддерживаемость**: Легко найти и изменить нужный компонент
   - Понятная структура папок
   - Один файл = одна ответственность
4. **Масштабируемость**: Легко добавлять новые features
   - Новые компоненты не влияют на существующие
   - Можно переиспользовать shared компоненты
5. **Консистентность**: Единый стиль во всем приложении
   - Централизованная тема
   - Одинаковые отступы, цвета, шрифты
6. **Производительность**: Мелкие виджеты эффективнее перестраиваются
   - Меньше ненужных rebuild
   - Оптимизация на уровне компонентов
7. **Читаемость**: Понятная структура и назначение каждого файла
   - Atomic Design делает структуру предсказуемой
   - Легко ориентироваться новым разработчикам

## Миграция

### Обратная совместимость
Старые виджеты будут помечены как `@deprecated` и постепенно заменены:
```dart
@Deprecated('Use LoginPage instead. Will be removed in v2.0.0')
class LoginForm extends StatefulWidget {
  // ...
}

@Deprecated('Use ChatPage instead. Will be removed in v2.0.0')
class ChatView extends StatefulWidget {
  // ...
}
```

### Поэтапная миграция
1. Создать новые компоненты параллельно со старыми
2. Протестировать новые компоненты
3. Заменить старые на новые в точках входа
4. Удалить deprecated код после полной миграции

## Метрики успеха

- [ ] Средний размер виджета < 150 строк
- [ ] Покрытие тестами > 80%
- [ ] Переиспользование компонентов > 70%
- [ ] Время на добавление нового feature < 2 часов
- [ ] Количество дублирующегося кода < 5%
- [ ] Все цвета и стили из централизованной темы
- [ ] Нет хардкода размеров и отступов

## Дополнительные улучшения

### 1. Accessibility
- Поддержка screen readers
- Правильные семантические метки
- Keyboard navigation

### 2. Internationalization
- Вынести все тексты в локализацию
- Поддержка RTL языков

### 3. Animations
- Плавные переходы между экранами
- Анимации для feedback (loading, success, error)

### 4. Error Handling
- Централизованная обработка ошибок UI
- Graceful degradation
- Retry механизмы
