import 'package:dio/dio.dart';

import 'api_client.dart';
import 'dto.dart';

class RootClient {
  RootClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Version> getVersion() async {
    final Response<dynamic> response = await _apiClient.dio.get('/version');
    return Version.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
