import 'package:fluent_ui/fluent_ui.dart';

/// Типы агентов в мультиагентной системе
enum AgentType {
  orchestrator,
  coder,
  architect,
  debug,
  ask;

  /// Отображаемое имя агента
  String get displayName {
    switch (this) {
      case AgentType.orchestrator:
        return 'Orchestrator';
      case AgentType.coder:
        return 'Coder';
      case AgentType.architect:
        return 'Architect';
      case AgentType.debug:
        return 'Debug';
      case AgentType.ask:
        return 'Ask';
    }
  }

  /// Иконка агента (emoji)
  String get icon {
    switch (this) {
      case AgentType.orchestrator:
        return '🎭';
      case AgentType.coder:
        return '💻';
      case AgentType.architect:
        return '🏗️';
      case AgentType.debug:
        return '🐛';
      case AgentType.ask:
        return '💬';
    }
  }

  /// Цвет агента для UI
  Color get color {
    switch (this) {
      case AgentType.orchestrator:
        return Colors.red.lighter;
      case AgentType.coder:
        return Colors.blue.lighter;
      case AgentType.architect:
        return Colors.green.lighter;
      case AgentType.debug:
        return Colors.orange.lighter;
      case AgentType.ask:
        return Colors.purple.lighter;
    }
  }

  /// Описание агента
  String get description {
    switch (this) {
      case AgentType.orchestrator:
        return 'Coordinates and routes tasks to specialists';
      case AgentType.coder:
        return 'Writes and modifies code';
      case AgentType.architect:
        return 'Designs architecture and creates specifications';
      case AgentType.debug:
        return 'Investigates errors and debugs issues';
      case AgentType.ask:
        return 'Answers questions and explains concepts';
    }
  }

  /// Парсинг из строки
  static AgentType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'orchestrator':
        return AgentType.orchestrator;
      case 'coder':
        return AgentType.coder;
      case 'architect':
        return AgentType.architect;
      case 'debug':
        return AgentType.debug;
      case 'ask':
        return AgentType.ask;
      default:
        return AgentType.orchestrator;
    }
  }

  /// Конвертация в строку для API
  String toApiString() {
    return name;
  }
}

/// Событие переключения агента
class AgentSwitchEvent {
  final AgentType fromAgent;
  final AgentType toAgent;
  final String reason;
  final String? confidence;
  final DateTime timestamp;

  AgentSwitchEvent({
    required this.fromAgent,
    required this.toAgent,
    required this.reason,
    this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Создание из JSON (из WebSocket)
  factory AgentSwitchEvent.fromJson(Map<String, dynamic> json) {
    return AgentSwitchEvent(
      fromAgent: AgentType.fromString(json['from_agent'] as String),
      toAgent: AgentType.fromString(json['to_agent'] as String),
      reason: json['reason'] as String,
      confidence: json['confidence'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'from_agent': fromAgent.toApiString(),
      'to_agent': toAgent.toApiString(),
      'reason': reason,
      if (confidence != null) 'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Информация об агенте
class AgentInfo {
  final AgentType type;
  final String name;
  final String description;
  final List<String> allowedTools;
  final bool hasFileRestrictions;

  AgentInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.allowedTools,
    required this.hasFileRestrictions,
  });

  /// Создание из JSON (из API)
  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      type: AgentType.fromString(json['type'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      allowedTools: (json['allowed_tools'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hasFileRestrictions: json['has_file_restrictions'] as bool,
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toApiString(),
      'name': name,
      'description': description,
      'allowed_tools': allowedTools,
      'has_file_restrictions': hasFileRestrictions,
    };
  }
}
