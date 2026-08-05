// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeerApp _$PeerAppFromJson(Map<String, dynamic> json) => PeerApp(
  bundleId: json['bundleId'] as String?,
  userId: json['userId'] as String?,
  username: json['username'] as String?,
  appName: json['appName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$PeerAppToJson(PeerApp instance) => <String, dynamic>{
  'bundleId': ?instance.bundleId,
  'userId': ?instance.userId,
  'username': ?instance.username,
  'appName': ?instance.appName,
  'avatarUrl': ?instance.avatarUrl,
};

PeerDevice _$PeerDeviceFromJson(Map<String, dynamic> json) => PeerDevice(
  deviceId: json['deviceId'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  deviceName: json['deviceName'] as String,
  deviceType: json['deviceType'] as String,
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  online: json['online'] as bool,
  apps: (json['apps'] as List<dynamic>)
      .map((e) => PeerApp.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PeerDeviceToJson(PeerDevice instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'name': instance.name,
      'avatarUrl': ?instance.avatarUrl,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
      'host': instance.host,
      'port': instance.port,
      'online': instance.online,
      'apps': instance.apps.map((e) => e.toJson()).toList(),
    };

PeerDeviceEvent _$PeerDeviceEventFromJson(Map<String, dynamic> json) =>
    PeerDeviceEvent(
      type: $enumDecode(_$PeerDeviceEventTypeEnumMap, json['type']),
      device: PeerDevice.fromJson(json['device'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PeerDeviceEventToJson(PeerDeviceEvent instance) =>
    <String, dynamic>{
      'type': _$PeerDeviceEventTypeEnumMap[instance.type]!,
      'device': instance.device.toJson(),
    };

const _$PeerDeviceEventTypeEnumMap = {
  PeerDeviceEventType.joined: 'joined',
  PeerDeviceEventType.left: 'left',
  PeerDeviceEventType.updated: 'updated',
};

SelfInfo _$SelfInfoFromJson(Map<String, dynamic> json) => SelfInfo(
  deviceId: json['deviceId'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  deviceName: json['deviceName'] as String,
  deviceType: json['deviceType'] as String,
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  online: json['online'] as bool,
  apps: (json['apps'] as List<dynamic>)
      .map((e) => PeerApp.fromJson(e as Map<String, dynamic>))
      .toList(),
  nearbyTransferEnabled: json['nearbyTransferEnabled'] as bool,
  registered: json['registered'] as bool,
);

Map<String, dynamic> _$SelfInfoToJson(SelfInfo instance) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'name': instance.name,
  'avatarUrl': ?instance.avatarUrl,
  'deviceName': instance.deviceName,
  'deviceType': instance.deviceType,
  'host': instance.host,
  'port': instance.port,
  'online': instance.online,
  'apps': instance.apps.map((e) => e.toJson()).toList(),
  'nearbyTransferEnabled': instance.nearbyTransferEnabled,
  'registered': instance.registered,
};

DiscoveryRegisterRequest _$DiscoveryRegisterRequestFromJson(
  Map<String, dynamic> json,
) => DiscoveryRegisterRequest(
  receivePolicy: $enumDecodeNullable(
    _$FileReceivePolicyEnumMap,
    json['receivePolicy'],
  ),
);

Map<String, dynamic> _$DiscoveryRegisterRequestToJson(
  DiscoveryRegisterRequest instance,
) => <String, dynamic>{
  'receivePolicy': ?_$FileReceivePolicyEnumMap[instance.receivePolicy],
};

const _$FileReceivePolicyEnumMap = {
  FileReceivePolicy.autoAccept: 'autoAccept',
  FileReceivePolicy.requireConfirm: 'requireConfirm',
};

DiscoveryRegisterResponse _$DiscoveryRegisterResponseFromJson(
  Map<String, dynamic> json,
) => DiscoveryRegisterResponse(
  status: json['status'] as String,
  bundleId: json['bundleId'] as String,
);

Map<String, dynamic> _$DiscoveryRegisterResponseToJson(
  DiscoveryRegisterResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'bundleId': instance.bundleId,
};

DiscoveryUnregisterResponse _$DiscoveryUnregisterResponseFromJson(
  Map<String, dynamic> json,
) => DiscoveryUnregisterResponse(
  status: json['status'] as String,
  bundleId: json['bundleId'] as String,
);

Map<String, dynamic> _$DiscoveryUnregisterResponseToJson(
  DiscoveryUnregisterResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'bundleId': instance.bundleId,
};
