import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import '../../utils/api_client.dart';
import 'agents_dto.dart';
import 'capability_dto.dart';
import 'common_dto.dart';
import 'messages_dto.dart';
import 'sessions_dto.dart';

class AgentKitClient {
  AgentKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getAgent({
    required String bearerToken,
    required String agentId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/agentkit/agent',
      queryParameters: AgentId(agentId: agentId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> createAgent({
    required String bearerToken,
    required Agent agent,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/agentkit/agent/create',
      data: agent.toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> updateAgent({
    required String bearerToken,
    required String agentId,
    required Agent agent,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/agentkit/agent/update',
      data: agent.toJson(),
      queryParameters: AgentId(agentId: agentId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> deleteAgent({
    required String bearerToken,
    required String agentId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/agentkit/agent/delete',
      queryParameters: AgentId(agentId: agentId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> initSession({
    required String bearerToken,
    Capability? capability,
    String? agentId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/agentkit/initSession',
      data: capability?.toJson(),
      queryParameters: agentId == null
          ? null
          : AgentId(agentId: agentId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> initSimple({
    required String bearerToken,
    required SimpleCapability simpleCapability,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/agentkit/initSimple',
      data: simpleCapability.toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Stream<AgentEvent>> chat({
    required String bearerToken,
    required String sessionId,
    required UserTask userTask,
  }) async {
    final Response<ResponseBody> response = await _apiClient.dio
        .post<ResponseBody>(
          '/agentkit/chat',
          data: userTask.toJson(),
          queryParameters: Session(sessionId: sessionId).toJson(),
          options: _authOptions(
            bearerToken,
            responseType: ResponseType.stream,
          ),
        );
    final ResponseBody? body = response.data;
    if (body == null) {
      return const Stream<AgentEvent>.empty();
    }
    return _parseSse(body.stream.cast<List<int>>());
  }

  Future<Map<String, dynamic>> chatSimple({
    required String bearerToken,
    required String sessionId,
    required UserTask userTask,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/agentkit/chat/simple',
      data: userTask.toJson(),
      queryParameters: Session(sessionId: sessionId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<List<dynamic>> history({
    required String bearerToken,
    required String sessionId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/agentkit/history',
      queryParameters: Session(sessionId: sessionId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonList(response.data);
  }

  Future<Map<String, dynamic>> stop({
    required String bearerToken,
    required String sessionId,
    String? taskId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/agentkit/stop',
      queryParameters: SessionTask(sessionId: sessionId, taskId: taskId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> clear({
    required String bearerToken,
    required String sessionId,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.get(
      '/agentkit/clear',
      queryParameters: Session(sessionId: sessionId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> callback({
    required String bearerToken,
    required String sessionId,
    required ToolReturn toolReturn,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/agentkit/callback',
      data: toolReturn.toJson(),
      queryParameters: Session(sessionId: sessionId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Future<Map<String, dynamic>> streamCallback({
    required String bearerToken,
    required String sessionId,
    required EventToolReturn eventToolReturn,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/agentkit/streamCallback',
      data: eventToolReturn.toJson(),
      queryParameters: Session(sessionId: sessionId).toJson(),
      options: _authOptions(bearerToken),
    );
    return _asJsonMap(response.data);
  }

  Options _authOptions(String bearerToken, {ResponseType? responseType}) {
    return Options(
      responseType: responseType,
      headers: {HttpHeaders.authorizationHeader: 'Bearer $bearerToken'},
    );
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

  Map<String, dynamic> _asJsonMap(dynamic data) {
    final decoded = _decodeJson(data);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asJsonList(dynamic data) {
    final decoded = _decodeJson(data);
    if (decoded is List) {
      return decoded;
    }
    return const [];
  }

  Stream<AgentEvent> _parseSse(Stream<List<int>> source) {
    final controller = StreamController<AgentEvent>();
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
                  AgentEvent(agentEventType: currentEvent!, data: currentData!),
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
