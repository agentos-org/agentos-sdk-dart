import 'package:json_annotation/json_annotation.dart';
import 'sessions_dto.dart';

part 'capability_dto.g.dart';

// Object? _readSupportsToolCalling(Map json, String key) {
//   return json['supportsToolCall'] ?? json['supportsToolCalling'];
// }
//
// Object? _readSupportsDeepThinking(Map json, String key) {
//   return json['supportsReasoning'] ?? json['supportsDeepThinking'];
// }

enum ApiKeyType { basic, bearer, original }

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ApiKey {
  ApiKeyType type;
  String apiKey;

  ApiKey({required this.type, required this.apiKey});

  factory ApiKey.fromJson(Map<String, dynamic> json) => _$ApiKeyFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyToJson(this);
}

enum Protocol {
  openapi,
  openmodbus,
  jsonrpcHttp,
  opentool,
  mcpStdio,
  mcpHttp,
  serialport,
}

enum PipelineStrategyType { parallel, serial, reject }

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class OpenSpec {
  String openSpec;
  ApiKey? apiKey;
  Protocol protocol;
  String? serverUrl;
  String? openToolId; //When protocol is open tool, this is the tool id

  OpenSpec({
    required this.openSpec,
    this.apiKey,
    required this.protocol,
    this.serverUrl,
    this.openToolId,
  });

  factory OpenSpec.fromJson(Map<String, dynamic> json) =>
      _$OpenSpecFromJson(json);

  Map<String, dynamic> toJson() => _$OpenSpecToJson(this);
}

@JsonSerializable()
class CallbackOpenTool {
  String opentool;
  int? timeout;

  CallbackOpenTool({required this.opentool, this.timeout});

  factory CallbackOpenTool.fromJson(Map<String, dynamic> json) =>
      _$CallbackOpenToolFromJson(json);

  Map<String, dynamic> toJson() => _$CallbackOpenToolToJson(this);
}

@JsonSerializable(includeIfNull: false)
class LLMConfig {
  String? modelId;
  String? baseUrl;
  String? apiKey;
  String? model;
  double temperature;
  int maxTokens;
  int? contextWindowSize;
  double topP;
  bool supportsToolCall;
  bool supportsReasoning;

  LLMConfig({
    this.modelId,
    this.baseUrl,
    this.apiKey,
    this.model,
    this.temperature = 0.0,
    this.maxTokens = 4096,
    this.contextWindowSize,
    this.topP = 1.0,
    this.supportsToolCall = true,
    this.supportsReasoning = false,
  });

  factory LLMConfig.fromJson(Map<String, dynamic> json) =>
      _$LLMConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LLMConfigToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ReflectPrompt {
  LLMConfig llmConfig;
  String prompt;

  ReflectPrompt({required this.llmConfig, required this.prompt});

  factory ReflectPrompt.fromJson(Map<String, dynamic> json) =>
      _$ReflectPromptFromJson(json);

  Map<String, dynamic> toJson() => _$ReflectPromptToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SimpleCapability {
  LLMConfig? llmConfig;
  String systemPrompt;

  SimpleCapability({this.llmConfig, required this.systemPrompt});

  factory SimpleCapability.fromJson(Map<String, dynamic> json) =>
      _$SimpleCapabilityFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleCapabilityToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Capability extends SimpleCapability {
  List<OpenSpec>? openSpecList;
  CallbackOpenTool? callbackOpenTool;
  List<SessionName>? sessionList;
  List<ReflectPrompt>? reflectPromptList;
  int timeoutSeconds;
  PipelineStrategyType taskPipelineStrategy;
  PipelineStrategyType? toolPipelineStrategy;
  bool? auto;
  List<LLMConfig>? llmConfigList;
  bool? enableThinking;
  int? toolReturnPackMinLength;

  Capability({
    super.llmConfig,
    required super.systemPrompt,
    this.openSpecList,
    this.callbackOpenTool,
    this.sessionList,
    this.reflectPromptList,
    this.timeoutSeconds = 3600,
    this.taskPipelineStrategy = PipelineStrategyType.parallel,
    this.toolPipelineStrategy,
    this.auto,
    this.llmConfigList,
    this.enableThinking,
    this.toolReturnPackMinLength,
  });

  factory Capability.fromJson(Map<String, dynamic> json) =>
      _$CapabilityFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CapabilityToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class OpenToolInfo {
  late String openToolId;
  late String description;

  OpenToolInfo({required this.openToolId, required this.description});

  factory OpenToolInfo.fromJson(Map<String, dynamic> json) =>
      _$OpenToolInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolInfoToJson(this);
}
