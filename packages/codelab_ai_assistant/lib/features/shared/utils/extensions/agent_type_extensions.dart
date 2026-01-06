// Extension для маппинга между domain AgentType и uikit AgentType
import 'package:codelab_uikit/codelab_uikit.dart' as uikit;

/// Extension для конвертации между domain и UI типами агентов
extension AgentTypeMapping on String {
  /// Конвертировать строку в uikit.AgentType
  uikit.AgentType toUikitAgentType() {
    switch (toLowerCase()) {
      case 'orchestrator':
        return uikit.AgentType.orchestrator;
      case 'code':
      case 'coder':
        return uikit.AgentType.coder;
      case 'architect':
        return uikit.AgentType.architect;
      case 'debug':
        return uikit.AgentType.debug;
      case 'ask':
        return uikit.AgentType.ask;
      default:
        return uikit.AgentType.orchestrator;
    }
  }
  
  /// Конвертировать строку в domain AgentType
  String toDomainAgentType() {
    // Domain использует строки напрямую, просто возвращаем нормализованную версию
    switch (toLowerCase()) {
      case 'code':
        return 'coder';
      default:
        return toLowerCase();
    }
  }
}

/// Extension для uikit.AgentType
extension UikitAgentTypeExtension on uikit.AgentType {
  /// Конвертировать в строку для domain/API
  String toDomainString() {
    return toApiString();
  }
}
