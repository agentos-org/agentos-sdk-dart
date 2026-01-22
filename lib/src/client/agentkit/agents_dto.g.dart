// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agents_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentId _$AgentIdFromJson(Map<String, dynamic> json) =>
    AgentId(agentId: json['agentId'] as String);

Map<String, dynamic> _$AgentIdToJson(AgentId instance) => <String, dynamic>{
  'agentId': instance.agentId,
};

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
  name: json['name'] as String,
  capability: Capability.fromJson(json['capability'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
  'name': instance.name,
  'capability': instance.capability.toJson(),
};

AgentInfo _$AgentInfoFromJson(Map<String, dynamic> json) => AgentInfo(
  agentId: json['agentId'] as String,
  name: json['name'] as String,
  capability: Capability.fromJson(json['capability'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AgentInfoToJson(AgentInfo instance) => <String, dynamic>{
  'agentId': instance.agentId,
  'name': instance.name,
  'capability': instance.capability.toJson(),
};
