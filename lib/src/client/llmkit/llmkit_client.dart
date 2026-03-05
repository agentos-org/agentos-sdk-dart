import 'dart:convert';

import 'package:dio/dio.dart';

import '../../utils/api_client.dart';

enum LlmKitServiceType { text, vision, embedding, tts, asr }

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
  LlmKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Response<dynamic>> request(
    LlmKitServiceType service,
    String path, {
    String method = 'POST',
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return _apiClient.dio.request<dynamic>(
      '${_prefixFor(service)}$normalizedPath',
      data: data,
      queryParameters: queryParameters,
      options: options ?? Options(method: method),
    );
  }

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

  String _prefixFor(LlmKitServiceType service) {
    switch (service) {
      case LlmKitServiceType.text:
        return '/llmkit/text';
      case LlmKitServiceType.vision:
        return '/llmkit/vision';
      case LlmKitServiceType.embedding:
        return '/llmkit/embedding';
      case LlmKitServiceType.tts:
        return '/llmkit/tts';
      case LlmKitServiceType.asr:
        return '/llmkit/asr';
    }
  }
}
