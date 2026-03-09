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
  openToolId: json['openToolId'] as String?,
);

Map<String, dynamic> _$OpenSpecToJson(OpenSpec instance) => <String, dynamic>{
  'openSpec': instance.openSpec,
  'apiKey': ?instance.apiKey?.toJson(),
  'protocol': _$ProtocolEnumMap[instance.protocol]!,
  'serverUrl': ?instance.serverUrl,
  'openToolId': ?instance.openToolId,
};

const _$ProtocolEnumMap = {
  Protocol.openapi: 'openapi',
  Protocol.openmodbus: 'openmodbus',
  Protocol.jsonrpcHttp: 'jsonrpcHttp',
  Protocol.opentool: 'opentool',
  Protocol.mcpStdio: 'mcpStdio',
  Protocol.mcpHttp: 'mcpHttp',
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
  modelId: json['modelId'] as String?,
  baseUrl: json['baseUrl'] as String?,
  apiKey: json['apiKey'] as String?,
  model: json['model'] as String?,
  temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
  maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 4096,
  contextWindowSize: (json['contextWindowSize'] as num?)?.toInt(),
  topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
  supportsToolCall: json['supportsToolCall'] as bool? ?? true,
  supportsReasoning: json['supportsReasoning'] as bool? ?? false,
);

Map<String, dynamic> _$LLMConfigToJson(LLMConfig instance) => <String, dynamic>{
  'modelId': ?instance.modelId,
  'baseUrl': ?instance.baseUrl,
  'apiKey': ?instance.apiKey,
  'model': ?instance.model,
  'temperature': instance.temperature,
  'maxTokens': instance.maxTokens,
  'contextWindowSize': ?instance.contextWindowSize,
  'topP': instance.topP,
  'supportsToolCall': instance.supportsToolCall,
  'supportsReasoning': instance.supportsReasoning,
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
      llmConfig: json['llmConfig'] == null
          ? null
          : LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
      systemPrompt: json['systemPrompt'] as String,
    );

Map<String, dynamic> _$SimpleCapabilityToJson(SimpleCapability instance) =>
    <String, dynamic>{
      'llmConfig': ?instance.llmConfig?.toJson(),
      'systemPrompt': instance.systemPrompt,
    };

Capability _$CapabilityFromJson(Map<String, dynamic> json) => Capability(
  llmConfig: json['llmConfig'] == null
      ? null
      : LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
  systemPrompt: json['systemPrompt'] as String,
  openSpecList: (json['openSpecList'] as List<dynamic>?)
      ?.map((e) => OpenSpec.fromJson(e as Map<String, dynamic>))
      .toList(),
  callbackOpenTool: json['callbackOpenTool'] == null
      ? null
      : CallbackOpenTool.fromJson(
          json['callbackOpenTool'] as Map<String, dynamic>,
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
  auto: json['auto'] as bool?,
  llmConfigList: (json['llmConfigList'] as List<dynamic>?)
      ?.map((e) => LLMConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  enableThinking: json['enableThinking'] as bool?,
  toolReturnPackMinLength: (json['toolReturnPackMinLength'] as num?)?.toInt(),
);

Map<String, dynamic> _$CapabilityToJson(Capability instance) =>
    <String, dynamic>{
      'llmConfig': ?instance.llmConfig?.toJson(),
      'systemPrompt': instance.systemPrompt,
      'openSpecList': ?instance.openSpecList?.map((e) => e.toJson()).toList(),
      'callbackOpenTool': ?instance.callbackOpenTool?.toJson(),
      'sessionList': ?instance.sessionList?.map((e) => e.toJson()).toList(),
      'reflectPromptList': ?instance.reflectPromptList
          ?.map((e) => e.toJson())
          .toList(),
      'timeoutSeconds': instance.timeoutSeconds,
      'taskPipelineStrategy':
          _$PipelineStrategyTypeEnumMap[instance.taskPipelineStrategy]!,
      'toolPipelineStrategy':
          ?_$PipelineStrategyTypeEnumMap[instance.toolPipelineStrategy],
      'auto': ?instance.auto,
      'llmConfigList': ?instance.llmConfigList?.map((e) => e.toJson()).toList(),
      'enableThinking': ?instance.enableThinking,
      'toolReturnPackMinLength': ?instance.toolReturnPackMinLength,
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
