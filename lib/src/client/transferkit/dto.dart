import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

enum TransferState { pending, preparing, transferring, completed, failed, cancelled }

enum FileTransferState { pending, transferring, completed, failed }

enum TransferDirection { send, receive }

@JsonSerializable(includeIfNull: false)
class TransferFileInfo {
  String fileName;
  int size;
  String filePath;
  String? mimeType;

  TransferFileInfo({
    required this.fileName,
    required this.size,
    required this.filePath,
    this.mimeType,
  });

  factory TransferFileInfo.fromJson(Map<String, dynamic> json) =>
      _$TransferFileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$TransferFileInfoToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TransferSession {
  String transferId;
  TransferState state;
  double progress;
  String targetDeviceId;
  String bundleId;
  String? userId;
  String? targetBundleId;
  List<TransferFileInfo> files;
  String? errorMessage;

  TransferSession({
    required this.transferId,
    required this.state,
    required this.progress,
    required this.targetDeviceId,
    required this.bundleId,
    this.userId,
    this.targetBundleId,
    required this.files,
    this.errorMessage,
  });

  factory TransferSession.fromJson(Map<String, dynamic> json) =>
      _$TransferSessionFromJson(json);

  Map<String, dynamic> toJson() => _$TransferSessionToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ReceivedFileInfo {
  String fileName;
  int size;
  String savedPath;
  String? mimeType;

  ReceivedFileInfo({
    required this.fileName,
    required this.size,
    required this.savedPath,
    this.mimeType,
  });

  factory ReceivedFileInfo.fromJson(Map<String, dynamic> json) =>
      _$ReceivedFileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ReceivedFileInfoToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class IncomingTransferEvent {
  String transferId;
  String fromDeviceId;
  String fromName;
  String sourceBundleId;
  String? targetBundleId;
  bool autoAccepted;
  List<ReceivedFileInfo> files;

  IncomingTransferEvent({
    required this.transferId,
    required this.fromDeviceId,
    required this.fromName,
    required this.sourceBundleId,
    this.targetBundleId,
    required this.autoAccepted,
    required this.files,
  });

  factory IncomingTransferEvent.fromJson(Map<String, dynamic> json) =>
      _$IncomingTransferEventFromJson(json);

  Map<String, dynamic> toJson() => _$IncomingTransferEventToJson(this);
}

@JsonSerializable(includeIfNull: false)
class TransferHistoryFile {
  String fileName;
  int size;
  String? filePath;

  TransferHistoryFile({
    required this.fileName,
    required this.size,
    this.filePath,
  });

  factory TransferHistoryFile.fromJson(Map<String, dynamic> json) =>
      _$TransferHistoryFileFromJson(json);

  Map<String, dynamic> toJson() => _$TransferHistoryFileToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TransferHistoryRecord {
  String id;
  TransferDirection direction;
  String peerDeviceId;
  String peerName;
  String? peerAvatarUrl;
  List<TransferHistoryFile> files;
  int totalSize;
  TransferState state;
  String timestamp;
  String? savedDir;

  TransferHistoryRecord({
    required this.id,
    required this.direction,
    required this.peerDeviceId,
    required this.peerName,
    this.peerAvatarUrl,
    required this.files,
    required this.totalSize,
    required this.state,
    required this.timestamp,
    this.savedDir,
  });

  factory TransferHistoryRecord.fromJson(Map<String, dynamic> json) =>
      _$TransferHistoryRecordFromJson(json);

  Map<String, dynamic> toJson() => _$TransferHistoryRecordToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TransferSendRequest {
  String targetDeviceId;
  String? targetBundleId;
  List<TransferFileInfo> files;

  TransferSendRequest({
    required this.targetDeviceId,
    this.targetBundleId,
    required this.files,
  });

  factory TransferSendRequest.fromJson(Map<String, dynamic> json) =>
      _$TransferSendRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransferSendRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class TransferRespondRequest {
  bool accept;

  TransferRespondRequest({required this.accept});

  factory TransferRespondRequest.fromJson(Map<String, dynamic> json) =>
      _$TransferRespondRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TransferRespondRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class SetPolicyRequest {
  String policy;

  SetPolicyRequest({required this.policy});

  factory SetPolicyRequest.fromJson(Map<String, dynamic> json) =>
      _$SetPolicyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetPolicyRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class PolicyResponse {
  String policy;
  String? bundleId;

  PolicyResponse({required this.policy, this.bundleId});

  factory PolicyResponse.fromJson(Map<String, dynamic> json) =>
      _$PolicyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PolicyResponseToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AddHistoryRequest {
  String? id;
  TransferDirection? direction;
  String? peerDeviceId;
  String? peerName;
  String? peerAvatarUrl;
  List<TransferHistoryFile>? files;
  int? totalSize;
  TransferState? state;
  String? timestamp;
  String? savedDir;
  String? deviceId;
  String? userId;

  AddHistoryRequest({
    this.id,
    this.direction,
    this.peerDeviceId,
    this.peerName,
    this.peerAvatarUrl,
    this.files,
    this.totalSize,
    this.state,
    this.timestamp,
    this.savedDir,
    this.deviceId,
    this.userId,
  });

  factory AddHistoryRequest.fromJson(Map<String, dynamic> json) =>
      _$AddHistoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddHistoryRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class AddHistoryResponse {
  String status;
  String id;

  AddHistoryResponse({required this.status, required this.id});

  factory AddHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$AddHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddHistoryResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class StatusResponse {
  String status;

  StatusResponse({required this.status});

  factory StatusResponse.fromJson(Map<String, dynamic> json) =>
      _$StatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StatusResponseToJson(this);
}
