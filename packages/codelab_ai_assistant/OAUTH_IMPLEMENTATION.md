# OAuth2 Authentication Implementation

## Обзор

Реализована полная поддержка OAuth2 авторизации с использованием Password Grant и автоматическим обновлением токенов, включая UI для авторизации пользователей.

## Архитектура

Реализация следует Clean Architecture и разделена на слои:

### Domain Layer

#### Entities
- **`AuthToken`** - основная сущность токена авторизации
  - `accessToken` - токен доступа
  - `refreshToken` - токен обновления
  - `tokenType` - тип токена (bearer)
  - `expiresIn` - время жизни в секундах
  - `scope` - разрешения (опционально)
  - `issuedAt` - время выдачи

#### Parameters
- **`PasswordGrantParams`** - параметры для авторизации по паролю
- **`RefreshTokenParams`** - параметры для обновления токена

#### Repository Interface
- **`AuthRepository`** - контракт для работы с авторизацией
  - `loginWithPassword()` - авторизация по паролю
  - `refreshToken()` - обновление токена
  - `saveToken()` - сохранение токена
  - `getStoredToken()` - получение сохраненного токена
  - `clearToken()` - удаление токена
  - `isAuthenticated()` - проверка авторизации

### Data Layer

#### Models
- **`AuthTokenModel`** - DTO модель для сериализации/десериализации токена
- **`PasswordGrantRequest`** - модель запроса авторизации по паролю
- **`RefreshTokenRequest`** - модель запроса обновления токена

#### Data Sources

##### Remote Data Source
- **`AuthRemoteDataSource`** - интерфейс для работы с OAuth API
- **`AuthRemoteDataSourceImpl`** - реализация
  - Отправляет запросы на `/oauth/token` эндпоинт
  - Обрабатывает ошибки авторизации (401, 429)
  - Использует form-urlencoded формат

##### Local Data Source
- **`AuthLocalDataSource`** - интерфейс для локального хранения
- **`AuthLocalDataSourceImpl`** - реализация через SharedPreferences
  - Сохраняет токен в JSON формате
  - Автоматически удаляет поврежденные данные

#### Repository Implementation
- **`AuthRepositoryImpl`** - реализация репозитория
  - Координирует работу remote и local data sources
  - Преобразует исключения в Failure объекты
  - Автоматически удаляет истекшие токены

#### Services

##### Auth Interceptor
- **`AuthInterceptor`** - Dio interceptor для автоматической авторизации
  - Автоматически добавляет Authorization заголовок к запросам
  - Проверяет необходимость обновления токена перед запросом
  - Автоматически обновляет токен при получении 401 ошибки
  - Управляет очередью запросов во время обновления токена
  - Предотвращает циклические обновления

### Presentation Layer

#### BLoC
- **`AuthBloc`** - управление состоянием авторизации
  - События: `CheckAuthStatus`, `Login`, `Logout`, `RefreshToken`
  - Состояния: `Initial`, `Checking`, `Authenticated`, `Unauthenticated`, `Authenticating`, `Error`
  - Автоматическая проверка токена при инициализации
  - Обработка ошибок авторизации

#### Widgets
- **`LoginForm`** - форма авторизации
  - Поля для username/email и пароля
  - Валидация полей
  - Индикатор загрузки
  - Отображение ошибок
  
- **`AuthWrapper`** - обертка для проверки авторизации
  - Автоматическая проверка токена при открытии
  - Показывает форму авторизации если токен отсутствует или истек
  - Показывает дочерний виджет если пользователь авторизован
  - Индикатор загрузки во время проверки

## Использование

### Инициализация в DI модуле

```dart
AiAssistantModule(
  gatewayBaseUrl: 'http://localhost/api/v1',
  authServiceUrl: 'http://localhost', // OAuth эндпоинт: /oauth/token
  internalApiKey: 'my-super-secret-key',
  sharedPreferences: sharedPreferences,
  useOAuth: true, // Включить OAuth авторизацию
)
```

### Авторизация по паролю

```dart
final authRepository = scope.resolve<AuthRepository>();

final params = PasswordGrantParams.withDefaults(
  username: 'user@example.com',
  password: 'password123',
);

final result = await authRepository.loginWithPassword(params);

result.fold(
  (failure) => print('Login failed: ${failure.message}'),
  (token) => print('Login successful: ${token.accessToken}'),
);
```

### Обновление токена

```dart
final storedTokenResult = await authRepository.getStoredToken();

storedTokenResult.fold(
  (failure) => print('Error: ${failure.message}'),
  (tokenOption) => tokenOption.fold(
    () => print('No token stored'),
    (token) async {
      if (token.needsRefresh) {
        final params = RefreshTokenParams.withDefaults(
          refreshToken: token.refreshToken,
        );
        
        final result = await authRepository.refreshToken(params);
        // Обработка результата
      }
    },
  ),
);
```

### Автоматическое обновление

`AuthInterceptor` автоматически:
1. Добавляет токен к каждому запросу
2. Проверяет необходимость обновления (за 5 минут до истечения)
3. Обновляет токен при получении 401 ошибки
4. Повторяет неудавшиеся запросы с новым токеном

## Конфигурация

### Параметры модуля

- **`gatewayBaseUrl`** - URL Gateway сервиса (default: `http://localhost:8000`)
- **`authServiceUrl`** - URL Auth сервиса (default: `http://localhost/auth`)
- **`internalApiKey`** - API ключ для внутренней авторизации (fallback)
- **`sharedPreferences`** - экземпляр SharedPreferences для хранения токенов
- **`useOAuth`** - флаг включения OAuth (default: `false`)

### OAuth эндпоинты

Auth Service должен предоставлять следующие эндпоинты:

#### POST /oauth/token (Password Grant)
```
Content-Type: application/x-www-form-urlencoded

grant_type=password
&username=user@example.com
&password=password123
&client_id=codelab-ide
&scope=default
```

Response:
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 900,
  "scope": "default"
}
```

#### POST /oauth/token (Refresh Token Grant)
```
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=eyJhbGc...
&client_id=codelab-ide
```

Response: аналогичен Password Grant

## Обработка ошибок

### Failure типы

- **`Failure.unauthorized`** - ошибки авторизации (401, 403)
- **`Failure.server`** - ошибки сервера (5xx)
- **`Failure.cache`** - ошибки локального хранилища
- **`Failure.network`** - ошибки сети

### Исключения

- **`AuthenticationException`** - исключение авторизации с кодом статуса
- **`UnauthorizedException`** - неавторизованный доступ

## Безопасность

1. **Токены хранятся локально** в SharedPreferences
2. **Refresh token используется только один раз** - после обновления старый токен становится недействительным
3. **Автоматическое удаление истекших токенов** из хранилища
4. **Отдельный Dio клиент для OAuth запросов** - предотвращает циклические interceptor'ы
5. **Очередь запросов** - предотвращает множественные одновременные обновления токена

## Тестирование

### Проверка авторизации

```dart
final isAuth = await authRepository.isAuthenticated();
print('Is authenticated: $isAuth');
```

### Проверка токена

```dart
final result = await authRepository.getStoredToken();
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (tokenOption) => tokenOption.fold(
    () => print('No token'),
    (token) {
      print('Token expires at: ${token.expiresAt}');
      print('Needs refresh: ${token.needsRefresh}');
      print('Is expired: ${token.isExpired}');
    },
  ),
);
```

### Logout

```dart
final result = await authRepository.clearToken();
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (_) => print('Logged out successfully'),
);
```

## Интеграция с существующим кодом

### Миграция с X-Internal-Auth

Модуль поддерживает оба режима авторизации:

1. **OAuth режим** (`useOAuth: true`) - использует JWT токены
2. **Internal Auth режим** (`useOAuth: false`) - использует X-Internal-Auth заголовок

Переключение происходит через параметр `useOAuth` в конфигурации модуля.

### Совместимость

- Все существующие запросы продолжают работать
- OAuth эндпоинты (`/oauth/token`) автоматически исключаются из interceptor'а
- При отсутствии токена запросы выполняются без Authorization заголовка

## Дальнейшее развитие

### Возможные улучшения

1. **UI для авторизации** - форма логина/регистрации
2. **BLoC для управления состоянием** - AuthBloc для UI
3. **Биометрическая авторизация** - сохранение credentials с использованием биометрии
4. **Автоматический logout** - при истечении refresh token
5. **Уведомления** - о необходимости повторной авторизации
6. **Поддержка других grant types** - Authorization Code, Client Credentials
7. **Token introspection** - проверка валидности токена на сервере
8. **Revocation endpoint** - явное аннулирование токенов

## Зависимости

- `dio` - HTTP клиент
- `shared_preferences` - локальное хранилище
- `freezed` - генерация immutable классов
- `fpdart` - функциональное программирование (Either, Option)
- `json_annotation` - JSON сериализация
- `logger` - логирование

## Структура файлов

```
lib/features/authentication/
├── domain/
│   ├── entities/
│   │   └── auth_token.dart
│   └── repositories/
│       └── auth_repository.dart
├── data/
│   ├── models/
│   │   └── auth_token_model.dart
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart
│   │   └── auth_local_datasource.dart
│   ├── repositories/
│   │   └── auth_repository_impl.dart
│   └── services/
│       └── auth_interceptor.dart
```

## Логирование

Interceptor логирует следующие события:

- Добавление токена к запросу
- Необходимость обновления токена
- Получение 401 ошибки
- Начало обновления токена
- Успешное обновление токена
- Ошибки обновления токена
- Повторные запросы с новым токеном
- Обработка очереди запросов

Уровень логирования можно настроить через Logger в DI модуле.
