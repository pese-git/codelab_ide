// Обертка для проверки авторизации
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../bloc/auth_bloc.dart';
import '../pages/login_page.dart';

/// Обертка для проверки авторизации
///
/// Показывает форму авторизации если пользователь не авторизован,
/// иначе показывает дочерний виджет
class AuthWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAuthenticated;

  const AuthWrapper({
    super.key,
    required this.child,
    this.onAuthenticated,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _wasAuthenticated = false;
  bool _hasCheckedAuth = false; // ✅ Флаг для предотвращения повторных проверок
  AuthState? _lastKnownState; // ✅ Кешируем последнее известное состояние
  
  static final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.d('[AuthWrapper] 🏗️ initState');
    // Проверяем статус авторизации при инициализации ОДИН РАЗ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedAuth && mounted) {
        _hasCheckedAuth = true;
        _logger.d('[AuthWrapper] 🔍 Checking auth status');
        context.read<AuthBloc>().add(const AuthEvent.checkAuthStatus());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('[AuthWrapper] 🎨 Building widget');
    
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        _logger.d('[AuthWrapper] 👂 Listener received state: ${state.runtimeType}');
        // Отслеживаем переход в состояние authenticated
        state.whenOrNull(
          authenticated: (token) {
            if (!_wasAuthenticated) {
              _wasAuthenticated = true;
              _logger.i('[AuthWrapper] ✅ User authenticated, calling callback');
              // Вызываем callback после успешной авторизации
              widget.onAuthenticated?.call();
            }
          },
          unauthenticated: () {
            _logger.w('[AuthWrapper] ❌ User unauthenticated');
            _wasAuthenticated = false;
          },
        );
      },
      builder: (context, state) {
        _logger.d('[AuthWrapper] 🎨 Builder received state: ${state.runtimeType}');
        
        // ✅ Кешируем состояние, если оно не initial
        if (state is! AuthInitial) {
          _lastKnownState = state;
        }
        
        // ✅ Если получили initial, но есть кешированное состояние - используем его
        final effectiveState = (state is AuthInitial && _lastKnownState != null)
            ? _lastKnownState!
            : state;
        
        _logger.d('[AuthWrapper] 🎯 Using effective state: ${effectiveState.runtimeType}');
        
        return effectiveState.when(
          // Начальное состояние - показываем загрузку
          initial: () {
            _logger.d('[AuthWrapper] 📄 Showing initial state with ProgressRing');
            return const Center(
              child: ProgressRing(),
            );
          },

          // Проверка авторизации - показываем загрузку
          checking: () {
            _logger.d('[AuthWrapper] ⏳ Showing checking state with ProgressRing');
            return const Center(
              child: ProgressRing(),
            );
          },

          // Пользователь авторизован - показываем дочерний виджет
          authenticated: (token) {
            _logger.d('[AuthWrapper] ✅ Showing authenticated state with child widget');
            return widget.child;
          },

          // Пользователь не авторизован - показываем новую страницу авторизации
          unauthenticated: () {
            _logger.d('[AuthWrapper] 🔐 Showing unauthenticated state with LoginPage');
            return const LoginPage();
          },

          // Процесс авторизации - показываем новую страницу с индикатором загрузки
          authenticating: () {
            _logger.d('[AuthWrapper] 🔄 Showing authenticating state with LoginPage');
            return const LoginPage();
          },

          // Ошибка авторизации - показываем новую страницу с ошибкой
          error: (message) {
            _logger.e('[AuthWrapper] ❌ Showing error state with LoginPage: $message');
            return const LoginPage();
          },
        );
      },
    );
  }
}
