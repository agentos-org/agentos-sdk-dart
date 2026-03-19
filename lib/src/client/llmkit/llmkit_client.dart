import 'dart:convert';

import 'package:dart_openai_sdk/dart_openai_sdk.dart';
import 'package:dio/dio.dart';

import '../../utils/api_client.dart';

enum LlmModelCategory {
  textGeneration,
  visionLanguage,
  embedding,
  textToSpeech,
  speechToText,
  audioTextToText,
  unknown,
}

class LlmModelInfo {
  LlmModelInfo({
    required this.id,
    required this.name,
    required this.alias,
    this.description,
    required this.type,
    this.contextWindowSize,
    this.isRemote = false,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String alias;
  final String? description;
  final String type;
  final int? contextWindowSize;
  final bool isRemote;
  final bool isCustom;

  /// Raw model type returned by AgentOS API.
  ///
  /// Current upstream values include `text`, `textGeneration`,
  /// `image_text_to_text`, `imageTextToText`, `embedding`,
  /// `text_to_speech`, and `audio_text_to_text`.
  String get rawType => type;

  /// Normalized model category to absorb upstream naming variants.
  LlmModelCategory get category {
    final normalizedType = type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      return LlmModelCategory.unknown;
    }
    if (normalizedType == 'text' || normalizedType == 'textgeneration') {
      return LlmModelCategory.textGeneration;
    }
    if (normalizedType == 'image_text_to_text' ||
        normalizedType == 'imagetexttotext') {
      return LlmModelCategory.visionLanguage;
    }
    if (normalizedType.contains('embedding')) {
      return LlmModelCategory.embedding;
    }
    if (normalizedType == 'text_to_speech' || normalizedType == 'tts') {
      return LlmModelCategory.textToSpeech;
    }
    if (normalizedType == 'speech_to_text' ||
        normalizedType == 'audio_text_to_text' ||
        normalizedType == 'asr') {
      return normalizedType == 'audio_text_to_text'
          ? LlmModelCategory.audioTextToText
          : LlmModelCategory.speechToText;
    }
    return LlmModelCategory.unknown;
  }

  bool get supportsTextInference =>
      category == LlmModelCategory.textGeneration ||
      category == LlmModelCategory.visionLanguage ||
      category == LlmModelCategory.unknown;

  bool get isVisionLanguage => category == LlmModelCategory.visionLanguage;

  factory LlmModelInfo.fromJson(Map<String, dynamic> json) {
    return LlmModelInfo(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      alias: json['alias'] as String,
      description: json['description']?.toString(),
      type: (json['type'] ?? '').toString(),
      contextWindowSize: (json['contextWindowSize'] as num?)?.toInt(),
      isRemote: json['isRemote'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'alias': alias,
    'description': description,
    'type': type,
    'contextWindowSize': contextWindowSize,
    'isRemote': isRemote,
    'isCustom': isCustom,
  };
}

class LlmKitClient {
  LlmKitClient({ApiClient? apiClient}) : this._(apiClient ?? ApiClient());

  LlmKitClient._(this._apiClient);

  final ApiClient _apiClient;
  late final LlmKitChatClient chat = LlmKitChatClient._(_apiClient);

  /// Returns models exposed by `/llmkit/models`.
  ///
  /// Upstream currently returns all models that support text inference,
  /// including text-only and vision-language models.
  Future<List<LlmModelInfo>> listModels() async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/llmkit/models',
      options: Options(method: 'GET'),
    );
    return _asJsonList(
      response.data,
    ).map((item) => LlmModelInfo.fromJson(item)).toList();
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

class LlmKitChatClient {
  LlmKitChatClient._(ApiClient apiClient)
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
    return uri.replace(path: '$normalizedBase/llmkit/text').toString();
  }

  static Duration? _resolveTimeout(Duration? timeout) {
    if (timeout == null || timeout == Duration.zero) {
      return null;
    }
    return timeout;
  }
}
