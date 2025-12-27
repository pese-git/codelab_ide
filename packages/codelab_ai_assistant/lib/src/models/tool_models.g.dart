// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => ToolCall(
  callId: json['call_id'] as String,
  toolName: json['tool_name'] as String,
  arguments: json['arguments'] as Map<String, dynamic>,
  requiresConfirmation: json['requires_confirmation'] as bool? ?? false,
);

Map<String, dynamic> _$ToolCallToJson(ToolCall instance) => <String, dynamic>{
  'call_id': instance.callId,
  'tool_name': instance.toolName,
  'arguments': instance.arguments,
  'requires_confirmation': instance.requiresConfirmation,
};

ToolResult _$ToolResultFromJson(Map<String, dynamic> json) => ToolResult(
  callId: json['call_id'] as String,
  result: json['result'] == null
      ? null
      : FileOperationResult.fromJson(json['result'] as Map<String, dynamic>),
  error: json['error'] as String?,
);

Map<String, dynamic> _$ToolResultToJson(ToolResult instance) =>
    <String, dynamic>{
      'call_id': instance.callId,
      'result': instance.result,
      'error': instance.error,
    };

FileOperationResult _$FileOperationResultFromJson(Map<String, dynamic> json) =>
    FileOperationResult(
      success: json['success'] as bool,
      content: json['content'] as String?,
      linesRead: (json['lines_read'] as num?)?.toInt(),
      bytesWritten: (json['bytes_written'] as num?)?.toInt(),
      backupPath: json['backup_path'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$FileOperationResultToJson(
  FileOperationResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'content': instance.content,
  'lines_read': instance.linesRead,
  'bytes_written': instance.bytesWritten,
  'backup_path': instance.backupPath,
  'error': instance.error,
};

ReadFileArgs _$ReadFileArgsFromJson(Map<String, dynamic> json) => ReadFileArgs(
  path: json['path'] as String,
  encoding: json['encoding'] as String? ?? 'utf-8',
  startLine: (json['start_line'] as num?)?.toInt(),
  endLine: (json['end_line'] as num?)?.toInt(),
);

Map<String, dynamic> _$ReadFileArgsToJson(ReadFileArgs instance) =>
    <String, dynamic>{
      'path': instance.path,
      'encoding': instance.encoding,
      'start_line': instance.startLine,
      'end_line': instance.endLine,
    };

WriteFileArgs _$WriteFileArgsFromJson(Map<String, dynamic> json) =>
    WriteFileArgs(
      path: json['path'] as String,
      content: json['content'] as String,
      encoding: json['encoding'] as String? ?? 'utf-8',
      createDirs: json['create_dirs'] as bool? ?? false,
      backup: json['backup'] as bool? ?? true,
    );

Map<String, dynamic> _$WriteFileArgsToJson(WriteFileArgs instance) =>
    <String, dynamic>{
      'path': instance.path,
      'content': instance.content,
      'encoding': instance.encoding,
      'create_dirs': instance.createDirs,
      'backup': instance.backup,
    };
