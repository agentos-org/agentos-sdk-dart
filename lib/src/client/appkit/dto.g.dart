// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppBundle _$AppBundleFromJson(Map<String, dynamic> json) => AppBundle(
  bundleId: json['bundleId'] as String,
  appGroupId: json['appGroupId'] as String?,
  opentoolServers:
      (json['opentoolServers'] as List<dynamic>?)
          ?.map(
            (e) =>
                OpenToolServerDeclaration.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$AppBundleToJson(AppBundle instance) => <String, dynamic>{
  'bundleId': instance.bundleId,
  'appGroupId': ?instance.appGroupId,
  'opentoolServers': instance.opentoolServers.map((e) => e.toJson()).toList(),
};

AccessToken _$AccessTokenFromJson(Map<String, dynamic> json) => AccessToken(
  token: json['token'] as String,
  bundleId: json['bundleId'] as String?,
  appGroupId: json['appGroupId'] as String?,
  opentoolServers:
      (json['opentoolServers'] as List<dynamic>?)
          ?.map(
            (e) =>
                OpenToolServerRegistration.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$AccessTokenToJson(
  AccessToken instance,
) => <String, dynamic>{
  'token': instance.token,
  'bundleId': ?instance.bundleId,
  'appGroupId': ?instance.appGroupId,
  'opentoolServers': instance.opentoolServers.map((e) => e.toJson()).toList(),
};

AgentOSEvent _$AgentOSEventFromJson(Map<String, dynamic> json) => AgentOSEvent(
  id: json['id'] as String?,
  agentosEventType: json['agentosEventType'] as String,
  data: json['data'] as String,
);

Map<String, dynamic> _$AgentOSEventToJson(AgentOSEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'agentosEventType': instance.agentosEventType,
      'data': instance.data,
    };

Welcome _$WelcomeFromJson(Map<String, dynamic> json) => Welcome(
  bundleId: json['bundleId'] as String,
  appGroupId: json['appGroupId'] as String?,
);

Map<String, dynamic> _$WelcomeToJson(Welcome instance) => <String, dynamic>{
  'bundleId': instance.bundleId,
  'appGroupId': instance.appGroupId,
};

AppKitError _$AppKitErrorFromJson(Map<String, dynamic> json) =>
    AppKitError(error: json['error'] as String);

Map<String, dynamic> _$AppKitErrorToJson(AppKitError instance) =>
    <String, dynamic>{'error': instance.error};

OpenToolServerDeclaration _$OpenToolServerDeclarationFromJson(
  Map<String, dynamic> json,
) => OpenToolServerDeclaration(
  ref: json['ref'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$OpenToolServerDeclarationToJson(
  OpenToolServerDeclaration instance,
) => <String, dynamic>{'ref': instance.ref, 'name': instance.name};

OpenToolResolvedServer _$OpenToolResolvedServerFromJson(
  Map<String, dynamic> json,
) => OpenToolResolvedServer(
  repo: _readOpenToolNamespace(json, 'namespace') as String,
  name: json['name'] as String,
  tag: _readOpenToolVersion(json, 'version') as String,
);

Map<String, dynamic> _$OpenToolResolvedServerToJson(
  OpenToolResolvedServer instance,
) => <String, dynamic>{
  'namespace': instance.repo,
  'name': instance.name,
  'version': instance.tag,
};

OpenToolServerRegistration _$OpenToolServerRegistrationFromJson(
  Map<String, dynamic> json,
) => OpenToolServerRegistration(
  ref: json['ref'] as String,
  status: json['status'] as String,
  name: json['name'] as String?,
  server: json['server'] == null
      ? null
      : OpenToolResolvedServer.fromJson(json['server'] as Map<String, dynamic>),
  id: json['id'] as String?,
);

Map<String, dynamic> _$OpenToolServerRegistrationToJson(
  OpenToolServerRegistration instance,
) => <String, dynamic>{
  'ref': instance.ref,
  'status': instance.status,
  'name': ?instance.name,
  'server': ?instance.server?.toJson(),
  'id': ?instance.id,
};

AppEvent _$AppEventFromJson(Map<String, dynamic> json) => AppEvent(
  version: (json['version'] as num).toInt(),
  id: json['id'] as String,
  type: json['type'] as String,
  source: json['source'] as String,
  time: DateTime.parse(json['time'] as String),
  subject: json['subject'] as String,
  data: json['data'] as Map<String, dynamic>,
);

Map<String, dynamic> _$AppEventToJson(AppEvent instance) => <String, dynamic>{
  'version': instance.version,
  'id': instance.id,
  'type': instance.type,
  'source': instance.source,
  'time': instance.time.toIso8601String(),
  'subject': instance.subject,
  'data': instance.data,
};

OpenToolProvisionSuccess _$OpenToolProvisionSuccessFromJson(
  Map<String, dynamic> json,
) => OpenToolProvisionSuccess(
  ref: json['ref'] as String,
  name: json['name'] as String,
  status: json['status'] as String,
  server: OpenToolResolvedServer.fromJson(
    json['server'] as Map<String, dynamic>,
  ),
  id: json['id'] as String,
);

Map<String, dynamic> _$OpenToolProvisionSuccessToJson(
  OpenToolProvisionSuccess instance,
) => <String, dynamic>{
  'ref': instance.ref,
  'name': instance.name,
  'status': instance.status,
  'server': instance.server.toJson(),
  'id': instance.id,
};

OpenToolProvisionFailure _$OpenToolProvisionFailureFromJson(
  Map<String, dynamic> json,
) => OpenToolProvisionFailure(
  ref: json['ref'] as String,
  name: json['name'] as String,
  status: json['status'] as String,
  error: AppEventError.fromJson(json['error'] as Map<String, dynamic>),
  server: json['server'] == null
      ? null
      : OpenToolResolvedServer.fromJson(json['server'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OpenToolProvisionFailureToJson(
  OpenToolProvisionFailure instance,
) => <String, dynamic>{
  'ref': instance.ref,
  'name': instance.name,
  'status': instance.status,
  'server': ?instance.server?.toJson(),
  'error': instance.error.toJson(),
};

AppEventError _$AppEventErrorFromJson(Map<String, dynamic> json) =>
    AppEventError(
      code: json['code'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$AppEventErrorToJson(AppEventError instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};
