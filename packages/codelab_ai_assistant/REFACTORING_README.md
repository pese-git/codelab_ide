# Рефакторинг codelab_ai_assistant - Руководство

## Обзор

Модуль `codelab_ai_assistant` проходит рефакторинг для приведения к Clean Architecture с использованием функционального программирования (fpdart).

## Документация

- **[CLEAN_ARCHITECTURE_PLAN.md](CLEAN_ARCHITECTURE_PLAN.md)** - Детальный план рефакторинга с примерами кода
- **[REFACTORING_PROGRESS.md](REFACTORING_PROGRESS.md)** - Текущий прогресс и статус выполнения

## Текущий статус

### ✅ Завершено (40%)

1. **Core слой** - Базовая инфраструктура
   - Failures (domain errors)
   - Exceptions (data errors)
   - UseCase interfaces
   - Type definitions с fpdart

2. **Domain слой - session_management**
   - Entities (Session, параметры)
   - Repository interface
   - Use cases (create, load, list, delete)

3. **Документация**
   - Архитектурный план
   - Прогресс рефакторинга
   - Это руководство

### ⏳ В процессе (0%)

4. **Data слой - session_management**
   - Нужно создать DTO модели
   - Нужно создать data sources
   - Нужно реализовать repository

### ❌ Не начато (60%)

5. **Domain слой - tool_execution**
6. **Domain слой - agent_chat**
7. **Data слой - tool_execution**
8. **Data слой - agent_chat**
9. **Presentation слой - все фичи**
10. **DI обновление**
11. **Тестирование**

## Структура проекта

```
lib/
├── core/                                    # ✅ Завершено
│   ├── error/
│   │   ├── failures.dart                    # Domain failures
│   │   └── exceptions.dart                  # Data exceptions
│   ├── usecases/
│   │   └── usecase.dart                     # Base use case interfaces
│   └── utils/
│       └── type_defs.dart                   # FutureEither, StreamEither
│
├── features/
│   ├── session_management/                  # ✅ Domain завершен
│   │   ├── domain/                          # ✅ 100%
│   │   │   ├── entities/
│   │   │   │   └── session.dart
│   │   │   ├── repositories/
│   │   │   │   └── session_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_session.dart
│   │   │       ├── load_session.dart
│   │   │       ├── list_sessions.dart
│   │   │       └── delete_session.dart
│   │   ├── data/                            # ⏳ Следующий шаг
│   │   │   ├── models/                      # Нужно создать
│   │   │   ├── datasources/                 # Нужно создать
│   │   │   └── repositories/                # Нужно создать
│   │   └── presentation/                    # ❌ Не начато
│   │
│   ├── tool_execution/                      # ❌ Не начато
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── agent_chat/                          # ❌ Не начато
│       ├── domain/
│       ├── data/
│       └── presentation/
│
└── injection_container.dart                 # ❌ Нужно обновить
```

## Следующие шаги

### Шаг 1: Завершить Data слой для session_management

#### 1.1 Создать DTO модель

Файл: `lib/features/session_management/data/models/session_model.dart`

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/entities/session.dart';

part 'session_model.g.dart';

@JsonSerializable()
class SessionModel {
  @JsonKey(name: 'session_id')
  final String id;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  @JsonKey(name: 'current_agent')
  final String currentAgent;
  
  @JsonKey(name: 'message_count')
  final int messageCount;
  
  final String? title;
  final String? description;
  
  SessionModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.currentAgent,
    required this.messageCount,
    this.title,
    this.description,
  });
  
  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$SessionModelToJson(this);
  
  // Маппинг в Entity
  Session toEntity() {
    return Session(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      currentAgent: currentAgent,
      messageCount: messageCount,
      title: title != null ? some(title!) : none(),
      description: description != null ? some(description!) : none(),
    );
  }
  
  // Маппинг из Entity
  factory SessionModel.fromEntity(Session session) {
    return SessionModel(
      id: session.id,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      currentAgent: session.currentAgent,
      messageCount: session.messageCount,
      title: session.title.toNullable(),
      description: session.description.toNullable(),
    );
  }
}
```

#### 1.2 Создать Data Sources

Файл: `lib/features/session_management/data/datasources/session_remote_datasource.dart`

```dart
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/session_model.dart';

abstract class SessionRemoteDataSource {
  Future<SessionModel> createSession();
  Future<SessionModel> getSession(String sessionId);
  Future<List<SessionModel>> listSessions();
  Future<void> deleteSession(String sessionId);
}

class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;
  
  SessionRemoteDataSourceImpl({
    required Dio dio,
    required String baseUrl,
  }) : _dio = dio, _baseUrl = baseUrl;
  
  @override
  Future<SessionModel> createSession() async {
    try {
      final response = await _dio.post('$_baseUrl/api/v1/sessions');
      return SessionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  @override
  Future<SessionModel> getSession(String sessionId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/v1/sessions/$sessionId');
      return SessionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  @override
  Future<List<SessionModel>> listSessions() async {
    try {
      final response = await _dio.get('$_baseUrl/api/v1/sessions');
      final sessions = (response.data['sessions'] as List)
          .map((json) => SessionModel.fromJson(json))
          .toList();
      return sessions;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _dio.delete('$_baseUrl/api/v1/sessions/$sessionId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Connection timeout', e);
    }
    
    if (e.response?.statusCode == 404) {
      return NotFoundException('Session not found', e);
    }
    
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return UnauthorizedException('Unauthorized', e);
    }
    
    return ServerException('Server error: ${e.message}', e);
  }
}
```

Файл: `lib/features/session_management/data/datasources/session_local_datasource.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/error/exceptions.dart';
import '../models/session_model.dart';

abstract class SessionLocalDataSource {
  Future<void> cacheSession(SessionModel session);
  Future<SessionModel?> getLastSession();
  Future<void> clearCache();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final SharedPreferences _prefs;
  static const String _lastSessionKey = 'last_session';
  
  SessionLocalDataSourceImpl(this._prefs);
  
  @override
  Future<void> cacheSession(SessionModel session) async {
    try {
      final jsonString = jsonEncode(session.toJson());
      await _prefs.setString(_lastSessionKey, jsonString);
    } catch (e) {
      throw CacheException('Failed to cache session', e);
    }
  }
  
  @override
  Future<SessionModel?> getLastSession() async {
    try {
      final jsonString = _prefs.getString(_lastSessionKey);
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SessionModel.fromJson(json);
    } catch (e) {
      throw CacheException('Failed to get cached session', e);
    }
  }
  
  @override
  Future<void> clearCache() async {
    try {
      await _prefs.remove(_lastSessionKey);
    } catch (e) {
      throw CacheException('Failed to clear cache', e);
    }
  }
}
```

#### 1.3 Реализовать Repository

Файл: `lib/features/session_management/data/repositories/session_repository_impl.dart`

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_datasource.dart';
import '../datasources/session_local_datasource.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource _remoteDataSource;
  final SessionLocalDataSource _localDataSource;
  
  SessionRepositoryImpl({
    required SessionRemoteDataSource remoteDataSource,
    required SessionLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  
  @override
  Future<Either<Failure, Session>> createSession(CreateSessionParams params) async {
    try {
      final model = await _remoteDataSource.createSession();
      await _localDataSource.cacheSession(model);
      return right(model.toEntity());
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Session>> loadSession(LoadSessionParams params) async {
    try {
      final model = await _remoteDataSource.getSession(params.sessionId);
      await _localDataSource.cacheSession(model);
      return right(model.toEntity());
    } on NotFoundException catch (e) {
      return left(Failure.notFound(e.message));
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error: $e'));
    }
  }
  
  @override
  Future<Either<Failure, List<Session>>> listSessions() async {
    try {
      final models = await _remoteDataSource.listSessions();
      final sessions = models.map((m) => m.toEntity()).toList();
      return right(sessions);
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Unit>> deleteSession(DeleteSessionParams params) async {
    try {
      await _remoteDataSource.deleteSession(params.sessionId);
      return right(unit);
    } on NotFoundException catch (e) {
      return left(Failure.notFound(e.message));
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return left(Failure.network(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Option<Session>>> getLastSession() async {
    try {
      final model = await _localDataSource.getLastSession();
      if (model == null) {
        return right(none());
      }
      return right(some(model.toEntity()));
    } on CacheException catch (e) {
      return left(Failure.cache(e.message));
    } catch (e) {
      return left(Failure.unknown('Unexpected error: $e'));
    }
  }
  
  @override
  Future<Either<Failure, Session>> updateSessionTitle(
    String sessionId,
    String title,
  ) async {
    // TODO: Implement when backend API is ready
    return left(Failure.server('Not implemented'));
  }
}
```

### Шаг 2: Запустить build_runner

```bash
cd codelab_ide/packages/codelab_ai_assistant
dart run build_runner build --delete-conflicting-outputs
```

### Шаг 3: Написать тесты

Создать тесты для:
- Use cases (с mock репозиториями)
- Repository (с mock data sources)
- Data sources (с mock HTTP клиентом)

### Шаг 4: Повторить для других фич

После завершения session_management, повторить процесс для:
1. tool_execution
2. agent_chat

## Ключевые принципы

### 1. Dependency Rule

Зависимости всегда направлены внутрь:

```
Presentation → Data → Domain
```

Domain не знает о Data и Presentation.

### 2. Either для обработки ошибок

```dart
// Вместо try-catch
final result = await useCase(params);
result.fold(
  (failure) => handleError(failure),
  (success) => handleSuccess(success),
);
```

### 3. Immutability

Все entities и DTOs immutable (freezed).

### 4. Single Responsibility

Каждый use case делает одну вещь.

## Команды

### Генерация кода

```bash
# Генерация freezed и json_serializable
dart run build_runner build --delete-conflicting-outputs

# Watch mode (автоматическая генерация)
dart run build_runner watch --delete-conflicting-outputs
```

### Тестирование

```bash
# Запуск всех тестов
flutter test

# Запуск конкретного теста
flutter test test/features/session_management/domain/usecases/create_session_test.dart

# С покрытием
flutter test --coverage
```

### Анализ кода

```bash
# Статический анализ
dart analyze

# Форматирование
dart format lib/ test/
```

## Полезные ссылки

- [fpdart документация](https://pub.dev/packages/fpdart)
- [freezed документация](https://pub.dev/packages/freezed)
- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Вопросы и проблемы

При возникновении вопросов:
1. Проверьте [CLEAN_ARCHITECTURE_PLAN.md](CLEAN_ARCHITECTURE_PLAN.md)
2. Посмотрите примеры в уже реализованном коде
3. Обратитесь к архитектору проекта

## Чеклист для новой фичи

- [ ] Создать entities в domain/entities/
- [ ] Создать repository interface в domain/repositories/
- [ ] Создать use cases в domain/usecases/
- [ ] Создать DTO models в data/models/
- [ ] Создать data sources в data/datasources/
- [ ] Реализовать repository в data/repositories/
- [ ] Обновить BLoC в presentation/bloc/
- [ ] Обновить UI в presentation/widgets/
- [ ] Зарегистрировать в DI
- [ ] Написать тесты
- [ ] Обновить документацию
