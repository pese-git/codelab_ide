// Обертка для проверки авторизации
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'login_form.dart';

/// Обертка для проверки авторизации
///
/// Показывает форму авторизации если пользователь не авторизован,
/// иначе показывает дочерний виджет
class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Проверяем статус авторизации при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AuthEvent.checkAuthStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return state.when(
          // Начальное состояние - показываем загрузку
          initial: () => const Center(
            child: ProgressRing(),
          ),

          // Проверка авторизации - показываем загрузку
          checking: () => const Center(
            child: ProgressRing(),
          ),

          // Пользователь авторизован - показываем дочерний виджет
          authenticated: (token) => widget.child,

          // Пользователь не авторизован - показываем форму авторизации
          unauthenticated: () => const LoginForm(),

          // Процесс авторизации - показываем форму с индикатором загрузки
          authenticating: () => const LoginForm(),

          // Ошибка авторизации - показываем форму с ошибкой
          error: (message) => const LoginForm(),
        );
      },
    );
  }
}
