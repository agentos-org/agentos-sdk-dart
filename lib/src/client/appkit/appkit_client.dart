import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

class AppKitClient {
  AppKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AccessToken> registerBundle({required String bundleId}) async {
    final bundle = AppBundle(bundleId: bundleId);
    final Response<dynamic> response = await _apiClient.dio.post(
      '/appkit/register',
      data: bundle.toJson(),
    );
    return AccessToken.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Stream<AgentOSEvent>> subscribe({required String bearerToken}) async {
    final Response<ResponseBody> response = await _apiClient.dio
        .get<ResponseBody>(
          '/appkit/subscribe',
          options: Options(
            responseType: ResponseType.stream,
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
    final controller = StreamController<AgentOSEvent>();
    String? currentEvent;
    String? currentData;

    source
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
              return;
            }
            if (line.startsWith('data:')) {
              currentData = line.substring(5).trim();
              return;
            }
            if (line.isEmpty) {
              if (currentEvent != null && currentData != null) {
                controller.add(
                  AgentOSEvent(agentosEventType: currentEvent!, data: currentData!),
                );
              }
              currentEvent = null;
              currentData = null;
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );

    return controller.stream;
  }
}
