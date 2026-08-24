import 'package:json_annotation/json_annotation.dart';
import 'capability_dto.dart';

part 'agents_dto.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Agent {
  String name;
  Capability capability;
  Agent({required this.name, required this.capability});

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);

  Map<String, dynamic> toJson() => _$AgentToJson(this);
}
