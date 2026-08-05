// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorizeRequest _$AuthorizeRequestFromJson(Map<String, dynamic> json) =>
    AuthorizeRequest(
      scopes: (json['scopes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      appName: json['appName'] as String?,
    );

Map<String, dynamic> _$AuthorizeRequestToJson(AuthorizeRequest instance) =>
    <String, dynamic>{'scopes': ?instance.scopes, 'appName': ?instance.appName};

AuthorizeResponse _$AuthorizeResponseFromJson(Map<String, dynamic> json) =>
    AuthorizeResponse(
      requestId: json['requestId'] as String,
      status: $enumDecode(_$AuthRequestStatusEnumMap, json['status']),
      authCode: json['authCode'] as String?,
    );

Map<String, dynamic> _$AuthorizeResponseToJson(AuthorizeResponse instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'status': _$AuthRequestStatusEnumMap[instance.status]!,
      'authCode': ?instance.authCode,
    };

const _$AuthRequestStatusEnumMap = {
  AuthRequestStatus.pending: 'pending',
  AuthRequestStatus.granted: 'granted',
  AuthRequestStatus.denied: 'denied',
  AuthRequestStatus.timeout: 'timeout',
};

ExchangeTokenRequest _$ExchangeTokenRequestFromJson(
  Map<String, dynamic> json,
) => ExchangeTokenRequest(authCode: json['authCode'] as String);

Map<String, dynamic> _$ExchangeTokenRequestToJson(
  ExchangeTokenRequest instance,
) => <String, dynamic>{'authCode': instance.authCode};

ExchangeTokenResponse _$ExchangeTokenResponseFromJson(
  Map<String, dynamic> json,
) => ExchangeTokenResponse(
  accessToken: json['accessToken'] as String,
  userInfo: AuthKitUserInfo.fromJson(json['userInfo'] as Map<String, dynamic>),
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$ExchangeTokenResponseToJson(
  ExchangeTokenResponse instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'userInfo': instance.userInfo,
  'userId': ?instance.userId,
};

AuthKitUserInfo _$AuthKitUserInfoFromJson(Map<String, dynamic> json) =>
    AuthKitUserInfo(
      userId: json['userId'] as String?,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
    );

Map<String, dynamic> _$AuthKitUserInfoToJson(AuthKitUserInfo instance) =>
    <String, dynamic>{
      'userId': ?instance.userId,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
    };

RevokeRequest _$RevokeRequestFromJson(Map<String, dynamic> json) =>
    RevokeRequest(bundleId: json['bundleId'] as String?);

Map<String, dynamic> _$RevokeRequestToJson(RevokeRequest instance) =>
    <String, dynamic>{'bundleId': ?instance.bundleId};

RevokeResponse _$RevokeResponseFromJson(Map<String, dynamic> json) =>
    RevokeResponse(status: json['status'] as String);

Map<String, dynamic> _$RevokeResponseToJson(RevokeResponse instance) =>
    <String, dynamic>{'status': instance.status};
