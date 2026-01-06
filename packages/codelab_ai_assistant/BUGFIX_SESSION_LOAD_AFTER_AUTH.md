# Исправление: Ошибка загрузки сессий после авторизации

## Проблема

После успешной авторизации пользователь получал ошибку 401 (Unauthorized) при попытке загрузить список сессий, хотя авторизация прошла успешно.

### Симптомы

```
flutter: [SessionRepository] Listing sessions...
flutter: │ 🐛 [AuthBloc] User is not authenticated
flutter: │ ⚠️ [AuthInterceptor] No token found in storage
flutter: │ ⚠️ [AuthInterceptor] Received 401, attempting token refresh
flutter: [SessionRepository] Unexpected error listing sessions: UnauthorizedException
...
flutter: │ 💡 [AuthBloc] Login successful
```

## Причина

Проблема возникала из-за race condition в последовательности инициализации:

1. При открытии `AiAssistantPanel` вызывался `_initSessionManager()` в `initState()`
2. `SessionManagerBloc` сразу же отправлял событие `loadSessions()`
3. Запрос на загрузку сессий выполнялся **до** того, как пользователь авторизовался
4. `AuthInterceptor` не находил токен и возвращал 401
5. После успешной авторизации список сессий не перезагружался

## Решение

Добавлен механизм перезагрузки списка сессий после успешной авторизации:

### 1. Обновлен `AuthWrapper`

Добавлен callback `onAuthenticated`, который вызывается при переходе в состояние `authenticated`:

```dart
class AuthWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAuthenticated;  // Новый параметр

  const AuthWrapper({
    super.key,
    required this.child,
    this.onAuthenticated,
  });
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _wasAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: (token) {
            if (!_wasAuthenticated) {
              _wasAuthenticated = true;
              // Вызываем callback после успешной авторизации
              widget.onAuthenticated?.call();
            }
          },
          unauthenticated: () {
            _wasAuthenticated = false;
          },
        );
      },
      builder: (context, state) {
        // ... остальной код
      },
    );
  }
}
```

### 2. Обновлен `AiAssistantPanel`

Добавлен callback для перезагрузки сессий после авторизации:

```dart
return BlocProvider<AuthBloc>.value(
  value: authBloc,
  child: AuthWrapper(
    onAuthenticated: () {
      // После успешной авторизации перезагружаем список сессий
      _sessionManagerBloc?.add(const SessionManagerEvent.loadSessions());
    },
    child: _buildContent(),
  ),
);
```

## Результат

Теперь последовательность работает корректно:

1. Пользователь открывает панель AI Assistant
2. `AuthWrapper` проверяет статус авторизации
3. Если пользователь не авторизован, показывается форма логина
4. После успешной авторизации срабатывает callback `onAuthenticated`
5. Список сессий перезагружается с валидным токеном
6. Пользователь видит свои сессии без ошибок

## Измененные файлы

- [`lib/features/authentication/presentation/widgets/auth_wrapper.dart`](lib/features/authentication/presentation/widgets/auth_wrapper.dart)
- [`lib/features/agent_chat/presentation/widgets/ai_assistant_panel.dart`](lib/features/agent_chat/presentation/widgets/ai_assistant_panel.dart)

## Тестирование

Для проверки исправления:

1. Запустите приложение
2. Откройте панель AI Assistant
3. Введите учетные данные и авторизуйтесь
4. Убедитесь, что список сессий загружается без ошибок 401
5. Проверьте логи - не должно быть сообщений об ошибках авторизации после успешного логина
