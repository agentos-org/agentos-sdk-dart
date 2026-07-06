import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:opentool_daemon/opentool_daemon_client.dart';
import 'package:opentool_dart/opentool_client.dart'
    show FunctionCall, ToolReturn;
import 'package:opentool_dart/opentool_schema.dart';
import '../../utils/api_client.dart';

class ToolKitStreamEvent {
  ToolKitStreamEvent({required this.event, required this.data});

  final String event;
  final Map<String, dynamic> data;
}

class ToolKitServerRef {
  ToolKitServerRef({required this.repo, required this.name, required this.tag});

  final String repo;
  final String name;
  final String tag;

  factory ToolKitServerRef.fromJson(Map<String, dynamic> json) {
    return ToolKitServerRef(
      repo: (json['repo'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      tag: (json['tag'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'repo': repo, 'name': name, 'tag': tag};
  }
}

class ToolKitToolDto extends ToolDto {
  ToolKitToolDto({
    required super.id,
    required super.alias,
    required super.host,
    required super.port,
    required super.status,
    super.serverId,
    this.server,
  });

  final ToolKitServerRef? server;

  factory ToolKitToolDto.fromJson(Map<String, dynamic> json) {
    final server = json['server'];
    return ToolKitToolDto(
      id: (json['id'] ?? '').toString(),
      alias: (json['alias'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      port: (json['port'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      serverId: json['serverId']?.toString(),
      server: server is Map
          ? ToolKitServerRef.fromJson(Map<String, dynamic>.from(server))
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'alias': alias,
      'host': host,
      'port': port,
      'status': status,
      if (serverId != null) 'serverId': serverId,
      if (server != null) 'server': server!.toJson(),
    };
  }
}

class ToolKitClient {
  ToolKitClient({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ToolKitToolDto>> listTool([String? all]) {
    return _listTools(all: all);
  }

  Future<List<ToolKitToolDto>> listTools({String? bearerToken, String? all}) {
    return _listTools(bearerToken: bearerToken, all: all);
  }

  Future<List<ToolKitToolDto>> _listTools({
    String? bearerToken,
    String? all,
  }) async {
    final queryParameters = all != null && all.isNotEmpty
        ? <String, dynamic>{'all': all}
        : null;
    final response = await _apiClient.dio.get<dynamic>(
      '/toolkit/list',
      queryParameters: queryParameters,
      options: _authOptions(bearerToken),
    );
    return _asJsonList(
      response.data,
    ).map((item) => ToolKitToolDto.fromJson(item)).toList();
  }

  Future<OpenTool?> loadTool(String toolId, {String? bearerToken}) async {
    final response = await _apiClient.dio.get<dynamic>(
      '/toolkit/$toolId/load',
      options: _authOptions(bearerToken),
    );
    final decoded = _decodeJson(response.data);
    if (decoded == null) {
      return null;
    }
    return OpenTool.fromJson(_asJsonMap(decoded));
  }

  Future<ToolReturn> callTool({
    required String bearerToken,
    required String toolId,
    required FunctionCall functionCall,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      '/toolkit/$toolId/call',
      data: functionCall.toJson(),
      options: _authOptions(bearerToken),
    );
    return ToolReturn.fromJson(_asJsonMap(_decodeJson(response.data)));
  }

  Future<Stream<ToolKitStreamEvent>> streamCallTool({
    required String bearerToken,
    required String toolId,
    required FunctionCall functionCall,
  }) async {
    final response = await _apiClient.dio.post<ResponseBody>(
      '/toolkit/$toolId/streamCall',
      data: functionCall.toJson(),
      options: _authOptions(bearerToken, responseType: ResponseType.stream),
    );
    final body = response.data;
    if (body == null) {
      return const Stream<ToolKitStreamEvent>.empty();
    }
    return _parseToolCallSse(body.stream.cast<List<int>>());
  }

  @Deprecated('Not exposed by the AgentOS API gateway ToolKit API.')
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

  Options? _authOptions(String? bearerToken, {ResponseType? responseType}) {
    if (bearerToken == null && responseType == null) {
      return null;
    }
    return Options(
      responseType: responseType,
      receiveTimeout: responseType == ResponseType.stream
          ? Duration.zero
          : null,
      headers: <String, dynamic>{
        if (bearerToken != null)
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken',
      },
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

  Stream<ToolKitStreamEvent> _parseToolCallSse(Stream<List<int>> source) {
    final controller = StreamController<ToolKitStreamEvent>();
    String? currentEvent;
    final dataLines = <String>[];

    void flush() {
      if (currentEvent != null && dataLines.isNotEmpty) {
        final data = dataLines.join('\n');
        controller.add(
          ToolKitStreamEvent(
            event: currentEvent!,
            data: _asJsonMap(jsonDecode(data)),
          ),
        );
      }
      currentEvent = null;
      dataLines.clear();
    }

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
              dataLines.add(line.substring(5).trim());
              return;
            }
            if (line.isEmpty) {
              flush();
            }
          },
          onError: controller.addError,
          onDone: () {
            flush();
            controller.close();
          },
        );

    return controller.stream;
  }
}
