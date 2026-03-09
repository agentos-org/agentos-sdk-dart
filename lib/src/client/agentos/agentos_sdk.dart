import 'dart:async';
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
import '../intentkit/dto.dart';
import '../intentkit/intentkit_client.dart';
import '../llmkit/llmkit_client.dart';
import '../toolkit/toolkit_client.dart';

/// Unified AgentOS SDK that manages Root, AgentKit, and AppKit APIs.
class AgentOSSDK {
  AgentOSSDK({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    ApiClient? apiClient,
  }) : _apiClient = _buildApiClient(
         baseUrl: baseUrl,
         connectTimeout: connectTimeout,
         receiveTimeout: receiveTimeout,
         apiClient: apiClient,
       ) {
    _systemKit = SystemKitClient(apiClient: _apiClient);
    _agentKit = AgentKitClient(apiClient: _apiClient);
    _appKit = AppKitClient(apiClient: _apiClient);
    _intentKit = IntentKitClient(apiClient: _apiClient);
    _llmKit = LlmKitClient(apiClient: _apiClient);
    _toolKit = ToolKitClient(apiClient: _apiClient);
    agentos = AgentOSModule._(this);
    agentkit = AgentKitModule._(this);
    intentkit = IntentKitModule._(this);
    llmkit = LlmKitModule._(this);
    toolkit = ToolKitModule._(this);
  }

  final ApiClient _apiClient;
  late final SystemKitClient _systemKit;
  late final AgentKitClient _agentKit;
  late final AppKitClient _appKit;
  late final IntentKitClient _intentKit;
  late final LlmKitClient _llmKit;
  late final ToolKitClient _toolKit;
  String? _token;
  StreamSubscription<AgentOSEvent>? _agentOsSubscription;
  AgentOSEventHandler? _agentOsEventHandler;

  late final AgentOSModule agentos;
  late final AgentKitModule agentkit;
  late final IntentKitModule intentkit;
  late final LlmKitModule llmkit;
  late final ToolKitModule toolkit;

  static ApiClient _buildApiClient({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    ApiClient? apiClient,
  }) {
    if (apiClient != null) {
      if (connectTimeout != null) {
        apiClient.dio.options.connectTimeout = connectTimeout;
      }
      if (receiveTimeout != null) {
        apiClient.dio.options.receiveTimeout = receiveTimeout;
      }
      if (baseUrl != null && baseUrl.isNotEmpty) {
        apiClient.dio.options.baseUrl = baseUrl;
      }
      return apiClient;
    }
    final effectiveConnectTimeout =
        connectTimeout ?? const Duration(seconds: 5);
    final effectiveReceiveTimeout =
        receiveTimeout ?? const Duration(seconds: 10);
    if (baseUrl != null && baseUrl.isNotEmpty) {
      return ApiClient(
        baseOptions: BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: effectiveConnectTimeout,
          receiveTimeout: effectiveReceiveTimeout,
        ),
      );
    }
    if (connectTimeout != null || receiveTimeout != null) {
      return ApiClient(
        baseOptions: BaseOptions(
          baseUrl: 'http://localhost:20261',
          connectTimeout: effectiveConnectTimeout,
          receiveTimeout: effectiveReceiveTimeout,
        ),
      );
    }
    return ApiClient();
  }

  Map<String, dynamic> _asJsonMap(String data) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw FormatException(
      'Expected JSON object but got ${decoded.runtimeType}',
    );
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

  bool get isSubscribed => _agentOsSubscription != null;

  Future<void> _cancelAgentOsSubscription() async {
    final subscription = _agentOsSubscription;
    _agentOsSubscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }
  }

  Future<void> dispose() async {
    await _cancelAgentOsSubscription();
    _agentOsEventHandler = null;
  }
}

class AgentOSModule {
  AgentOSModule._(this._client);

  final AgentOSSDK _client;

  /// Fetches the AgentOS service version.
  Future<Version> getVersion() => _client._systemKit.getVersion();

  /// Fetches the AgentOS gateway metadata.
  Future<RootInfo> getRoot() => _client._systemKit.getRoot();

  /// Fetches the AgentOS readiness status.
  Future<Readiness> getReady() => _client._systemKit.getReady();

  /// Registers an app bundle and stores the returned bearer token internally.
  Future<void> registerBundle({required String bundleId}) async {
    final info = await _client._appKit.registerBundle(bundleId: bundleId);
    _client._token = info.token;
  }

  /// Subscribes to AppKit SSE events using a handler implementation.
  Future<void> subscribe(AgentOSEventHandler handler) async {
    _client._agentOsEventHandler = handler;
    if (_client._agentOsSubscription != null) {
      return;
    }
    final stream = await _client._appKit.subscribe(
      bearerToken: _client._requireToken(),
    );
    _client._agentOsSubscription = stream.listen(
      (event) async {
        final currentHandler = _client._agentOsEventHandler;
        if (currentHandler == null) {
          return;
        }
        try {
          if (event.agentosEventType == AgentOSEventType.welcome) {
            final payload = _client._asJsonMap(event.data);
            await currentHandler.onWelcome(Welcome.fromJson(payload));
          } else if (event.agentosEventType == AgentOSEventType.error) {
            final payload = _client._asJsonMap(event.data);
            final error = AppKitError.fromJson(payload);
            await currentHandler.onError(Exception(error.error));
          } else if (event.agentosEventType == AgentOSEventType.callApp) {
            final payload = _client._asJsonMap(event.data);
            await currentHandler.onCallApp(Call.fromJson(payload));
          } else {
            throw Exception('Unknown AgentOS event: ${event.agentosEventType}');
          }
        } catch (error) {
          final exception = error is Exception
              ? error
              : Exception(error.toString());
          await currentHandler.onError(exception);
        }
      },
      onDone: () async {
        _client._agentOsSubscription = null;
        final currentHandler = _client._agentOsEventHandler;
        if (currentHandler != null) {
          await currentHandler.onDone();
        }
      },
      onError: (error) {
        _client._agentOsSubscription = null;
        final currentHandler = _client._agentOsEventHandler;
        if (currentHandler == null) {
          return;
        }
        final exception = error is Exception
            ? error
            : Exception(error.toString());
        currentHandler.onError(exception);
      },
    );
  }
}

class AgentKitModule {
  AgentKitModule._(this._client);

  final AgentOSSDK _client;

  /// Fetches the AgentKit service version.
  Future<Version> getVersion() {
    return _client._agentKit.getVersion(bearerToken: _client._requireToken());
  }

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
          final payload = _client._asJsonMap(event.data);
          final functionCallJson = payload['functionCall'];
          if (functionCallJson is! Map) {
            throw FormatException(
              'Invalid functionCall event payload: missing functionCall object.',
            );
          }
          final functionCallMap = Map<String, dynamic>.from(functionCallJson);
          final functionCall = FunctionCall.fromJson(functionCallMap);
          if (_isStreamFunctionCall(payload, functionCallMap)) {
            final pendingCallbacks = <Future<void>>[];
            await agentMessageHandler.onStreamFunctionCall(
              session.sessionId,
              functionCall,
              (eventToolReturn) {
                pendingCallbacks.add(_streamCallback(session, eventToolReturn));
              },
            );
            for (final pending in pendingCallbacks) {
              await pending;
            }
          } else {
            final toolReturn = await agentMessageHandler.onFunctionCall(
              session.sessionId,
              functionCall,
            );
            await _callback(session, toolReturn);
          }
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

  Future<void> _streamCallback(
    Session session,
    EventToolReturn eventToolReturn,
  ) async {
    await _client._agentKit.streamCallback(
      bearerToken: _client._requireToken(),
      sessionId: session.sessionId,
      eventToolReturn: eventToolReturn,
    );
  }

  bool _isStreamFunctionCall(
    Map<String, dynamic> payload,
    Map<String, dynamic> functionCall,
  ) {
    return _readBoolFlag(payload, 'stream') ||
        _readBoolFlag(functionCall, 'stream') ||
        _readBoolFlag(payload, 'isStream') ||
        _readBoolFlag(functionCall, 'isStream');
  }

  bool _readBoolFlag(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is bool && value;
  }
}

class IntentKitModule {
  IntentKitModule._(this._client);

  final AgentOSSDK _client;

  Future<IntentKitJobHandle> submitRaw(IntentKitSubmitRawRequest request) {
    return _client._intentKit.submitRaw(
      bearerToken: _client._requireToken(),
      request: request,
    );
  }

  Future<IntentKitJobHandle> submitIntent(
    IntentKitSubmitIntentRequest request,
  ) {
    return _client._intentKit.submitIntent(
      bearerToken: _client._requireToken(),
      request: request,
    );
  }

  Future<IntentKitJobHandle> confirmJob(IntentKitConfirmJobRequest request) {
    return _client._intentKit.confirmJob(
      bearerToken: _client._requireToken(),
      request: request,
    );
  }

  Future<IntentKitSuggestNextActionResponse> suggestNextAction(
    IntentKitSuggestNextActionRequest request,
  ) {
    return _client._intentKit.suggestNextAction(
      bearerToken: _client._requireToken(),
      request: request,
    );
  }
}

class LlmKitModule {
  LlmKitModule._(this._client);

  final AgentOSSDK _client;

  LlmKitChatClient get chat => _client._llmKit.chat;

  Future<List<LlmModelInfo>> listModels() {
    return _client._llmKit.listModels();
  }
}

class ToolKitModule {
  ToolKitModule._(this._client);

  final AgentOSSDK _client;

  Future<Response<dynamic>> request(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Options? options,
  }) {
    return _client._toolKit.request(
      path,
      method: method,
      queryParameters: queryParameters,
      data: data,
      options: options,
    );
  }
}
