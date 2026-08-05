import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

enum FileReceivePolicy { autoAccept, requireConfirm }

enum PeerDeviceEventType { joined, left, updated }

@JsonSerializable(includeIfNull: false)
class PeerApp {
  String? bundleId;
  String? userId;
  String? username;
  String? appName;
  String? avatarUrl;

  PeerApp({
    this.bundleId,
    this.userId,
    this.username,
    this.appName,
    this.avatarUrl,
  });

  factory PeerApp.fromJson(Map<String, dynamic> json) =>
      _$PeerAppFromJson(json);

  Map<String, dynamic> toJson() => _$PeerAppToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PeerDevice {
  String deviceId;
  String name;
  String? avatarUrl;
  String deviceName;
  String deviceType;
  String host;
  int port;
  bool online;
  List<PeerApp> apps;

  PeerDevice({
    required this.deviceId,
    required this.name,
    this.avatarUrl,
    required this.deviceName,
    required this.deviceType,
    required this.host,
    required this.port,
    required this.online,
    required this.apps,
  });

  factory PeerDevice.fromJson(Map<String, dynamic> json) =>
      _$PeerDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$PeerDeviceToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PeerDeviceEvent {
  PeerDeviceEventType type;
  PeerDevice device;

  PeerDeviceEvent({required this.type, required this.device});

  factory PeerDeviceEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerDeviceEventFromJson(json);

  Map<String, dynamic> toJson() => _$PeerDeviceEventToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SelfInfo {
  String deviceId;
  String name;
  String? avatarUrl;
  String deviceName;
  String deviceType;
  String host;
  int port;
  bool online;
  List<PeerApp> apps;
  bool nearbyTransferEnabled;
  bool registered;

  SelfInfo({
    required this.deviceId,
    required this.name,
    this.avatarUrl,
    required this.deviceName,
    required this.deviceType,
    required this.host,
    required this.port,
    required this.online,
    required this.apps,
    required this.nearbyTransferEnabled,
    required this.registered,
  });

  factory SelfInfo.fromJson(Map<String, dynamic> json) =>
      _$SelfInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SelfInfoToJson(this);
}

@JsonSerializable(includeIfNull: false)
class DiscoveryRegisterRequest {
  FileReceivePolicy? receivePolicy;

  DiscoveryRegisterRequest({this.receivePolicy});

  factory DiscoveryRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryRegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveryRegisterRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class DiscoveryRegisterResponse {
  String status;
  String bundleId;

  DiscoveryRegisterResponse({required this.status, required this.bundleId});

  factory DiscoveryRegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryRegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveryRegisterResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class DiscoveryUnregisterResponse {
  String status;
  String bundleId;

  DiscoveryUnregisterResponse({required this.status, required this.bundleId});

  factory DiscoveryUnregisterResponse.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryUnregisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DiscoveryUnregisterResponseToJson(this);
}
