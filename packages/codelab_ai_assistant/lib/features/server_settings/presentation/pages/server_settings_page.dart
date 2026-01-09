// Страница настроек сервера
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/presentation/theme/app_theme.dart';
import '../../../shared/presentation/molecules/inputs/text_input_field.dart';
import '../../../shared/presentation/atoms/buttons/primary_button.dart';
import '../../../shared/utils/extensions/context_extensions.dart';
import '../bloc/server_settings_bloc.dart';

/// Страница настроек сервера
///
/// Позволяет пользователю настроить базовый URL сервера AI Assistant
class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final _urlController = TextEditingController(
    text: 'https://codelab.openidealab.com',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleTestConnection() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ServerSettingsBloc>().add(
            ServerSettingsEvent.testConnection(
              baseUrl: _urlController.text.trim(),
            ),
          );
    }
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ServerSettingsBloc>().add(
            ServerSettingsEvent.saveSettings(
              baseUrl: _urlController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServerSettingsBloc, ServerSettingsState>(
      listener: (context, state) {
        state.whenOrNull(
          error: (message) => context.showError(message),
          testSuccess: () => context.showSuccess('Соединение успешно!'),
          testFailure: (message) => context.showError(message),
          saved: (_) => context.showSuccess('Настройки сохранены'),
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          loading: () => true,
          saving: () => true,
          testing: () => true,
          orElse: () => false,
        );

        final isTesting = state.maybeWhen(
          testing: () => true,
          orElse: () => false,
        );

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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

                  // URL field
                  TextInputField(
                    controller: _urlController,
                    label: 'Base URL сервера',
                    placeholder: 'https://codelab.openidealab.com',
                    enabled: !isLoading,
                    autofocus: true,
                    validator: _validateUrl,
                    onSubmitted: (_) => _handleSave(),
                  ),
                  AppSpacing.gapVerticalMd,

                  // Hint
                  Text(
                    'Укажите базовый URL сервера AI Assistant без завершающего слеша',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapVerticalXl,

                  // Test connection button
                  PrimaryButton(
                    onPressed: isLoading ? null : _handleTestConnection,
                    isLoading: isTesting,
                    child: const Text('Тестировать соединение'),
                  ),
                  AppSpacing.gapVerticalMd,

                  // Save button
                  FilledButton(
                    onPressed: isLoading ? null : _handleSave,
                    child: isLoading && !isTesting
                        ? const ProgressRing()
                        : const Text('Сохранить'),
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
          'Настройка сервера',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapVerticalSm,
        Text(
          'Укажите адрес сервера AI Assistant для продолжения работы',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите URL сервера';
    }

    final trimmedValue = value.trim();

    // Проверка формата URL
    final uri = Uri.tryParse(trimmedValue);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Некорректный формат URL. Пример: http://localhost:8000';
    }

    // Проверка схемы
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL должен начинаться с http:// или https://';
    }

    // Проверка на завершающий слеш
    if (trimmedValue.endsWith('/')) {
      return 'URL не должен заканчиваться слешем';
    }

    return null;
  }
}
