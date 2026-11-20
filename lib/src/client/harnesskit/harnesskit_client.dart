import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sse_client_dart/sse_client_dart.dart';

import '../../utils/api_client.dart';
import 'dto.dart';

/// HTTP client for the authenticated AgentOS HarnessKit gateway.
class HarnessKitClient {
  HarnessKitClient({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Checks whether the Harness runtime is reachable.
  Future<Map<String, dynamic>> health({required String bearerToken}) async =>
      _asJsonMap(
        await request<dynamic>(bearerToken: bearerToken, path: '/healthz'),
      );

  /// Reads the active Harness runtime engine.
  Future<HarnessKitRuntimeInfo> getRuntime({
    required String bearerToken,
  }) async => HarnessKitRuntimeInfo.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/runtime/harness-engine',
      ),
    ),
  );

  /// Switches the active Harness runtime engine.
  Future<HarnessKitEngineSwitchResult> switchEngine({
    required String bearerToken,
    required HarnessKitEngineId engine,
  }) async => HarnessKitEngineSwitchResult.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/runtime/harness-engine',
        method: 'POST',
        data: <String, dynamic>{'engine': engine},
      ),
    ),
  );

  /// Lists saved Harness threads. An absent `threads` field returns an empty list.
  Future<List<HarnessKitThreadSnapshot>> listThreads({
    required String bearerToken,
  }) async {
    final response = _asJsonMap(
      await request<dynamic>(bearerToken: bearerToken, path: '/v1/threads'),
    );
    final threads = response['threads'];
    if (threads is! List) return const <HarnessKitThreadSnapshot>[];
    return threads
        .map((thread) => HarnessKitThreadSnapshot.fromJson(_asJsonMap(thread)))
        .toList(growable: false);
  }

  /// Retrieves one saved thread.
  Future<HarnessKitThreadSnapshot> getThread({
    required String bearerToken,
    required String threadId,
  }) async => HarnessKitThreadSnapshot.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/threads/${Uri.encodeComponent(threadId)}',
      ),
    ),
  );

  /// Renames a saved thread.
  Future<HarnessKitThreadRenameResult> renameThread({
    required String bearerToken,
    required String threadId,
    required String title,
  }) async => HarnessKitThreadRenameResult.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/threads/${Uri.encodeComponent(threadId)}',
        method: 'PATCH',
        data: <String, dynamic>{'title': title},
      ),
    ),
  );

  /// Deletes a saved thread.
  Future<HarnessKitThreadDeleteResult> deleteThread({
    required String bearerToken,
    required String threadId,
  }) async => HarnessKitThreadDeleteResult.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/threads/${Uri.encodeComponent(threadId)}',
        method: 'DELETE',
      ),
    ),
  );

  /// Registers or replaces a local App's OpenTool callbacks for one thread.
  Future<HarnessKitPrivateToolsRegistrationResult> registerPrivateTools({
    required String bearerToken,
    required String threadId,
    required HarnessKitPrivateToolsRegistration registration,
  }) async => HarnessKitPrivateToolsRegistrationResult.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/threads/${Uri.encodeComponent(threadId)}/private-tools',
        method: 'PUT',
        data: registration.toJson(),
      ),
    ),
  );

  /// Starts a run on a thread and returns the accepted run identifier.
  Future<HarnessKitRunAccepted> startRun({
    required String bearerToken,
    required String threadId,
    required HarnessKitRunRequest request,
  }) async => HarnessKitRunAccepted.fromJson(
    _asJsonMap(
      await this.request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/threads/${Uri.encodeComponent(threadId)}/runs',
        method: 'POST',
        data: <String, dynamic>{...request.toJson(), 'threadId': threadId},
      ),
    ),
  );

  /// Submits a command. Rejected commands are returned as receipts in HTTP 400.
  Future<HarnessKitCommandReceipt> submitCommand({
    required String bearerToken,
    required String threadId,
    required HarnessKitCommand command,
  }) async {
    final path = '/v1/threads/${Uri.encodeComponent(threadId)}/commands';
    try {
      return HarnessKitCommandReceipt.fromJson(
        _asJsonMap(
          await request<dynamic>(
            bearerToken: bearerToken,
            path: path,
            method: 'POST',
            data: command.toJson(threadIdOverride: threadId),
          ),
        ),
      );
    } on DioException catch (error) {
      final body = _decodeJson(error.response?.data);
      if (_isCommandReceipt(body)) {
        return HarnessKitCommandReceipt.fromJson(_asJsonMap(body));
      }
      rethrow;
    }
  }

  /// Opens a resumable SSE stream for events on a thread.
  Future<Stream<HarnessKitEvent>> events({
    required String bearerToken,
    required String threadId,
    HarnessKitEventsOptions options = const HarnessKitEventsOptions(),
    CancelToken? cancelToken,
  }) async {
    if (options.afterSequence < 0) {
      throw ArgumentError.value(
        options.afterSequence,
        'afterSequence',
        'must be a non-negative integer',
      );
    }
    final response = await requestStream(
      bearerToken: bearerToken,
      path: '/v1/threads/${Uri.encodeComponent(threadId)}/events',
      queryParameters: <String, dynamic>{
        'afterSequence': options.afterSequence,
        if (options.runId != null) 'runId': options.runId,
      },
      cancelToken: cancelToken,
    );
    final body = response.data;
    if (body == null) return const Stream<HarnessKitEvent>.empty();
    return body.stream
        .cast<List<int>>()
        .transform(const EventSourceDecoder())
        .where((event) => event.data != null && event.data!.isNotEmpty)
        .map((event) {
          try {
            return HarnessKitEvent.fromJson(
              _asJsonMap(jsonDecode(event.data!)),
            );
          } catch (error) {
            throw FormatException(
              'Invalid HarnessKit SSE event "${event.event}": $error',
            );
          }
        });
  }

  /// Retrieves the final result for one run.
  Future<HarnessKitRunResult> getRunResult({
    required String bearerToken,
    required String runId,
  }) async => HarnessKitRunResult.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/runs/${Uri.encodeComponent(runId)}/result',
      ),
    ),
  );

  /// Retrieves the current operational snapshot for this Harness runtime.
  Future<HarnessKitOperationalSnapshot> getOperationalSnapshot({
    required String bearerToken,
  }) async => HarnessKitOperationalSnapshot.fromJson(
    _asJsonMap(
      await request<dynamic>(
        bearerToken: bearerToken,
        path: '/v1/ops/snapshot',
      ),
    ),
  );

  /// Calls an API path relative to the Harness API root.
  Future<T> request<T>({
    required String bearerToken,
    required String path,
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final response = await _apiClient.dio.request<dynamic>(
      _toGatewayPath(path),
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: Options(
        method: method,
        headers: <String, String>{'authorization': 'Bearer $bearerToken'},
      ),
    );
    return _decodeJson(response.data) as T;
  }

  /// Opens a streaming Harness endpoint relative to the Harness API root.
  Future<Response<ResponseBody>> requestStream({
    required String bearerToken,
    required String path,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) => _apiClient.dio.get<ResponseBody>(
    _toGatewayPath(path),
    queryParameters: queryParameters,
    cancelToken: cancelToken,
    options: Options(
      responseType: ResponseType.stream,
      receiveTimeout: Duration.zero,
      headers: <String, String>{
        'authorization': 'Bearer $bearerToken',
        'accept': 'text/event-stream',
      },
    ),
  );

  String _toGatewayPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty ||
        RegExp(
          r'^[a-z][a-z\d+.-]*://',
          caseSensitive: false,
        ).hasMatch(trimmed)) {
      throw ArgumentError.value(path, 'path', 'must be a relative API path');
    }
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final harnessPath = normalized == '/harnesskit'
        ? '/'
        : normalized.startsWith('/harnesskit/')
        ? normalized.substring('/harnesskit'.length)
        : normalized;
    final pathOnly = harnessPath.split(RegExp(r'[?#]')).first;
    for (final segment in pathOnly.split('/')) {
      String decoded;
      try {
        decoded = Uri.decodeComponent(segment);
      } on FormatException {
        throw ArgumentError.value(
          path,
          'path',
          'contains invalid URL encoding',
        );
      }
      if (decoded == '.' || decoded == '..') {
        throw ArgumentError.value(path, 'path', 'cannot contain dot segments');
      }
    }
    return '/harnesskit$harnessPath';
  }

  dynamic _decodeJson(dynamic data) {
    if (data is String && data.isNotEmpty) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return data;
      }
    }
    return data;
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    final decoded = _decodeJson(data);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw FormatException(
      'Expected JSON object but got ${decoded.runtimeType}',
    );
  }

  bool _isCommandReceipt(dynamic value) {
    final decoded = _decodeJson(value);
    return decoded is Map &&
        decoded['commandId'] is String &&
        decoded['status'] is String;
  }
}
