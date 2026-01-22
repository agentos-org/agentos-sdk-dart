// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanModel _$PlanModelFromJson(Map<String, dynamic> json) =>
    PlanModel(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$PlanModelToJson(PlanModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

PlanTool _$PlanToolFromJson(Map<String, dynamic> json) => PlanTool(
  id: json['id'] as String,
  name: json['name'] as String,
  desc: json['desc'] as String,
);

Map<String, dynamic> _$PlanToolToJson(PlanTool instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'desc': instance.desc,
};

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
  name: json['name'] as String,
  model: PlanModel.fromJson(json['model'] as Map<String, dynamic>),
  prompt: json['prompt'] as String,
  tools:
      (json['tools'] as List<dynamic>?)
          ?.map((e) => PlanTool.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  subPlans:
      (json['subPlans'] as List<dynamic>?)
          ?.map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'name': instance.name,
  'model': instance.model.toJson(),
  'prompt': instance.prompt,
  'tools': instance.tools.map((e) => e.toJson()).toList(),
  'subPlans': instance.subPlans.map((e) => e.toJson()).toList(),
};

PlanningContent _$PlanningContentFromJson(Map<String, dynamic> json) =>
    PlanningContent(
      planId: json['planId'] as String,
      plans: (json['plans'] as List<dynamic>)
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanningContentToJson(PlanningContent instance) =>
    <String, dynamic>{
      'planId': instance.planId,
      'plans': instance.plans.map((e) => e.toJson()).toList(),
    };
