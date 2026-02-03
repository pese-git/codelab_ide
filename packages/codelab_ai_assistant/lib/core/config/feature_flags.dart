/// Feature flags для управления постепенной миграцией и A/B тестированием
///
/// Используется для безопасного внедрения новых функций и рефакторинга
/// без нарушения существующей функциональности.
class FeatureFlags {
  // Приватный конструктор для предотвращения создания экземпляров
  FeatureFlags._();

  // =========================================================================
  // Фаза 2: Unified Approval System
  // =========================================================================

  /// Использовать новую унифицированную систему approvals
  ///
  /// true - использовать ApprovalService (новая система)
  /// false - использовать ToolApprovalService (legacy)
  ///
  /// Статус: В разработке
  /// Планируемая дата включения: Фаза 2 (неделя 3-4)
  static const bool useUnifiedApproval = false;

  /// Включить восстановление pending approvals через новую систему
  ///
  /// Требует: useUnifiedApproval = true
  ///
  /// Статус: В разработке
  static const bool useUnifiedApprovalRestore = false;

  // =========================================================================
  // Фаза 3: Модульный DI
  // =========================================================================

  /// Использовать новую модульную DI конфигурацию
  ///
  /// true - использовать AppModule с feature modules
  /// false - использовать AiAssistantModule (legacy)
  ///
  /// Статус: Запланировано
  /// Планируемая дата включения: Фаза 3 (неделя 5)
  static const bool useModularDI = false;

  // =========================================================================
  // Фаза 4: BLoC Middleware
  // =========================================================================

  /// Использовать middleware для обработки сообщений в AgentChatBloc
  ///
  /// true - использовать MessageHandlerMiddleware и другие
  /// false - использовать встроенную логику в BLoC
  ///
  /// Статус: Запланировано
  /// Планируемая дата включения: Фаза 4 (неделя 6-7)
  static const bool useBlocMiddleware = false;

  /// Использовать отдельный ToolExecutionMiddleware
  ///
  /// Требует: useBlocMiddleware = true
  ///
  /// Статус: Запланировано
  static const bool useToolExecutionMiddleware = false;

  /// Использовать отдельный ApprovalMiddleware
  ///
  /// Требует: useBlocMiddleware = true
  ///
  /// Статус: Запланировано
  static const bool useApprovalMiddleware = false;

  // =========================================================================
  // Фаза 5: Улучшения
  // =========================================================================

  /// Загружать список агентов с сервера вместо хардкода
  ///
  /// Статус: Запланировано
  /// Планируемая дата включения: Фаза 5 (неделя 8)
  static const bool loadAgentsFromServer = false;

  /// Использовать автоматическое переподключение WebSocket
  ///
  /// Статус: Запланировано
  /// Планируемая дата включения: Фаза 5 (неделя 8-9)
  static const bool useAutoReconnect = false;

  /// Максимальное количество попыток переподключения
  ///
  /// Используется только если useAutoReconnect = true
  static const int maxReconnectAttempts = 5;

  /// Задержка между попытками переподключения (в секундах)
  ///
  /// Используется только если useAutoReconnect = true
  static const int reconnectDelaySeconds = 3;

  /// Включить сбор метрик производительности
  ///
  /// Статус: Запланировано
  /// Планируемая дата включения: Фаза 5 (неделя 9)
  static const bool enablePerformanceMetrics = false;

  /// Включить аналитику использования
  ///
  /// Статус: Запланировано
  static const bool enableAnalytics = false;

  // =========================================================================
  // Отладка и разработка
  // =========================================================================

  /// Включить детальное логирование для отладки
  ///
  /// ВНИМАНИЕ: Не использовать в production!
  static const bool enableVerboseLogging = false;

  /// Включить логирование WebSocket сообщений
  ///
  /// ВНИМАНИЕ: Может содержать чувствительные данные!
  static const bool logWebSocketMessages = false;

  /// Включить симуляцию сетевых ошибок для тестирования
  ///
  /// Используется только в тестах
  static const bool simulateNetworkErrors = false;

  /// Задержка для симуляции медленной сети (в миллисекундах)
  ///
  /// Используется только если simulateNetworkErrors = true
  static const int networkDelayMs = 1000;

  // =========================================================================
  // Экспериментальные функции
  // =========================================================================

  /// Использовать кэширование для списка агентов
  ///
  /// Статус: Экспериментально
  static const bool useAgentCaching = false;

  /// Время жизни кэша агентов (в часах)
  ///
  /// Используется только если useAgentCaching = true
  static const int agentCacheTTLHours = 1;

  /// Использовать debounce для отправки сообщений
  ///
  /// Статус: Экспериментально
  static const bool useMessageDebounce = false;

  /// Задержка debounce для сообщений (в миллисекундах)
  ///
  /// Используется только если useMessageDebounce = true
  static const int messageDebounceMs = 300;

  /// Использовать lazy loading для истории сообщений
  ///
  /// Статус: Экспериментально
  static const bool useLazyLoadHistory = false;

  /// Количество сообщений для загрузки за раз
  ///
  /// Используется только если useLazyLoadHistory = true
  static const int historyPageSize = 50;

  // =========================================================================
  // Утилиты
  // =========================================================================

  /// Проверить, все ли зависимости для флага выполнены
  static bool canEnable(String flagName) {
    switch (flagName) {
      case 'useUnifiedApprovalRestore':
        return useUnifiedApproval;
      case 'useToolExecutionMiddleware':
      case 'useApprovalMiddleware':
        return useBlocMiddleware;
      case 'maxReconnectAttempts':
      case 'reconnectDelaySeconds':
        return useAutoReconnect;
      case 'agentCacheTTLHours':
        return useAgentCaching;
      case 'messageDebounceMs':
        return useMessageDebounce;
      case 'historyPageSize':
        return useLazyLoadHistory;
      case 'networkDelayMs':
        return simulateNetworkErrors;
      default:
        return true;
    }
  }

  /// Получить описание флага
  static String getDescription(String flagName) {
    // Можно расширить для динамического получения описаний
    return 'Feature flag: $flagName';
  }

  /// Получить все активные флаги
  static Map<String, bool> getActiveFlags() {
    return {
      'useUnifiedApproval': useUnifiedApproval,
      'useUnifiedApprovalRestore': useUnifiedApprovalRestore,
      'useModularDI': useModularDI,
      'useBlocMiddleware': useBlocMiddleware,
      'useToolExecutionMiddleware': useToolExecutionMiddleware,
      'useApprovalMiddleware': useApprovalMiddleware,
      'loadAgentsFromServer': loadAgentsFromServer,
      'useAutoReconnect': useAutoReconnect,
      'enablePerformanceMetrics': enablePerformanceMetrics,
      'enableAnalytics': enableAnalytics,
      'enableVerboseLogging': enableVerboseLogging,
      'logWebSocketMessages': logWebSocketMessages,
      'simulateNetworkErrors': simulateNetworkErrors,
      'useAgentCaching': useAgentCaching,
      'useMessageDebounce': useMessageDebounce,
      'useLazyLoadHistory': useLazyLoadHistory,
    };
  }

  /// Вывести отчет о состоянии флагов
  static String getReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Feature Flags Report ===');
    buffer.writeln();

    final flags = getActiveFlags();
    final enabled = flags.entries.where((e) => e.value).map((e) => e.key);
    final disabled = flags.entries.where((e) => !e.value).map((e) => e.key);

    buffer.writeln('Enabled (${enabled.length}):');
    for (final flag in enabled) {
      buffer.writeln('  ✅ $flag');
    }

    buffer.writeln();
    buffer.writeln('Disabled (${disabled.length}):');
    for (final flag in disabled) {
      buffer.writeln('  ❌ $flag');
    }

    return buffer.toString();
  }
}
