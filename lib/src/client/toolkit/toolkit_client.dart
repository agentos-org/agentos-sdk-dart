import 'package:dio/dio.dart';

import '../../utils/api_client.dart';

class ToolKitClient {
  ToolKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Response<dynamic>> request(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return _apiClient.dio.request<dynamic>(
      '/toolkit$normalizedPath',
      data: data,
      queryParameters: queryParameters,
      options: options ?? Options(method: method),
    );
  }
}
