import 'package:json_annotation/json_annotation.dart';
import '../shared/dto.dart';
import 'capability_dto.dart';
import 'common_dto.dart';

part 'messages_dto.g.dart';

Object? _readOriginalTaskId(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json['taskId'];

@JsonSerializable()
class AgentEvent {
  String
  agentEventType; // AgentEventType.message | AgentEventType.chunk | AgentEventType.functionCall (agentmessage/agentmessagechunk are normalized)
  String data;

  AgentEvent({required this.agentEventType, required this.data});

  factory AgentEvent.fromJson(Map<String, dynamic> json) =>
      _$AgentEventFromJson(json);

  Map<String, dynamic> toJson() => _$AgentEventToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentMessage {
  String sessionId;
  String? agentId;
  @JsonKey(readValue: _readOriginalTaskId)
  String originalTaskId;
  String? parentTaskId;
  String taskId;
  String role;
  String to;
  String type;
  dynamic content;
  String? reasoningContent;

  Completions?
  completions; //When role is llm, this is current llm calling token usage

  DateTime createTime;

  AgentMessage({
    required this.sessionId,
    this.agentId,
    String? originalTaskId,
    this.parentTaskId,
    required this.taskId,
    required this.role,
    required this.to,
    required this.type,
    required this.content,
    this.reasoningContent,
    this.completions,
    required this.createTime,
  }) : originalTaskId = originalTaskId ?? taskId;

  factory AgentMessage.fromJson(Map<String, dynamic> json) =>
      _$AgentMessageFromJson(json);

  Map<String, dynamic> toJson() => _$AgentMessageToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class AgentMessageChunk {
  String sessionId;
  String? agentId;
  String? parentTaskId;
  String taskId;
  String role;
  String to;
  String type;
  dynamic part;
  DateTime createTime;

  AgentMessageChunk({
    required this.sessionId,
    this.agentId,
    this.parentTaskId,
    required this.taskId,
    required this.role,
    required this.to,
    required this.type,
    required this.part,
    required this.createTime,
  });

  factory AgentMessageChunk.fromJson(Map<String, dynamic> json) =>
      _$AgentMessageChunkFromJson(json);

  Map<String, dynamic> toJson() => _$AgentMessageChunkToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Completions {
  TokenUsage? usage;

  /// When role is llm, this is current llm calling token usage
  String id;

  /// When role is llm, this is current /chat/completions return message id
  String model;
  CompletionsLimits? limits;

  Completions({
    required this.usage,
    required this.id,
    required this.model,
    this.limits,
  });

  factory Completions.fromJson(Map<String, dynamic> json) =>
      _$CompletionsFromJson(json);

  Map<String, dynamic> toJson() => _$CompletionsToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CompletionsLimits {
  final int maxTokens;
  final int? contextWindowSize;

  CompletionsLimits({required this.maxTokens, this.contextWindowSize});

  factory CompletionsLimits.fromJson(Map<String, dynamic> json) =>
      _$CompletionsLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$CompletionsLimitsToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double? contextUsageRatio;

  TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.contextUsageRatio,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) =>
      _$TokenUsageFromJson(json);

  Map<String, dynamic> toJson() => _$TokenUsageToJson(this);
}

class HistoryTurnStatus {
  static const String running = 'running';
  static const String done = 'done';
  static const String error = 'error';
  static const String stopped = 'stopped';
}

@JsonSerializable(explicitToJson: true)
class HistoryTurnSummaryDto {
  final String originalTaskId;
  final String sessionId;
  final AgentMessage? userMessage;
  final AgentMessage? finalMessage;
  final String status;
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final int? durationMs;
  final TokenUsage? usage;
  final int processMessageCount;

  const HistoryTurnSummaryDto({
    required this.originalTaskId,
    required this.sessionId,
    required this.userMessage,
    required this.finalMessage,
    required this.status,
    required this.error,
    required this.createdAt,
    required this.completedAt,
    required this.durationMs,
    required this.usage,
    required this.processMessageCount,
  });

  factory HistoryTurnSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$HistoryTurnSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryTurnSummaryDtoToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class UserTask {
  List<Content> content;
  bool? isChunk;
  String? extraSystemPrompt;
  LLMConfig? llmConfig;

  UserTask({
    required this.content,
    this.isChunk,
    this.extraSystemPrompt,
    this.llmConfig,
  });

  factory UserTask.fromJson(Map<String, dynamic> json) =>
      _$UserTaskFromJson(json);

  Map<String, dynamic> toJson() => _$UserTaskToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class EventToolReturn {
  @JsonKey(name: 'event')
  String event; // EventType.start | EventType.data | EventType.error | EventType.done
  ToolReturn toolReturn;

  EventToolReturn({required this.event, required this.toolReturn});

  factory EventToolReturn.fromJson(Map<String, dynamic> json) =>
      _$EventToolReturnFromJson(json);

  Map<String, dynamic> toJson() => _$EventToolReturnToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class Dispatch {
  String dispatchId;
  String agentId;
  String name;
  List<Content> content;

  Dispatch({
    required this.dispatchId,
    required this.agentId,
    required this.name,
    required this.content,
  });

  factory Dispatch.fromJson(Map<String, dynamic> json) =>
      _$DispatchFromJson(json);

  Map<String, dynamic> toJson() => _$DispatchToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class TaskStatus {
  String status;
  String? taskId;
  Map<String, dynamic>? description;

  TaskStatus({required this.status, this.taskId, this.description});

  factory TaskStatus.fromJson(Map<String, dynamic> json) =>
      _$TaskStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStatusToJson(this);
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

  factory Reflection.fromJson(Map<String, dynamic> json) =>
      _$ReflectionFromJson(json);

  Map<String, dynamic> toJson() => _$ReflectionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class MessageScore {
  List<Content> content;
  String
  messageType; // AgentMessageType.text | AgentMessageType.imageUrl | AgentMessageType.dispatch | AgentMessageType.toolCalls | AgentMessageType.toolReturn | AgentMessageType.contentList | AgentMessageType.reflection | AgentMessageType.taskStatus | AgentMessageType.functionCall | AgentMessageType.reasoningContent | AgentMessageType.planning
  String message;
  List<ReflectScore> reflectScoreList;
  MessageScore({
    required this.content,
    required this.messageType,
    required this.message,
    required this.reflectScoreList,
  });

  factory MessageScore.fromJson(Map<String, dynamic> json) =>
      _$MessageScoreFromJson(json);

  Map<String, dynamic> toJson() => _$MessageScoreToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ReflectScore {
  int score;
  String? description;
  ReflectScore({required this.score, this.description});

  factory ReflectScore.fromJson(Map<String, dynamic> json) =>
      _$ReflectScoreFromJson(json);

  Map<String, dynamic> toJson() => _$ReflectScoreToJson(this);
}
