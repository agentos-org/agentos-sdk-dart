import 'package:json_annotation/json_annotation.dart';

part 'planning_dto.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PlanModel {
  String id;
  String name;

  PlanModel({required this.id, required this.name});

  factory PlanModel.fromJson(Map<String, dynamic> json) => _$PlanModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlanModelToJson(this);
}


@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PlanTool {
  String id;
  String name;
  String desc;

  PlanTool({required this.id, required this.name, required this.desc});

  factory PlanTool.fromJson(Map<String, dynamic> json) => _$PlanToolFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToolToJson(this);
}


@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Plan {
  String name;
  PlanModel model;
  String prompt;
  @JsonKey(defaultValue: const <PlanTool>[]) List<PlanTool> tools;
  @JsonKey(defaultValue: const <Plan>[]) List<Plan> subPlans;

  Plan({required this.name, required this.model, required this.prompt, List<PlanTool>? tools, List<Plan>? subPlans})
      : tools = tools ?? [],
        subPlans = subPlans ?? [];

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToJson(this);
}


@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PlanningContent {
  String planId;
  List<Plan> plans;

  PlanningContent({required this.planId, required this.plans});

  factory PlanningContent.fromJson(Map<String, dynamic> json) => _$PlanningContentFromJson(json);

  Map<String, dynamic> toJson() => _$PlanningContentToJson(this);
}

