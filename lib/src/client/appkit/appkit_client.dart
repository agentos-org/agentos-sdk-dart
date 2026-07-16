import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sse_client_dart/sse_client_dart.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class AppKitClient {
  AppKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AccessToken> registerBundle({
    required String bundleId,
    String? appGroupId,
    List<OpenToolServerDeclaration> opentoolServers = const [],
  }) async {
    final bundle = AppBundle(
      bundleId: bundleId,
      appGroupId: appGroupId,
      opentoolServers: opentoolServers,
    );
    final Response<dynamic> response = await _apiClient.dio.post(
      '/appkit/register',
      data: bundle.toJson(),
    );
    return AccessToken.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Stream<AgentOSEvent>> subscribe({required String bearerToken}) async {
    final Response<ResponseBody> response = await _apiClient.dio
        .get<ResponseBody>(
          '/appkit/subscribe',
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: Duration.zero,
            headers: {HttpHeaders.authorizationHeader: 'Bearer $bearerToken'},
          ),
        );
    final ResponseBody? body = response.data;
    if (body == null) {
      return const Stream<AgentOSEvent>.empty();
    }
    return _parseSse(body.stream.cast<List<int>>());
  }

  Stream<AgentOSEvent> _parseSse(Stream<List<int>> source) {
    return source.transform(const EventSourceDecoder()).map((event) {
      return AgentOSEvent(
        id: event.id,
        agentosEventType: event.event ?? 'message',
        data: event.data ?? '',
      );
    });
  }
}
