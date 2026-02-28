// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Version _$VersionFromJson(Map<String, dynamic> json) =>
    Version(version: json['version'] as String);

Map<String, dynamic> _$VersionToJson(Version instance) => <String, dynamic>{
  'version': instance.version,
};

RootInfo _$RootInfoFromJson(Map<String, dynamic> json) => RootInfo(
  name: json['name'] as String,
  version: json['version'] as String,
  description: json['description'] as String,
  baseUrl: json['baseUrl'] as String,
  endpoints: Map<String, String>.from(json['endpoints'] as Map),
);

Map<String, dynamic> _$RootInfoToJson(RootInfo instance) => <String, dynamic>{
  'name': instance.name,
  'version': instance.version,
  'description': instance.description,
  'baseUrl': instance.baseUrl,
  'endpoints': instance.endpoints,
};

Readiness _$ReadinessFromJson(Map<String, dynamic> json) => Readiness(
  ready: json['ready'] as bool,
  llmConfigured: json['llmConfigured'] as bool?,
  llmServicesReady: json['llmServicesReady'] as bool?,
  liteAgentReady: json['liteAgentReady'] as bool?,
  openToolDaemonReady: json['openToolDaemonReady'] as bool?,
  embeddingsReady: json['embeddingsReady'] as bool?,
  reasons: (json['reasons'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ReadinessToJson(Readiness instance) => <String, dynamic>{
  'ready': instance.ready,
  'llmConfigured': ?instance.llmConfigured,
  'llmServicesReady': ?instance.llmServicesReady,
  'liteAgentReady': ?instance.liteAgentReady,
  'openToolDaemonReady': ?instance.openToolDaemonReady,
  'embeddingsReady': ?instance.embeddingsReady,
  'reasons': ?instance.reasons,
};
