// Main Application Module - объединяет все feature modules
import 'package:cherrypick/cherrypick.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/feature_flags.dart';
import 'core_module.dart';
import 'network_module.dart';
import 'features/auth_module.dart';
import 'features/server_settings_module.dart';
import 'features/session_module.dart';
import 'features/approval_module.dart';
import 'features/tool_module.dart';
import 'features/agent_chat_module.dart';

/// Главный модуль приложения
///
/// Объединяет все feature modules в правильном порядке зависимостей:
/// 1. CoreModule - базовые зависимости (Logger, BlocObserver)
/// 2. NetworkModule - сетевые клиенты (Dio, WebSocket)
/// 3. AuthModule - аутентификация
/// 4. ServerSettingsModule - настройки сервера
/// 5. SessionModule - управление сессиями
/// 6. ApprovalModule - система подтверждений
/// 7. ToolModule - выполнение инструментов
/// 8. AgentChatModule - чат с агентами
///
/// Использование:
/// ```dart
/// final module = AppModule(
///   baseUrl: 'http://localhost:8000',
///   sharedPreferences: await SharedPreferences.getInstance(),
/// );
///
/// final scope = module.createScope();
/// final authBloc = scope.resolve<AuthBloc>();
/// ```
class AppModule extends Module {
  final String baseUrl;
  final SharedPreferences? sharedPreferences;

  AppModule({
    this.baseUrl = 'http://localhost',
    this.sharedPreferences,
  });

  @override
  void builder(Scope currentScope) {
    // ========================================================================
    // Регистрация SharedPreferences (если доступен)
    // ========================================================================

    if (sharedPreferences != null) {
      bind<SharedPreferences>().toProvide(() => sharedPreferences!).singleton();
    }
  }

  @override
  List<Module> get imports => [
        // 1. Core - базовые зависимости
        CoreModule(),

        // 2. Network - сетевые клиенты
        NetworkModule(baseUrl: baseUrl),

        // 3. Authentication - должен быть до других features
        // (AuthInterceptor нужен для Dio)
        AuthModule(sharedPreferences: sharedPreferences),

        // 4. Server Settings
        if (sharedPreferences != null) ServerSettingsModule(),

        // 5. Session Management
        if (sharedPreferences != null)
          SessionModule(sharedPreferences: sharedPreferences),

        // 6. Approval System - должен быть до Tool и AgentChat
        ApprovalModule(),

        // 7. Tool Execution - должен быть до AgentChat
        ToolModule(),

        // 8. Agent Chat - зависит от всех предыдущих
        AgentChatModule(),
      ];
}

/// Фабрика для создания AppModule с feature flags
///
/// Использует FeatureFlags для определения конфигурации модулей.
/// В будущем можно добавить разные профили (dev, prod, test).
class AppModuleFactory {
  /// Создать AppModule для production
  static AppModule createProduction({
    required String baseUrl,
    SharedPreferences? sharedPreferences,
  }) {
    return AppModule(
      baseUrl: baseUrl,
      sharedPreferences: sharedPreferences,
    );
  }

  /// Создать AppModule для разработки
  static AppModule createDevelopment({
    required String baseUrl,
    SharedPreferences? sharedPreferences,
  }) {
    // В dev режиме можно включить дополнительные флаги
    return AppModule(
      baseUrl: baseUrl,
      sharedPreferences: sharedPreferences,
    );
  }

  /// Создать AppModule для тестирования
  static AppModule createTest({
    String baseUrl = 'http://localhost:8000',
    SharedPreferences? sharedPreferences,
  }) {
    return AppModule(
      baseUrl: baseUrl,
      sharedPreferences: sharedPreferences,
    );
  }

  /// Вывести отчет о текущей конфигурации
  static String getConfigurationReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== AppModule Configuration ===');
    buffer.writeln();
    buffer.writeln('Feature Flags:');
    buffer.writeln(FeatureFlags.getReport());
    buffer.writeln();
    buffer.writeln('Modules:');
    buffer.writeln('  ✅ CoreModule');
    buffer.writeln('  ✅ NetworkModule');
    buffer.writeln('  ✅ AuthModule');
    buffer.writeln('  ✅ ServerSettingsModule');
    buffer.writeln('  ✅ SessionModule');
    buffer.writeln('  ${FeatureFlags.useUnifiedApproval ? "✅" : "⚠️"} ApprovalModule (${FeatureFlags.useUnifiedApproval ? "Unified" : "Legacy"})');
    buffer.writeln('  ✅ ToolModule');
    buffer.writeln('  ✅ AgentChatModule');
    return buffer.toString();
  }
}
