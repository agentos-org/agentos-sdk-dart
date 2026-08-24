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
  ApiKeyType.original: 'original',
};

OpenSpec _$OpenSpecFromJson(Map<String, dynamic> json) => OpenSpec(
  openSpec: json['openSpec'] as String,
  apiKey: json['apiKey'] == null
      ? null
      : ApiKey.fromJson(json['apiKey'] as Map<String, dynamic>),
  protocol: $enumDecode(_$ProtocolEnumMap, json['protocol']),
  serverUrl: json['serverUrl'] as String?,
);

Map<String, dynamic> _$OpenSpecToJson(OpenSpec instance) => <String, dynamic>{
  'openSpec': instance.openSpec,
  'apiKey': ?instance.apiKey?.toJson(),
  'protocol': _$ProtocolEnumMap[instance.protocol]!,
  'serverUrl': ?instance.serverUrl,
};

const _$ProtocolEnumMap = {
  Protocol.openapi: 'openapi',
  Protocol.jsonrpcHttp: 'jsonrpcHttp',
  Protocol.opentool: 'opentool',
  Protocol.mcpStdio: 'mcpStdio',
  Protocol.mcpHttp: 'mcpHttp',
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
  modelId: json['modelId'] as String?,
  provider: json['provider'] as String?,
  baseUrl: json['baseUrl'] as String?,
  apiKey: json['apiKey'] as String?,
  model: json['model'] as String?,
  adapter: json['adapter'] as String?,
  headers: (json['headers'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  providerOptions: json['providerOptions'] as Map<String, dynamic>?,
  temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
  maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 4096,
  contextWindowSize: (json['contextWindowSize'] as num?)?.toInt(),
  topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
  supportsToolCall: json['supportsToolCall'] as bool? ?? true,
  supportsReasoning: json['supportsReasoning'] as bool? ?? false,
);

Map<String, dynamic> _$LLMConfigToJson(LLMConfig instance) => <String, dynamic>{
  'modelId': ?instance.modelId,
  'provider': ?instance.provider,
  'baseUrl': ?instance.baseUrl,
  'apiKey': ?instance.apiKey,
  'model': ?instance.model,
  'adapter': ?instance.adapter,
  'headers': ?instance.headers,
  'providerOptions': ?instance.providerOptions,
  'temperature': instance.temperature,
  'maxTokens': instance.maxTokens,
  'contextWindowSize': ?instance.contextWindowSize,
  'topP': instance.topP,
  'supportsToolCall': instance.supportsToolCall,
  'supportsReasoning': instance.supportsReasoning,
};

SimpleCapability _$SimpleCapabilityFromJson(Map<String, dynamic> json) =>
    SimpleCapability(
      llmConfig: json['llmConfig'] == null
          ? null
          : LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
      systemPrompt: json['systemPrompt'] as String,
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SimpleCapabilityToJson(SimpleCapability instance) =>
    <String, dynamic>{
      'llmConfig': ?instance.llmConfig?.toJson(),
      'systemPrompt': instance.systemPrompt,
      'skills': ?instance.skills,
    };

Capability _$CapabilityFromJson(Map<String, dynamic> json) => Capability(
  llmConfig: json['llmConfig'] == null
      ? null
      : LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
  systemPrompt: json['systemPrompt'] as String,
  skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
  openSpecList: (json['openSpecList'] as List<dynamic>?)
      ?.map((e) => OpenSpec.fromJson(e as Map<String, dynamic>))
      .toList(),
  callbackOpenTool: json['callbackOpenTool'] == null
      ? null
      : CallbackOpenTool.fromJson(
          json['callbackOpenTool'] as Map<String, dynamic>,
        ),
  subAgentList: (json['subAgentList'] as List<dynamic>?)
      ?.map((e) => Agent.fromJson(e as Map<String, dynamic>))
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
  auto: json['auto'] as bool?,
  llmConfigList: (json['llmConfigList'] as List<dynamic>?)
      ?.map((e) => LLMConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  enableThinking: json['enableThinking'] as bool?,
  toolReturnPackMinLength: (json['toolReturnPackMinLength'] as num?)?.toInt(),
  maxLlmRequests: (json['maxLlmRequests'] as num?)?.toInt(),
  maxToolRounds: (json['maxToolRounds'] as num?)?.toInt(),
  maxToolCalls: (json['maxToolCalls'] as num?)?.toInt(),
  maxConsecutiveIdenticalToolRounds:
      (json['maxConsecutiveIdenticalToolRounds'] as num?)?.toInt(),
  maxTaskDurationSeconds: (json['maxTaskDurationSeconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$CapabilityToJson(Capability instance) =>
    <String, dynamic>{
      'llmConfig': ?instance.llmConfig?.toJson(),
      'systemPrompt': instance.systemPrompt,
      'skills': ?instance.skills,
      'openSpecList': ?instance.openSpecList?.map((e) => e.toJson()).toList(),
      'callbackOpenTool': ?instance.callbackOpenTool?.toJson(),
      'subAgentList': ?instance.subAgentList?.map((e) => e.toJson()).toList(),
      'timeoutSeconds': instance.timeoutSeconds,
      'taskPipelineStrategy':
          _$PipelineStrategyTypeEnumMap[instance.taskPipelineStrategy]!,
      'toolPipelineStrategy':
          ?_$PipelineStrategyTypeEnumMap[instance.toolPipelineStrategy],
      'auto': ?instance.auto,
      'llmConfigList': ?instance.llmConfigList?.map((e) => e.toJson()).toList(),
      'enableThinking': ?instance.enableThinking,
      'toolReturnPackMinLength': ?instance.toolReturnPackMinLength,
      'maxLlmRequests': ?instance.maxLlmRequests,
      'maxToolRounds': ?instance.maxToolRounds,
      'maxToolCalls': ?instance.maxToolCalls,
      'maxConsecutiveIdenticalToolRounds':
          ?instance.maxConsecutiveIdenticalToolRounds,
      'maxTaskDurationSeconds': ?instance.maxTaskDurationSeconds,
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
