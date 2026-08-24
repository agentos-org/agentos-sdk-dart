// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agents_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
  name: json['name'] as String,
  capability: Capability.fromJson(json['capability'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
  'name': instance.name,
  'capability': instance.capability.toJson(),
};
