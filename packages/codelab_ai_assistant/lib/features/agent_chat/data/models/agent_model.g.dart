// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgentModel _$AgentModelFromJson(Map<String, dynamic> json) => _AgentModel(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  icon: json['icon'] as String,
  isAvailable: json['is_available'] as bool? ?? true,
  capabilities:
      (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AgentModelToJson(_AgentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'is_available': instance.isAvailable,
      'capabilities': instance.capabilities,
      'metadata': instance.metadata,
    };
