import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sse_client_dart/sse_client_dart.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class DiscoveryKitClient {
  DiscoveryKitClient({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PeerDevice>> getPeers({
    required String bearerToken,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/discoverykit/peers',
      options: _options(bearerToken),
    );
    final items = response.data as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => PeerDevice.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Stream<PeerDeviceEvent>> streamPeers({
    required String bearerToken,
  }) async {
    final response = await _apiClient.dio.get<ResponseBody>(
      '/discoverykit/peers/stream',
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: <String, dynamic>{
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
        },
      ),
    );
    final body = response.data;
    if (body == null) {
      return const Stream<PeerDeviceEvent>.empty();
    }
    return body.stream.cast<List<int>>().transform(const EventSourceDecoder()).where(
      (event) => event.data != null && event.data!.isNotEmpty,
    ).map((event) {
      final json = jsonDecode(event.data!) as Map<String, dynamic>;
      return PeerDeviceEvent.fromJson(json);
    });
  }

  Future<SelfInfo> getSelf({
    required String bearerToken,
  }) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/discoverykit/self',
      options: _options(bearerToken),
    );
    return SelfInfo.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<DiscoveryRegisterResponse> register({
    required String bearerToken,
    DiscoveryRegisterRequest? request,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/discoverykit/register',
      data: request?.toJson() ?? <String, dynamic>{},
      options: _options(bearerToken),
    );
    return DiscoveryRegisterResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<DiscoveryUnregisterResponse> unregister({
    required String bearerToken,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/discoverykit/unregister',
      data: <String, dynamic>{},
      options: _options(bearerToken),
    );
    return DiscoveryUnregisterResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Options _options(String bearerToken) => Options(
    headers: <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
    },
  );
}
