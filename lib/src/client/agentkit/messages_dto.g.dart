// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_dto.dart';

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

AgentMessage _$AgentMessageFromJson(Map<String, dynamic> json) => AgentMessage(
  sessionId: json['sessionId'] as String,
  agentId: json['agentId'] as String?,
  originalTaskId: _readOriginalTaskId(json, 'originalTaskId') as String?,
  parentTaskId: json['parentTaskId'] as String?,
  taskId: json['taskId'] as String,
  role: json['role'] as String,
  to: json['to'] as String,
  type: json['type'] as String,
  content: json['content'],
  reasoningContent: json['reasoningContent'] as String?,
  completions: json['completions'] == null
      ? null
      : Completions.fromJson(json['completions'] as Map<String, dynamic>),
  createTime: DateTime.parse(json['createTime'] as String),
);

Map<String, dynamic> _$AgentMessageToJson(AgentMessage instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'agentId': ?instance.agentId,
      'originalTaskId': instance.originalTaskId,
      'parentTaskId': ?instance.parentTaskId,
      'taskId': instance.taskId,
      'role': instance.role,
      'to': instance.to,
      'type': instance.type,
      'content': ?instance.content,
      'reasoningContent': ?instance.reasoningContent,
      'completions': ?instance.completions?.toJson(),
      'createTime': instance.createTime.toIso8601String(),
    };

AgentMessageChunk _$AgentMessageChunkFromJson(Map<String, dynamic> json) =>
    AgentMessageChunk(
      sessionId: json['sessionId'] as String,
      agentId: json['agentId'] as String?,
      parentTaskId: json['parentTaskId'] as String?,
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
      'agentId': ?instance.agentId,
      'parentTaskId': ?instance.parentTaskId,
      'taskId': instance.taskId,
      'role': instance.role,
      'to': instance.to,
      'type': instance.type,
      'part': ?instance.part,
      'createTime': instance.createTime.toIso8601String(),
    };

Completions _$CompletionsFromJson(Map<String, dynamic> json) => Completions(
  usage: json['usage'] == null
      ? null
      : TokenUsage.fromJson(json['usage'] as Map<String, dynamic>),
  id: json['id'] as String,
  model: json['model'] as String,
  limits: json['limits'] == null
      ? null
      : CompletionsLimits.fromJson(json['limits'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CompletionsToJson(Completions instance) =>
    <String, dynamic>{
      'usage': ?instance.usage?.toJson(),
      'id': instance.id,
      'model': instance.model,
      'limits': ?instance.limits?.toJson(),
    };

CompletionsLimits _$CompletionsLimitsFromJson(Map<String, dynamic> json) =>
    CompletionsLimits(
      maxTokens: (json['maxTokens'] as num).toInt(),
      contextWindowSize: (json['contextWindowSize'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CompletionsLimitsToJson(CompletionsLimits instance) =>
    <String, dynamic>{
      'maxTokens': instance.maxTokens,
      'contextWindowSize': ?instance.contextWindowSize,
    };

TokenUsage _$TokenUsageFromJson(Map<String, dynamic> json) => TokenUsage(
  promptTokens: (json['promptTokens'] as num).toInt(),
  completionTokens: (json['completionTokens'] as num).toInt(),
  totalTokens: (json['totalTokens'] as num).toInt(),
  contextUsageRatio: (json['contextUsageRatio'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TokenUsageToJson(TokenUsage instance) =>
    <String, dynamic>{
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
      'contextUsageRatio': ?instance.contextUsageRatio,
    };

HistoryTurnSummaryDto _$HistoryTurnSummaryDtoFromJson(
  Map<String, dynamic> json,
) => HistoryTurnSummaryDto(
  originalTaskId: json['originalTaskId'] as String,
  sessionId: json['sessionId'] as String,
  userMessage: json['userMessage'] == null
      ? null
      : AgentMessage.fromJson(json['userMessage'] as Map<String, dynamic>),
  finalMessage: json['finalMessage'] == null
      ? null
      : AgentMessage.fromJson(json['finalMessage'] as Map<String, dynamic>),
  status: json['status'] as String,
  error: json['error'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  durationMs: (json['durationMs'] as num?)?.toInt(),
  usage: json['usage'] == null
      ? null
      : TokenUsage.fromJson(json['usage'] as Map<String, dynamic>),
  processMessageCount: (json['processMessageCount'] as num).toInt(),
);

Map<String, dynamic> _$HistoryTurnSummaryDtoToJson(
  HistoryTurnSummaryDto instance,
) => <String, dynamic>{
  'originalTaskId': instance.originalTaskId,
  'sessionId': instance.sessionId,
  'userMessage': instance.userMessage?.toJson(),
  'finalMessage': instance.finalMessage?.toJson(),
  'status': instance.status,
  'error': instance.error,
  'createdAt': instance.createdAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'durationMs': instance.durationMs,
  'usage': instance.usage?.toJson(),
  'processMessageCount': instance.processMessageCount,
};

UserTask _$UserTaskFromJson(Map<String, dynamic> json) => UserTask(
  content: (json['content'] as List<dynamic>)
      .map((e) => Content.fromJson(e as Map<String, dynamic>))
      .toList(),
  isChunk: json['isChunk'] as bool?,
  extraSystemPrompt: json['extraSystemPrompt'] as String?,
  llmConfig: json['llmConfig'] == null
      ? null
      : LLMConfig.fromJson(json['llmConfig'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserTaskToJson(UserTask instance) => <String, dynamic>{
  'content': instance.content.map((e) => e.toJson()).toList(),
  'isChunk': ?instance.isChunk,
  'extraSystemPrompt': ?instance.extraSystemPrompt,
  'llmConfig': ?instance.llmConfig?.toJson(),
};

EventToolReturn _$EventToolReturnFromJson(Map<String, dynamic> json) =>
    EventToolReturn(
      event: json['event'] as String,
      toolReturn: ToolReturn.fromJson(
        json['toolReturn'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$EventToolReturnToJson(EventToolReturn instance) =>
    <String, dynamic>{
      'event': instance.event,
      'toolReturn': instance.toolReturn.toJson(),
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

TaskStatus _$TaskStatusFromJson(Map<String, dynamic> json) => TaskStatus(
  status: json['status'] as String,
  taskId: json['taskId'] as String?,
  description: json['description'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$TaskStatusToJson(TaskStatus instance) =>
    <String, dynamic>{
      'status': instance.status,
      'taskId': ?instance.taskId,
      'description': ?instance.description,
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

ReflectScore _$ReflectScoreFromJson(Map<String, dynamic> json) => ReflectScore(
  score: (json['score'] as num).toInt(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$ReflectScoreToJson(ReflectScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'description': ?instance.description,
    };
