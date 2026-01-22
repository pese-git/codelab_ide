# Руководство разработчика CodeLab IDE

Полное руководство по разработке, тестированию и внесению вклада в проект CodeLab IDE.

**Версия**: 1.0.0  
**Дата обновления**: 21 января 2026

## 📋 Содержание

- [Начало работы](#начало-работы)
- [Структура проекта](#структура-проекта)
- [Разработка](#разработка)
- [Тестирование](#тестирование)
- [Стандарты кодирования](#стандарты-кодирования)
- [Git workflow](#git-workflow)
- [Отладка](#отладка)

## Начало работы

### Предварительные требования

- **Flutter SDK**: 3.38.5 (через FVM)
- **Dart SDK**: 3.10.1+
- **Git**: последняя версия
- **IDE**: VS Code или Android Studio с Flutter плагинами
- **Melos**: для управления монорепозиторием

### Установка окружения

1. **Клонирование репозитория**:
```bash
git clone <repository-url>
cd codelab_ide
```

2. **Установка FVM**:
```bash
# macOS/Linux
dart pub global activate fvm

# Установка Flutter через FVM
fvm install
fvm use 3.38.5
```

3. **Установка Melos**:
```bash
dart pub global activate melos
```

4. **Инициализация проекта**:
```bash
# Установка всех зависимостей
melos bootstrap

# Генерация кода
melos generate
```

5. **Проверка установки**:
```bash
# Проверка Flutter
fvm flutter doctor

# Проверка Melos
melos --version

# Запуск тестов
melos test
```

## Структура проекта

### Монорепозиторий

```
codelab_ide/
├── apps/                    # Приложения
│   └── codelab_ide/        # Основное приложение
├── packages/               # Пакеты
│   ├── codelab_core/       # Основные сервисы
│   ├── codelab_engine/     # Движок редактора
│   ├── codelab_ai_assistant/  # AI интеграция
│   ├── codelab_terminal/   # Терминал
│   ├── codelab_uikit/      # UI компоненты
│   └── codelab_version_control/  # Git
├── doc/                    # Документация
├── melos.yaml             # Конфигурация Melos
└── pubspec.yaml           # Workspace конфигурация
```

### Структура пакета

Каждый пакет следует стандартной структуре:

```
package_name/
├── lib/
│   ├── src/               # Приватный код
│   │   ├── models/        # Модели данных
│   │   ├── services/      # Сервисы
│   │   └── widgets/       # Виджеты
│   └── package_name.dart  # Публичный API
├── test/                  # Тесты
├── pubspec.yaml          # Зависимости
├── README.md             # Документация
└── CHANGELOG.md          # История изменений
```

### Clean Architecture (для codelab_ai_assistant)

```
lib/
├── core/                  # Общие компоненты
│   ├── error/            # Обработка ошибок
│   ├── usecases/         # Базовые use cases
│   └── bloc/             # BLoC инфраструктура
└── features/             # Функциональные модули
    └── feature_name/
        ├── domain/       # Бизнес-логика
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        ├── data/         # Реализация данных
        │   ├── models/
        │   ├── repositories/
        │   └── datasources/
        └── presentation/ # UI
            ├── bloc/
            └── widgets/
```

## Разработка

### Команды Melos

```bash
# Запуск приложения
melos run:codelab_ide

# Запуск всех тестов
melos test

# Запуск тестов конкретного пакета
melos test --scope=codelab_core

# Генерация кода (freezed, json_serializable)
melos generate

# Анализ кода
melos analyze

# Форматирование кода
melos format

# Проверка устаревших зависимостей
melos outdated

# Очистка build артефактов
melos clean
```

### Создание нового пакета

1. **Создать директорию**:
```bash
mkdir -p packages/my_new_package/lib/src
cd packages/my_new_package
```

2. **Создать pubspec.yaml**:
```yaml
name: my_new_package
description: Description of the package
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.10.1 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # Добавить зависимости

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

3. **Добавить в workspace**:
```yaml
# В корневом pubspec.yaml
workspace:
  - apps/codelab_ide
  - packages/*
  - packages/my_new_package  # Добавить
```

4. **Инициализировать**:
```bash
cd ../..
melos bootstrap
```

### Добавление новой функции

#### 1. Создать feature в Clean Architecture

```bash
# Структура feature
mkdir -p lib/features/my_feature/{domain,data,presentation}/{entities,repositories,usecases,models,datasources,bloc,widgets}
```

#### 2. Создать entities

```dart
// lib/features/my_feature/domain/entities/my_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_entity.freezed.dart';

@freezed
class MyEntity with _$MyEntity {
  const factory MyEntity({
    required String id,
    required String name,
  }) = _MyEntity;
}
```

#### 3. Создать repository interface

```dart
// lib/features/my_feature/domain/repositories/my_repository.dart
import 'package:fpdart/fpdart.dart';
import '../entities/my_entity.dart';

abstract class MyRepository {
  Future<Either<Failure, MyEntity>> getEntity(String id);
  Future<Either<Failure, void>> saveEntity(MyEntity entity);
}
```

#### 4. Создать use case

```dart
// lib/features/my_feature/domain/usecases/get_entity.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/my_entity.dart';
import '../repositories/my_repository.dart';

class GetEntityUseCase implements UseCase<MyEntity, GetEntityParams> {
  final MyRepository repository;
  
  GetEntityUseCase(this.repository);
  
  @override
  Future<Either<Failure, MyEntity>> call(GetEntityParams params) {
    return repository.getEntity(params.id);
  }
}

class GetEntityParams {
  final String id;
  GetEntityParams({required this.id});
}
```

#### 5. Создать BLoC

```dart
// lib/features/my_feature/presentation/bloc/my_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_bloc.freezed.dart';

@freezed
class MyEvent with _$MyEvent {
  const factory MyEvent.load(String id) = LoadEvent;
}

@freezed
class MyState with _$MyState {
  const factory MyState.initial() = Initial;
  const factory MyState.loading() = Loading;
  const factory MyState.success(MyEntity entity) = Success;
  const factory MyState.error(String message) = Error;
}

class MyBloc extends Bloc<MyEvent, MyState> {
  final GetEntityUseCase getEntity;
  
  MyBloc({required this.getEntity}) : super(const MyState.initial()) {
    on<LoadEvent>(_onLoad);
  }
  
  Future<void> _onLoad(LoadEvent event, Emitter<MyState> emit) async {
    emit(const MyState.loading());
    
    final result = await getEntity(GetEntityParams(id: event.id));
    
    result.fold(
      (failure) => emit(MyState.error(failure.message)),
      (entity) => emit(MyState.success(entity)),
    );
  }
}
```

#### 6. Генерация кода

```bash
melos generate
```

### Работа с WebSocket

```dart
// Подключение
final channel = WebSocketChannel.connect(
  Uri.parse('ws://localhost:8000/ws'),
);

// Отправка сообщения
channel.sink.add(jsonEncode({
  'type': 'user_message',
  'content': 'Hello',
}));

// Получение сообщений
channel.stream.listen((message) {
  final data = jsonDecode(message);
  print('Received: $data');
});

// Закрытие
await channel.sink.close();
```

### Работа с файлами

```dart
import 'package:codelab_core/codelab_core.dart';

final fileService = FileService();

// Чтение
final result = await fileService.readFile('/path/to/file.dart');
result.fold(
  (error) => print('Error: ${error.message}'),
  (content) => print('Content: $content'),
);

// Запись
await fileService.writeFile('/path/to/file.dart', 'content');

// Дерево файлов
final tree = await fileService.loadFileTree('/path/to/project');
```

## Тестирование

### Unit Tests

```dart
// test/services/my_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements MyRepository {}

void main() {
  late MyService service;
  late MockRepository repository;
  
  setUp(() {
    repository = MockRepository();
    service = MyService(repository);
  });
  
  group('MyService', () {
    test('should return data successfully', () async {
      // Arrange
      when(() => repository.getData())
          .thenAnswer((_) async => right(testData));
      
      // Act
      final result = await service.fetchData();
      
      // Assert
      expect(result.isRight(), true);
      verify(() => repository.getData()).called(1);
    });
    
    test('should return error on failure', () async {
      // Arrange
      when(() => repository.getData())
          .thenAnswer((_) async => left(TestFailure()));
      
      // Act
      final result = await service.fetchData();
      
      // Assert
      expect(result.isLeft(), true);
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/my_widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('should display text', (tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: MyWidget(text: 'Hello'),
      ),
    );
    
    // Assert
    expect(find.text('Hello'), findsOneWidget);
  });
  
  testWidgets('should call callback on tap', (tester) async {
    // Arrange
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MyWidget(
          onTap: () => called = true,
        ),
      ),
    );
    
    // Act
    await tester.tap(find.byType(MyWidget));
    await tester.pump();
    
    // Assert
    expect(called, true);
  });
}
```

### BLoC Tests

```dart
// test/bloc/my_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MyBloc bloc;
  late MockUseCase useCase;
  
  setUp(() {
    useCase = MockUseCase();
    bloc = MyBloc(useCase: useCase);
  });
  
  blocTest<MyBloc, MyState>(
    'emits [loading, success] when data is fetched successfully',
    build: () {
      when(() => useCase(any()))
          .thenAnswer((_) async => right(testData));
      return bloc;
    },
    act: (bloc) => bloc.add(const MyEvent.load()),
    expect: () => [
      const MyState.loading(),
      MyState.success(testData),
    ],
  );
}
```

### Integration Tests

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('full app flow', (tester) async {
    // Arrange
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Act - открыть файл
    await tester.tap(find.text('Open File'));
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('File opened'), findsOneWidget);
    
    // Act - отправить сообщение AI
    await tester.enterText(find.byType(TextField), 'Hello AI');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('Hello AI'), findsOneWidget);
  });
}
```

### Запуск тестов

```bash
# Все тесты
melos test

# Конкретный пакет
melos test --scope=codelab_core

# С coverage
melos test --coverage

# Integration tests
cd apps/codelab_ide
flutter test integration_test/
```

## Стандарты кодирования

### Dart Style Guide

Следуйте [Effective Dart](https://dart.dev/guides/language/effective-dart):

```dart
// ✅ Хорошо
class MyClass {
  final String name;
  final int age;
  
  const MyClass({
    required this.name,
    required this.age,
  });
  
  void doSomething() {
    // ...
  }
}

// ❌ Плохо
class myclass {
  String Name;
  int AGE;
  
  myclass(this.Name, this.AGE);
  
  doSomething() {
    // ...
  }
}
```

### Именование

```dart
// Классы - PascalCase
class MyClass {}

// Переменные и функции - camelCase
var myVariable = 'value';
void myFunction() {}

// Константы - lowerCamelCase
const myConstant = 42;

// Приватные члены - начинаются с _
class MyClass {
  String _privateField;
  void _privateMethod() {}
}
```

### Комментарии

```dart
/// Документация класса.
///
/// Подробное описание того, что делает класс.
class MyClass {
  /// Документация метода.
  ///
  /// [param] - описание параметра
  /// 
  /// Returns описание возвращаемого значения
  String myMethod(String param) {
    // Обычный комментарий для пояснения логики
    return param.toUpperCase();
  }
}
```

### Обработка ошибок

```dart
// ✅ Используйте Either
Future<Either<Failure, Data>> fetchData() async {
  try {
    final data = await api.getData();
    return right(data);
  } catch (e) {
    return left(NetworkFailure(e.toString()));
  }
}

// ❌ Не используйте try-catch без Either
Future<Data> fetchData() async {
  try {
    return await api.getData();
  } catch (e) {
    throw Exception(e);  // Плохо
  }
}
```

### Null Safety

```dart
// ✅ Используйте Option для nullable
Option<String> findUser(String id) {
  final user = users[id];
  return user != null ? some(user) : none();
}

// ✅ Используйте ?? для значений по умолчанию
final name = user?.name ?? 'Unknown';

// ✅ Используйте ?. для безопасного доступа
final length = user?.name?.length;
```

## Git Workflow

### Ветки

```
main              # Стабильная версия
├── develop       # Разработка
│   ├── feature/my-feature
│   ├── bugfix/fix-issue
│   └── refactor/improve-code
└── release/v1.1.0
```

### Commit Messages

Следуйте [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Формат
<type>(<scope>): <subject>

# Примеры
feat(ai-assistant): add multi-agent support
fix(terminal): resolve PTY connection issue
docs(readme): update installation instructions
refactor(core): improve file service performance
test(engine): add unit tests for editor manager
chore(deps): update dependencies
```

### Pull Request

1. Создать feature branch:
```bash
git checkout -b feature/my-feature
```

2. Сделать изменения и commit:
```bash
git add .
git commit -m "feat(scope): add new feature"
```

3. Push и создать PR:
```bash
git push origin feature/my-feature
```

4. PR должен включать:
   - Описание изменений
   - Ссылки на issues
   - Скриншоты (если UI изменения)
   - Результаты тестов

## Отладка

### Логирование

```dart
import 'package:logger/logger.dart';

final logger = Logger();

// Уровни логирования
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
logger.f('Fatal message');

// С контекстом
logger.i('User logged in', error: user, stackTrace: stackTrace);
```

### Flutter DevTools

```bash
# Запустить с DevTools
flutter run --observatory-port=9999

# Открыть DevTools
flutter pub global run devtools
```

### Отладка BLoC

```dart
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('${bloc.runtimeType} $event');
  }
  
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('${bloc.runtimeType} $transition');
  }
  
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}

// В main.dart
void main() {
  Bloc.observer = AppBlocObserver();
  runApp(MyApp());
}
```

### Breakpoints

```dart
// Программный breakpoint
debugger();

// Условный breakpoint
if (condition) {
  debugger();
}
```

## Производительность

### Профилирование

```bash
# Profile mode
flutter run --profile

# Анализ производительности
flutter analyze --profile
```

### Оптимизация

```dart
// ✅ Используйте const конструкторы
const MyWidget(text: 'Hello');

// ✅ Кэшируйте дорогие вычисления
final _cache = <String, Data>{};

Data getData(String key) {
  return _cache.putIfAbsent(key, () => expensiveComputation());
}

// ✅ Используйте ListView.builder для длинных списков
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

## Дополнительные ресурсы

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [BLoC Library](https://bloclibrary.dev/)
- [FPDart](https://pub.dev/packages/fpdart)
- [Melos](https://melos.invertase.dev/)

## Получение помощи

- **Issues**: Создайте issue в GitHub
- **Discussions**: Используйте GitHub Discussions
- **Chat**: Присоединяйтесь к Discord/Slack каналу
