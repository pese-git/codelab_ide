// lib/ai_agent/integration/tool_api.dart

/// Абстракция для интеграции tool_call из AI agent с системами IDE.
abstract class ToolApi {
  /// Выполнить команду toolCall (название + аргументы).
  /// Должен вернуть результат как Map (или бросать исключение).
  Future<Map<String, dynamic>> call(String toolName, Map<String, dynamic> arguments);
}

/// Заглушка для ToolApi, всегда возвращает успешный результат.
class ToolApiImpl implements ToolApi {
  @override
  Future<Map<String, dynamic>> call(String toolName, Map<String, dynamic> arguments) async {
    // TODO: Имплементировать логику инструментов (read_file, write_file и др.) через сервисы IDE
    // Пока просто возвращаем эхо для демонстрации
    await Future.delayed(const Duration(milliseconds: 200));
    return {'echo_tool': toolName, 'echo_args': arguments};
  }
}

/// Моковая реализация, для тестов/отладки, всегда выбрасывает ошибку
class ToolApiMock implements ToolApi {
  @override
  Future<Map<String, dynamic>> call(String toolName, Map<String, dynamic> arguments) async {
    throw Exception('ToolApiMock: tool [$toolName] не реализован.');
  }
}
