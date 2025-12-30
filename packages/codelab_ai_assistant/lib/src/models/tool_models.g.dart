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

_ListFilesArgs _$ListFilesArgsFromJson(Map<String, dynamic> json) =>
    _ListFilesArgs(
      path: json['path'] as String,
      recursive: json['recursive'] as bool? ?? false,
      includeHidden: json['include_hidden'] as bool? ?? false,
      pattern: json['pattern'] as String?,
    );

Map<String, dynamic> _$ListFilesArgsToJson(_ListFilesArgs instance) =>
    <String, dynamic>{
      'path': instance.path,
      'recursive': instance.recursive,
      'include_hidden': instance.includeHidden,
      'pattern': instance.pattern,
    };

_FileItem _$FileItemFromJson(Map<String, dynamic> json) => _FileItem(
  name: json['name'] as String,
  path: json['path'] as String,
  type: json['type'] as String,
  size: (json['size'] as num?)?.toInt(),
  modified: json['modified'] == null
      ? null
      : DateTime.parse(json['modified'] as String),
);

Map<String, dynamic> _$FileItemToJson(_FileItem instance) => <String, dynamic>{
  'name': instance.name,
  'path': instance.path,
  'type': instance.type,
  'size': instance.size,
  'modified': instance.modified?.toIso8601String(),
};

_ListFilesResult _$ListFilesResultFromJson(Map<String, dynamic> json) =>
    _ListFilesResult(
      success: json['success'] as bool,
      path: json['path'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => FileItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ListFilesResultToJson(_ListFilesResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'path': instance.path,
      'items': instance.items,
      'total_count': instance.totalCount,
      'error': instance.error,
    };

_CreateDirectoryArgs _$CreateDirectoryArgsFromJson(Map<String, dynamic> json) =>
    _CreateDirectoryArgs(
      path: json['path'] as String,
      recursive: json['recursive'] as bool? ?? true,
    );

Map<String, dynamic> _$CreateDirectoryArgsToJson(
  _CreateDirectoryArgs instance,
) => <String, dynamic>{'path': instance.path, 'recursive': instance.recursive};

_CreateDirectoryResult _$CreateDirectoryResultFromJson(
  Map<String, dynamic> json,
) => _CreateDirectoryResult(
  success: json['success'] as bool,
  path: json['path'] as String,
  created: json['created'] as bool,
  alreadyExists: json['already_exists'] as bool,
  error: json['error'] as String?,
);

Map<String, dynamic> _$CreateDirectoryResultToJson(
  _CreateDirectoryResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'path': instance.path,
  'created': instance.created,
  'already_exists': instance.alreadyExists,
  'error': instance.error,
};

_RunCommandArgs _$RunCommandArgsFromJson(Map<String, dynamic> json) =>
    _RunCommandArgs(
      command: json['command'] as String,
      cwd: json['cwd'] as String? ?? '.',
      timeout: (json['timeout'] as num?)?.toInt() ?? 60,
      shell: json['shell'] as bool? ?? false,
    );

Map<String, dynamic> _$RunCommandArgsToJson(_RunCommandArgs instance) =>
    <String, dynamic>{
      'command': instance.command,
      'cwd': instance.cwd,
      'timeout': instance.timeout,
      'shell': instance.shell,
    };

_RunCommandResult _$RunCommandResultFromJson(Map<String, dynamic> json) =>
    _RunCommandResult(
      command: json['command'] as String,
      exitCode: (json['exitCode'] as num).toInt(),
      stdout: json['stdout'] as String,
      stderr: json['stderr'] as String,
      durationMs: (json['durationMs'] as num).toInt(),
      timedOut: json['timedOut'] as bool,
    );

Map<String, dynamic> _$RunCommandResultToJson(_RunCommandResult instance) =>
    <String, dynamic>{
      'command': instance.command,
      'exitCode': instance.exitCode,
      'stdout': instance.stdout,
      'stderr': instance.stderr,
      'durationMs': instance.durationMs,
      'timedOut': instance.timedOut,
    };

_SearchInCodeArgs _$SearchInCodeArgsFromJson(Map<String, dynamic> json) =>
    _SearchInCodeArgs(
      query: json['query'] as String,
      path: json['path'] as String? ?? '.',
      filePattern: json['file_pattern'] as String?,
      caseSensitive: json['case_sensitive'] as bool? ?? false,
      regex: json['regex'] as bool? ?? false,
      maxResults: (json['max_results'] as num?)?.toInt() ?? 100,
    );

Map<String, dynamic> _$SearchInCodeArgsToJson(_SearchInCodeArgs instance) =>
    <String, dynamic>{
      'query': instance.query,
      'path': instance.path,
      'file_pattern': instance.filePattern,
      'case_sensitive': instance.caseSensitive,
      'regex': instance.regex,
      'max_results': instance.maxResults,
    };

_SearchMatch _$SearchMatchFromJson(Map<String, dynamic> json) => _SearchMatch(
  file: json['file'] as String,
  line: (json['line'] as num).toInt(),
  column: (json['column'] as num).toInt(),
  matchedText: json['matched_text'] as String,
  lineContent: json['line_content'] as String,
);

Map<String, dynamic> _$SearchMatchToJson(_SearchMatch instance) =>
    <String, dynamic>{
      'file': instance.file,
      'line': instance.line,
      'column': instance.column,
      'matched_text': instance.matchedText,
      'line_content': instance.lineContent,
    };

_SearchInCodeResult _$SearchInCodeResultFromJson(Map<String, dynamic> json) =>
    _SearchInCodeResult(
      query: json['query'] as String,
      matches: (json['matches'] as List<dynamic>)
          .map((e) => SearchMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalMatches: (json['total_matches'] as num).toInt(),
      truncated: json['truncated'] as bool,
      durationMs: (json['duration_ms'] as num).toInt(),
    );

Map<String, dynamic> _$SearchInCodeResultToJson(_SearchInCodeResult instance) =>
    <String, dynamic>{
      'query': instance.query,
      'matches': instance.matches,
      'total_matches': instance.totalMatches,
      'truncated': instance.truncated,
      'duration_ms': instance.durationMs,
    };
