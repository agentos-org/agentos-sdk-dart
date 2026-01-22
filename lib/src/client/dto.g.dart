// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentEvent _$AgentEventFromJson(Map<String, dynamic> json) => AgentEvent(
  agentEventType: json['agentEventType'] as String,
  data: json['data'] as String,
);

Map<String, dynamic> _$AgentEventToJson(AgentEvent instance) =>
    <String, dynamic>{
      'agentEventType': instance.agentEventType,
      'data': instance.data,
    };

AgentOSEvent _$AgentOSEventFromJson(Map<String, dynamic> json) => AgentOSEvent(
  agentosEventType: json['agentosEventType'] as String,
  data: json['data'] as String,
);

Map<String, dynamic> _$AgentOSEventToJson(AgentOSEvent instance) =>
    <String, dynamic>{
      'agentosEventType': instance.agentosEventType,
      'data': instance.data,
    };

Call _$CallFromJson(Map<String, dynamic> json) => Call(
  id: json['id'] as String,
  from: json['from'] as String,
  contentList: (json['contentList'] as List<dynamic>)
      .map((e) => Content.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CallToJson(Call instance) => <String, dynamic>{
  'id': instance.id,
  'from': instance.from,
  'contentList': instance.contentList,
};

Welcome _$WelcomeFromJson(Map<String, dynamic> json) =>
    Welcome(bundleId: json['bundleId'] as String);

Map<String, dynamic> _$WelcomeToJson(Welcome instance) => <String, dynamic>{
  'bundleId': instance.bundleId,
};

AppBundle _$AppBundleFromJson(Map<String, dynamic> json) =>
    AppBundle(bundleId: json['bundleId'] as String);

Map<String, dynamic> _$AppBundleToJson(AppBundle instance) => <String, dynamic>{
  'bundleId': instance.bundleId,
};

AccessToken _$AccessTokenFromJson(Map<String, dynamic> json) =>
    AccessToken(token: json['token'] as String);

Map<String, dynamic> _$AccessTokenToJson(AccessToken instance) =>
    <String, dynamic>{'token': instance.token};

Session _$SessionFromJson(Map<String, dynamic> json) =>
    Session(sessionId: json['sessionId'] as String);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
};

SessionName _$SessionNameFromJson(Map<String, dynamic> json) => SessionName(
  sessionId: json['sessionId'] as String,
  name: json['name'] as String?,
);

Map<String, dynamic> _$SessionNameToJson(SessionName instance) =>
    <String, dynamic>{'sessionId': instance.sessionId, 'name': ?instance.name};

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

LLMConfig _$LLMConfigFromJson(Map<String, dynamic> json) => LLMConfig(
  baseUrl: json['baseUrl'] as String,
  apiKey: json['apiKey'] as String,
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

AgentMessage _$AgentMessageFromJson(Map<String, dynamic> json) => AgentMessage(
  sessionId: json['sessionId'] as String,
  taskId: json['taskId'] as String,
  role: json['role'] as String,
  to: json['to'] as String,
  type: json['type'] as String,
  content: json['content'],
  completions: json['completions'] == null
      ? null
      : Completions.fromJson(json['completions'] as Map<String, dynamic>),
  createTime: DateTime.parse(json['createTime'] as String),
);

Map<String, dynamic> _$AgentMessageToJson(AgentMessage instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'taskId': instance.taskId,
      'role': instance.role,
      'to': instance.to,
      'type': instance.type,
      'content': ?instance.content,
      'completions': ?instance.completions?.toJson(),
      'createTime': instance.createTime.toIso8601String(),
    };

Completions _$CompletionsFromJson(Map<String, dynamic> json) => Completions(
  usage: json['usage'] == null
      ? null
      : TokenUsage.fromJson(json['usage'] as Map<String, dynamic>),
  id: json['id'] as String,
  model: json['model'] as String,
);

Map<String, dynamic> _$CompletionsToJson(Completions instance) =>
    <String, dynamic>{
      'usage': ?instance.usage?.toJson(),
      'id': instance.id,
      'model': instance.model,
    };

TokenUsage _$TokenUsageFromJson(Map<String, dynamic> json) => TokenUsage(
  promptTokens: (json['promptTokens'] as num).toInt(),
  completionTokens: (json['completionTokens'] as num).toInt(),
  totalTokens: (json['totalTokens'] as num).toInt(),
);

Map<String, dynamic> _$TokenUsageToJson(TokenUsage instance) =>
    <String, dynamic>{
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
    };

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

UserTask _$UserTaskFromJson(Map<String, dynamic> json) => UserTask(
  taskId: json['taskId'] as String?,
  content: (json['content'] as List<dynamic>)
      .map((e) => Content.fromJson(e as Map<String, dynamic>))
      .toList(),
  isChunk: json['isChunk'] as bool? ?? true,
);

Map<String, dynamic> _$UserTaskToJson(UserTask instance) => <String, dynamic>{
  'taskId': ?instance.taskId,
  'content': instance.content.map((e) => e.toJson()).toList(),
  'isChunk': instance.isChunk,
};

EventToolReturn _$EventToolReturnFromJson(Map<String, dynamic> json) =>
    EventToolReturn(
      agentEventType: json['agentEventType'] as String,
      toolReturn: ToolReturn.fromJson(
        json['toolReturn'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$EventToolReturnToJson(EventToolReturn instance) =>
    <String, dynamic>{
      'agentEventType': instance.agentEventType,
      'toolReturn': instance.toolReturn.toJson(),
    };

SessionTask _$SessionTaskFromJson(Map<String, dynamic> json) => SessionTask(
  sessionId: json['sessionId'] as String,
  taskId: json['taskId'] as String?,
);

Map<String, dynamic> _$SessionTaskToJson(SessionTask instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'taskId': ?instance.taskId,
    };

ReflectScore _$ReflectScoreFromJson(Map<String, dynamic> json) => ReflectScore(
  score: (json['score'] as num).toInt(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$ReflectScoreToJson(ReflectScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'description': ?instance.description,
    };

MessageScore _$MessageScoreFromJson(Map<String, dynamic> json) => MessageScore(
  content: (json['content'] as List<dynamic>)
      .map((e) => Content.fromJson(e as Map<String, dynamic>))
      .toList(),
  messageType: json['messageType'] as String,
  message: json['message'] as String,
  reflectScoreList: (json['reflectScoreList'] as List<dynamic>)
      .map((e) => ReflectScore.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MessageScoreToJson(
  MessageScore instance,
) => <String, dynamic>{
  'content': instance.content.map((e) => e.toJson()).toList(),
  'messageType': instance.messageType,
  'message': instance.message,
  'reflectScoreList': instance.reflectScoreList.map((e) => e.toJson()).toList(),
};

Reflection _$ReflectionFromJson(Map<String, dynamic> json) => Reflection(
  isPass: json['isPass'] as bool,
  messageScore: MessageScore.fromJson(
    json['messageScore'] as Map<String, dynamic>,
  ),
  passScore: (json['passScore'] as num).toInt(),
  count: (json['count'] as num).toInt(),
  maxCount: (json['maxCount'] as num).toInt(),
);

Map<String, dynamic> _$ReflectionToJson(Reflection instance) =>
    <String, dynamic>{
      'isPass': instance.isPass,
      'messageScore': instance.messageScore.toJson(),
      'passScore': instance.passScore,
      'count': instance.count,
      'maxCount': instance.maxCount,
    };

TaskStatus _$TaskStatusFromJson(Map<String, dynamic> json) => TaskStatus(
  status: json['status'] as String,
  description: json['description'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$TaskStatusToJson(TaskStatus instance) =>
    <String, dynamic>{
      'status': instance.status,
      'description': ?instance.description,
    };

Content _$ContentFromJson(Map<String, dynamic> json) =>
    Content(type: json['type'] as String, message: json['message'] as String);

Map<String, dynamic> _$ContentToJson(Content instance) => <String, dynamic>{
  'type': instance.type,
  'message': instance.message,
};

Dispatch _$DispatchFromJson(Map<String, dynamic> json) => Dispatch(
  dispatchId: json['dispatchId'] as String,
  agentId: json['agentId'] as String,
  name: json['name'] as String,
  content: (json['content'] as List<dynamic>)
      .map((e) => Content.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DispatchToJson(Dispatch instance) => <String, dynamic>{
  'dispatchId': instance.dispatchId,
  'agentId': instance.agentId,
  'name': instance.name,
  'content': instance.content.map((e) => e.toJson()).toList(),
};

PlanModel _$PlanModelFromJson(Map<String, dynamic> json) =>
    PlanModel(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$PlanModelToJson(PlanModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

PlanTool _$PlanToolFromJson(Map<String, dynamic> json) => PlanTool(
  id: json['id'] as String,
  name: json['name'] as String,
  desc: json['desc'] as String,
);

Map<String, dynamic> _$PlanToolToJson(PlanTool instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'desc': instance.desc,
};

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
  name: json['name'] as String,
  model: PlanModel.fromJson(json['model'] as Map<String, dynamic>),
  prompt: json['prompt'] as String,
  tools:
      (json['tools'] as List<dynamic>?)
          ?.map((e) => PlanTool.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  subPlans:
      (json['subPlans'] as List<dynamic>?)
          ?.map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'name': instance.name,
  'model': instance.model.toJson(),
  'prompt': instance.prompt,
  'tools': instance.tools.map((e) => e.toJson()).toList(),
  'subPlans': instance.subPlans.map((e) => e.toJson()).toList(),
};

PlanningContent _$PlanningContentFromJson(Map<String, dynamic> json) =>
    PlanningContent(
      planId: json['planId'] as String,
      plans: (json['plans'] as List<dynamic>)
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanningContentToJson(PlanningContent instance) =>
    <String, dynamic>{
      'planId': instance.planId,
      'plans': instance.plans.map((e) => e.toJson()).toList(),
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

AgentMessageChunk _$AgentMessageChunkFromJson(Map<String, dynamic> json) =>
    AgentMessageChunk(
      sessionId: json['sessionId'] as String,
      taskId: json['taskId'] as String,
      role: json['role'] as String,
      to: json['to'] as String,
      type: json['type'] as String,
      part: json['part'],
      createTime: DateTime.parse(json['createTime'] as String),
    );

Map<String, dynamic> _$AgentMessageChunkToJson(AgentMessageChunk instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'taskId': instance.taskId,
      'role': instance.role,
      'to': instance.to,
      'type': instance.type,
      'part': ?instance.part,
      'createTime': instance.createTime.toIso8601String(),
    };

AgentId _$AgentIdFromJson(Map<String, dynamic> json) =>
    AgentId(agentId: json['agentId'] as String);

Map<String, dynamic> _$AgentIdToJson(AgentId instance) => <String, dynamic>{
  'agentId': instance.agentId,
};

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
  name: json['name'] as String,
  capability: Capability.fromJson(json['capability'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
  'name': instance.name,
  'capability': instance.capability.toJson(),
};

AgentInfo _$AgentInfoFromJson(Map<String, dynamic> json) => AgentInfo(
  agentId: json['agentId'] as String,
  name: json['name'] as String,
  capability: Capability.fromJson(json['capability'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AgentInfoToJson(AgentInfo instance) => <String, dynamic>{
  'agentId': instance.agentId,
  'name': instance.name,
  'capability': instance.capability.toJson(),
};

SessionAgentMessage _$SessionAgentMessageFromJson(Map<String, dynamic> json) =>
    SessionAgentMessage(
      sessionId: json['sessionId'] as String,
      agentMessage: AgentMessage.fromJson(
        json['agentMessage'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SessionAgentMessageToJson(
  SessionAgentMessage instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'agentMessage': instance.agentMessage.toJson(),
};

Version _$VersionFromJson(Map<String, dynamic> json) =>
    Version(version: json['version'] as String);

Map<String, dynamic> _$VersionToJson(Version instance) => <String, dynamic>{
  'version': instance.version,
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

CallbackOpenTool _$CallbackOpenToolFromJson(Map<String, dynamic> json) =>
    CallbackOpenTool(
      opentool: json['opentool'] as String,
      timeout: (json['timeout'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CallbackOpenToolToJson(CallbackOpenTool instance) =>
    <String, dynamic>{
      'opentool': instance.opentool,
      'timeout': ?instance.timeout,
    };
