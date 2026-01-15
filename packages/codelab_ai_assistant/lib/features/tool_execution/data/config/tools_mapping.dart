/// Mapping таблица между agent-runtime tools и IDE реализацией
/// 
/// Этот файл содержит полную спецификацию всех tools, используемых в системе,
/// и служит источником истины для проверки совместимости между agent-runtime и IDE.
library;

/// Спецификация одного tool parameter
class ToolParameterSpec {
  final String name;
  final String type;
  final bool required;
  final dynamic defaultValue;
  final String? description;
  final List<String>? enumValues;
  final int? minimum;
  final int? maximum;

  const ToolParameterSpec({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.description,
    this.enumValues,
    this.minimum,
    this.maximum,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'required': required,
        if (defaultValue != null) 'default': defaultValue,
        if (description != null) 'description': description,
        if (enumValues != null) 'enum': enumValues,
        if (minimum != null) 'minimum': minimum,
        if (maximum != null) 'maximum': maximum,
      };
}

/// Спецификация tool
class ToolSpec {
  final String name;
  final String description;
  final List<ToolParameterSpec> parameters;
  final ToolExecutionLocation executionLocation;
  final bool requiresApproval;
  final String? agentRuntimeFile;
  final String? ideImplementationFile;

  const ToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
    required this.executionLocation,
    this.requiresApproval = false,
    this.agentRuntimeFile,
    this.ideImplementationFile,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'execution_location': executionLocation.name,
        'requires_approval': requiresApproval,
        if (agentRuntimeFile != null) 'agent_runtime_file': agentRuntimeFile,
        if (ideImplementationFile != null)
          'ide_implementation_file': ideImplementationFile,
      };
}

/// Место выполнения tool
enum ToolExecutionLocation {
  /// Выполняется на стороне agent-runtime (сервер)
  agentRuntime,

  /// Выполняется на стороне IDE (клиент)
  ide,
}

/// Полный реестр всех tools в системе
class ToolsRegistry {
  /// Локальные tools (выполняются в agent-runtime)
  static const List<ToolSpec> localTools = [
    ToolSpec(
      name: 'echo',
      description: 'Echo any text string',
      executionLocation: ToolExecutionLocation.agentRuntime,
      requiresApproval: false,
      agentRuntimeFile: 'app/services/tool_registry.py:18',
      parameters: [
        ToolParameterSpec(
          name: 'text',
          type: 'string',
          required: true,
          description: 'Text to echo',
        ),
      ],
    ),
    ToolSpec(
      name: 'calculator',
      description: 'Calculate a math expression',
      executionLocation: ToolExecutionLocation.agentRuntime,
      requiresApproval: false,
      agentRuntimeFile: 'app/services/tool_registry.py:23',
      parameters: [
        ToolParameterSpec(
          name: 'expr',
          type: 'string',
          required: true,
          description: 'Math expression to evaluate',
        ),
      ],
    ),
    ToolSpec(
      name: 'switch_mode',
      description:
          'Switch to a different agent mode when the current agent cannot handle the task',
      executionLocation: ToolExecutionLocation.agentRuntime,
      requiresApproval: false,
      agentRuntimeFile: 'app/services/tool_registry.py:36',
      parameters: [
        ToolParameterSpec(
          name: 'mode',
          type: 'string',
          required: true,
          description: 'Target agent mode to switch to',
          enumValues: ['orchestrator', 'coder', 'architect', 'debug', 'ask'],
        ),
        ToolParameterSpec(
          name: 'reason',
          type: 'string',
          required: false,
          description: 'Reason for switching modes',
          defaultValue: 'Task requires different agent capabilities',
        ),
      ],
    ),
    ToolSpec(
      name: 'create_plan',
      description:
          'Create an execution plan for complex tasks by breaking them down into subtasks',
      executionLocation: ToolExecutionLocation.agentRuntime,
      requiresApproval: false,
      agentRuntimeFile: 'app/services/tool_registry.py:55',
      parameters: [
        ToolParameterSpec(
          name: 'subtasks',
          type: 'array',
          required: true,
          description: 'List of subtasks to execute in order',
        ),
      ],
    ),
  ];

  /// IDE-side tools (выполняются в codelab_ai_assistant)
  static const List<ToolSpec> ideTools = [
    ToolSpec(
      name: 'read_file',
      description:
          'Read content from a file on disk. Supports partial reading by line numbers.',
      executionLocation: ToolExecutionLocation.ide,
      requiresApproval: false,
      agentRuntimeFile: 'app/services/tool_registry.py:215',
      ideImplementationFile:
          'lib/features/tool_execution/data/datasources/tool_executor_datasource.dart:102',
      parameters: [
        ToolParameterSpec(
          name: 'path',
          type: 'string',
          required: true,
          description: 'Path to the file relative to project workspace',
        ),
        ToolParameterSpec(
          name: 'encoding',
          type: 'string',
          required: false,
          description: 'File encoding',
          defaultValue: 'utf-8',
        ),
        ToolParameterSpec(
          name: 'start_line',
          type: 'integer',
          required: false,
          description: 'Starting line number (1-based, inclusive)',
          minimum: 1,
        ),
        ToolParameterSpec(
          name: 'end_line',
          type: 'integer',
          required: false,
          description: 'Ending line number (1-based, inclusive)',
          minimum: 1,
        ),
      ],
    ),
    ToolSpec(
      name: 'write_file',
      description:
          'Write content to a file. Requires user confirmation before execution.',
      executionLocation: ToolExecutionLocation.ide,
      requiresApproval: true,
      agentRuntimeFile: 'app/services/tool_registry.py:247',
      ideImplementationFile:
          'lib/features/tool_execution/data/datasources/tool_executor_datasource.dart:145',
      parameters: [
        ToolParameterSpec(
          name: 'path',
          type: 'string',
          required: true,
          description: 'Path to the file relative to project workspace',
        ),
        ToolParameterSpec(
          name: 'content',
          type: 'string',
          required: true,
          description: 'Content to write to the file',
        ),
        ToolParameterSpec(
          name: 'encoding',
          type: 'string',
          required: false,
          description: 'File encoding',
          defaultValue: 'utf-8',
        ),
        ToolParameterSpec(
          name: 'create_dirs',
          type: 'boolean',
          required: false,
          description: "Create parent directories if they don't exist",
          defaultValue: false,
        ),
        ToolParameterSpec(
          name: 'backup',
          type: 'boolean',
          required: false,
          description: 'Create backup before overwriting existing file',
          defaultValue: true,
        ),
      ],
    ),
    ToolSpec(
      name: 'list_files',
      description:
          'List files and directories in the specified path within workspace.',
      executionLocation: ToolExecutionLocation.ide,
      requiresApproval: false,
      agentRuntimeFile: 'app/services/tool_registry.py:283',
      ideImplementationFile:
          'lib/features/tool_execution/data/datasources/tool_executor_datasource.dart:166',
      parameters: [
        ToolParameterSpec(
          name: 'path',
          type: 'string',
          required: true,
          description:
              "Relative path to directory within workspace. Use '.' for workspace root.",
        ),
        ToolParameterSpec(
          name: 'recursive',
          type: 'boolean',
          required: false,
          description: 'If true, list files recursively in subdirectories',
          defaultValue: false,
        ),
        ToolParameterSpec(
          name: 'include_hidden',
          type: 'boolean',
          required: false,
          description: 'If true, include hidden files (starting with .)',
          defaultValue: false,
        ),
        ToolParameterSpec(
          name: 'pattern',
          type: 'string',
          required: false,
          description:
              "Optional glob pattern to filter files (e.g., '*.dart', '**/*.yaml')",
        ),
      ],
    ),
    ToolSpec(
      name: 'create_directory',
      description:
          'Create a new directory at the specified path within workspace.',
      executionLocation: ToolExecutionLocation.ide,
      requiresApproval: true,
      agentRuntimeFile: 'app/services/tool_registry.py:314',
      ideImplementationFile:
          'lib/features/tool_execution/data/datasources/tool_executor_datasource.dart:188',
      parameters: [
        ToolParameterSpec(
          name: 'path',
          type: 'string',
          required: true,
          description: 'Relative path for the new directory within workspace',
        ),
        ToolParameterSpec(
          name: 'recursive',
          type: 'boolean',
          required: false,
          description: 'If true, create parent directories as needed',
          defaultValue: true,
        ),
      ],
    ),
    ToolSpec(
      name: 'execute_command',
      description:
          'Execute a shell command in the workspace. Dangerous commands require user approval.',
      executionLocation: ToolExecutionLocation.ide,
      requiresApproval: true,
      agentRuntimeFile: 'app/services/tool_registry.py:336',
      ideImplementationFile:
          'lib/features/tool_execution/data/datasources/tool_executor_datasource.dart:214',
      parameters: [
        ToolParameterSpec(
          name: 'command',
          type: 'string',
          required: true,
          description:
              "Command to execute (e.g., 'flutter pub get', 'git status')",
        ),
        ToolParameterSpec(
          name: 'cwd',
          type: 'string',
          required: false,
          description: 'Working directory relative to workspace root',
        ),
        ToolParameterSpec(
          name: 'timeout',
          type: 'integer',
          required: false,
          description: 'Timeout in seconds (default: 60, max: 300)',
          defaultValue: 60,
          minimum: 1,
          maximum: 300,
        ),
        ToolParameterSpec(
          name: 'shell',
          type: 'boolean',
          required: false,
          description: 'Run command through shell',
          defaultValue: false,
        ),
      ],
    ),
    ToolSpec(
      name: 'search_in_code',
      description: 'Search for text patterns in code files using grep.',
      executionLocation: ToolExecutionLocation.ide,
      requiresApproval: false,
      agentRuntimeFile: 'app/services/tool_registry.py:367',
      ideImplementationFile:
          'lib/features/tool_execution/data/datasources/tool_executor_datasource.dart:234',
      parameters: [
        ToolParameterSpec(
          name: 'query',
          type: 'string',
          required: true,
          description: 'Search query (text or regex pattern)',
        ),
        ToolParameterSpec(
          name: 'path',
          type: 'string',
          required: false,
          description: 'Directory path to search in (default: workspace root)',
          defaultValue: '.',
        ),
        ToolParameterSpec(
          name: 'file_pattern',
          type: 'string',
          required: false,
          description:
              "Glob pattern to filter files (e.g., '*.dart', '*.yaml')",
        ),
        ToolParameterSpec(
          name: 'case_sensitive',
          type: 'boolean',
          required: false,
          description: 'Case-sensitive search',
          defaultValue: false,
        ),
        ToolParameterSpec(
          name: 'regex',
          type: 'boolean',
          required: false,
          description: 'Treat query as regex pattern',
          defaultValue: false,
        ),
        ToolParameterSpec(
          name: 'max_results',
          type: 'integer',
          required: false,
          description: 'Maximum number of results (default: 100, max: 1000)',
          defaultValue: 100,
          minimum: 1,
          maximum: 1000,
        ),
      ],
    ),
  ];

  /// Все tools (локальные + IDE)
  static List<ToolSpec> get allTools => [...localTools, ...ideTools];

  /// Получить tool по имени
  static ToolSpec? getToolByName(String name) {
    try {
      return allTools.firstWhere((tool) => tool.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Получить все IDE tools
  static List<ToolSpec> get getIdeTools =>
      allTools.where((t) => t.executionLocation == ToolExecutionLocation.ide).toList();

  /// Получить все локальные tools
  static List<ToolSpec> get getLocalTools =>
      allTools.where((t) => t.executionLocation == ToolExecutionLocation.agentRuntime).toList();

  /// Получить все tools, требующие подтверждения
  static List<ToolSpec> get getToolsRequiringApproval =>
      allTools.where((t) => t.requiresApproval).toList();

  /// Проверить, поддерживается ли tool в IDE
  static bool isToolSupportedInIde(String toolName) {
    final tool = getToolByName(toolName);
    return tool != null && tool.executionLocation == ToolExecutionLocation.ide;
  }

  /// Проверить, требует ли tool подтверждения
  static bool doesToolRequireApproval(String toolName) {
    final tool = getToolByName(toolName);
    return tool?.requiresApproval ?? false;
  }

  /// Экспортировать спецификацию в JSON
  static Map<String, dynamic> toJson() => {
        'version': '1.0.0',
        'local_tools': localTools.map((t) => t.toJson()).toList(),
        'ide_tools': ideTools.map((t) => t.toJson()).toList(),
        'total_tools': allTools.length,
      };
}
