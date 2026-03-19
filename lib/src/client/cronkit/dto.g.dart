// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CronSpec _$CronSpecFromJson(Map<String, dynamic> json) => CronSpec(
  systemPrompt: json['systemPrompt'] as String,
  content: (json['content'] as List<dynamic>)
      .map((e) => Content.fromJson(e as Map<String, dynamic>))
      .toList(),
  timeoutSeconds: (json['timeoutSeconds'] as num?)?.toInt() ?? 3600,
  modelId: json['modelId'] as String?,
  modelName: json['modelName'] as String?,
);

Map<String, dynamic> _$CronSpecToJson(CronSpec instance) => <String, dynamic>{
  'systemPrompt': instance.systemPrompt,
  'content': instance.content.map((e) => e.toJson()).toList(),
  'timeoutSeconds': instance.timeoutSeconds,
  'modelId': ?instance.modelId,
  'modelName': ?instance.modelName,
};

CronTaskCreateRequest _$CronTaskCreateRequestFromJson(
  Map<String, dynamic> json,
) => CronTaskCreateRequest(
  name: json['name'] as String,
  schedule: json['schedule'] as String,
  spec: CronSpec.fromJson(json['spec'] as Map<String, dynamic>),
  userId: json['userId'] as String?,
  sessionId: json['sessionId'] as String?,
  timezone: json['timezone'] as String?,
  concurrency:
      $enumDecodeNullable(_$CronTaskConcurrencyEnumMap, json['concurrency']) ??
      CronTaskConcurrency.skipIfRunning,
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$CronTaskCreateRequestToJson(
  CronTaskCreateRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'schedule': instance.schedule,
  'spec': instance.spec.toJson(),
  'userId': ?instance.userId,
  'sessionId': ?instance.sessionId,
  'timezone': ?instance.timezone,
  'concurrency': _$CronTaskConcurrencyEnumMap[instance.concurrency]!,
  'enabled': instance.enabled,
};

const _$CronTaskConcurrencyEnumMap = {
  CronTaskConcurrency.skipIfRunning: 'skipIfRunning',
};

CronTaskUpdateRequest _$CronTaskUpdateRequestFromJson(
  Map<String, dynamic> json,
) => CronTaskUpdateRequest(
  cronId: json['cronId'] as String,
  name: json['name'] as String?,
  schedule: json['schedule'] as String?,
  spec: json['spec'] == null
      ? null
      : CronSpec.fromJson(json['spec'] as Map<String, dynamic>),
  timezone: json['timezone'] as String?,
  concurrency: $enumDecodeNullable(
    _$CronTaskConcurrencyEnumMap,
    json['concurrency'],
  ),
  enabled: json['enabled'] as bool?,
);

Map<String, dynamic> _$CronTaskUpdateRequestToJson(
  CronTaskUpdateRequest instance,
) => <String, dynamic>{
  'cronId': instance.cronId,
  'name': ?instance.name,
  'schedule': ?instance.schedule,
  'spec': ?instance.spec?.toJson(),
  'timezone': ?instance.timezone,
  'concurrency': ?_$CronTaskConcurrencyEnumMap[instance.concurrency],
  'enabled': ?instance.enabled,
};

CronTaskActionRequest _$CronTaskActionRequestFromJson(
  Map<String, dynamic> json,
) => CronTaskActionRequest(cronId: json['cronId'] as String);

Map<String, dynamic> _$CronTaskActionRequestToJson(
  CronTaskActionRequest instance,
) => <String, dynamic>{'cronId': instance.cronId};

CronTaskSetEnabledRequest _$CronTaskSetEnabledRequestFromJson(
  Map<String, dynamic> json,
) => CronTaskSetEnabledRequest(
  cronId: json['cronId'] as String,
  enabled: json['enabled'] as bool,
);

Map<String, dynamic> _$CronTaskSetEnabledRequestToJson(
  CronTaskSetEnabledRequest instance,
) => <String, dynamic>{'cronId': instance.cronId, 'enabled': instance.enabled};

CronTaskRunNowRequest _$CronTaskRunNowRequestFromJson(
  Map<String, dynamic> json,
) => CronTaskRunNowRequest(
  cronId: json['cronId'] as String,
  scheduledAt: json['scheduledAt'] == null
      ? null
      : DateTime.parse(json['scheduledAt'] as String),
);

Map<String, dynamic> _$CronTaskRunNowRequestToJson(
  CronTaskRunNowRequest instance,
) => <String, dynamic>{
  'cronId': instance.cronId,
  'scheduledAt': ?instance.scheduledAt?.toIso8601String(),
};

CronRunQuery _$CronRunQueryFromJson(Map<String, dynamic> json) =>
    CronRunQuery(runId: json['runId'] as String);

Map<String, dynamic> _$CronRunQueryToJson(CronRunQuery instance) =>
    <String, dynamic>{'runId': instance.runId};

CronTask _$CronTaskFromJson(Map<String, dynamic> json) => CronTask(
  cronId: json['cronId'] as String,
  name: json['name'] as String,
  schedule: json['schedule'] as String,
  source: json['source'] as String,
  userId: json['userId'] as String?,
  sessionId: json['sessionId'] as String?,
  timezone: json['timezone'] as String?,
  enabled: json['enabled'] as bool,
  status: json['status'] as String,
  concurrency: json['concurrency'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  lastRunAt: json['lastRunAt'] == null
      ? null
      : DateTime.parse(json['lastRunAt'] as String),
  nextRunAt: json['nextRunAt'] == null
      ? null
      : DateTime.parse(json['nextRunAt'] as String),
  spec: CronSpec.fromJson(json['spec'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CronTaskToJson(CronTask instance) => <String, dynamic>{
  'cronId': instance.cronId,
  'name': instance.name,
  'schedule': instance.schedule,
  'source': instance.source,
  'userId': ?instance.userId,
  'sessionId': ?instance.sessionId,
  'timezone': ?instance.timezone,
  'enabled': instance.enabled,
  'status': instance.status,
  'concurrency': instance.concurrency,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'lastRunAt': ?instance.lastRunAt?.toIso8601String(),
  'nextRunAt': ?instance.nextRunAt?.toIso8601String(),
  'spec': instance.spec,
};

CronTaskListItem _$CronTaskListItemFromJson(Map<String, dynamic> json) =>
    CronTaskListItem(
      cronId: json['cronId'] as String,
      name: json['name'] as String,
      schedule: json['schedule'] as String,
      enabled: json['enabled'] as bool,
      status: json['status'] as String,
      lastRunAt: json['lastRunAt'] == null
          ? null
          : DateTime.parse(json['lastRunAt'] as String),
      nextRunAt: json['nextRunAt'] == null
          ? null
          : DateTime.parse(json['nextRunAt'] as String),
    );

Map<String, dynamic> _$CronTaskListItemToJson(CronTaskListItem instance) =>
    <String, dynamic>{
      'cronId': instance.cronId,
      'name': instance.name,
      'schedule': instance.schedule,
      'enabled': instance.enabled,
      'status': instance.status,
      'lastRunAt': ?instance.lastRunAt?.toIso8601String(),
      'nextRunAt': ?instance.nextRunAt?.toIso8601String(),
    };

CronTaskDeleteResult _$CronTaskDeleteResultFromJson(
  Map<String, dynamic> json,
) => CronTaskDeleteResult(
  deleted: json['deleted'] as bool,
  cronId: json['cronId'] as String,
);

Map<String, dynamic> _$CronTaskDeleteResultToJson(
  CronTaskDeleteResult instance,
) => <String, dynamic>{'deleted': instance.deleted, 'cronId': instance.cronId};

CronRun _$CronRunFromJson(Map<String, dynamic> json) => CronRun(
  runId: json['runId'] as String,
  cronId: json['cronId'] as String,
  trigger: json['trigger'] as String,
  status: json['status'] as String,
  scheduledAt: DateTime.parse(json['scheduledAt'] as String),
  startedAt: DateTime.parse(json['startedAt'] as String),
  hasDisplayableResult: json['hasDisplayableResult'] as bool,
  finishedAt: json['finishedAt'] == null
      ? null
      : DateTime.parse(json['finishedAt'] as String),
  liteAgentSessionId: json['liteAgentSessionId'] as String?,
  error: json['error'] as String?,
  result: json['result'] as Map<String, dynamic>?,
  displayMessageId: json['displayMessageId'] as String?,
  displayText: json['displayText'] as String?,
);

Map<String, dynamic> _$CronRunToJson(CronRun instance) => <String, dynamic>{
  'runId': instance.runId,
  'cronId': instance.cronId,
  'trigger': instance.trigger,
  'status': instance.status,
  'scheduledAt': instance.scheduledAt.toIso8601String(),
  'startedAt': instance.startedAt.toIso8601String(),
  'hasDisplayableResult': instance.hasDisplayableResult,
  'finishedAt': ?instance.finishedAt?.toIso8601String(),
  'liteAgentSessionId': ?instance.liteAgentSessionId,
  'error': ?instance.error,
  'result': ?instance.result,
  'displayMessageId': ?instance.displayMessageId,
  'displayText': ?instance.displayText,
};

CronRunListItem _$CronRunListItemFromJson(Map<String, dynamic> json) =>
    CronRunListItem(
      runId: json['runId'] as String,
      cronId: json['cronId'] as String,
      trigger: json['trigger'] as String,
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      hasDisplayableResult: json['hasDisplayableResult'] as bool,
      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.parse(json['finishedAt'] as String),
      displayText: json['displayText'] as String?,
    );

Map<String, dynamic> _$CronRunListItemToJson(CronRunListItem instance) =>
    <String, dynamic>{
      'runId': instance.runId,
      'cronId': instance.cronId,
      'trigger': instance.trigger,
      'status': instance.status,
      'scheduledAt': instance.scheduledAt.toIso8601String(),
      'startedAt': instance.startedAt.toIso8601String(),
      'hasDisplayableResult': instance.hasDisplayableResult,
      'finishedAt': ?instance.finishedAt?.toIso8601String(),
      'displayText': ?instance.displayText,
    };

CronRunMessage _$CronRunMessageFromJson(Map<String, dynamic> json) =>
    CronRunMessage(
      messageId: json['messageId'] as String,
      runId: json['runId'] as String,
      cronId: json['cronId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: AgentMessage.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CronRunMessageToJson(CronRunMessage instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'runId': instance.runId,
      'cronId': instance.cronId,
      'timestamp': instance.timestamp.toIso8601String(),
      'message': instance.message.toJson(),
    };

CronDeleteRunResult _$CronDeleteRunResultFromJson(Map<String, dynamic> json) =>
    CronDeleteRunResult(
      deleted: json['deleted'] as bool,
      runId: json['runId'] as String,
    );

Map<String, dynamic> _$CronDeleteRunResultToJson(
  CronDeleteRunResult instance,
) => <String, dynamic>{'deleted': instance.deleted, 'runId': instance.runId};

CronSchedulerSnapshot _$CronSchedulerSnapshotFromJson(
  Map<String, dynamic> json,
) => CronSchedulerSnapshot(
  running: json['running'] as bool,
  activeTaskCount: (json['activeTaskCount'] as num).toInt(),
  runningTaskCount: (json['runningTaskCount'] as num).toInt(),
  lastTickAt: json['lastTickAt'] == null
      ? null
      : DateTime.parse(json['lastTickAt'] as String),
);

Map<String, dynamic> _$CronSchedulerSnapshotToJson(
  CronSchedulerSnapshot instance,
) => <String, dynamic>{
  'running': instance.running,
  'activeTaskCount': instance.activeTaskCount,
  'runningTaskCount': instance.runningTaskCount,
  'lastTickAt': ?instance.lastTickAt?.toIso8601String(),
};

CronSchedulerStatus _$CronSchedulerStatusFromJson(Map<String, dynamic> json) =>
    CronSchedulerStatus(status: json['status'] as String);

Map<String, dynamic> _$CronSchedulerStatusToJson(
  CronSchedulerStatus instance,
) => <String, dynamic>{'status': instance.status};
