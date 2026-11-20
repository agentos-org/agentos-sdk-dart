import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

/// JSON objects exchanged with HarnessKit.
typedef HarnessKitJsonObject = Map<String, dynamic>;

/// Harness engine identifier. Hosts may add engine identifiers over time.
typedef HarnessKitEngineId = String;

/// A local App's OpenTool callback registration for one Harness thread.
@JsonSerializable()
class HarnessKitPrivateToolsRegistration {
  const HarnessKitPrivateToolsRegistration({
    required this.endpoint,
    required this.token,
    required this.specification,
  });

  /// Callback service root, `http://127.0.0.1:<port>/`.
  final String endpoint;

  /// Callback service bearer token; separate from the AppKit token.
  final String token;

  /// OpenTool JSON document describing the App's functions.
  final HarnessKitJsonObject specification;

  factory HarnessKitPrivateToolsRegistration.fromJson(
    Map<String, dynamic> json,
  ) => _$HarnessKitPrivateToolsRegistrationFromJson(json);

  Map<String, dynamic> toJson() =>
      _$HarnessKitPrivateToolsRegistrationToJson(this);
}

/// Identifies the tools registered for a Harness thread.
@JsonSerializable()
class HarnessKitPrivateToolsRegistrationResult {
  const HarnessKitPrivateToolsRegistrationResult({required this.toolId});

  /// Tool ID to include in a run's allow-list, when one is used.
  final String toolId;

  factory HarnessKitPrivateToolsRegistrationResult.fromJson(
    Map<String, dynamic> json,
  ) => _$HarnessKitPrivateToolsRegistrationResultFromJson(json);

  Map<String, dynamic> toJson() =>
      _$HarnessKitPrivateToolsRegistrationResultToJson(this);
}

HarnessKitJsonObject _asJsonObject(dynamic value, String name) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Expected $name to be a JSON object');
}

String _stringValue(Map<String, dynamic> json, String key) =>
    json[key] is String ? json[key] as String : '';

int? _intValue(Map<String, dynamic> json, String key) =>
    (json[key] as num?)?.toInt();

bool? _boolValue(Map<String, dynamic> json, String key) =>
    json[key] is bool ? json[key] as bool : null;

HarnessKitJsonObject _extraFields(
  Map<String, dynamic> json,
  Set<String> knownKeys,
) => <String, dynamic>{
  for (final entry in json.entries)
    if (!knownKeys.contains(entry.key)) entry.key: entry.value,
};

/// Harness runtime engine state.
class HarnessKitRuntimeInfo {
  const HarnessKitRuntimeInfo({
    required this.status,
    required this.engine,
    this.activeEngine,
    this.availableEngines = const <HarnessKitEngineId>[],
    this.switching = false,
    this.extra = const <String, dynamic>{},
  });

  final String status;
  final HarnessKitEngineId engine;
  final HarnessKitEngineId? activeEngine;
  final List<HarnessKitEngineId> availableEngines;
  final bool switching;
  final HarnessKitJsonObject extra;

  factory HarnessKitRuntimeInfo.fromJson(Map<String, dynamic> json) =>
      HarnessKitRuntimeInfo(
        status: _stringValue(json, 'status'),
        engine: _stringValue(json, 'engine'),
        activeEngine: json['activeEngine'] as String?,
        availableEngines: (json['availableEngines'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        switching: _boolValue(json, 'switching') ?? false,
        extra: _extraFields(json, <String>{
          'status',
          'engine',
          'activeEngine',
          'availableEngines',
          'switching',
        }),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'status': status,
    'engine': engine,
    'activeEngine': activeEngine,
    'availableEngines': availableEngines,
    'switching': switching,
  };
}

/// Result of switching the active Harness engine.
class HarnessKitEngineSwitchResult {
  const HarnessKitEngineSwitchResult({
    required this.status,
    required this.engine,
    this.activeEngine,
    this.previousEngine,
    this.requestedEngine,
    this.message,
    this.extra = const <String, dynamic>{},
  });

  final String status;
  final HarnessKitEngineId engine;
  final HarnessKitEngineId? activeEngine;
  final HarnessKitEngineId? previousEngine;
  final HarnessKitEngineId? requestedEngine;
  final String? message;
  final HarnessKitJsonObject extra;

  factory HarnessKitEngineSwitchResult.fromJson(Map<String, dynamic> json) =>
      HarnessKitEngineSwitchResult(
        status: _stringValue(json, 'status'),
        engine: _stringValue(json, 'engine'),
        activeEngine: json['activeEngine'] as String?,
        previousEngine: json['previousEngine'] as String?,
        requestedEngine: json['requestedEngine'] as String?,
        message: json['message'] as String?,
        extra: _extraFields(json, <String>{
          'status',
          'engine',
          'activeEngine',
          'previousEngine',
          'requestedEngine',
          'message',
        }),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'status': status,
    'engine': engine,
    'activeEngine': activeEngine,
    'previousEngine': previousEngine,
    'requestedEngine': requestedEngine,
    'message': message,
  };
}

/// One message in a Harness thread snapshot.
class HarnessKitThreadMessage {
  const HarnessKitThreadMessage({
    required this.role,
    this.content,
    this.contentParts,
    this.metadata,
    this.extra = const <String, dynamic>{},
  });

  final String role;
  final String? content;
  final List<dynamic>? contentParts;
  final HarnessKitJsonObject? metadata;
  final HarnessKitJsonObject extra;

  factory HarnessKitThreadMessage.fromJson(Map<String, dynamic> json) =>
      HarnessKitThreadMessage(
        role: _stringValue(json, 'role'),
        content: json['content'] as String?,
        contentParts: json['contentParts'] as List<dynamic>?,
        metadata: json['metadata'] == null
            ? null
            : _asJsonObject(json['metadata'], 'metadata'),
        extra: _extraFields(json, <String>{
          'role',
          'content',
          'contentParts',
          'metadata',
        }),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'role': role,
    if (content != null) 'content': content,
    if (contentParts != null) 'contentParts': contentParts,
    if (metadata != null) 'metadata': metadata,
  };
}

/// Persisted conversation state returned by HarnessKit.
class HarnessKitThreadSnapshot {
  const HarnessKitThreadSnapshot({
    required this.threadId,
    this.schemaVersion,
    this.title,
    this.updatedAt,
    this.activeRunId,
    this.queuedCommandCount,
    this.runCount,
    this.hasPausedRun,
    this.messages = const <HarnessKitThreadMessage>[],
    this.extra = const <String, dynamic>{},
  });

  final int? schemaVersion;
  final String threadId;
  final String? title;
  final String? updatedAt;
  final String? activeRunId;
  final int? queuedCommandCount;
  final int? runCount;
  final bool? hasPausedRun;
  final List<HarnessKitThreadMessage> messages;
  final HarnessKitJsonObject extra;

  factory HarnessKitThreadSnapshot.fromJson(Map<String, dynamic> json) =>
      HarnessKitThreadSnapshot(
        schemaVersion: _intValue(json, 'schemaVersion'),
        threadId: _stringValue(json, 'threadId'),
        title: json['title'] as String?,
        updatedAt: json['updatedAt'] as String?,
        activeRunId: json['activeRunId'] as String?,
        queuedCommandCount: _intValue(json, 'queuedCommandCount'),
        runCount: _intValue(json, 'runCount'),
        hasPausedRun: _boolValue(json, 'hasPausedRun'),
        messages: (json['messages'] as List? ?? const [])
            .map(
              (item) => HarnessKitThreadMessage.fromJson(
                _asJsonObject(item, 'thread message'),
              ),
            )
            .toList(growable: false),
        extra: _extraFields(json, <String>{
          'schemaVersion',
          'threadId',
          'title',
          'updatedAt',
          'activeRunId',
          'queuedCommandCount',
          'runCount',
          'hasPausedRun',
          'messages',
        }),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'schemaVersion': schemaVersion,
    'threadId': threadId,
    'title': title,
    'updatedAt': updatedAt,
    'activeRunId': activeRunId,
    'queuedCommandCount': queuedCommandCount,
    'runCount': runCount,
    'hasPausedRun': hasPausedRun,
    'messages': messages.map((message) => message.toJson()).toList(),
  };
}

class HarnessKitThreadRenameResult {
  const HarnessKitThreadRenameResult({
    required this.threadId,
    required this.title,
  });

  final String threadId;
  final String title;

  factory HarnessKitThreadRenameResult.fromJson(Map<String, dynamic> json) =>
      HarnessKitThreadRenameResult(
        threadId: _stringValue(json, 'threadId'),
        title: _stringValue(json, 'title'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'threadId': threadId,
    'title': title,
  };
}

class HarnessKitThreadDeleteResult {
  const HarnessKitThreadDeleteResult({
    required this.deleted,
    required this.threadId,
  });

  final bool deleted;
  final String threadId;

  factory HarnessKitThreadDeleteResult.fromJson(Map<String, dynamic> json) =>
      HarnessKitThreadDeleteResult(
        deleted: _boolValue(json, 'deleted') ?? false,
        threadId: _stringValue(json, 'threadId'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'deleted': deleted,
    'threadId': threadId,
  };
}

/// Model configuration accepted by a Harness run.
class HarnessKitLlmConfig {
  const HarnessKitLlmConfig({
    required this.model,
    this.provider,
    this.baseUrl,
    this.apiKey,
    this.adapter,
    this.headers,
    this.providerOptions,
    this.temperature,
    this.maxTokens,
    this.contextWindowSize,
    this.topP,
    this.supportsToolCall,
    this.supportsReasoning,
    this.extra = const <String, dynamic>{},
  });

  final String model;
  final String? provider;
  final String? baseUrl;
  final String? apiKey;
  final String? adapter;
  final Map<String, String>? headers;
  final HarnessKitJsonObject? providerOptions;
  final double? temperature;
  final int? maxTokens;
  final int? contextWindowSize;
  final double? topP;
  final bool? supportsToolCall;
  final bool? supportsReasoning;
  final HarnessKitJsonObject extra;

  factory HarnessKitLlmConfig.fromJson(Map<String, dynamic> json) =>
      HarnessKitLlmConfig(
        model: _stringValue(json, 'model'),
        provider: json['provider'] as String?,
        baseUrl: json['baseUrl'] as String?,
        apiKey: json['apiKey'] as String?,
        adapter: json['adapter'] as String?,
        headers: json['headers'] == null
            ? null
            : Map<String, String>.from(json['headers'] as Map),
        providerOptions: json['providerOptions'] == null
            ? null
            : _asJsonObject(json['providerOptions'], 'providerOptions'),
        temperature: (json['temperature'] as num?)?.toDouble(),
        maxTokens: _intValue(json, 'maxTokens'),
        contextWindowSize: _intValue(json, 'contextWindowSize'),
        topP: (json['topP'] as num?)?.toDouble(),
        supportsToolCall: _boolValue(json, 'supportsToolCall'),
        supportsReasoning: _boolValue(json, 'supportsReasoning'),
        extra: _extraFields(json, <String>{
          'model',
          'provider',
          'baseUrl',
          'apiKey',
          'adapter',
          'headers',
          'providerOptions',
          'temperature',
          'maxTokens',
          'contextWindowSize',
          'topP',
          'supportsToolCall',
          'supportsReasoning',
        }),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'model': model,
    if (provider != null) 'provider': provider,
    if (baseUrl != null) 'baseUrl': baseUrl,
    if (apiKey != null) 'apiKey': apiKey,
    if (adapter != null) 'adapter': adapter,
    if (headers != null) 'headers': headers,
    if (providerOptions != null) 'providerOptions': providerOptions,
    if (temperature != null) 'temperature': temperature,
    if (maxTokens != null) 'maxTokens': maxTokens,
    if (contextWindowSize != null) 'contextWindowSize': contextWindowSize,
    if (topP != null) 'topP': topP,
    if (supportsToolCall != null) 'supportsToolCall': supportsToolCall,
    if (supportsReasoning != null) 'supportsReasoning': supportsReasoning,
  };
}

/// Request payload for `POST /v1/threads/{threadId}/runs`.
class HarnessKitRunRequest {
  const HarnessKitRunRequest({
    required this.requestId,
    required this.goal,
    required this.llmConfig,
    this.actorId,
    this.messages,
    this.context,
    this.extra = const <String, dynamic>{},
  });

  final String requestId;
  final String goal;
  final HarnessKitLlmConfig llmConfig;
  final String? actorId;
  final List<HarnessKitThreadMessage>? messages;
  final HarnessKitJsonObject? context;
  final HarnessKitJsonObject extra;

  factory HarnessKitRunRequest.fromJson(Map<String, dynamic> json) =>
      HarnessKitRunRequest(
        requestId: _stringValue(json, 'requestId'),
        goal: _stringValue(json, 'goal'),
        llmConfig: HarnessKitLlmConfig.fromJson(
          _asJsonObject(json['llmConfig'], 'llmConfig'),
        ),
        actorId: json['actorId'] as String?,
        messages: (json['messages'] as List?)
            ?.map(
              (item) => HarnessKitThreadMessage.fromJson(
                _asJsonObject(item, 'thread message'),
              ),
            )
            .toList(growable: false),
        context: json['context'] == null
            ? null
            : _asJsonObject(json['context'], 'context'),
        extra: _extraFields(json, <String>{
          'requestId',
          'goal',
          'llmConfig',
          'actorId',
          'messages',
          'context',
        }),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'requestId': requestId,
    'goal': goal,
    'llmConfig': llmConfig.toJson(),
    if (actorId != null) 'actorId': actorId,
    if (messages != null)
      'messages': messages!.map((message) => message.toJson()).toList(),
    if (context != null) 'context': context,
  };
}

class HarnessKitRunAccepted {
  const HarnessKitRunAccepted({
    required this.status,
    required this.threadId,
    required this.runId,
    this.events,
  });

  final String status;
  final String threadId;
  final String runId;
  final String? events;

  factory HarnessKitRunAccepted.fromJson(Map<String, dynamic> json) =>
      HarnessKitRunAccepted(
        status: _stringValue(json, 'status'),
        threadId: _stringValue(json, 'threadId'),
        runId: _stringValue(json, 'runId'),
        events: json['events'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status,
    'threadId': threadId,
    'runId': runId,
    'events': events,
  };
}

/// Command payload. [extra] carries fields for command types added by hosts.
class HarnessKitCommand {
  const HarnessKitCommand({
    required this.type,
    required this.commandId,
    this.threadId,
    this.extra = const <String, dynamic>{},
  });

  final String type;
  final String commandId;
  final String? threadId;
  final HarnessKitJsonObject extra;

  factory HarnessKitCommand.fromJson(Map<String, dynamic> json) =>
      HarnessKitCommand(
        type: _stringValue(json, 'type'),
        commandId: _stringValue(json, 'commandId'),
        threadId: json['threadId'] as String?,
        extra: _extraFields(json, <String>{'type', 'commandId', 'threadId'}),
      );

  Map<String, dynamic> toJson({String? threadIdOverride}) => <String, dynamic>{
    ...extra,
    'type': type,
    'commandId': commandId,
    'threadId': threadIdOverride ?? threadId,
  };
}

class HarnessKitCommandReceipt {
  const HarnessKitCommandReceipt({
    required this.commandId,
    required this.status,
    this.threadId,
    this.turnId,
    this.runId,
    this.reason,
  });

  final String commandId;
  final String status;
  final String? threadId;
  final String? turnId;
  final String? runId;
  final String? reason;

  factory HarnessKitCommandReceipt.fromJson(Map<String, dynamic> json) =>
      HarnessKitCommandReceipt(
        commandId: _stringValue(json, 'commandId'),
        status: _stringValue(json, 'status'),
        threadId: json['threadId'] as String?,
        turnId: json['turnId'] as String?,
        runId: json['runId'] as String?,
        reason: json['reason'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'commandId': commandId,
    'status': status,
    'threadId': threadId,
    'turnId': turnId,
    'runId': runId,
    'reason': reason,
  };
}

/// Event envelope streamed by HarnessKit as server-sent events.
class HarnessKitEvent {
  const HarnessKitEvent({
    required this.eventId,
    required this.threadId,
    required this.sequence,
    required this.timestamp,
    required this.type,
    required this.lifecycle,
    required this.data,
    this.turnId,
    this.runId,
    this.stepId,
    this.callId,
  });

  final String eventId;
  final String threadId;
  final String? turnId;
  final String? runId;
  final String? stepId;
  final String? callId;
  final int sequence;
  final String timestamp;
  final String type;
  final String lifecycle;
  final HarnessKitJsonObject data;

  factory HarnessKitEvent.fromJson(Map<String, dynamic> json) =>
      HarnessKitEvent(
        eventId: _stringValue(json, 'eventId'),
        threadId: _stringValue(json, 'threadId'),
        turnId: json['turnId'] as String?,
        runId: json['runId'] as String?,
        stepId: json['stepId'] as String?,
        callId: json['callId'] as String?,
        sequence: _intValue(json, 'sequence') ?? 0,
        timestamp: _stringValue(json, 'timestamp'),
        type: _stringValue(json, 'type'),
        lifecycle: _stringValue(json, 'lifecycle'),
        data: _asJsonObject(json['data'], 'event data'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'eventId': eventId,
    'threadId': threadId,
    'turnId': turnId,
    'runId': runId,
    'stepId': stepId,
    'callId': callId,
    'sequence': sequence,
    'timestamp': timestamp,
    'type': type,
    'lifecycle': lifecycle,
    'data': data,
  };
}

class HarnessKitRunError {
  const HarnessKitRunError({
    this.code,
    this.message,
    this.source,
    this.retryable,
    this.details,
  });

  final String? code;
  final String? message;
  final String? source;
  final bool? retryable;
  final HarnessKitJsonObject? details;

  factory HarnessKitRunError.fromJson(Map<String, dynamic> json) =>
      HarnessKitRunError(
        code: json['code'] as String?,
        message: json['message'] as String?,
        source: json['source'] as String?,
        retryable: _boolValue(json, 'retryable'),
        details: json['details'] == null
            ? null
            : _asJsonObject(json['details'], 'error details'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'message': message,
    'source': source,
    'retryable': retryable,
    'details': details,
  };
}

class HarnessKitRunUsage {
  const HarnessKitRunUsage({
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
  });

  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;

  factory HarnessKitRunUsage.fromJson(Map<String, dynamic> json) =>
      HarnessKitRunUsage(
        inputTokens: _intValue(json, 'inputTokens'),
        outputTokens: _intValue(json, 'outputTokens'),
        totalTokens: _intValue(json, 'totalTokens'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'totalTokens': totalTokens,
  };
}

class HarnessKitRunResult {
  const HarnessKitRunResult({
    required this.runId,
    required this.status,
    this.output,
    this.error,
    this.usage,
    this.steps,
    this.toolCalls,
    this.extra = const <String, dynamic>{},
  });

  final String runId;
  final String status;
  final String? output;
  final HarnessKitRunError? error;
  final HarnessKitRunUsage? usage;
  final List<dynamic>? steps;
  final List<dynamic>? toolCalls;
  final HarnessKitJsonObject extra;

  factory HarnessKitRunResult.fromJson(
    Map<String, dynamic> json,
  ) => HarnessKitRunResult(
    runId: _stringValue(json, 'runId'),
    status: _stringValue(json, 'status'),
    output: json['output'] as String?,
    error: json['error'] is Map
        ? HarnessKitRunError.fromJson(_asJsonObject(json['error'], 'run error'))
        : null,
    usage: json['usage'] is Map
        ? HarnessKitRunUsage.fromJson(_asJsonObject(json['usage'], 'run usage'))
        : null,
    steps: json['steps'] as List<dynamic>?,
    toolCalls: json['toolCalls'] as List<dynamic>?,
    extra: _extraFields(json, <String>{
      'runId',
      'status',
      'output',
      'error',
      'usage',
      'steps',
      'toolCalls',
    }),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'runId': runId,
    'status': status,
    'output': output,
    'error': error?.toJson(),
    'usage': usage?.toJson(),
    'steps': steps,
    'toolCalls': toolCalls,
  };
}

class HarnessKitOperationalSnapshot {
  const HarnessKitOperationalSnapshot({
    required this.schemaVersion,
    required this.capturedAt,
    required this.lifecycle,
    required this.threadCount,
    required this.activeRunCount,
    required this.pausedRunCount,
    required this.waitingForAdmissionCount,
    required this.waitingForApprovalCount,
    required this.waitingForHumanInputCount,
    required this.pendingCommandCount,
    required this.unresolvedToolReceiptCount,
    required this.unresolvedModelReceiptCount,
    this.threads = const <dynamic>[],
    this.extra = const <String, dynamic>{},
  });

  final int schemaVersion;
  final String capturedAt;
  final String lifecycle;
  final int threadCount;
  final int activeRunCount;
  final int pausedRunCount;
  final int waitingForAdmissionCount;
  final int waitingForApprovalCount;
  final int waitingForHumanInputCount;
  final int pendingCommandCount;
  final int unresolvedToolReceiptCount;
  final int unresolvedModelReceiptCount;
  final List<dynamic> threads;
  final HarnessKitJsonObject extra;

  factory HarnessKitOperationalSnapshot.fromJson(
    Map<String, dynamic> json,
  ) => HarnessKitOperationalSnapshot(
    schemaVersion: _intValue(json, 'schemaVersion') ?? 0,
    capturedAt: _stringValue(json, 'capturedAt'),
    lifecycle: _stringValue(json, 'lifecycle'),
    threadCount: _intValue(json, 'threadCount') ?? 0,
    activeRunCount: _intValue(json, 'activeRunCount') ?? 0,
    pausedRunCount: _intValue(json, 'pausedRunCount') ?? 0,
    waitingForAdmissionCount: _intValue(json, 'waitingForAdmissionCount') ?? 0,
    waitingForApprovalCount: _intValue(json, 'waitingForApprovalCount') ?? 0,
    waitingForHumanInputCount:
        _intValue(json, 'waitingForHumanInputCount') ?? 0,
    pendingCommandCount: _intValue(json, 'pendingCommandCount') ?? 0,
    unresolvedToolReceiptCount:
        _intValue(json, 'unresolvedToolReceiptCount') ?? 0,
    unresolvedModelReceiptCount:
        _intValue(json, 'unresolvedModelReceiptCount') ?? 0,
    threads: json['threads'] as List<dynamic>? ?? const <dynamic>[],
    extra: _extraFields(json, <String>{
      'schemaVersion',
      'capturedAt',
      'lifecycle',
      'threadCount',
      'activeRunCount',
      'pausedRunCount',
      'waitingForAdmissionCount',
      'waitingForApprovalCount',
      'waitingForHumanInputCount',
      'pendingCommandCount',
      'unresolvedToolReceiptCount',
      'unresolvedModelReceiptCount',
      'threads',
    }),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...extra,
    'schemaVersion': schemaVersion,
    'capturedAt': capturedAt,
    'lifecycle': lifecycle,
    'threadCount': threadCount,
    'activeRunCount': activeRunCount,
    'pausedRunCount': pausedRunCount,
    'waitingForAdmissionCount': waitingForAdmissionCount,
    'waitingForApprovalCount': waitingForApprovalCount,
    'waitingForHumanInputCount': waitingForHumanInputCount,
    'pendingCommandCount': pendingCommandCount,
    'unresolvedToolReceiptCount': unresolvedToolReceiptCount,
    'unresolvedModelReceiptCount': unresolvedModelReceiptCount,
    'threads': threads,
  };
}

/// Options for subscribing to a Harness thread's event stream.
class HarnessKitEventsOptions {
  const HarnessKitEventsOptions({this.afterSequence = 0, this.runId});

  final int afterSequence;
  final String? runId;
}
