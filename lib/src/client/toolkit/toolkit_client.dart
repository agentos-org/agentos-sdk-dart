import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:opentool_daemon/opentool_daemon_client.dart';
import 'package:opentool_dart/opentool_schema.dart';
import '../../utils/api_client.dart';

class ToolKitClient {
  ToolKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ToolDto>> listTool([String? all]) async {
    final queryParameters = all != null && all.isNotEmpty
        ? <String, dynamic>{'all': all}
        : null;
    final response = await _apiClient.dio.get<dynamic>(
      '/toolkit/list',
      queryParameters: queryParameters,
    );
    return _asJsonList(
      response.data,
    ).map((item) => ToolDto.fromJson(item)).toList();
  }

  Future<OpenTool?> loadTool(String toolId) async {
    final response = await _apiClient.dio.get<dynamic>('/toolkit/$toolId/load');
    final decoded = _decodeJson(response.data);
    if (decoded == null) {
      return null;
    }
    return OpenTool.fromJson(_asJsonMap(decoded));
  }

  Future<Stream<ToolLifecycleEventDto>> subscribeToolEvents({
    required String daemonApiKey,
    bool snapshot = true,
  }) async {
    final response = await _apiClient.dio.get<ResponseBody>(
      '/toolkit/events',
      queryParameters: <String, dynamic>{'snapshot': snapshot ? '1' : '0'},
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: <String, dynamic>{TOOL_API_KEY_HEADER: daemonApiKey},
      ),
    );
    final body = response.data;
    if (body == null) {
      return const Stream<ToolLifecycleEventDto>.empty();
    }
    return _parseSse(body.stream.cast<List<int>>());
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

  List<Map<String, dynamic>> _asJsonList(dynamic data) {
    final decoded = _decodeJson(data);
    if (decoded is List) {
      return decoded
          .map(
            (item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map),
          )
          .toList();
    }
    throw FormatException('Expected JSON array but got ${decoded.runtimeType}');
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw FormatException('Expected JSON object but got ${data.runtimeType}');
  }

  Stream<ToolLifecycleEventDto> _parseSse(Stream<List<int>> source) {
    final controller = StreamController<ToolLifecycleEventDto>();
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
                if (currentEvent == 'ready') {
                  currentEvent = null;
                  currentData = null;
                  return;
                }
                controller.add(
                  ToolLifecycleEventDto.fromJson(
                    _asJsonMap(jsonDecode(currentData!)),
                  ),
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
