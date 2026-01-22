import 'dart:convert';

import 'package:dio/dio.dart';

import '../agentkit/agent_message_handler.dart';
import '../agentkit/agentkit_client.dart';
import '../agentkit/agents_dto.dart';
import '../agentkit/capability_dto.dart';
import '../agentkit/common_dto.dart';
import '../agentkit/messages_dto.dart';
import '../agentkit/sessions_dto.dart';
import 'agentos_event_handler.dart';
import '../../utils/api_client.dart';
import '../appkit/appkit_client.dart';
import '../appkit/dto.dart';
import '../systemkit/dto.dart';
import '../systemkit/systemkit_client.dart';

/// Unified AgentOS SDK that manages Root, AgentKit, and AppKit APIs.
class AgentOSSDK {
  AgentOSSDK({
    ApiClient? apiClient,
    Dio? dio,
    String? baseUrl,
    BaseOptions? baseOptions,
  }) : _apiClient =
            apiClient ??
            ApiClient(dio: dio, baseUrl: baseUrl, baseOptions: baseOptions) {
    _systemKit = SystemKitClient(apiClient: _apiClient);
    _agentKit = AgentKitClient(apiClient: _apiClient);
    _appKit = AppKitClient(apiClient: _apiClient);
    agentos = AgentOSModule._(this);
    agentkit = AgentKitModule._(this);
  }

  final ApiClient _apiClient;
  late final SystemKitClient _systemKit;
  late final AgentKitClient _agentKit;
  late final AppKitClient _appKit;
  String? _token;

  late final AgentOSModule agentos;
  late final AgentKitModule agentkit;

  Map<String, dynamic> _asJsonMap(String data) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw FormatException('Expected JSON object but got ${decoded.runtimeType}');
  }

  String _requireToken() {
    final token = _token;
    if (token == null || token.isEmpty) {
      throw StateError(
        'Bearer token is not set. Call agentos.registerBundle() first.',
      );
    }
    return token;
  }
}

class AgentOSModule {
  AgentOSModule._(this._client);

  final AgentOSSDK _client;

  /// Fetches the AgentOS service version.
  Future<Version> getVersion() => _client._systemKit.getVersion();

  /// Registers an app bundle and stores the returned bearer token internally.
  Future<void> registerBundle({required String bundleId}) async {
    final info = await _client._appKit.registerBundle(bundleId: bundleId);
    _client._token = info.token;
  }

  /// Subscribes to AppKit SSE events using a handler implementation.
  Future<void> subscribe(AgentOSEventHandler handler) async {
    final stream = await _client._appKit.subscribe(
      bearerToken: _client._requireToken(),
    );
    stream.listen(
      (event) async {
        try {
          if (event.agentosEventType == AgentOSEventType.welcome) {
            final payload = _client._asJsonMap(event.data);
            await handler.onWelcome(Welcome.fromJson(payload));
          } else if (event.agentosEventType == AgentOSEventType.call) {
            final payload = _client._asJsonMap(event.data);
            await handler.onCall(Call.fromJson(payload));
          } else {
            throw Exception('Unknown AgentOS event: ${event.agentosEventType}');
          }
        } catch (error) {
          final exception = error is Exception
              ? error
              : Exception(error?.toString() ?? 'Unknown error');
          await handler.onError(exception);
        }
      },
      onDone: () => handler.onDone(),
      onError: (error) {
        final exception = error is Exception
            ? error
            : Exception(error?.toString() ?? 'Unknown error');
        handler.onError(exception);
      },
    );
  }
}

class AgentKitModule {
  AgentKitModule._(this._client);

  final AgentOSSDK _client;

  /// Retrieves an agent by agentId.
  Future<Map<String, dynamic>> getAgent({required String agentId}) {
    return _client._agentKit.getAgent(
      bearerToken: _client._requireToken(),
      agentId: agentId,
    );
  }

  /// Creates an agent with the provided payload.
  Future<Map<String, dynamic>> createAgent({required Agent agent}) {
    return _client._agentKit.createAgent(
      bearerToken: _client._requireToken(),
      agent: agent,
    );
  }

  /// Updates an agent by agentId.
  Future<Map<String, dynamic>> updateAgent({
    required String agentId,
    required Agent agent,
  }) {
    return _client._agentKit.updateAgent(
      bearerToken: _client._requireToken(),
      agentId: agentId,
      agent: agent,
    );
  }

  /// Deletes an agent by agentId.
  Future<Map<String, dynamic>> deleteAgent({required String agentId}) {
    return _client._agentKit.deleteAgent(
      bearerToken: _client._requireToken(),
      agentId: agentId,
    );
  }

  /// Initializes a SessionAgent session via AgentKit.
  Future<Map<String, dynamic>> initSession({
    String? agentId,
    Capability? capability,
  }) {
    return _client._agentKit.initSession(
      bearerToken: _client._requireToken(),
      agentId: agentId,
      capability: capability,
    );
  }

  /// Initializes a SimpleAgent session via AgentKit.
  Future<Map<String, dynamic>> initSimple({
    required SimpleCapability simpleCapability,
  }) {
    return _client._agentKit.initSimple(
      bearerToken: _client._requireToken(),
      simpleCapability: simpleCapability,
    );
  }

  /// Starts a SessionAgent task and streams messages via the handler callbacks.
  Future<void> chat(
    Session session,
    UserTask userTask,
    AgentMessageHandler agentMessageHandler,
  ) async {
    final stream = await _client._agentKit.chat(
      bearerToken: _client._requireToken(),
      sessionId: session.sessionId,
      userTask: userTask,
    );
    stream.listen(
      (event) async {
        if (event.agentEventType == AgentEventType.message) {
          final agentMessage = AgentMessage.fromJson(
            jsonDecode(event.data) as Map<String, dynamic>,
          );
          await agentMessageHandler.onMessage(session.sessionId, agentMessage);
        } else if (event.agentEventType == AgentEventType.chunk) {
          final agentMessageChunk = AgentMessageChunk.fromJson(
            jsonDecode(event.data) as Map<String, dynamic>,
          );
          await agentMessageHandler.onChunk(
            session.sessionId,
            agentMessageChunk,
          );
        } else if (event.agentEventType == AgentEventType.functionCall) {
          final agentMessage = AgentMessage.fromJson(
            jsonDecode(event.data) as Map<String, dynamic>,
          );
          final functionCall = FunctionCall.fromJson(
            agentMessage.content as Map<String, dynamic>,
          );
          final toolReturn = await agentMessageHandler.onFunctionCall(
            session.sessionId,
            functionCall,
          );
          await _callback(session, toolReturn);
        }
      },
      onDone: agentMessageHandler.onDone,
      onError: (error) {
        final exception = error is Exception
            ? error
            : Exception(error?.toString() ?? 'Unknown error');
        agentMessageHandler.onError(exception);
      },
    );
  }

  /// Sends a SimpleAgent request and returns the one-time response.
  Future<Map<String, dynamic>> chatSimple({
    required String sessionId,
    required UserTask userTask,
  }) {
    return _client._agentKit.chatSimple(
      bearerToken: _client._requireToken(),
      sessionId: sessionId,
      userTask: userTask,
    );
  }

  /// Retrieves message history for a session via AgentKit.
  Future<List<dynamic>> history({required String sessionId}) {
    return _client._agentKit.history(
      bearerToken: _client._requireToken(),
      sessionId: sessionId,
    );
  }

  /// Stops a session or task via AgentKit.
  Future<Map<String, dynamic>> stop({
    required String sessionId,
    String? taskId,
  }) {
    return _client._agentKit.stop(
      bearerToken: _client._requireToken(),
      sessionId: sessionId,
      taskId: taskId,
    );
  }

  /// Clears session data via AgentKit.
  Future<Map<String, dynamic>> clear({required String sessionId}) {
    return _client._agentKit.clear(
      bearerToken: _client._requireToken(),
      sessionId: sessionId,
    );
  }

  /// Lists available OpenTools via AgentKit.
  Future<List<dynamic>> openToolList() {
    return _client._agentKit.openToolList(
      bearerToken: _client._requireToken(),
    );
  }

  /// Sends tool callback results via AgentKit.
  Future<Map<String, dynamic>> callback({
    required String sessionId,
    required ToolReturn toolReturn,
  }) {
    return _client._agentKit.callback(
      bearerToken: _client._requireToken(),
      sessionId: sessionId,
      toolReturn: toolReturn,
    );
  }

  /// Sends streaming tool callback results via AgentKit.
  Future<Map<String, dynamic>> streamCallback({
    required String sessionId,
    required EventToolReturn eventToolReturn,
  }) {
    return _client._agentKit.streamCallback(
      bearerToken: _client._requireToken(),
      sessionId: sessionId,
      eventToolReturn: eventToolReturn,
    );
  }

  Future<void> _callback(Session session, ToolReturn toolReturn) async {
    await _client._agentKit.callback(
      bearerToken: _client._requireToken(),
      sessionId: session.sessionId,
      toolReturn: toolReturn,
    );
  }
}
