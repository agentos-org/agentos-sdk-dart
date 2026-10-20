import 'dart:convert';

import 'package:dart_openai_sdk/dart_openai_sdk.dart';
import 'package:dio/dio.dart';

import '../../utils/api_client.dart';

/// Task-oriented model classifier shared with the agentos-api ModelKit
/// controller.
enum ModelTask {
  chat('chat'),
  embedding('embedding'),
  asr('asr'),
  tts('tts'),

  /// Typed-question decision models (llama.cpp `/v1/systemone`). They answer
  /// by scoring caller-provided options and never generate text.
  decision('decision');

  const ModelTask(this.wireName);

  /// Wire identifier expected by the agentos-api gateway.
  final String wireName;

  static ModelTask? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final t in values) {
      if (t.wireName == normalized || t.name == normalized) return t;
    }
    return null;
  }
}

enum Modality {
  text('text'),
  image('image'),
  audio('audio'),
  video('video'),

  /// Output modality of [ModelTask.decision] models.
  decisions('decisions');

  const Modality(this.wireName);

  final String wireName;

  static Modality? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final m in values) {
      if (m.wireName == normalized || m.name == normalized) return m;
    }
    return null;
  }
}

/// Capability flags that are orthogonal to input/output modalities.
class ModelCapabilities {
  const ModelCapabilities({
    this.vision = false,
    this.toolCall = false,
    this.stream = true,
    this.reasoning = false,
  });

  final bool vision;
  final bool toolCall;
  final bool stream;
  final bool reasoning;

  factory ModelCapabilities.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModelCapabilities();
    return ModelCapabilities(
      vision: json['vision'] as bool? ?? false,
      toolCall: json['tool_call'] as bool? ?? false,
      stream: json['stream'] as bool? ?? true,
      reasoning: json['reasoning'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'vision': vision,
    'tool_call': toolCall,
    'stream': stream,
    'reasoning': reasoning,
  };
}

/// Mutually exclusive origin of a model, as reported by the gateway's
/// `source` field of `/modelkit/models`.
///
/// Group and label models by it instead of combining [ModelInfo.isRemote],
/// [ModelInfo.isCustom] and [ModelInfo.isAppModel]. Run location (on-device vs.
/// cloud) is secondary information and is not part of the group name.
enum ModelSource {
  /// Runs on this device.
  local('local'),

  /// A remote model provided by the AgentOS platform.
  platform('platform'),

  /// A remote model the user configured.
  custom('custom'),

  /// Registered by a third-party app through `/modelkit/app-models`.
  app('app');

  const ModelSource(this.wireName);

  /// Wire identifier used by the agentos-api gateway.
  final String wireName;

  /// Parses a wire value (case-insensitive); returns null when [value] is
  /// missing or not a known source.
  static ModelSource? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final source in values) {
      if (source.wireName == normalized) return source;
    }
    return null;
  }

  /// Derives the source from the legacy flags, with the same rules as the
  /// gateway: an app model is always [app]; otherwise a non-remote model is
  /// [local], a remote custom model is [custom] and any other remote model is
  /// [platform].
  static ModelSource derive({
    required bool isRemote,
    required bool isCustom,
    required bool isAppModel,
  }) {
    if (isAppModel) return ModelSource.app;
    if (!isRemote) return ModelSource.local;
    return isCustom ? ModelSource.custom : ModelSource.platform;
  }
}

/// Model descriptor returned by `/modelkit/models`.
///
/// ModelKit classifies models by [task] and uses [inputModalities] +
/// [capabilities] to describe multimodal, tool, streaming, and reasoning
/// support.
class ModelInfo {
  ModelInfo({
    required this.id,
    required this.name,
    required this.alias,
    this.description,
    required this.task,
    this.contextWindowSize,
    this.inputModalities = const [Modality.text],
    this.outputModalities = const [Modality.text],
    this.capabilities = const ModelCapabilities(),
    this.isRemote = false,
    this.isCustom = false,
    ModelSource? source,
    this.isAppModel = false,
    this.appBundleId,
    this.appName,
  }) : source =
           source ??
           ModelSource.derive(
             isRemote: isRemote,
             isCustom: isCustom,
             isAppModel: isAppModel,
           );

  final String id;
  final String name;
  final String alias;
  final String? description;
  final ModelTask task;
  final int? contextWindowSize;
  final List<Modality> inputModalities;
  final List<Modality> outputModalities;
  final ModelCapabilities capabilities;
  final bool isRemote;
  final bool isCustom;

  /// Mutually exclusive origin of the model. Group and label models by it.
  ///
  /// Defaults to the value derived from [isRemote] / [isCustom] /
  /// [isAppModel] (see [ModelSource.derive]) when it is not given, which is
  /// also how [ModelInfo.fromJson] handles gateways that predate `source` or
  /// report an unknown value.
  final ModelSource source;

  /// Whether a third-party app registered this model through
  /// [ModelKitClient.registerAppModel].
  final bool isAppModel;

  /// Bundle ID of the app that registered this model. Only present for app
  /// models.
  final String? appBundleId;

  /// Human-readable name of the app that registered this model, for group
  /// titles in model pickers (for example `App · {appName}`). Only present for
  /// app models, and only when the gateway reports one; fall back to
  /// [appBundleId] otherwise.
  final String? appName;

  bool get hasVision =>
      capabilities.vision ||
      inputModalities.contains(Modality.image) ||
      inputModalities.contains(Modality.video);

  bool get supportsChatInference => task == ModelTask.chat;

  /// Whether this is a typed-question decision model, callable through
  /// [ModelKitDecisionClient].
  bool get supportsDecisionInference => task == ModelTask.decision;

  /// Legacy alias kept for callers still reading `isVisionLanguage`.
  bool get isVisionLanguage => hasVision && task == ModelTask.chat;

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    final task =
        ModelTask.fromString(json['task'] as String?) ??
        ModelTask.fromString(json['type'] as String?) ??
        ModelTask.chat;
    return ModelInfo(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      alias: (json['alias'] ?? '').toString(),
      description: json['description']?.toString(),
      task: task,
      contextWindowSize: (json['contextWindowSize'] as num?)?.toInt(),
      inputModalities: _parseModalities(json['input']),
      outputModalities: _parseModalities(json['output']),
      capabilities: ModelCapabilities.fromJson(
        json['capabilities'] as Map<String, dynamic>?,
      ),
      isRemote: json['isRemote'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
      // 缺失或未知的 source 由构造函数按布尔字段推导。
      source: ModelSource.tryParse(json['source']?.toString()),
      isAppModel: json['isAppModel'] as bool? ?? false,
      appBundleId: json['appBundleId']?.toString(),
      appName: _nonEmptyOrNull(json['appName']),
    );
  }

  static String? _nonEmptyOrNull(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'alias': alias,
    if (description != null) 'description': description,
    'task': task.wireName,
    if (contextWindowSize != null) 'contextWindowSize': contextWindowSize,
    'input': inputModalities.map((m) => m.wireName).toList(),
    'output': outputModalities.map((m) => m.wireName).toList(),
    'capabilities': capabilities.toJson(),
    'isRemote': isRemote,
    if (isCustom) 'isCustom': true,
    'source': source.wireName,
    if (isAppModel) 'isAppModel': true,
    'appBundleId': ?appBundleId,
    'appName': ?appName,
  };

  static List<Modality> _parseModalities(dynamic value) {
    if (value is! List) return const [Modality.text];
    final result = <Modality>[];
    for (final item in value) {
      final modality = Modality.fromString(item?.toString());
      if (modality != null) result.add(modality);
    }
    return result.isEmpty ? const [Modality.text] : result;
  }
}

/// Question primitive accepted by decision models.
enum DecisionQuestionType {
  /// Pick one option; `criteria` maps every option to its description.
  choice('choice'),

  /// Ordinal scale of 2-10 levels; `criteria` lists the level descriptions.
  score('score'),

  /// Yes/no judgement; `criteria` optionally describes `true` and `false`.
  noul('noul');

  const DecisionQuestionType(this.wireName);

  final String wireName;

  static DecisionQuestionType? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final type in DecisionQuestionType.values) {
      if (type.wireName == normalized) return type;
    }
    return null;
  }
}

/// One typed question sent to a decision model (`/modelkit/decision`).
///
/// Prefer the [DecisionQuestion.choice], [DecisionQuestion.score] and
/// [DecisionQuestion.noul] factories, which build the matching `criteria`.
class DecisionQuestion {
  const DecisionQuestion({
    required this.type,
    required this.instructions,
    this.criteria,
  });

  /// Pick exactly one of [options] (`option -> description`).
  factory DecisionQuestion.choice({
    required String instructions,
    required Map<String, String> options,
  }) => DecisionQuestion(
    type: DecisionQuestionType.choice,
    instructions: instructions,
    criteria: options,
  );

  /// Rate on a scale; [levels] holds the 2-10 level descriptions in order.
  factory DecisionQuestion.score({
    required String instructions,
    required List<String> levels,
  }) => DecisionQuestion(
    type: DecisionQuestionType.score,
    instructions: instructions,
    criteria: levels,
  );

  /// Yes/no judgement. [trueMeaning] and [falseMeaning] are optional hints.
  factory DecisionQuestion.noul({
    required String instructions,
    String? trueMeaning,
    String? falseMeaning,
  }) {
    final criteria = <String, String>{
      'true': ?trueMeaning,
      'false': ?falseMeaning,
    };
    return DecisionQuestion(
      type: DecisionQuestionType.noul,
      instructions: instructions,
      criteria: criteria.isEmpty ? null : criteria,
    );
  }

  final DecisionQuestionType type;
  final String instructions;

  /// `Map<String, String>` for choice, `List<String>` for score, optional
  /// `Map<String, String>` for noul.
  final Object? criteria;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.wireName,
    'instructions': instructions,
    'criteria': ?criteria,
  };
}

/// Answer to one [DecisionQuestion].
///
/// Only the field matching [type] is populated: [choice] (with [confidence])
/// for choice questions, [score] for score questions, [noul] for noul
/// questions. [probabilities] and [legend] are passed through untouched; read
/// [raw] for anything else the server returns.
class DecisionAnswer {
  const DecisionAnswer({
    this.type,
    this.choice,
    this.score,
    this.noul,
    this.probabilities,
    this.confidence,
    this.legend,
    this.raw = const <String, dynamic>{},
  });

  factory DecisionAnswer.fromJson(Map<String, dynamic> json) {
    return DecisionAnswer(
      type: DecisionQuestionType.fromString(json['type']?.toString()),
      choice: json['choice']?.toString(),
      score: (json['score'] as num?)?.toDouble(),
      noul: (json['noul'] as num?)?.toDouble(),
      probabilities: json['probabilities'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      legend: json['legend'],
      raw: json,
    );
  }

  final DecisionQuestionType? type;

  /// Selected option of a choice question.
  final String? choice;

  /// Numeric result of a score question.
  final double? score;

  /// Numeric result of a noul question.
  final double? noul;

  final Object? probabilities;
  final double? confidence;
  final Object? legend;

  /// The complete answer object as returned by the server.
  final Map<String, dynamic> raw;
}

/// Token usage reported by a decision model.
class DecisionUsage {
  const DecisionUsage({this.inputTokens = 0, this.outputTokens = 0});

  factory DecisionUsage.fromJson(Map<String, dynamic> json) {
    return DecisionUsage(
      inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
    );
  }

  final int inputTokens;
  final int outputTokens;
}

/// Response of `POST /modelkit/decision`.
class DecisionResponse {
  const DecisionResponse({
    this.model,
    this.answers = const <String, DecisionAnswer>{},
    this.usage,
    this.raw = const <String, dynamic>{},
  });

  factory DecisionResponse.fromJson(Map<String, dynamic> json) {
    final answers = <String, DecisionAnswer>{};
    final answersJson = json['answers'];
    if (answersJson is Map) {
      answersJson.forEach((key, value) {
        if (value is Map) {
          answers[key.toString()] = DecisionAnswer.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }
    final usageJson = json['usage'];
    return DecisionResponse(
      model: json['model']?.toString(),
      answers: answers,
      usage: usageJson is Map
          ? DecisionUsage.fromJson(Map<String, dynamic>.from(usageJson))
          : null,
      raw: json,
    );
  }

  final String? model;

  /// Answers keyed by the question ids of the request.
  final Map<String, DecisionAnswer> answers;
  final DecisionUsage? usage;

  /// The complete response object as returned by the server.
  final Map<String, dynamic> raw;
}

/// A model registered by a third-party app (`GET /modelkit/app-models`).
///
/// The API key is never returned; [hasApiKey] only tells whether one is stored.
class AppModel {
  const AppModel({
    required this.id,
    required this.name,
    String? qualifiedId,
    this.alias = '',
    this.description = '',
    this.task = ModelTask.chat,
    this.provider = '',
    this.inputModalities = const [Modality.text],
    this.outputModalities = const [Modality.text],
    this.capabilities = const ModelCapabilities(),
    this.baseUrl,
    this.hasApiKey = false,
    this.contextWindowSize,
    this.isDisabled = false,
    required this.appBundleId,
    this.appName = '',
  }) : qualifiedId = qualifiedId ?? id;

  factory AppModel.fromJson(Map<String, dynamic> json) {
    final capabilitiesJson = json['capabilities'];
    return AppModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      qualifiedId: json['qualifiedId']?.toString(),
      alias: json['alias']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      task: ModelTask.fromString(json['task']?.toString()) ?? ModelTask.chat,
      provider: json['provider']?.toString() ?? '',
      inputModalities: ModelInfo._parseModalities(json['input']),
      outputModalities: ModelInfo._parseModalities(json['output']),
      capabilities: capabilitiesJson is Map
          ? ModelCapabilities.fromJson(
              Map<String, dynamic>.from(capabilitiesJson),
            )
          : const ModelCapabilities(),
      baseUrl: json['baseUrl']?.toString(),
      hasApiKey: json['hasApiKey'] as bool? ?? false,
      contextWindowSize: (json['contextWindowSize'] as num?)?.toInt(),
      isDisabled: json['isDisabled'] as bool? ?? false,
      appBundleId: json['appBundleId']?.toString() ?? '',
      appName: json['appName']?.toString() ?? '',
    );
  }

  /// The app's own identifier for this model (the `localId` it registered).
  ///
  /// Different apps may use the same [id]; use [qualifiedId] to address a model
  /// in requests, and [id] only for `updateAppModel` / `unregisterAppModel` /
  /// `toggleAppModel` on models owned by the calling app.
  final String id;

  /// The full model ID, `<id>@<appBundleId>`: identical to the model's `id` in
  /// [ModelKitClient.listModels]. Pass it as the `model` of chat / embedding /
  /// ASR / TTS / decision requests to route to exactly this model.
  ///
  /// Falls back to [id] when the gateway predates namespaced model IDs and does
  /// not return `qualifiedId` (such a gateway routes by the bare [id]).
  final String qualifiedId;
  final String name;
  final String alias;
  final String description;
  final ModelTask task;
  final String provider;
  final List<Modality> inputModalities;
  final List<Modality> outputModalities;
  final ModelCapabilities capabilities;
  final String? baseUrl;

  /// Whether an API key is stored for this model (the key itself is never
  /// exposed).
  final bool hasApiKey;
  final int? contextWindowSize;

  /// Disabled models stay registered but are hidden from model lists.
  final bool isDisabled;

  /// Bundle ID of the app that owns this model.
  final String appBundleId;
  final String appName;
}

/// Request body of [ModelKitClient.registerAppModel].
///
/// Only [id] and [name] are required; every unset field is omitted from the
/// request so the server applies its own defaults. Decision models
/// (`task: ModelTask.decision`) are normalized by the server to input
/// `text` (+ optional `image`), output `decisions` and no capabilities.
class AppModelRegistration {
  const AppModelRegistration({
    required this.id,
    required this.name,
    this.alias,
    this.description,
    this.task,
    this.provider,
    this.inputModalities,
    this.outputModalities,
    this.stream,
    this.toolCall,
    this.reasoning,
    this.baseUrl,
    this.apiKey,
    this.contextWindowSize,
    this.appBundleId,
    this.appName,
  });

  /// The model's identifier within this app (its `localId`): 1-64 characters
  /// from `[A-Za-z0-9._-]`. Different apps may use the same value; the gateway
  /// exposes the model as `<id>@<bundleId>` (see
  /// [AppModelWriteResult.qualifiedId]).
  final String id;
  final String name;
  final String? alias;
  final String? description;
  final ModelTask? task;
  final String? provider;
  final List<Modality>? inputModalities;
  final List<Modality>? outputModalities;
  final bool? stream;
  final bool? toolCall;
  final bool? reasoning;

  /// Upstream endpoint the gateway forwards to. For decision models the
  /// default upstream path is `/v1/systemone`.
  final String? baseUrl;

  /// Upstream credential. Stored by the server and never returned.
  final String? apiKey;
  final int? contextWindowSize;

  /// Must match the bundle ID of the bearer token when provided.
  final String? appBundleId;
  final String? appName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'alias': ?alias,
    'description': ?description,
    'task': ?task?.wireName,
    'provider': ?provider,
    'input': ?inputModalities?.map((m) => m.wireName).toList(),
    'output': ?outputModalities?.map((m) => m.wireName).toList(),
    'capabilities': ?_appModelCapabilitiesJson(stream, toolCall, reasoning),
    'baseUrl': ?baseUrl,
    'apiKey': ?apiKey,
    'contextWindowSize': ?contextWindowSize,
    'appBundleId': ?appBundleId,
    'appName': ?appName,
  };
}

/// Request body of [ModelKitClient.updateAppModel] (partial update).
///
/// Unset fields are left unchanged on the server. [apiKey] is overwritten
/// only when non-empty. When [task] changes, input/output/capabilities that
/// are not provided are reset to the new task's defaults. The owning
/// `appBundleId` cannot be changed.
class AppModelUpdate {
  const AppModelUpdate({
    this.name,
    this.alias,
    this.description,
    this.task,
    this.provider,
    this.inputModalities,
    this.outputModalities,
    this.stream,
    this.toolCall,
    this.reasoning,
    this.baseUrl,
    this.apiKey,
    this.contextWindowSize,
    this.appName,
  });

  final String? name;
  final String? alias;
  final String? description;
  final ModelTask? task;
  final String? provider;
  final List<Modality>? inputModalities;
  final List<Modality>? outputModalities;
  final bool? stream;
  final bool? toolCall;
  final bool? reasoning;
  final String? baseUrl;
  final String? apiKey;
  final int? contextWindowSize;
  final String? appName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': ?name,
    'alias': ?alias,
    'description': ?description,
    'task': ?task?.wireName,
    'provider': ?provider,
    'input': ?inputModalities?.map((m) => m.wireName).toList(),
    'output': ?outputModalities?.map((m) => m.wireName).toList(),
    'capabilities': ?_appModelCapabilitiesJson(stream, toolCall, reasoning),
    'baseUrl': ?baseUrl,
    'apiKey': ?apiKey,
    'contextWindowSize': ?contextWindowSize,
    'appName': ?appName,
  };
}

/// Result of an app-model write call (register / update / unregister /
/// toggle).
class AppModelWriteResult {
  const AppModelWriteResult({
    required this.success,
    this.id,
    this.qualifiedId,
    this.updated = false,
  });

  factory AppModelWriteResult.fromJson(Map<String, dynamic> json) {
    return AppModelWriteResult(
      success: json['success'] as bool? ?? false,
      id: json['id']?.toString(),
      qualifiedId: json['qualifiedId']?.toString(),
      updated: json['updated'] as bool? ?? false,
    );
  }

  final bool success;

  /// The app's own model id (`localId`); returned by register only.
  final String? id;

  /// The full model ID (`<id>@<bundleId>`) to use as the `model` of requests;
  /// returned by register only. Store it: it routes to exactly this model.
  ///
  /// `null` when the gateway predates namespaced model IDs; use [id] then.
  final String? qualifiedId;

  /// `true` when register replaced an existing model of the same app.
  final bool updated;
}

Map<String, dynamic>? _appModelCapabilitiesJson(
  bool? stream,
  bool? toolCall,
  bool? reasoning,
) {
  if (stream == null && toolCall == null && reasoning == null) return null;
  return <String, dynamic>{
    'stream': ?stream,
    'tool_call': ?toolCall,
    'reasoning': ?reasoning,
  };
}

/// Task-oriented ModelKit client.
///
/// Routes:
/// - GET    `/modelkit/models`
/// - ALL    `/modelkit/chat/<path>`        (OpenAI Chat Completions)
/// - ALL    `/modelkit/embedding/<path>`   (OpenAI Embeddings)
/// - ALL    `/modelkit/asr/<path>`         (OpenAI Audio Transcriptions)
/// - ALL    `/modelkit/tts/<path>`         (OpenAI Audio Speech)
/// - ALL    `/modelkit/decision`           (typed-question decisions)
/// - GET    `/modelkit/app-models`         (list app-registered models)
/// - POST   `/modelkit/app-models`         (register, bearer token)
/// - PUT    `/modelkit/app-models/<id>`    (update, bearer token)
/// - DELETE `/modelkit/app-models/<id>`    (unregister, bearer token)
/// - POST   `/modelkit/app-models/<id>/toggle` (enable/disable, bearer token)
class ModelKitClient {
  ModelKitClient({ApiClient? apiClient}) : this._(apiClient ?? ApiClient());

  ModelKitClient._(this._apiClient);

  final ApiClient _apiClient;
  late final ModelKitChatClient chat = ModelKitChatClient._(_apiClient);
  late final ModelKitEmbeddingClient embedding = ModelKitEmbeddingClient._(
    _apiClient,
  );
  late final ModelKitAsrClient asr = ModelKitAsrClient._(_apiClient);
  late final ModelKitTtsClient tts = ModelKitTtsClient._(_apiClient);
  late final ModelKitDecisionClient decision = ModelKitDecisionClient._(
    _apiClient,
  );

  Future<List<ModelInfo>> listModels() async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/modelkit/models',
      options: Options(method: 'GET'),
    );
    return _asJsonList(
      response.data,
    ).map((item) => ModelInfo.fromJson(item)).toList();
  }

  /// Returns models filtered by [task] (client-side filter).
  Future<List<ModelInfo>> listModelsByTask(ModelTask task) async {
    final all = await listModels();
    return all.where((m) => m.task == task).toList(growable: false);
  }

  /// Lists models registered by apps (`GET /modelkit/app-models`).
  ///
  /// Public endpoint, no token required. Disabled models are included; check
  /// [AppModel.isDisabled].
  Future<List<AppModel>> listAppModels() async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/modelkit/app-models',
      options: Options(method: 'GET'),
    );
    return _asJsonList(response.data).map(AppModel.fromJson).toList();
  }

  /// Registers (or replaces) an app model (`POST /modelkit/app-models`).
  ///
  /// [bearerToken] is the AppKit token from `registerApp`. The model `id` only
  /// has to be unique within the calling app; the result carries
  /// [AppModelWriteResult.qualifiedId] (`<id>@<bundleId>`), the ID to use as
  /// `model` in requests. Re-registering an id of the same app replaces it
  /// ([AppModelWriteResult.updated] is `true`).
  ///
  /// Throws a [DioException] with status 401 (missing/invalid token), 403
  /// (`appBundleId` mismatch), 409 (the `name` is already used by another model
  /// of the same app) or 400 (invalid body, unknown `task`, or an `id` /
  /// bundle ID outside `[A-Za-z0-9._-]` or over the length limit: 64 / 128).
  Future<AppModelWriteResult> registerAppModel({
    required String bearerToken,
    required AppModelRegistration request,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/modelkit/app-models',
      data: request.toJson(),
      options: _appModelAuthOptions(bearerToken),
    );
    return AppModelWriteResult.fromJson(_jsonMapFrom(response.data));
  }

  /// Partially updates an app model owned by the token's app
  /// (`PUT /modelkit/app-models/<id>`).
  ///
  /// [modelId] is the app's own `id` (not the qualified ID) and is looked up
  /// only among the calling app's models; an unknown id is a 404.
  Future<AppModelWriteResult> updateAppModel({
    required String bearerToken,
    required String modelId,
    required AppModelUpdate request,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.put(
      _appModelPath(modelId),
      data: request.toJson(),
      options: _appModelAuthOptions(bearerToken),
    );
    return AppModelWriteResult.fromJson(_jsonMapFrom(response.data));
  }

  /// Removes an app model owned by the token's app
  /// (`DELETE /modelkit/app-models/<id>`).
  Future<AppModelWriteResult> unregisterAppModel({
    required String bearerToken,
    required String modelId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.delete(
      _appModelPath(modelId),
      options: _appModelAuthOptions(bearerToken),
    );
    return AppModelWriteResult.fromJson(_jsonMapFrom(response.data));
  }

  /// Flips the enabled/disabled state of an app model owned by the token's
  /// app (`POST /modelkit/app-models/<id>/toggle`).
  Future<AppModelWriteResult> toggleAppModel({
    required String bearerToken,
    required String modelId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '${_appModelPath(modelId)}/toggle',
      options: _appModelAuthOptions(bearerToken),
    );
    return AppModelWriteResult.fromJson(_jsonMapFrom(response.data));
  }

  String _appModelPath(String modelId) =>
      '/modelkit/app-models/${Uri.encodeComponent(modelId)}';

  Options _appModelAuthOptions(String bearerToken) => Options(
    headers: <String, String>{'authorization': 'Bearer $bearerToken'},
  );

  dynamic _decodeJson(dynamic data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<Map<String, dynamic>> _asJsonList(dynamic data) {
    final decoded = _decodeJson(data);
    if (decoded is List) {
      return decoded
          .map(
            (item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map),
          )
          .toList();
    }
    throw FormatException('Expected JSON array but got ${decoded.runtimeType}');
  }
}

Map<String, dynamic> _jsonMapFrom(dynamic data) {
  final decoded = data is String && data.isNotEmpty ? jsonDecode(data) : data;
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  throw FormatException('Expected JSON object but got ${decoded.runtimeType}');
}

/// Typed-question decisions (`POST /modelkit/decision`).
///
/// Decision models (`ModelTask.decision`, llama.cpp `/v1/systemone`) score
/// caller-provided options instead of generating text.
class ModelKitDecisionClient {
  ModelKitDecisionClient._(this._apiClient);

  final ApiClient _apiClient;

  /// Asks [questions] about [state].
  ///
  /// - [state]: a string, JSON object or JSON array describing the situation.
  /// - [questions]: question id -> [DecisionQuestion]; answers come back under
  ///   the same ids.
  /// - [model]: decision model id; the gateway picks a default when omitted.
  /// - [images]: optional data URLs, for models that accept `image` input.
  /// - [extra]: additional top-level fields merged into the request body.
  Future<DecisionResponse> create({
    String? model,
    required Object state,
    required Map<String, DecisionQuestion> questions,
    List<String>? images,
    Map<String, dynamic>? extra,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/modelkit/decision',
      data: <String, dynamic>{
        ...?extra,
        'model': ?model,
        'state': state,
        'questions': questions.map((id, q) => MapEntry(id, q.toJson())),
        'images': ?images,
      },
    );
    return DecisionResponse.fromJson(_jsonMapFrom(response.data));
  }
}

/// Forwards chat (text + vision) traffic to `/modelkit/chat/...` using the
/// OpenAI Chat Completions wire protocol.
class ModelKitChatClient {
  ModelKitChatClient._(ApiClient apiClient)
    : _client = OpenAIClient(
        baseUrl: _buildBaseUrl(apiClient.dio.options.baseUrl),
        requestsTimeOut: _resolveTimeout(apiClient.dio.options.receiveTimeout),
      );

  final OpenAIClient _client;

  String get baseUrl => _client.baseUrl;

  Future<OpenAIChatCompletionModel> create({
    required String model,
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
    List<OpenAIToolModel>? tools,
    dynamic toolChoice,
    double? temperature,
    double? topP,
    int? n,
    dynamic stop,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    Map<String, dynamic>? logitBias,
    String? user,
    Object? responseFormat,
    int? seed,
    bool? logprobs,
    int? topLogprobs,
    String? reasoningEffort,
    bool? enableThinking,
  }) {
    return _client.chat.create(
      model: model,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      temperature: temperature,
      topP: topP,
      n: n,
      stop: stop,
      maxTokens: maxTokens,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: logitBias,
      user: user,
      responseFormat: responseFormat,
      seed: seed,
      logprobs: logprobs,
      topLogprobs: topLogprobs,
      reasoningEffort: reasoningEffort,
      enableThinking: enableThinking,
    );
  }

  Stream<OpenAIStreamChatCompletionModel> createStream({
    required String model,
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
    List<OpenAIToolModel>? tools,
    dynamic toolChoice,
    double? temperature,
    double? topP,
    int? n,
    dynamic stop,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    Map<String, dynamic>? logitBias,
    Object? responseFormat,
    int? seed,
    String? user,
    Map<String, dynamic>? streamOptions,
    String? reasoningEffort,
    bool? enableThinking,
  }) {
    return _client.chat.createStream(
      model: model,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      temperature: temperature,
      topP: topP,
      n: n,
      stop: stop,
      maxTokens: maxTokens,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: logitBias,
      responseFormat: responseFormat,
      seed: seed,
      user: user,
      streamOptions: streamOptions,
      reasoningEffort: reasoningEffort,
      enableThinking: enableThinking,
    );
  }

  Stream<OpenAIStreamChatCompletionModel> createRemoteFunctionStream({
    required String model,
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
    List<OpenAIToolModel>? tools,
    dynamic toolChoice,
    double? temperature,
    double? topP,
    int? n,
    dynamic stop,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    Map<String, dynamic>? logitBias,
    String? user,
    Object? responseFormat,
    int? seed,
    String? reasoningEffort,
    bool? enableThinking,
  }) {
    return _client.chat.createRemoteFunctionStream(
      model: model,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      temperature: temperature,
      topP: topP,
      n: n,
      stop: stop,
      maxTokens: maxTokens,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: logitBias,
      user: user,
      responseFormat: responseFormat,
      seed: seed,
      reasoningEffort: reasoningEffort,
      enableThinking: enableThinking,
    );
  }

  static String _buildBaseUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final normalizedBase = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    return uri.replace(path: '$normalizedBase/modelkit/chat').toString();
  }

  static Duration? _resolveTimeout(Duration? timeout) {
    if (timeout == null || timeout == Duration.zero) {
      return null;
    }
    return timeout;
  }
}

/// Forwards embedding requests to `/modelkit/embedding/...` using the OpenAI
/// embeddings wire protocol.
class ModelKitEmbeddingClient {
  ModelKitEmbeddingClient._(this._apiClient);

  final ApiClient _apiClient;

  static const String _path = '/modelkit/embedding/v1/embeddings';

  /// Creates embeddings. [input] accepts a string, a list of strings, or a
  /// list of token ids (OpenAI compatible).
  Future<Map<String, dynamic>> create({
    required String model,
    required Object input,
    String? encodingFormat,
    int? dimensions,
    String? user,
    Map<String, dynamic>? extra,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'input': input,
      if (encodingFormat != null) 'encoding_format': encodingFormat,
      if (dimensions != null) 'dimensions': dimensions,
      if (user != null) 'user': user,
      if (extra != null) ...extra,
    };
    final Response<dynamic> response = await _apiClient.dio.post(
      _path,
      data: body,
    );
    return _asJsonMap(response.data);
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw FormatException('Expected JSON object but got ${data.runtimeType}');
  }
}

/// Forwards speech-to-text requests to `/modelkit/asr/...` using the OpenAI
/// audio transcriptions wire protocol.
class ModelKitAsrClient {
  ModelKitAsrClient._(this._apiClient);

  final ApiClient _apiClient;

  static const String _path = '/modelkit/asr/v1/audio/transcriptions';

  /// Transcribes [audioBytes]. [fileName] is used as the multipart filename;
  /// other parameters mirror the OpenAI audio transcription API.
  Future<Map<String, dynamic>> transcribe({
    required String model,
    required List<int> audioBytes,
    required String fileName,
    String? language,
    String? prompt,
    String? responseFormat,
    double? temperature,
    Map<String, dynamic>? extra,
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'model': model,
      'file': MultipartFile.fromBytes(audioBytes, filename: fileName),
      if (language != null) 'language': language,
      if (prompt != null) 'prompt': prompt,
      if (responseFormat != null) 'response_format': responseFormat,
      if (temperature != null) 'temperature': temperature,
      if (extra != null) ...extra,
    });
    final Response<dynamic> response = await _apiClient.dio.post(
      _path,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _asJsonMap(response.data);
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return <String, dynamic>{'text': data};
      }
    }
    throw FormatException('Expected JSON object but got ${data.runtimeType}');
  }
}

/// Forwards text-to-speech requests to `/modelkit/tts/...` using the OpenAI
/// audio speech wire protocol.
class ModelKitTtsClient {
  ModelKitTtsClient._(this._apiClient);

  final ApiClient _apiClient;

  static const String _speechPath = '/modelkit/tts/v1/audio/speech';
  static const String _voicesPath = '/modelkit/tts/v1/audio/voices';

  /// Returns raw synthesized audio bytes.
  Future<List<int>> synthesize({
    required String model,
    required String input,
    String? voice,
    String? responseFormat,
    double? speed,
    Map<String, dynamic>? extra,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'input': input,
      if (voice != null) 'voice': voice,
      if (responseFormat != null) 'response_format': responseFormat,
      if (speed != null) 'speed': speed,
      if (extra != null) ...extra,
    };
    final Response<List<int>> response = await _apiClient.dio.post<List<int>>(
      _speechPath,
      data: body,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const <int>[];
  }

  /// Lists configured voices. The shape `{voice_id: {...}}` is provider
  /// specific and may vary across upstream services.
  Future<Map<String, dynamic>> listVoices() async {
    final Response<dynamic> response = await _apiClient.dio.get(_voicesPath);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return const <String, dynamic>{};
  }
}
