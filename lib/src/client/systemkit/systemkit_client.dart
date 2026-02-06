import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class SystemKitClient {
  SystemKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Version> getVersion() async {
    final Response<dynamic> response = await _apiClient.dio.get('/version');
    return Version.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RootInfo> getRoot() async {
    final Response<dynamic> response = await _apiClient.dio.get('/');
    return RootInfo.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
