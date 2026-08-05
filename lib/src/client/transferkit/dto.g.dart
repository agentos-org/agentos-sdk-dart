// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferFileInfo _$TransferFileInfoFromJson(Map<String, dynamic> json) =>
    TransferFileInfo(
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
      filePath: json['filePath'] as String,
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$TransferFileInfoToJson(TransferFileInfo instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'size': instance.size,
      'filePath': instance.filePath,
      'mimeType': ?instance.mimeType,
    };

TransferSession _$TransferSessionFromJson(Map<String, dynamic> json) =>
    TransferSession(
      transferId: json['transferId'] as String,
      state: $enumDecode(_$TransferStateEnumMap, json['state']),
      progress: (json['progress'] as num).toDouble(),
      targetDeviceId: json['targetDeviceId'] as String,
      bundleId: json['bundleId'] as String,
      userId: json['userId'] as String?,
      targetBundleId: json['targetBundleId'] as String?,
      files: (json['files'] as List<dynamic>)
          .map((e) => TransferFileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$TransferSessionToJson(TransferSession instance) =>
    <String, dynamic>{
      'transferId': instance.transferId,
      'state': _$TransferStateEnumMap[instance.state]!,
      'progress': instance.progress,
      'targetDeviceId': instance.targetDeviceId,
      'bundleId': instance.bundleId,
      'userId': ?instance.userId,
      'targetBundleId': ?instance.targetBundleId,
      'files': instance.files.map((e) => e.toJson()).toList(),
      'errorMessage': ?instance.errorMessage,
    };

const _$TransferStateEnumMap = {
  TransferState.pending: 'pending',
  TransferState.preparing: 'preparing',
  TransferState.transferring: 'transferring',
  TransferState.completed: 'completed',
  TransferState.failed: 'failed',
  TransferState.cancelled: 'cancelled',
};

ReceivedFileInfo _$ReceivedFileInfoFromJson(Map<String, dynamic> json) =>
    ReceivedFileInfo(
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
      savedPath: json['savedPath'] as String,
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$ReceivedFileInfoToJson(ReceivedFileInfo instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'size': instance.size,
      'savedPath': instance.savedPath,
      'mimeType': ?instance.mimeType,
    };

IncomingTransferEvent _$IncomingTransferEventFromJson(
  Map<String, dynamic> json,
) => IncomingTransferEvent(
  transferId: json['transferId'] as String,
  fromDeviceId: json['fromDeviceId'] as String,
  fromName: json['fromName'] as String,
  sourceBundleId: json['sourceBundleId'] as String,
  targetBundleId: json['targetBundleId'] as String?,
  autoAccepted: json['autoAccepted'] as bool,
  files: (json['files'] as List<dynamic>)
      .map((e) => ReceivedFileInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IncomingTransferEventToJson(
  IncomingTransferEvent instance,
) => <String, dynamic>{
  'transferId': instance.transferId,
  'fromDeviceId': instance.fromDeviceId,
  'fromName': instance.fromName,
  'sourceBundleId': instance.sourceBundleId,
  'targetBundleId': ?instance.targetBundleId,
  'autoAccepted': instance.autoAccepted,
  'files': instance.files.map((e) => e.toJson()).toList(),
};

TransferHistoryFile _$TransferHistoryFileFromJson(Map<String, dynamic> json) =>
    TransferHistoryFile(
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
      filePath: json['filePath'] as String?,
    );

Map<String, dynamic> _$TransferHistoryFileToJson(
  TransferHistoryFile instance,
) => <String, dynamic>{
  'fileName': instance.fileName,
  'size': instance.size,
  'filePath': ?instance.filePath,
};

TransferHistoryRecord _$TransferHistoryRecordFromJson(
  Map<String, dynamic> json,
) => TransferHistoryRecord(
  id: json['id'] as String,
  direction: $enumDecode(_$TransferDirectionEnumMap, json['direction']),
  peerDeviceId: json['peerDeviceId'] as String,
  peerName: json['peerName'] as String,
  peerAvatarUrl: json['peerAvatarUrl'] as String?,
  files: (json['files'] as List<dynamic>)
      .map((e) => TransferHistoryFile.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalSize: (json['totalSize'] as num).toInt(),
  state: $enumDecode(_$TransferStateEnumMap, json['state']),
  timestamp: json['timestamp'] as String,
  savedDir: json['savedDir'] as String?,
);

Map<String, dynamic> _$TransferHistoryRecordToJson(
  TransferHistoryRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'direction': _$TransferDirectionEnumMap[instance.direction]!,
  'peerDeviceId': instance.peerDeviceId,
  'peerName': instance.peerName,
  'peerAvatarUrl': ?instance.peerAvatarUrl,
  'files': instance.files.map((e) => e.toJson()).toList(),
  'totalSize': instance.totalSize,
  'state': _$TransferStateEnumMap[instance.state]!,
  'timestamp': instance.timestamp,
  'savedDir': ?instance.savedDir,
};

const _$TransferDirectionEnumMap = {
  TransferDirection.send: 'send',
  TransferDirection.receive: 'receive',
};

TransferSendRequest _$TransferSendRequestFromJson(Map<String, dynamic> json) =>
    TransferSendRequest(
      targetDeviceId: json['targetDeviceId'] as String,
      targetBundleId: json['targetBundleId'] as String?,
      files: (json['files'] as List<dynamic>)
          .map((e) => TransferFileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TransferSendRequestToJson(
  TransferSendRequest instance,
) => <String, dynamic>{
  'targetDeviceId': instance.targetDeviceId,
  'targetBundleId': ?instance.targetBundleId,
  'files': instance.files.map((e) => e.toJson()).toList(),
};

TransferRespondRequest _$TransferRespondRequestFromJson(
  Map<String, dynamic> json,
) => TransferRespondRequest(accept: json['accept'] as bool);

Map<String, dynamic> _$TransferRespondRequestToJson(
  TransferRespondRequest instance,
) => <String, dynamic>{'accept': instance.accept};

SetPolicyRequest _$SetPolicyRequestFromJson(Map<String, dynamic> json) =>
    SetPolicyRequest(policy: json['policy'] as String);

Map<String, dynamic> _$SetPolicyRequestToJson(SetPolicyRequest instance) =>
    <String, dynamic>{'policy': instance.policy};

PolicyResponse _$PolicyResponseFromJson(Map<String, dynamic> json) =>
    PolicyResponse(
      policy: json['policy'] as String,
      bundleId: json['bundleId'] as String?,
    );

Map<String, dynamic> _$PolicyResponseToJson(PolicyResponse instance) =>
    <String, dynamic>{
      'policy': instance.policy,
      'bundleId': ?instance.bundleId,
    };

AddHistoryRequest _$AddHistoryRequestFromJson(Map<String, dynamic> json) =>
    AddHistoryRequest(
      id: json['id'] as String?,
      direction: $enumDecodeNullable(
        _$TransferDirectionEnumMap,
        json['direction'],
      ),
      peerDeviceId: json['peerDeviceId'] as String?,
      peerName: json['peerName'] as String?,
      peerAvatarUrl: json['peerAvatarUrl'] as String?,
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => TransferHistoryFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSize: (json['totalSize'] as num?)?.toInt(),
      state: $enumDecodeNullable(_$TransferStateEnumMap, json['state']),
      timestamp: json['timestamp'] as String?,
      savedDir: json['savedDir'] as String?,
      deviceId: json['deviceId'] as String?,
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$AddHistoryRequestToJson(AddHistoryRequest instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'direction': ?_$TransferDirectionEnumMap[instance.direction],
      'peerDeviceId': ?instance.peerDeviceId,
      'peerName': ?instance.peerName,
      'peerAvatarUrl': ?instance.peerAvatarUrl,
      'files': ?instance.files?.map((e) => e.toJson()).toList(),
      'totalSize': ?instance.totalSize,
      'state': ?_$TransferStateEnumMap[instance.state],
      'timestamp': ?instance.timestamp,
      'savedDir': ?instance.savedDir,
      'deviceId': ?instance.deviceId,
      'userId': ?instance.userId,
    };

AddHistoryResponse _$AddHistoryResponseFromJson(Map<String, dynamic> json) =>
    AddHistoryResponse(
      status: json['status'] as String,
      id: json['id'] as String,
    );

Map<String, dynamic> _$AddHistoryResponseToJson(AddHistoryResponse instance) =>
    <String, dynamic>{'status': instance.status, 'id': instance.id};

StatusResponse _$StatusResponseFromJson(Map<String, dynamic> json) =>
    StatusResponse(status: json['status'] as String);

Map<String, dynamic> _$StatusResponseToJson(StatusResponse instance) =>
    <String, dynamic>{'status': instance.status};
