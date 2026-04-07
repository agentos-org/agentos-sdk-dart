import 'package:json_annotation/json_annotation.dart';

import '../agentkit/messages_dto.dart';
import '../shared/dto.dart';

part 'dto.g.dart';

enum CronTaskConcurrency { skipIfRunning }

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CronSpec {
  String systemPrompt;
  List<Content> content;
  int timeoutSeconds;
  String? modelId;
  String? modelName;

  CronSpec({
    required this.systemPrompt,
    required this.content,
    this.timeoutSeconds = 3600,
    this.modelId,
    this.modelName,
  });

  factory CronSpec.fromJson(Map<String, dynamic> json) =>
      _$CronSpecFromJson(json);

  Map<String, dynamic> toJson() => _$CronSpecToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CronTaskCreateRequest {
  String name;
  String schedule;
  CronSpec spec;
  String? userId;
  String? sessionId;
  String? timezone;
  CronTaskConcurrency concurrency;
  bool enabled;

  CronTaskCreateRequest({
    required this.name,
    required this.schedule,
    required this.spec,
    this.userId,
    this.sessionId,
    this.timezone,
    this.concurrency = CronTaskConcurrency.skipIfRunning,
    this.enabled = true,
  });

  factory CronTaskCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$CronTaskCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskCreateRequestToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CronTaskUpdateRequest {
  String cronId;
  String? name;
  String? schedule;
  CronSpec? spec;
  String? timezone;
  CronTaskConcurrency? concurrency;
  bool? enabled;

  CronTaskUpdateRequest({
    required this.cronId,
    this.name,
    this.schedule,
    this.spec,
    this.timezone,
    this.concurrency,
    this.enabled,
  });

  factory CronTaskUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$CronTaskUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskUpdateRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronTaskActionRequest {
  String cronId;

  CronTaskActionRequest({required this.cronId});

  factory CronTaskActionRequest.fromJson(Map<String, dynamic> json) =>
      _$CronTaskActionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskActionRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronTaskSetEnabledRequest {
  String cronId;
  bool enabled;

  CronTaskSetEnabledRequest({required this.cronId, required this.enabled});

  factory CronTaskSetEnabledRequest.fromJson(Map<String, dynamic> json) =>
      _$CronTaskSetEnabledRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskSetEnabledRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronTaskRunNowRequest {
  String cronId;
  DateTime? scheduledAt;

  CronTaskRunNowRequest({required this.cronId, this.scheduledAt});

  factory CronTaskRunNowRequest.fromJson(Map<String, dynamic> json) =>
      _$CronTaskRunNowRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskRunNowRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronRunQuery {
  String runId;

  CronRunQuery({required this.runId});

  factory CronRunQuery.fromJson(Map<String, dynamic> json) =>
      _$CronRunQueryFromJson(json);

  Map<String, dynamic> toJson() => _$CronRunQueryToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronTask {
  String cronId;
  String name;
  String schedule;
  String source;
  String? userId;
  String? sessionId;
  String? timezone;
  bool enabled;
  String status;
  String concurrency;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastRunAt;
  DateTime? nextRunAt;
  CronSpec spec;

  CronTask({
    required this.cronId,
    required this.name,
    required this.schedule,
    required this.source,
    this.userId,
    this.sessionId,
    this.timezone,
    required this.enabled,
    required this.status,
    required this.concurrency,
    required this.createdAt,
    required this.updatedAt,
    this.lastRunAt,
    this.nextRunAt,
    required this.spec,
  });

  factory CronTask.fromJson(Map<String, dynamic> json) =>
      _$CronTaskFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronTaskListItem {
  String cronId;
  String name;
  String schedule;
  bool enabled;
  String status;
  CronSpec? spec;
  DateTime? lastRunAt;
  DateTime? nextRunAt;

  CronTaskListItem({
    required this.cronId,
    required this.name,
    required this.schedule,
    required this.enabled,
    required this.status,
    this.spec,
    this.lastRunAt,
    this.nextRunAt,
  });

  factory CronTaskListItem.fromJson(Map<String, dynamic> json) =>
      _$CronTaskListItemFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskListItemToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronTaskDeleteResult {
  bool deleted;
  String cronId;

  CronTaskDeleteResult({required this.deleted, required this.cronId});

  factory CronTaskDeleteResult.fromJson(Map<String, dynamic> json) =>
      _$CronTaskDeleteResultFromJson(json);

  Map<String, dynamic> toJson() => _$CronTaskDeleteResultToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronRun {
  String runId;
  String cronId;
  String trigger;
  String status;
  String? modelId;
  DateTime scheduledAt;
  DateTime startedAt;
  bool hasDisplayableResult;
  DateTime? finishedAt;
  String? liteAgentSessionId;
  String? error;
  Map<String, dynamic>? result;
  String? displayMessageId;
  String? displayText;

  CronRun({
    required this.runId,
    required this.cronId,
    required this.trigger,
    required this.status,
    this.modelId,
    required this.scheduledAt,
    required this.startedAt,
    required this.hasDisplayableResult,
    this.finishedAt,
    this.liteAgentSessionId,
    this.error,
    this.result,
    this.displayMessageId,
    this.displayText,
  });

  factory CronRun.fromJson(Map<String, dynamic> json) =>
      _$CronRunFromJson(json);

  Map<String, dynamic> toJson() => _$CronRunToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronRunListItem {
  String runId;
  String cronId;
  String trigger;
  String status;
  String? modelId;
  DateTime scheduledAt;
  DateTime startedAt;
  bool hasDisplayableResult;
  DateTime? finishedAt;
  String? displayText;

  CronRunListItem({
    required this.runId,
    required this.cronId,
    required this.trigger,
    required this.status,
    this.modelId,
    required this.scheduledAt,
    required this.startedAt,
    required this.hasDisplayableResult,
    this.finishedAt,
    this.displayText,
  });

  factory CronRunListItem.fromJson(Map<String, dynamic> json) =>
      _$CronRunListItemFromJson(json);

  Map<String, dynamic> toJson() => _$CronRunListItemToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CronRunMessage {
  String messageId;
  String runId;
  String cronId;
  DateTime timestamp;
  AgentMessage message;

  CronRunMessage({
    required this.messageId,
    required this.runId,
    required this.cronId,
    required this.timestamp,
    required this.message,
  });

  factory CronRunMessage.fromJson(Map<String, dynamic> json) =>
      _$CronRunMessageFromJson(json);

  Map<String, dynamic> toJson() => _$CronRunMessageToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronDeleteRunResult {
  bool deleted;
  String runId;

  CronDeleteRunResult({required this.deleted, required this.runId});

  factory CronDeleteRunResult.fromJson(Map<String, dynamic> json) =>
      _$CronDeleteRunResultFromJson(json);

  Map<String, dynamic> toJson() => _$CronDeleteRunResultToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronSchedulerSnapshot {
  bool running;
  int activeTaskCount;
  int runningTaskCount;
  DateTime? lastTickAt;

  CronSchedulerSnapshot({
    required this.running,
    required this.activeTaskCount,
    required this.runningTaskCount,
    this.lastTickAt,
  });

  factory CronSchedulerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CronSchedulerSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$CronSchedulerSnapshotToJson(this);
}

@JsonSerializable(includeIfNull: false)
class CronSchedulerStatus {
  String status;

  CronSchedulerStatus({required this.status});

  factory CronSchedulerStatus.fromJson(Map<String, dynamic> json) =>
      _$CronSchedulerStatusFromJson(json);

  Map<String, dynamic> toJson() => _$CronSchedulerStatusToJson(this);
}
