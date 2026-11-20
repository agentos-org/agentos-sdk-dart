// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HarnessKitPrivateToolsRegistration _$HarnessKitPrivateToolsRegistrationFromJson(
  Map<String, dynamic> json,
) => HarnessKitPrivateToolsRegistration(
  endpoint: json['endpoint'] as String,
  token: json['token'] as String,
  specification: json['specification'] as Map<String, dynamic>,
);

Map<String, dynamic> _$HarnessKitPrivateToolsRegistrationToJson(
  HarnessKitPrivateToolsRegistration instance,
) => <String, dynamic>{
  'endpoint': instance.endpoint,
  'token': instance.token,
  'specification': instance.specification,
};

HarnessKitPrivateToolsRegistrationResult
_$HarnessKitPrivateToolsRegistrationResultFromJson(Map<String, dynamic> json) =>
    HarnessKitPrivateToolsRegistrationResult(toolId: json['toolId'] as String);

Map<String, dynamic> _$HarnessKitPrivateToolsRegistrationResultToJson(
  HarnessKitPrivateToolsRegistrationResult instance,
) => <String, dynamic>{'toolId': instance.toolId};
