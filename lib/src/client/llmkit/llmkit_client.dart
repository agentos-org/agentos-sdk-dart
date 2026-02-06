import 'package:dio/dio.dart';

import '../../utils/api_client.dart';

enum LlmKitServiceType {
  text,
  vision,
  embedding,
  tts,
  asr,
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
