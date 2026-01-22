import 'package:json_annotation/json_annotation.dart';
import 'package:opentool_dart/opentool_client.dart' as opentool;
part 'dto.g.dart';

typedef FunctionCall = opentool.FunctionCall;
typedef ToolReturn = opentool.ToolReturn;
typedef Tool = opentool.Tool;
typedef EventType = opentool.EventType;
typedef FunctionNotSupportedException = opentool.FunctionNotSupportedException;

class AgentRoleType {
  static const String system = "developer"; // system prompt
  static const String user = "user"; // user
  static const String agent = "agent"; // agent
  static const String llm = "assistant"; // llm
  static const String tool = "tool"; // external tools
  static const String client = "client"; // external caller
}

class AgentMessageType {
  static const String text = "text"; //String
  static const String imageUrl = "imageUrl"; //String
  static const String dispatch = "dispatch"; //List<Dispatch>
  static const String toolCalls = "toolCalls"; //List<FunctionCall>
  static const String toolReturn = "toolReturn"; //ToolReturn
  static const String contentList = "contentList"; //List<Content>
  static const String reflection = "reflection"; //Reflection
  static const String taskStatus = "taskStatus"; //TaskStatus
  static const String functionCall = "functionCall"; //FunctionCall
  static const String reasoningContent = "reasoningContent"; //String
  static const String planning = "planning"; //PlanningContent
}

class TaskStatusType {
  static const String start = "start";
  static const String stop = "stop";
  static const String done = "done";
  static const String exception = "exception";
  static const String toolsStart = "toolsStart";
  static const String toolsDone = "toolsDone";
  static const String subAgentStart = "subAgentStart";
  static const String subAgentDone = "subAgentDone";
}

class AgentEventType {
  static const String message = "message";
  static const String chunk = "chunk";
  static const String functionCall = "functionCall";
}

@JsonSerializable()
class AgentEvent {
  String agentEventType;
  String data;

  AgentEvent({required this.agentEventType, required this.data});

  factory AgentEvent.fromJson(Map<String, dynamic> json) => _$AgentEventFromJson(json);

  Map<String, dynamic> toJson() => _$AgentEventToJson(this);
}

class AgentOSEventType {
  static const String welcome = "welcome";
  static const String call = "call";
}

@JsonSerializable()
class AgentOSEvent {
  String agentosEventType;
  String data;

  AgentOSEvent({required this.agentosEventType, required this.data});

  factory AgentOSEvent.fromJson(Map<String, dynamic> json) => _$AgentOSEventFromJson(json);

  Map<String, dynamic> toJson() => _$AgentOSEventToJson(this);
}

@JsonSerializable()
class Call {
  String id;
  String from;  // "agentos" | other App bundleId
  List<Content> contentList;

  Call({required this.id, required this.from, required this.contentList});

  factory Call.fromJson(Map<String, dynamic> json) => _$CallFromJson(json);

  Map<String, dynamic> toJson() => _$CallToJson(this);
}

@JsonSerializable()
class Welcome {
  String bundleId;

  Welcome({required this.bundleId});

  factory Welcome.fromJson(Map<String, dynamic> json) => _$WelcomeFromJson(json);

  Map<String, dynamic> toJson() => _$WelcomeToJson(this);
}

@JsonSerializable()
class AppBundle {
  String bundleId;

  AppBundle({required this.bundleId});

  factory AppBundle.fromJson(Map<String, dynamic> json) => _$AppBundleFromJson(json);

  Map<String, dynamic> toJson() => _$AppBundleToJson(this);
}

@JsonSerializable()
class AccessToken {
  String token;

  AccessToken({required this.token});

  factory AccessToken.fromJson(Map<String, dynamic> json) => _$AccessTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AccessTokenToJson(this);
}

@JsonSerializable()
class Session {
  String sessionId;

  Session({required this.sessionId});

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SessionName extends Session {
  String? name; // OpenAI: The name of the function to be called. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.

  SessionName({required super.sessionId, String? name});

  factory SessionName.fromJson(Map<String, dynamic> json) => _$SessionNameFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SessionNameToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SimpleCapability {
  LLMConfig llmConfig;
  String systemPrompt;

  SimpleCapability({
    required this.llmConfig,
    required this.systemPrompt
  });

  factory SimpleCapability.fromJson(Map<String, dynamic> json) => _$SimpleCapabilityFromJson(json);

  Map<String, dynamic> toJson() => _$SimpleCapabilityToJson(this);
}

enum PipelineStrategyType {
  parallel,
  serial,
  reject,
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Capability extends SimpleCapability {
  List<OpenSpec>? openSpecList;
  CallbackOpenTool? clientOpenTool;
  List<SessionName>? sessionList;
  List<ReflectPrompt>? reflectPromptList;
  int timeoutSeconds;
  PipelineStrategyType taskPipelineStrategy;
  PipelineStrategyType? toolPipelineStrategy;

  Capability({
    required super.llmConfig,
    required super.systemPrompt,
    this.openSpecList,
    this.clientOpenTool,
    this.sessionList,
    this.reflectPromptList,
    this.timeoutSeconds = 3600,
    this.taskPipelineStrategy  = PipelineStrategyType.parallel,
    this.toolPipelineStrategy
  });

  factory Capability.fromJson(Map<String, dynamic> json) => _$CapabilityFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CapabilityToJson(this);
}

enum Protocol {
  openapi,
  openmodbus,
  jsonrpcHttp,
  opentool,
  serialport,
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class OpenSpec {
  String openSpec;
  ApiKey? apiKey;
  Protocol protocol;
  String? openToolId; //When protocol is open tool, this is the tool id

  OpenSpec({required this.openSpec, this.apiKey, required this.protocol, this.openToolId});

  factory OpenSpec.fromJson(Map<String, dynamic> json) => _$OpenSpecFromJson(json);

  Map<String, dynamic> toJson() => _$OpenSpecToJson(this);
}

@JsonSerializable()
class LLMConfig {
  String baseUrl;
  String? apiKey;
  String model;
  double temperature;
  int maxTokens;
  double topP;

  LLMConfig({
    this.baseUrl = "http://localhost:8888/agentos/llm/text",
    required this.apiKey,
    required this.model,
    this.temperature = 0.0,
    this.maxTokens = 4096,
    this.topP = 1.0
  });

  factory LLMConfig.fromJson(Map<String, dynamic> json) => _$LLMConfigFromJson(json);

  Map<String, dynamic> toJson() => _$LLMConfigToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentMessage {
  String sessionId;
  String taskId;
  String role;
  String to;
  String type;
  dynamic content;

  Completions? completions; //When role is llm, this is current llm calling token usage

  DateTime createTime;

  AgentMessage({
    required this.sessionId,
    required this.taskId,
    required this.role,
    required this.to,
    required this.type,
    required this.content,
    this.completions,
    required this.createTime
  });

  factory AgentMessage.fromJson(Map<String, dynamic> json) => _$AgentMessageFromJson(json);

  Map<String, dynamic> toJson() => _$AgentMessageToJson(this);

}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Completions {
  TokenUsage? usage;

  /// When role is llm, this is current llm calling token usage
  String id;

  /// When role is llm, this is current /chat/completions return message id
  String model;

  Completions({required this.usage, required this.id, required this.model});

  factory Completions.fromJson(Map<String, dynamic> json) => _$CompletionsFromJson(json);

  Map<String, dynamic> toJson() => _$CompletionsToJson(this);

}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) => _$TokenUsageFromJson(json);

  Map<String, dynamic> toJson() => _$TokenUsageToJson(this);

}

enum ApiKeyType { basic, bearer }

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ApiKey {
  ApiKeyType type;
  String apiKey;

  ApiKey({required this.type, required this.apiKey});

  factory ApiKey.fromJson(Map<String, dynamic> json) => _$ApiKeyFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class UserTask {
  String? taskId;
  List<Content> content;
  bool isChunk;

  UserTask({this.taskId, required this.content, this.isChunk = true});

  factory UserTask.fromJson(Map<String, dynamic> json) {
    if(json["taskId"] != null && (json["taskId"] as String).length > 36) {
      throw FormatException("taskId length should not more then 36");
    }
    return _$UserTaskFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserTaskToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class EventToolReturn {
  String agentEventType;
  ToolReturn toolReturn;

  EventToolReturn({required this.agentEventType, required this.toolReturn});

  factory EventToolReturn.fromJson(Map<String, dynamic> json) => _$EventToolReturnFromJson(json);

  Map<String, dynamic> toJson() => _$EventToolReturnToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SessionTask {
  String sessionId;
  String? taskId;

  SessionTask({required this.sessionId, this.taskId});

  factory SessionTask.fromJson(Map<String, dynamic> json) => _$SessionTaskFromJson(json);

  Map<String, dynamic> toJson() => _$SessionTaskToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ReflectScore {
  int score;
  String? description;
  ReflectScore({required this.score, this.description});

  factory ReflectScore.fromJson(Map<String, dynamic> json) => _$ReflectScoreFromJson(json);

  Map<String, dynamic> toJson() => _$ReflectScoreToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class MessageScore {
  List<Content> content;
  String messageType; //Follow AgentMessage.type
  String message;
  List<ReflectScore> reflectScoreList;
  MessageScore({required this.content, required this.messageType, required this.message, required this.reflectScoreList});

  factory MessageScore.fromJson(Map<String, dynamic> json) => _$MessageScoreFromJson(json);

  Map<String, dynamic> toJson() => _$MessageScoreToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Reflection {
  final bool isPass;
  final MessageScore messageScore;
  final int passScore;
  final int count;
  final int maxCount;

  Reflection({
    required this.isPass,
    required this.messageScore,
    required this.passScore,
    required this.count,
    required this.maxCount,
  });

  factory Reflection.fromJson(Map<String, dynamic> json) => _$ReflectionFromJson(json);

  Map<String, dynamic> toJson() => _$ReflectionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TaskStatus {
  String status;
  Map<String, dynamic>? description;

  TaskStatus({required this.status, this.description});

  factory TaskStatus.fromJson(Map<String, dynamic> json) => _$TaskStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStatusToJson(this);
}

// enum ContentType {
//   text,
//   image_url
// }

class ContentType {
  static final String text = "text";
  static final String imageUrl = "imageUrl";
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Content {
  String type;
  String message;

  Content({required this.type, required this.message});

  factory Content.fromJson(Map<String, dynamic> json) => _$ContentFromJson(json);

  Map<String, dynamic> toJson() => _$ContentToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Dispatch {
  String dispatchId;
  String agentId;
  String name;
  List<Content> content;

  Dispatch({required this.dispatchId, required this.agentId, required this.name, required this.content});

  factory Dispatch.fromJson(Map<String, dynamic> json) => _$DispatchFromJson(json);

  Map<String, dynamic> toJson() => _$DispatchToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PlanModel {
  String id;
  String name;

  PlanModel({required this.id, required this.name});

  factory PlanModel.fromJson(Map<String, dynamic> json) => _$PlanModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlanModelToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PlanTool {
  String id;
  String name;
  String desc;

  PlanTool({required this.id, required this.name, required this.desc});

  factory PlanTool.fromJson(Map<String, dynamic> json) => _$PlanToolFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToolToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Plan {
  String name;
  PlanModel model;
  String prompt;
  @JsonKey(defaultValue: const <PlanTool>[]) List<PlanTool> tools;
  @JsonKey(defaultValue: const <Plan>[]) List<Plan> subPlans;

  Plan({required this.name, required this.model, required this.prompt, List<PlanTool>? tools, List<Plan>? subPlans})
      : tools = tools ?? [],
        subPlans = subPlans ?? [];

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PlanningContent {
  String planId;
  List<Plan> plans;

  PlanningContent({required this.planId, required this.plans});

  factory PlanningContent.fromJson(Map<String, dynamic> json) => _$PlanningContentFromJson(json);

  Map<String, dynamic> toJson() => _$PlanningContentToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ReflectPrompt {
  LLMConfig llmConfig;
  String prompt;

  ReflectPrompt({required this.llmConfig, required this.prompt});

  factory ReflectPrompt.fromJson(Map<String, dynamic> json) => _$ReflectPromptFromJson(json);

  Map<String, dynamic> toJson() => _$ReflectPromptToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentMessageChunk {
  String sessionId;
  String taskId;
  String role;
  String to;
  String type;
  dynamic part;
  DateTime createTime;

  AgentMessageChunk({
    required this.sessionId,
    required this.taskId,
    required this.role,
    required this.to,
    required this.type,
    required this.part,
    required this.createTime
  });

  factory AgentMessageChunk.fromJson(Map<String, dynamic> json) => _$AgentMessageChunkFromJson(json);

  Map<String, dynamic> toJson() => _$AgentMessageChunkToJson(this);

}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentId {
  String agentId;
  AgentId({required this.agentId});

  factory AgentId.fromJson(Map<String, dynamic> json) => _$AgentIdFromJson(json);

  Map<String, dynamic> toJson() => _$AgentIdToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Agent {
  String name;
  Capability capability;
  Agent({required this.name, required this.capability});

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);

  Map<String, dynamic> toJson() => _$AgentToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentInfo extends AgentId {
  String name;
  Capability capability;
  AgentInfo({required super.agentId, required this.name, required this.capability});

  factory AgentInfo.fromJson(Map<String, dynamic> json) => _$AgentInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AgentInfoToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SessionAgentMessage {
  String sessionId;
  AgentMessage agentMessage;
  SessionAgentMessage({required this.sessionId, required this.agentMessage});

  factory SessionAgentMessage.fromJson(Map<String, dynamic> json) => _$SessionAgentMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SessionAgentMessageToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Version {
  late String version;

  Version({required this.version});

  factory Version.fromJson(Map<String, dynamic> json) => _$VersionFromJson(json);

  Map<String, dynamic> toJson() => _$VersionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class OpenToolInfo {
  late String openToolId;
  late String description;

  OpenToolInfo({required this.openToolId, required this.description});

  factory OpenToolInfo.fromJson(Map<String, dynamic> json) => _$OpenToolInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OpenToolInfoToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CallbackOpenTool {
  String opentool;
  int? timeout;

  CallbackOpenTool({required this.opentool, this.timeout});

  factory CallbackOpenTool.fromJson(Map<String, dynamic> json) => _$CallbackOpenToolFromJson(json);

  Map<String, dynamic> toJson() => _$CallbackOpenToolToJson(this);
}
