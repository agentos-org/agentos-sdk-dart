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
  tts('tts');

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
  video('video');

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
  });

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

  bool get hasVision =>
      capabilities.vision ||
      inputModalities.contains(Modality.image) ||
      inputModalities.contains(Modality.video);

  bool get supportsChatInference => task == ModelTask.chat;

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
    );
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

/// Task-oriented ModelKit client.
///
/// Routes:
/// - GET    `/modelkit/models`
/// - ALL    `/modelkit/chat/<path>`        (OpenAI Chat Completions)
/// - ALL    `/modelkit/embedding/<path>`   (OpenAI Embeddings)
/// - ALL    `/modelkit/asr/<path>`         (OpenAI Audio Transcriptions)
/// - ALL    `/modelkit/tts/<path>`         (OpenAI Audio Speech)
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
