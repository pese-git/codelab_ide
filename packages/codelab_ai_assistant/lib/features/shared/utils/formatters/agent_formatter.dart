// Утилиты для форматирования информации об агентах
/// Форматирование информации об агентах для UI
class AgentFormatter {
  AgentFormatter._();

  /// Форматирует имя агента с эмодзи
  static String formatAgentName(String agentType) {
    final agentNames = {
      'orchestrator': '🪃 Orchestrator',
      'coder': '💻 Code',
      'code': '💻 Code',
      'architect': '🏗️ Architect',
      'debug': '🪲 Debug',
      'ask': '❓ Ask',
    };
    return agentNames[agentType.toLowerCase()] ?? agentType;
  }

  /// Получает только эмодзи агента
  static String getAgentEmoji(String agentType) {
    final emojis = {
      'orchestrator': '🪃',
      'coder': '💻',
      'code': '💻',
      'architect': '🏗️',
      'debug': '🪲',
      'ask': '❓',
    };
    return emojis[agentType.toLowerCase()] ?? '🤖';
  }

  /// Получает короткое имя агента без эмодзи
  static String getAgentShortName(String agentType) {
    final names = {
      'orchestrator': 'Orchestrator',
      'coder': 'Code',
      'code': 'Code',
      'architect': 'Architect',
      'debug': 'Debug',
      'ask': 'Ask',
    };
    return names[agentType.toLowerCase()] ?? agentType;
  }

  /// Получает описание агента
  static String getAgentDescription(String agentType) {
    final descriptions = {
      'orchestrator': 'Coordinates complex multi-step tasks',
      'coder': 'Writes and modifies code',
      'code': 'Writes and modifies code',
      'architect': 'Plans and designs system architecture',
      'debug': 'Troubleshoots and fixes issues',
      'ask': 'Answers questions and provides explanations',
    };
    return descriptions[agentType.toLowerCase()] ?? 'AI Assistant';
  }
}
