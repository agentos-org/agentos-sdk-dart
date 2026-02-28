// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBundle _$AppBundleFromJson(Map<String, dynamic> json) =>
    AppBundle(bundleId: json['bundleId'] as String);

Map<String, dynamic> _$AppBundleToJson(AppBundle instance) => <String, dynamic>{
  'bundleId': instance.bundleId,
};

AccessToken _$AccessTokenFromJson(Map<String, dynamic> json) =>
    AccessToken(token: json['token'] as String);

Map<String, dynamic> _$AccessTokenToJson(AccessToken instance) =>
    <String, dynamic>{'token': instance.token};

AgentOSEvent _$AgentOSEventFromJson(Map<String, dynamic> json) => AgentOSEvent(
  agentosEventType: json['agentosEventType'] as String,
  data: json['data'] as String,
);

Map<String, dynamic> _$AgentOSEventToJson(AgentOSEvent instance) =>
    <String, dynamic>{
      'agentosEventType': instance.agentosEventType,
      'data': instance.data,
    };

Welcome _$WelcomeFromJson(Map<String, dynamic> json) =>
    Welcome(bundleId: json['bundleId'] as String);

Map<String, dynamic> _$WelcomeToJson(Welcome instance) => <String, dynamic>{
  'bundleId': instance.bundleId,
};

AppKitError _$AppKitErrorFromJson(Map<String, dynamic> json) =>
    AppKitError(error: json['error'] as String);

Map<String, dynamic> _$AppKitErrorToJson(AppKitError instance) =>
    <String, dynamic>{'error': instance.error};
