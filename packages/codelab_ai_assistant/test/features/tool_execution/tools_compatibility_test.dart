/// Интеграционные тесты для проверки совместимости tools
/// между agent-runtime и IDE реализацией
import 'package:codelab_ai_assistant/features/tool_execution/data/config/tools_mapping.dart';
import 'package:codelab_ai_assistant/features/tool_execution/data/datasources/tool_executor_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tools Compatibility Tests', () {
    group('IDE Tools Registration', () {
      test('all IDE tools from registry are supported by executor', () {
        // Arrange
        final ideTools = ToolsRegistry.getIdeTools;
        final supportedTools = ToolExecutorDataSourceImpl.supportedTools;

        // Act & Assert
        for (final tool in ideTools) {
          expect(
            supportedTools.contains(tool.name),
            isTrue,
            reason: 'Tool ${tool.name} from registry is not supported by executor',
          );
        }
      });

      test('executor does not support tools not in registry', () {
        // Arrange
        final allToolNames = ToolsRegistry.allTools.map((t) => t.name).toSet();
        final supportedTools = ToolExecutorDataSourceImpl.supportedTools;

        // Act & Assert
        for (final toolName in supportedTools) {
          // Исключаем алиас run_command (это execute_command)
          if (toolName == 'run_command') continue;

          expect(
            allToolNames.contains(toolName),
            isTrue,
            reason: 'Executor supports tool $toolName which is not in registry',
          );
        }
      });

      test('all IDE tools have implementation file reference', () {
        // Arrange
        final ideTools = ToolsRegistry.getIdeTools;

        // Act & Assert
        for (final tool in ideTools) {
          expect(
            tool.ideImplementationFile,
            isNotNull,
            reason: 'Tool ${tool.name} does not have implementation file reference',
          );
          expect(
            tool.ideImplementationFile!.isNotEmpty,
            isTrue,
            reason: 'Tool ${tool.name} has empty implementation file reference',
          );
        }
      });
    });

    group('Tool Parameters Validation', () {
      test('read_file has all required parameters', () {
        // Arrange
        final tool = ToolsRegistry.getToolByName('read_file');

        // Assert
        expect(tool, isNotNull);
        expect(tool!.parameters.length, equals(4));

        final pathParam = tool.parameters.firstWhere((p) => p.name == 'path');
        expect(pathParam.required, isTrue);
        expect(pathParam.type, equals('string'));

        final encodingParam = tool.parameters.firstWhere((p) => p.name == 'encoding');
        expect(encodingParam.required, isFalse);
        expect(encodingParam.defaultValue, equals('utf-8'));

        final startLineParam = tool.parameters.firstWhere((p) => p.name == 'start_line');
        expect(startLineParam.required, isFalse);
        expect(startLineParam.type, equals('integer'));
        expect(startLineParam.minimum, equals(1));

        final endLineParam = tool.parameters.firstWhere((p) => p.name == 'end_line');
        expect(endLineParam.required, isFalse);
        expect(endLineParam.type, equals('integer'));
        expect(endLineParam.minimum, equals(1));
      });

      test('write_file has all required parameters', () {
        // Arrange
        final tool = ToolsRegistry.getToolByName('write_file');

        // Assert
        expect(tool, isNotNull);
        expect(tool!.parameters.length, equals(5));
        expect(tool.requiresApproval, isTrue);

        final pathParam = tool.parameters.firstWhere((p) => p.name == 'path');
        expect(pathParam.required, isTrue);

        final contentParam = tool.parameters.firstWhere((p) => p.name == 'content');
        expect(contentParam.required, isTrue);

        final createDirsParam = tool.parameters.firstWhere((p) => p.name == 'create_dirs');
        expect(createDirsParam.required, isFalse);
        expect(createDirsParam.defaultValue, equals(false));

        final backupParam = tool.parameters.firstWhere((p) => p.name == 'backup');
        expect(backupParam.required, isFalse);
        expect(backupParam.defaultValue, equals(true));
      });

      test('execute_command has all required parameters', () {
        // Arrange
        final tool = ToolsRegistry.getToolByName('execute_command');

        // Assert
        expect(tool, isNotNull);
        expect(tool!.parameters.length, equals(4));
        expect(tool.requiresApproval, isTrue);

        final commandParam = tool.parameters.firstWhere((p) => p.name == 'command');
        expect(commandParam.required, isTrue);

        final timeoutParam = tool.parameters.firstWhere((p) => p.name == 'timeout');
        expect(timeoutParam.required, isFalse);
        expect(timeoutParam.defaultValue, equals(60));
        expect(timeoutParam.minimum, equals(1));
        expect(timeoutParam.maximum, equals(300));
      });

      test('search_in_code has all required parameters', () {
        // Arrange
        final tool = ToolsRegistry.getToolByName('search_in_code');

        // Assert
        expect(tool, isNotNull);
        expect(tool!.parameters.length, equals(6));

        final queryParam = tool.parameters.firstWhere((p) => p.name == 'query');
        expect(queryParam.required, isTrue);

        final maxResultsParam = tool.parameters.firstWhere((p) => p.name == 'max_results');
        expect(maxResultsParam.required, isFalse);
        expect(maxResultsParam.defaultValue, equals(100));
        expect(maxResultsParam.minimum, equals(1));
        expect(maxResultsParam.maximum, equals(1000));
      });
    });

    group('Tool Execution Location', () {
      test('local tools are marked as agent-runtime execution', () {
        // Arrange
        final localToolNames = ['echo', 'calculator', 'switch_mode', 'create_plan'];

        // Act & Assert
        for (final toolName in localToolNames) {
          final tool = ToolsRegistry.getToolByName(toolName);
          expect(tool, isNotNull, reason: 'Tool $toolName not found in registry');
          expect(
            tool!.executionLocation,
            equals(ToolExecutionLocation.agentRuntime),
            reason: 'Tool $toolName should be executed in agent-runtime',
          );
        }
      });

      test('IDE tools are marked as IDE execution', () {
        // Arrange
        final ideToolNames = [
          'read_file',
          'write_file',
          'list_files',
          'create_directory',
          'execute_command',
          'search_in_code',
        ];

        // Act & Assert
        for (final toolName in ideToolNames) {
          final tool = ToolsRegistry.getToolByName(toolName);
          expect(tool, isNotNull, reason: 'Tool $toolName not found in registry');
          expect(
            tool!.executionLocation,
            equals(ToolExecutionLocation.ide),
            reason: 'Tool $toolName should be executed in IDE',
          );
        }
      });
    });

    group('HITL Approval Requirements', () {
      test('dangerous tools require approval', () {
        // Arrange
        final dangerousTools = ['write_file', 'create_directory', 'execute_command'];

        // Act & Assert
        for (final toolName in dangerousTools) {
          final tool = ToolsRegistry.getToolByName(toolName);
          expect(tool, isNotNull);
          expect(
            tool!.requiresApproval,
            isTrue,
            reason: 'Tool $toolName should require approval',
          );
        }
      });

      test('safe tools do not require approval', () {
        // Arrange
        final safeTools = ['read_file', 'list_files', 'search_in_code'];

        // Act & Assert
        for (final toolName in safeTools) {
          final tool = ToolsRegistry.getToolByName(toolName);
          expect(tool, isNotNull);
          expect(
            tool!.requiresApproval,
            isFalse,
            reason: 'Tool $toolName should not require approval',
          );
        }
      });

      test('helper method correctly identifies approval requirements', () {
        expect(ToolsRegistry.doesToolRequireApproval('write_file'), isTrue);
        expect(ToolsRegistry.doesToolRequireApproval('execute_command'), isTrue);
        expect(ToolsRegistry.doesToolRequireApproval('read_file'), isFalse);
        expect(ToolsRegistry.doesToolRequireApproval('list_files'), isFalse);
      });
    });

    group('Registry Helper Methods', () {
      test('getToolByName returns correct tool', () {
        final tool = ToolsRegistry.getToolByName('read_file');
        expect(tool, isNotNull);
        expect(tool!.name, equals('read_file'));
      });

      test('getToolByName returns null for non-existent tool', () {
        final tool = ToolsRegistry.getToolByName('non_existent_tool');
        expect(tool, isNull);
      });

      test('isToolSupportedInIde correctly identifies IDE tools', () {
        expect(ToolsRegistry.isToolSupportedInIde('read_file'), isTrue);
        expect(ToolsRegistry.isToolSupportedInIde('write_file'), isTrue);
        expect(ToolsRegistry.isToolSupportedInIde('echo'), isFalse);
        expect(ToolsRegistry.isToolSupportedInIde('calculator'), isFalse);
      });

      test('getIdeTools returns only IDE tools', () {
        final ideTools = ToolsRegistry.getIdeTools;
        expect(ideTools.length, equals(6));
        for (final tool in ideTools) {
          expect(tool.executionLocation, equals(ToolExecutionLocation.ide));
        }
      });

      test('getLocalTools returns only local tools', () {
        final localTools = ToolsRegistry.getLocalTools;
        expect(localTools.length, equals(4));
        for (final tool in localTools) {
          expect(tool.executionLocation, equals(ToolExecutionLocation.agentRuntime));
        }
      });

      test('getToolsRequiringApproval returns only tools requiring approval', () {
        final approvalTools = ToolsRegistry.getToolsRequiringApproval;
        expect(approvalTools.length, equals(3));
        for (final tool in approvalTools) {
          expect(tool.requiresApproval, isTrue);
        }
      });
    });

    group('JSON Export', () {
      test('toJson exports complete registry', () {
        final json = ToolsRegistry.toJson();

        expect(json['version'], equals('1.0.0'));
        expect(json['local_tools'], isA<List>());
        expect(json['ide_tools'], isA<List>());
        expect(json['total_tools'], equals(10));
      });

      test('tool spec can be serialized to JSON', () {
        final tool = ToolsRegistry.getToolByName('read_file');
        final json = tool!.toJson();

        expect(json['name'], equals('read_file'));
        expect(json['description'], isNotEmpty);
        expect(json['parameters'], isA<List>());
        expect(json['execution_location'], equals('ide'));
        expect(json['requires_approval'], isFalse);
      });

      test('parameter spec can be serialized to JSON', () {
        final tool = ToolsRegistry.getToolByName('read_file');
        final pathParam = tool!.parameters.firstWhere((p) => p.name == 'path');
        final json = pathParam.toJson();

        expect(json['name'], equals('path'));
        expect(json['type'], equals('string'));
        expect(json['required'], isTrue);
        expect(json['description'], isNotEmpty);
      });
    });

    group('Consistency Checks', () {
      test('all tools have unique names', () {
        final allTools = ToolsRegistry.allTools;
        final names = allTools.map((t) => t.name).toList();
        final uniqueNames = names.toSet();

        expect(
          names.length,
          equals(uniqueNames.length),
          reason: 'Some tools have duplicate names',
        );
      });

      test('all tools have non-empty descriptions', () {
        final allTools = ToolsRegistry.allTools;

        for (final tool in allTools) {
          expect(
            tool.description.isNotEmpty,
            isTrue,
            reason: 'Tool ${tool.name} has empty description',
          );
        }
      });

      test('all tools have at least one parameter', () {
        final allTools = ToolsRegistry.allTools;

        for (final tool in allTools) {
          expect(
            tool.parameters.isNotEmpty,
            isTrue,
            reason: 'Tool ${tool.name} has no parameters',
          );
        }
      });

      test('all required parameters come before optional ones', () {
        final allTools = ToolsRegistry.allTools;

        for (final tool in allTools) {
          bool foundOptional = false;
          for (final param in tool.parameters) {
            if (!param.required) {
              foundOptional = true;
            } else if (foundOptional) {
              fail(
                'Tool ${tool.name} has required parameter ${param.name} '
                'after optional parameters',
              );
            }
          }
        }
      });

      test('all IDE tools have agent-runtime file reference', () {
        final ideTools = ToolsRegistry.getIdeTools;

        for (final tool in ideTools) {
          expect(
            tool.agentRuntimeFile,
            isNotNull,
            reason: 'Tool ${tool.name} does not have agent-runtime file reference',
          );
          expect(
            tool.agentRuntimeFile!.contains('tool_registry.py'),
            isTrue,
            reason: 'Tool ${tool.name} agent-runtime reference does not point to tool_registry.py',
          );
        }
      });
    });

    group('Parameter Type Validation', () {
      test('all parameters have valid types', () {
        final validTypes = ['string', 'integer', 'boolean', 'array', 'object'];
        final allTools = ToolsRegistry.allTools;

        for (final tool in allTools) {
          for (final param in tool.parameters) {
            expect(
              validTypes.contains(param.type),
              isTrue,
              reason: 'Tool ${tool.name} parameter ${param.name} has invalid type: ${param.type}',
            );
          }
        }
      });

      test('integer parameters with minimum have valid values', () {
        final allTools = ToolsRegistry.allTools;

        for (final tool in allTools) {
          for (final param in tool.parameters) {
            if (param.type == 'integer' && param.minimum != null) {
              expect(
                param.minimum! > 0,
                isTrue,
                reason: 'Tool ${tool.name} parameter ${param.name} has invalid minimum: ${param.minimum}',
              );
            }
          }
        }
      });

      test('parameters with enum have non-empty values', () {
        final allTools = ToolsRegistry.allTools;

        for (final tool in allTools) {
          for (final param in tool.parameters) {
            if (param.enumValues != null) {
              expect(
                param.enumValues!.isNotEmpty,
                isTrue,
                reason: 'Tool ${tool.name} parameter ${param.name} has empty enum values',
              );
            }
          }
        }
      });
    });
  });
}
