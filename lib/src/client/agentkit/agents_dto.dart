import 'package:json_annotation/json_annotation.dart';
import 'capability_dto.dart';

part 'agents_dto.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentId {
  String agentId;
  AgentId({required this.agentId});

  factory AgentId.fromJson(Map<String, dynamic> json) =>
      _$AgentIdFromJson(json);

  Map<String, dynamic> toJson() => _$AgentIdToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Agent {
  String name;
  Capability capability;
  Agent({required this.name, required this.capability});

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);

  Map<String, dynamic> toJson() => _$AgentToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentInfo extends AgentId {
  String name;
  Capability capability;
  AgentInfo({
    required super.agentId,
    required this.name,
    required this.capability,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) =>
      _$AgentInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AgentInfoToJson(this);
}
