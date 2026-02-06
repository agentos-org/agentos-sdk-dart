import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class IntentKitClient {
  IntentKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<IntentKitJobHandle> submitRaw({
    required String bearerToken,
    required IntentKitSubmitRawRequest request,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/intentkit/submitRaw',
      data: request.toJson(),
      options: _authOptions(bearerToken),
    );
    return IntentKitJobHandle.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<IntentKitJobHandle> submitIntent({
    required String bearerToken,
    required IntentKitSubmitIntentRequest request,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/intentkit/submitIntent',
      data: request.toJson(),
      options: _authOptions(bearerToken),
    );
    return IntentKitJobHandle.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<IntentKitJobHandle> confirmJob({
    required String bearerToken,
    required IntentKitConfirmJobRequest request,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/intentkit/confirmJob',
      data: request.toJson(),
      options: _authOptions(bearerToken),
    );
    return IntentKitJobHandle.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<IntentKitSuggestNextActionResponse> suggestNextAction({
    required String bearerToken,
    required IntentKitSuggestNextActionRequest request,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/intentkit/suggestNextAction',
      data: request.toJson(),
      options: _authOptions(bearerToken),
    );
    return IntentKitSuggestNextActionResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Options _authOptions(String bearerToken) {
    return Options(
      headers: {HttpHeaders.authorizationHeader: 'Bearer $bearerToken'},
    );
  }
}
