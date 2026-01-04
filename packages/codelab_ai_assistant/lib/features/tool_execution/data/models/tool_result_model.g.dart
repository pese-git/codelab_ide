// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ToolResultModel _$ToolResultModelFromJson(Map<String, dynamic> json) =>
    _ToolResultModel(
      callId: json['call_id'] as String,
      toolName: json['tool_name'] as String,
      success: json['success'] as bool,
      result: json['result'] as Map<String, dynamic>?,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      durationMs: (json['duration_ms'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ToolResultModelToJson(_ToolResultModel instance) =>
    <String, dynamic>{
      'call_id': instance.callId,
      'tool_name': instance.toolName,
      'success': instance.success,
      'result': instance.result,
      'error_code': instance.errorCode,
      'error_message': instance.errorMessage,
      'details': instance.details,
      'duration_ms': instance.durationMs,
    };
