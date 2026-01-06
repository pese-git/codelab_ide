// Новая страница авторизации с использованием рефакторинга
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../../shared/presentation/molecules/inputs/text_input_field.dart';
import '../../../shared/presentation/molecules/inputs/password_input_field.dart';
import '../../../shared/presentation/atoms/buttons/primary_button.dart';
import '../../../shared/utils/extensions/context_extensions.dart';
import '../bloc/auth_bloc.dart';

/// Новая страница авторизации с применением Atomic Design
///
/// Преимущества перед старой LoginForm:
/// - Использует переиспользуемые компоненты
/// - Применяет централизованную тему
/// - Меньше кода (120 строк vs 188)
/// - Легче тестировать
/// - Консистентный дизайн
/// - Исправлен бесконечный loader при resize
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthEvent.login(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        state.whenOrNull(
          error: (message) => context.showError(message),
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          authenticating: () => true,
          orElse: () => false,
        );

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: AppSpacing.paddingXl,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  AppSpacing.gapVerticalXxl,

                  // Username field
                  TextInputField(
                    controller: _usernameController,
                    label: 'Email или имя пользователя',
                    placeholder: 'user@example.com',
                    enabled: !isLoading,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите email или имя пользователя';
                      }
                      return null;
                    },
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  AppSpacing.gapVerticalLg,

                  // Password field
                  PasswordInputField(
                    controller: _passwordController,
                    label: 'Пароль',
                    placeholder: '••••••••',
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  AppSpacing.gapVerticalXl,

                  // Login button
                  PrimaryButton(
                    onPressed: isLoading ? null : _handleLogin,
                    isLoading: isLoading,
                    child: const Text('Войти'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Авторизация',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapVerticalSm,
        Text(
          'Войдите для доступа к AI Assistant',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
