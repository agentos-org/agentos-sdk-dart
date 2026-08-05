import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class AuthKitClient {
  AuthKitClient({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthorizeResponse> authorize({
    required String bearerToken,
    AuthorizeRequest? request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/authkit/authorize',
      data: request?.toJson() ?? <String, dynamic>{},
      options: _options(bearerToken),
    );
    return AuthorizeResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AuthorizeResponse> getStatus({
    required String bearerToken,
    required String requestId,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/authkit/authorize/$requestId/status',
      options: _options(bearerToken),
    );
    return AuthorizeResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<ExchangeTokenResponse> exchangeToken({
    required String bearerToken,
    required ExchangeTokenRequest request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/authkit/token',
      data: request.toJson(),
      options: _options(bearerToken),
    );
    return ExchangeTokenResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AuthKitUserInfo> getUserInfo({
    required String accessToken,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/authkit/userinfo',
      options: _options(accessToken),
    );
    return AuthKitUserInfo.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<RevokeResponse> revoke({
    required String bearerToken,
    RevokeRequest? request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/authkit/revoke',
      data: request?.toJson() ?? <String, dynamic>{},
      options: _options(bearerToken),
    );
    return RevokeResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Options _options(String bearerToken) => Options(
    headers: <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
    },
  );
}
