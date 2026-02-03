// Базовый интерфейс для BLoC middleware
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/agent_chat_bloc.dart';

/// Базовый интерфейс для middleware в AgentChatBloc
///
/// Middleware позволяет разделить сложную логику обработки событий
/// на отдельные, переиспользуемые компоненты.
///
/// Каждый middleware отвечает за обработку определенного типа событий
/// или выполнение определенной логики (например, выполнение tools,
/// управление approvals, обработка сообщений).
///
/// Пример использования:
/// ```dart
/// class MyMiddleware implements BlocMiddleware {
///   @override
///   Future<void> handle(
///     AgentChatEvent event,
///     Emitter<AgentChatState> emit,
///     AgentChatBloc bloc,
///   ) async {
///     // Обработка события
///   }
/// }
/// ```
abstract class BlocMiddleware {
  /// Обрабатывает событие
  ///
  /// Параметры:
  /// - [event] - событие для обработки
  /// - [emit] - функция для эмиссии новых состояний
  /// - [bloc] - ссылка на BLoC для доступа к текущему состоянию
  ///
  /// Возвращает true если событие было обработано и не требует
  /// дальнейшей обработки, false если нужно продолжить обработку.
  Future<bool> handle(
    AgentChatEvent event,
    Emitter<AgentChatState> emit,
    AgentChatBloc bloc,
  );

  /// Проверяет, может ли middleware обработать данное событие
  ///
  /// Используется для фильтрации событий перед обработкой.
  /// По умолчанию возвращает true (обрабатывает все события).
  bool canHandle(AgentChatEvent event) => true;
}

/// Композитный middleware, объединяющий несколько middleware
///
/// Выполняет middleware по порядку, останавливаясь на первом,
/// который вернул true (событие полностью обработано).
///
/// Пример:
/// ```dart
/// final composite = CompositeMiddleware([
///   MessageHandlerMiddleware(),
///   ToolExecutionMiddleware(),
///   ApprovalMiddleware(),
/// ]);
/// ```
class CompositeMiddleware implements BlocMiddleware {
  final List<BlocMiddleware> _middlewares;

  CompositeMiddleware(this._middlewares);

  @override
  Future<bool> handle(
    AgentChatEvent event,
    Emitter<AgentChatState> emit,
    AgentChatBloc bloc,
  ) async {
    for (final middleware in _middlewares) {
      if (middleware.canHandle(event)) {
        final handled = await middleware.handle(event, emit, bloc);
        if (handled) {
          return true; // Событие полностью обработано
        }
      }
    }
    return false; // Событие не обработано, продолжить стандартную обработку
  }

  @override
  bool canHandle(AgentChatEvent event) {
    return _middlewares.any((m) => m.canHandle(event));
  }
}

/// Middleware для логирования событий
///
/// Логирует все события и состояния для отладки.
/// Не изменяет поведение, только добавляет логирование.
class LoggingMiddleware implements BlocMiddleware {
  @override
  Future<bool> handle(
    AgentChatEvent event,
    Emitter<AgentChatState> emit,
    AgentChatBloc bloc,
  ) async {
    // Логируем событие
    print('[LoggingMiddleware] Event: ${event.runtimeType}');
    print('[LoggingMiddleware] Current state: ${bloc.state}');
    
    // Не обрабатываем событие, только логируем
    return false;
  }

  @override
  bool canHandle(AgentChatEvent event) => true; // Логируем все события
}
