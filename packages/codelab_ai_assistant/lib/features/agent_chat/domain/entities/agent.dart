// Domain entity для AI агента
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'agent.freezed.dart';

/// Domain entity представляющая AI агента
@freezed
abstract class Agent with _$Agent {
  const factory Agent({
    /// Уникальный идентификатор агента (тип)
    required String id,

    /// Отображаемое имя агента
    required String name,

    /// Описание агента и его возможностей
    required String description,

    /// Иконка агента (emoji или путь)
    required String icon,

    /// Доступен ли агент для использования
    @Default(true) bool isAvailable,

    /// Возможности агента
    @Default([]) List<String> capabilities,

    /// Дополнительные метаданные
    Option<Map<String, dynamic>>? metadata,
  }) = _Agent;

  const Agent._();

  /// Проверяет, поддерживает ли агент определенную возможность
  bool hasCapability(String capability) {
    return capabilities.contains(capability);
  }

  /// Проверяет, является ли агент orchestrator
  bool get isOrchestrator => id == 'orchestrator';

  /// Проверяет, является ли агент coder
  bool get isCoder => id == 'code';

  /// Проверяет, является ли агент architect
  bool get isArchitect => id == 'architect';

  /// Проверяет, является ли агент debugger
  bool get isDebugger => id == 'debug';

  /// Проверяет, является ли агент ask
  bool get isAsk => id == 'ask';
}

/// Предопределенные типы агентов
class AgentType {
  static const String orchestrator = 'orchestrator';
  static const String code = 'code';
  static const String architect = 'architect';
  static const String debug = 'debug';
  static const String ask = 'ask';

  static const List<String> all = [orchestrator, code, architect, debug, ask];

  /// Проверяет, является ли тип валидным
  static bool isValid(String type) => all.contains(type);
}
