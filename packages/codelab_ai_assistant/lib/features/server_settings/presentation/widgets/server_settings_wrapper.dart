// Обертка для проверки настроек сервера
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../bloc/server_settings_bloc.dart';
import '../pages/server_settings_page.dart';

/// Обертка для проверки настроек сервера
///
/// Показывает страницу настроек если baseUrl не настроен,
/// иначе показывает дочерний виджет
class ServerSettingsWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onConfigured;

  const ServerSettingsWrapper({
    super.key,
    required this.child,
    this.onConfigured,
  });

  @override
  State<ServerSettingsWrapper> createState() => _ServerSettingsWrapperState();
}

class _ServerSettingsWrapperState extends State<ServerSettingsWrapper> {
  bool _wasConfigured = false;

  static final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.d('[ServerSettingsWrapper] 🏗️ initState');
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('[ServerSettingsWrapper] 🎨 Building widget');

    return BlocConsumer<ServerSettingsBloc, ServerSettingsState>(
      listener: (context, state) {
        _logger.d('[ServerSettingsWrapper] 👂 Listener received state: ${state.runtimeType}');
        
        // Отслеживаем переход в состояние configured
        state.whenOrNull(
          saved: (settings) {
            if (!_wasConfigured) {
              _wasConfigured = true;
              _logger.i('[ServerSettingsWrapper] ✅ Server configured, calling callback');
              // Вызываем callback после успешной настройки
              widget.onConfigured?.call();
            }
          },
          loaded: (settings) {
            if (!_wasConfigured) {
              _wasConfigured = true;
              _logger.i('[ServerSettingsWrapper] ✅ Server already configured');
              widget.onConfigured?.call();
            }
          },
          notConfigured: () {
            _logger.w('[ServerSettingsWrapper] ❌ Server not configured');
            _wasConfigured = false;
          },
        );
      },
      builder: (context, state) {
        _logger.d('[ServerSettingsWrapper] 🎨 Builder received state: ${state.runtimeType}');

        return state.when(
          // Начальное состояние - показываем загрузку
          initial: () {
            _logger.d('[ServerSettingsWrapper] 📄 Showing initial state with ProgressRing');
            return const Center(
              child: ProgressRing(),
            );
          },

          // Загрузка настроек - показываем загрузку
          loading: () {
            _logger.d('[ServerSettingsWrapper] ⏳ Showing loading state with ProgressRing');
            return const Center(
              child: ProgressRing(),
            );
          },

          // Настройки загружены - показываем дочерний виджет
          loaded: (settings) {
            _logger.d('[ServerSettingsWrapper] ✅ Showing loaded state with child widget');
            return widget.child;
          },

          // Настройки не найдены - показываем страницу настроек
          notConfigured: () {
            _logger.d('[ServerSettingsWrapper] 🔧 Showing notConfigured state with ServerSettingsPage');
            return const ServerSettingsPage();
          },

          // Сохранение настроек - показываем страницу настроек с индикатором
          saving: () {
            _logger.d('[ServerSettingsWrapper] 💾 Showing saving state with ServerSettingsPage');
            return const ServerSettingsPage();
          },

          // Настройки сохранены - показываем дочерний виджет
          saved: (settings) {
            _logger.d('[ServerSettingsWrapper] ✅ Showing saved state with child widget');
            return widget.child;
          },

          // Тестирование соединения - показываем страницу настроек
          testing: () {
            _logger.d('[ServerSettingsWrapper] 🔍 Showing testing state with ServerSettingsPage');
            return const ServerSettingsPage();
          },

          // Тест успешен - показываем страницу настроек
          testSuccess: () {
            _logger.d('[ServerSettingsWrapper] ✅ Showing testSuccess state with ServerSettingsPage');
            return const ServerSettingsPage();
          },

          // Тест не удался - показываем страницу настроек с ошибкой
          testFailure: (message) {
            _logger.e('[ServerSettingsWrapper] ❌ Showing testFailure state with ServerSettingsPage: $message');
            return const ServerSettingsPage();
          },

          // Ошибка - показываем страницу настроек с ошибкой
          error: (message) {
            _logger.e('[ServerSettingsWrapper] ❌ Showing error state with ServerSettingsPage: $message');
            return const ServerSettingsPage();
          },
        );
      },
    );
  }
}
