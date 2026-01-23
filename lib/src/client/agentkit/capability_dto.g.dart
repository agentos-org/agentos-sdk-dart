// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capability_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKey _$ApiKeyFromJson(Map<String, dynamic> json) => ApiKey(
  type: $enumDecode(_$ApiKeyTypeEnumMap, json['type']),
  apiKey: json['apiKey'] as String,
);

Map<String, dynamic> _$ApiKeyToJson(ApiKey instance) => <String, dynamic>{
  'type': _$ApiKeyTypeEnumMap[instance.type]!,
  'apiKey': instance.apiKey,
};

const _$ApiKeyTypeEnumMap = {
  ApiKeyType.basic: 'basic',
  ApiKeyType.bearer: 'bearer',
};

OpenSpec _$OpenSpecFromJson(Map<String, dynamic> json) => OpenSpec(
  openSpec: json['openSpec'] as String,
  apiKey: json['apiKey'] == null
      ? null
      : ApiKey.fromJson(json['apiKey'] as Map<String, dynamic>),
  protocol: $enumDecode(_$ProtocolEnumMap, json['protocol']),
  openToolId: json['openToolId'] as String?,
);

Map<String, dynamic> _$OpenSpecToJson(OpenSpec instance) => <String, dynamic>{
  'openSpec': instance.openSpec,
  'apiKey': ?instance.apiKey?.toJson(),
  'protocol': _$ProtocolEnumMap[instance.protocol]!,
  'openToolId': ?instance.openToolId,
};

const _$ProtocolEnumMap = {
  Protocol.openapi: 'openapi',
  Protocol.openmodbus: 'openmodbus',
  Protocol.jsonrpcHttp: 'jsonrpcHttp',
  Protocol.opentool: 'opentool',
  Protocol.serialport: 'serialport',
};

CallbackOpenTool _$CallbackOpenToolFromJson(Map<String, dynamic> json) =>
    CallbackOpenTool(
      opentool: json['opentool'] as String,
      timeout: (json['timeout'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CallbackOpenToolToJson(CallbackOpenTool instance) =>
    <String, dynamic>{
      'opentool': instance.opentool,
      'timeout': instance.timeout,
    };

LLMConfig _$LLMConfigFromJson(Map<String, dynamic> json) => LLMConfig(
  baseUrl: json['baseUrl'] as String? ?? "http://localhost:8888/llmkit/text",
  apiKey: json['apiKey'] as String? ?? "sk-",
  model: json['model'] as String,
  temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
  maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 4096,
  topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
);

Map<String, dynamic> _$LLMConfigToJson(LLMConfig instance) => <String, dynamic>{
  'baseUrl': instance.baseUrl,
  'apiKey': instance.apiKey,
  'model': instance.model,
  'temperature': instance.temperature,
  'maxTokens': instance.maxTokens,
  'topP': instance.topP,
};

ReflectPrompt _$ReflectPromptFromJson(Map<String, dynamic> json) =>
    ReflectPrompt(
      llmConfig: LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
      prompt: json['prompt'] as String,
    );

Map<String, dynamic> _$ReflectPromptToJson(ReflectPrompt instance) =>
    <String, dynamic>{
      'llmConfig': instance.llmConfig.toJson(),
      'prompt': instance.prompt,
    };

SimpleCapability _$SimpleCapabilityFromJson(Map<String, dynamic> json) =>
    SimpleCapability(
      llmConfig: LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
      systemPrompt: json['systemPrompt'] as String,
    );

Map<String, dynamic> _$SimpleCapabilityToJson(SimpleCapability instance) =>
    <String, dynamic>{
      'llmConfig': instance.llmConfig.toJson(),
      'systemPrompt': instance.systemPrompt,
    };

Capability _$CapabilityFromJson(Map<String, dynamic> json) => Capability(
  llmConfig: LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
  systemPrompt: json['systemPrompt'] as String,
  openSpecList: (json['openSpecList'] as List<dynamic>?)
      ?.map((e) => OpenSpec.fromJson(e as Map<String, dynamic>))
      .toList(),
  clientOpenTool: json['clientOpenTool'] == null
      ? null
      : CallbackOpenTool.fromJson(
          json['clientOpenTool'] as Map<String, dynamic>,
        ),
  sessionList: (json['sessionList'] as List<dynamic>?)
      ?.map((e) => SessionName.fromJson(e as Map<String, dynamic>))
      .toList(),
  reflectPromptList: (json['reflectPromptList'] as List<dynamic>?)
      ?.map((e) => ReflectPrompt.fromJson(e as Map<String, dynamic>))
      .toList(),
  timeoutSeconds: (json['timeoutSeconds'] as num?)?.toInt() ?? 3600,
  taskPipelineStrategy:
      $enumDecodeNullable(
        _$PipelineStrategyTypeEnumMap,
        json['taskPipelineStrategy'],
      ) ??
      PipelineStrategyType.parallel,
  toolPipelineStrategy: $enumDecodeNullable(
    _$PipelineStrategyTypeEnumMap,
    json['toolPipelineStrategy'],
  ),
);

Map<String, dynamic> _$CapabilityToJson(Capability instance) =>
    <String, dynamic>{
      'llmConfig': instance.llmConfig.toJson(),
      'systemPrompt': instance.systemPrompt,
      'openSpecList': ?instance.openSpecList?.map((e) => e.toJson()).toList(),
      'clientOpenTool': ?instance.clientOpenTool?.toJson(),
      'sessionList': ?instance.sessionList?.map((e) => e.toJson()).toList(),
      'reflectPromptList': ?instance.reflectPromptList
          ?.map((e) => e.toJson())
          .toList(),
      'timeoutSeconds': instance.timeoutSeconds,
      'taskPipelineStrategy':
          _$PipelineStrategyTypeEnumMap[instance.taskPipelineStrategy]!,
      'toolPipelineStrategy':
          ?_$PipelineStrategyTypeEnumMap[instance.toolPipelineStrategy],
    };

const _$PipelineStrategyTypeEnumMap = {
  PipelineStrategyType.parallel: 'parallel',
  PipelineStrategyType.serial: 'serial',
  PipelineStrategyType.reject: 'reject',
};

OpenToolInfo _$OpenToolInfoFromJson(Map<String, dynamic> json) => OpenToolInfo(
  openToolId: json['openToolId'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$OpenToolInfoToJson(OpenToolInfo instance) =>
    <String, dynamic>{
      'openToolId': instance.openToolId,
      'description': instance.description,
    };
