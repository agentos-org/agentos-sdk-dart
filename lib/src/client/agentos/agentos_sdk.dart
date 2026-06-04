import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:opentool_daemon/opentool_daemon_client.dart';
import 'package:opentool_dart/opentool_schema.dart';

import '../agentkit/agent_message_handler.dart';
import '../agentkit/agentkit_client.dart';
import '../agentkit/agents_dto.dart';
import '../agentkit/capability_dto.dart';
import '../agentkit/common_dto.dart';
import '../agentkit/messages_dto.dart';
import '../agentkit/sessions_dto.dart';
import 'agentos_connection_event.dart';
import 'agentos_event_handler.dart';
import '../../utils/api_client.dart';
import '../appkit/appkit_client.dart';
import '../appkit/dto.dart';
import '../cronkit/cronkit_client.dart';
import '../cronkit/dto.dart';
import '../ragkit/dto.dart';
import '../ragkit/ragkit_client.dart';
import '../systemkit/dto.dart';
import '../systemkit/systemkit_client.dart';
import '../modelkit/modelkit_client.dart';
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
       );

  final ApiClient _apiClient;
  late final SystemKitClient _systemKit = SystemKitClient(
    apiClient: _apiClient,
  );
  late final AgentKitClient _agentKit = AgentKitClient(apiClient: _apiClient);
  late final AppKitClient _appKit = AppKitClient(apiClient: _apiClient);
  late final CronKitClient _cronKit = CronKitClient(apiClient: _apiClient);
  late final RagKitClient _ragKit = RagKitClient(apiClient: _apiClient);
  late final ModelKitClient _modelKit = ModelKitClient(apiClient: _apiClient);
  late final ToolKitClient _toolKit = ToolKitClient(apiClient: _apiClient);
  final Map<_AppAuthCacheKey, String> _appTokens = <_AppAuthCacheKey, String>{};
  final Map<String, _AppAuthCacheKey> _tokenContexts =
      <String, _AppAuthCacheKey>{};
  final Map<_AppAuthCacheKey, Future<String>> _refreshingTokens =
      <_AppAuthCacheKey, Future<String>>{};
  final StreamController<AgentOSSubscribeConnectionEvent>
  _agentOsConnectionEvents =
      StreamController<AgentOSSubscribeConnectionEvent>.broadcast();
  _AppAuthCacheKey? _activeAppAuthKey;
  StreamSubscription<AgentOSEvent>? _agentOsSubscription;
  Future<void>? _agentOsReconnectTask;
  AgentOSEventHandler? _agentOsEventHandler;
  AgentOSSubscribeOptions _agentOsSubscribeOptions =
      const AgentOSSubscribeOptions();
  AgentOSSubscribeConnectionStatus? _agentOsConnectionStatus;
  bool _shouldMaintainAgentOsSubscription = false;
  bool _isDisposed = false;

  late final AgentOSModule agentos = AgentOSModule._(this);
  late final AgentKitModule agentkit = AgentKitModule._(this);
  late final CronKitModule cronkit = CronKitModule._(this);
  late final RagKitModule ragkit = RagKitModule._(this);
  late final ModelKitModule modelkit = ModelKitModule._(this);
  late final ToolKitModule toolkit = ToolKitModule._(this);

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
          baseUrl: 'http://localhost:8888',
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

  Future<_AppAuthContext> _requireAppAuthContext() async {
    final key = _activeAppAuthKey;
    if (key == null) {
      throw StateError(
        'Bearer token is not set. Call agentos.registerBundle() first.',
      );
    }
    var token = _appTokens[key];
    if ((token == null || token.isEmpty) && _refreshingTokens[key] != null) {
      token = await _refreshingTokens[key];
    }
    if (token == null || token.isEmpty) {
      throw StateError(
        'Bearer token is not set. Call agentos.registerBundle() first.',
      );
    }
    return _AppAuthContext(key: key, token: token);
  }

  void _cacheAppToken(
    _AppAuthCacheKey key,
    String token, {
    required bool activate,
  }) {
    final previousToken = _appTokens[key];
    if (previousToken != null && previousToken != token) {
      _tokenContexts.remove(previousToken);
    }
    _appTokens[key] = token;
    _tokenContexts[token] = key;
    if (activate) {
      _activeAppAuthKey = key;
    }
  }

  void _clearAppToken(_AppAuthCacheKey key, {String? expectedToken}) {
    final currentToken = _appTokens[key];
    if (expectedToken != null &&
        currentToken != null &&
        currentToken != expectedToken) {
      _tokenContexts.remove(expectedToken);
      return;
    }
    final removedToken = _appTokens.remove(key);
    if (removedToken != null) {
      _tokenContexts.remove(removedToken);
    }
    if (expectedToken != null) {
      _tokenContexts.remove(expectedToken);
    }
  }

  _AppAuthCacheKey? _contextForToken(String token) {
    return _tokenContexts[token];
  }

  Future<String> _refreshAppToken(
    _AppAuthContext context, {
    required String failedToken,
  }) {
    final key = _contextForToken(failedToken) ?? context.key;
    final currentToken = _appTokens[key];
    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != failedToken) {
      return Future<String>.value(currentToken);
    }

    final inflight = _refreshingTokens[key];
    if (inflight != null) {
      return inflight;
    }

    _clearAppToken(key, expectedToken: failedToken);
    final refresh = () async {
      final info = await _appKit.registerBundle(
        bundleId: key.bundleId,
        appGroupId: key.appGroupId,
      );
      _cacheAppToken(key, info.token, activate: false);
      return info.token;
    }();
    _refreshingTokens[key] = refresh;
    return refresh.whenComplete(() {
      _refreshingTokens.remove(key);
    });
  }

  bool _shouldRecoverAppAuth(Object error) {
    if (error is! DioException) {
      return false;
    }
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }
    final errorText = _collectErrorText(error).toLowerCase();
    if (errorText.isEmpty) {
      return false;
    }
    return errorText.contains('invalid app token') ||
        errorText.contains('token expired') ||
        errorText.contains('unauthorized') ||
        errorText.contains('forbidden') ||
        errorText.contains('auth');
  }

  String _collectErrorText(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is DioException) {
      return <String>[
        if (value.message != null) value.message!,
        _collectErrorText(value.error),
        _collectErrorText(value.response?.data),
      ].where((text) => text.isNotEmpty).join(' ');
    }
    if (value is Map) {
      return value.values
          .map(_collectErrorText)
          .where((text) => text.isNotEmpty)
          .join(' ');
    }
    if (value is Iterable) {
      return value
          .map(_collectErrorText)
          .where((text) => text.isNotEmpty)
          .join(' ');
    }
    return value.toString();
  }

  Future<T> _withAppAuthRetry<T>(
    Future<T> Function(String bearerToken) action,
  ) async {
    final requestContext = await _requireAppAuthContext();
    try {
      return await action(requestContext.token);
    } catch (error) {
      if (!_shouldRecoverAppAuth(error)) {
        rethrow;
      }
      final refreshedToken = await _refreshAppToken(
        requestContext,
        failedToken: requestContext.token,
      );
      return action(refreshedToken);
    }
  }

  bool get isSubscribed => _agentOsSubscription != null;

  Stream<AgentOSSubscribeConnectionEvent> get agentOsConnectionEvents =>
      _agentOsConnectionEvents.stream;

  AgentOSSubscribeConnectionStatus? get agentOsConnectionStatus =>
      _agentOsConnectionStatus;

  void _emitAgentOsConnectionEvent(
    AgentOSSubscribeConnectionStatus status, {
    int attempt = 0,
    Exception? error,
  }) {
    _agentOsConnectionStatus = status;
    if (_agentOsConnectionEvents.isClosed) {
      return;
    }
    _agentOsConnectionEvents.add(
      AgentOSSubscribeConnectionEvent(
        status: status,
        attempt: attempt,
        error: error,
      ),
    );
  }

  Exception _asException(Object error) {
    if (error is Exception) {
      return error;
    }
    return Exception(error.toString());
  }

  Future<void> _cancelAgentOsSubscription() async {
    final subscription = _agentOsSubscription;
    _agentOsSubscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _shouldMaintainAgentOsSubscription = false;
    await _cancelAgentOsSubscription();
    _agentOsEventHandler = null;
    await _agentOsReconnectTask;
    await _agentOsConnectionEvents.close();
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
  Future<AccessToken> registerBundle({
    required String bundleId,
    String? appGroupId,
  }) async {
    final key = _AppAuthCacheKey(bundleId: bundleId, appGroupId: appGroupId);
    final info = await _client._appKit.registerBundle(
      bundleId: bundleId,
      appGroupId: appGroupId,
    );
    _client._cacheAppToken(key, info.token, activate: true);
    return info;
  }

  /// Subscribes to AppKit SSE events using a handler implementation.
  Stream<AgentOSSubscribeConnectionEvent> get connectionEvents =>
      _client.agentOsConnectionEvents;

  AgentOSSubscribeConnectionStatus? get connectionStatus =>
      _client.agentOsConnectionStatus;

  Future<void> subscribe(
    AgentOSEventHandler handler, {
    AgentOSSubscribeOptions options = const AgentOSSubscribeOptions(),
  }) async {
    _client._agentOsEventHandler = handler;
    _client._agentOsSubscribeOptions = options;
    _client._shouldMaintainAgentOsSubscription = true;
    _client._isDisposed = false;
    if (_client._agentOsSubscription != null ||
        _client._agentOsReconnectTask != null) {
      return;
    }
    try {
      await _openSubscription(isReconnect: false);
    } catch (error) {
      _client._emitAgentOsConnectionEvent(
        AgentOSSubscribeConnectionStatus.disconnected,
        error: _client._asException(error),
      );
      rethrow;
    }
  }

  Future<void> _openSubscription({required bool isReconnect}) async {
    final stream = await _client._withAppAuthRetry(
      (bearerToken) => _client._appKit.subscribe(bearerToken: bearerToken),
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
        await _handleSubscriptionClosed();
      },
      onError: (Object error) async {
        await _handleSubscriptionClosed(error: error);
      },
      cancelOnError: false,
    );
    if (isReconnect) {
      _client._emitAgentOsConnectionEvent(
        AgentOSSubscribeConnectionStatus.reconnected,
      );
    }
    _client._emitAgentOsConnectionEvent(
      AgentOSSubscribeConnectionStatus.connected,
    );
  }

  Future<void> _handleSubscriptionClosed({Object? error}) async {
    _client._agentOsSubscription = null;
    final currentHandler = _client._agentOsEventHandler;
    if (currentHandler != null) {
      if (error == null) {
        await currentHandler.onDone();
      } else {
        await currentHandler.onError(_client._asException(error));
      }
    }
    if (!_client._shouldMaintainAgentOsSubscription || _client._isDisposed) {
      return;
    }
    if (!_client._agentOsSubscribeOptions.autoReconnect) {
      _client._emitAgentOsConnectionEvent(
        AgentOSSubscribeConnectionStatus.disconnected,
        error: error == null ? null : _client._asException(error),
      );
      return;
    }
    _startReconnectLoop(initialError: error);
  }

  void _startReconnectLoop({Object? initialError}) {
    if (_client._agentOsReconnectTask != null) {
      return;
    }
    final options = _client._agentOsSubscribeOptions;
    final initialException = initialError == null
        ? null
        : _client._asException(initialError);
    _client._emitAgentOsConnectionEvent(
      AgentOSSubscribeConnectionStatus.reconnecting,
      attempt: 1,
      error: initialException,
    );
    _client._agentOsReconnectTask =
        () async {
          Exception? lastError = initialException;
          for (
            var attempt = 1;
            attempt <= options.maxReconnectAttempts;
            attempt++
          ) {
            if (!_client._shouldMaintainAgentOsSubscription ||
                _client._isDisposed) {
              break;
            }
            if (attempt > 1) {
              await Future<void>.delayed(options.reconnectDelay);
            }
            try {
              await _openSubscription(isReconnect: true);
              return;
            } catch (error) {
              lastError = _client._asException(error);
            }
          }
          if (_client._shouldMaintainAgentOsSubscription &&
              !_client._isDisposed) {
            _client._emitAgentOsConnectionEvent(
              AgentOSSubscribeConnectionStatus.disconnected,
              attempt: options.maxReconnectAttempts,
              error: lastError,
            );
          }
        }().whenComplete(() {
          _client._agentOsReconnectTask = null;
        });
  }
}

class CronKitModule {
  CronKitModule._(this._client);

  final AgentOSSDK _client;

  Future<CronTask> getTask({required String cronId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._cronKit.getTask(bearerToken: bearerToken, cronId: cronId),
    );
  }

  Future<List<CronTaskListItem>> listTasks({
    bool? enabled,
    int? offset,
    int? limit,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._cronKit.listTasks(
        bearerToken: bearerToken,
        enabled: enabled,
        offset: offset,
        limit: limit,
      ),
    );
  }

  Future<CronTask> createTask({required CronTaskCreateRequest request}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._cronKit.createTask(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<CronTask> updateTask({required CronTaskUpdateRequest request}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._cronKit.updateTask(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<CronTaskDeleteResult> deleteTask({required String cronId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._cronKit.deleteTask(bearerToken: bearerToken, cronId: cronId),
    );
  }

  Future<CronTask> enableTask({required String cronId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._cronKit.enableTask(bearerToken: bearerToken, cronId: cronId),
    );
  }

  Future<CronTask> disableTask({required String cronId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._cronKit.disableTask(
        bearerToken: bearerToken,
        cronId: cronId,
      ),
    );
  }

  Future<CronRun> runTaskNow({required String cronId, DateTime? scheduledAt}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._cronKit.runTaskNow(
        bearerToken: bearerToken,
        cronId: cronId,
        scheduledAt: scheduledAt,
      ),
    );
  }

  Future<CronRun> getRun({required String runId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._cronKit.getRun(bearerToken: bearerToken, runId: runId),
    );
  }

  Future<List<CronRunListItem>> listRuns({
    String? cronId,
    DateTime? after,
    DateTime? before,
    int? offset,
    int? limit,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._cronKit.listRuns(
        bearerToken: bearerToken,
        cronId: cronId,
        after: after,
        before: before,
        offset: offset,
        limit: limit,
      ),
    );
  }

  Future<List<CronRunMessage>> listRunMessages({
    required String runId,
    int? offset,
    int? limit,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._cronKit.listRunMessages(
        bearerToken: bearerToken,
        runId: runId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  Future<CronDeleteRunResult> deleteRun({required String runId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._cronKit.deleteRun(bearerToken: bearerToken, runId: runId),
    );
  }
}

class RagKitModule {
  RagKitModule._(this._client);

  final AgentOSSDK _client;

  Future<RagBase> getBase({required String baseId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._ragKit.getBase(bearerToken: bearerToken, baseId: baseId),
    );
  }

  Future<List<RagBaseListItem>> listBases({int? offset, int? limit}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.listBases(
        bearerToken: bearerToken,
        offset: offset,
        limit: limit,
      ),
    );
  }

  Future<RagBase> createBase({required RagBaseCreateRequest request}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.createBase(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<RagBase> updateBase({required RagBaseUpdateRequest request}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.updateBase(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<RagDeleteBaseResult> deleteBase({required String baseId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._ragKit.deleteBase(bearerToken: bearerToken, baseId: baseId),
    );
  }

  Future<RagDocument> getDocument({
    required String baseId,
    required String documentId,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.getDocument(
        bearerToken: bearerToken,
        baseId: baseId,
        documentId: documentId,
      ),
    );
  }

  Future<List<RagDocumentListItem>> listDocuments({
    required String baseId,
    int? offset,
    int? limit,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.listDocuments(
        bearerToken: bearerToken,
        baseId: baseId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  Future<RagDocument> upsertDocument({
    required RagUpsertDocumentRequest request,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.upsertDocument(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<RagBatchResult> upsertDocuments({
    required RagUpsertDocumentsRequest request,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.upsertDocuments(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<RagDeleteDocumentResult> deleteDocument({
    required String baseId,
    required String documentId,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.deleteDocument(
        bearerToken: bearerToken,
        baseId: baseId,
        documentId: documentId,
      ),
    );
  }

  Future<RagDocumentSyncResult> syncDocument({
    required String baseId,
    required String documentId,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._ragKit.syncDocument(
        bearerToken: bearerToken,
        baseId: baseId,
        documentId: documentId,
      ),
    );
  }

  Future<RagBatchResult> syncBase({required String baseId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._ragKit.syncBase(bearerToken: bearerToken, baseId: baseId),
    );
  }

  Future<RagBatchResult> retryFailed({String? baseId}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._ragKit.retryFailed(bearerToken: bearerToken, baseId: baseId),
    );
  }

  Future<RagQueryResult> query({required RagQueryRequest request}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._ragKit.query(bearerToken: bearerToken, request: request),
    );
  }
}

class AgentKitModule {
  AgentKitModule._(this._client);

  final AgentOSSDK _client;

  /// Retrieves an agent by agentId.
  Future<Map<String, dynamic>> getAgent({required String agentId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.getAgent(
        bearerToken: bearerToken,
        agentId: agentId,
      ),
    );
  }

  /// Creates an agent with the provided payload.
  Future<Map<String, dynamic>> createAgent({required Agent agent}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._agentKit.createAgent(bearerToken: bearerToken, agent: agent),
    );
  }

  /// Updates an agent by agentId.
  Future<Map<String, dynamic>> updateAgent({
    required String agentId,
    required Agent agent,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.updateAgent(
        bearerToken: bearerToken,
        agentId: agentId,
        agent: agent,
      ),
    );
  }

  /// Deletes an agent by agentId.
  Future<Map<String, dynamic>> deleteAgent({required String agentId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.deleteAgent(
        bearerToken: bearerToken,
        agentId: agentId,
      ),
    );
  }

  /// Initializes a SessionAgent session via AgentKit.
  Future<Map<String, dynamic>> initSession({
    String? agentId,
    Capability? capability,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.initSession(
        bearerToken: bearerToken,
        agentId: agentId,
        capability: capability,
      ),
    );
  }

  /// Initializes a SimpleAgent session via AgentKit.
  Future<Map<String, dynamic>> initSimple({
    required SimpleCapability simpleCapability,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.initSimple(
        bearerToken: bearerToken,
        simpleCapability: simpleCapability,
      ),
    );
  }

  /// Starts a SessionAgent task and streams messages via the handler callbacks.
  Future<void> chat(
    Session session,
    UserTask userTask,
    AgentMessageHandler agentMessageHandler,
  ) async {
    final stream = await _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.chat(
        bearerToken: bearerToken,
        sessionId: session.sessionId,
        userTask: userTask,
      ),
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
          await _handleFunctionCallEvent(
            session,
            event.data,
            agentMessageHandler,
          );
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
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.chatSimple(
        bearerToken: bearerToken,
        sessionId: sessionId,
        userTask: userTask,
      ),
    );
  }

  /// Retrieves message history for a session via AgentKit.
  Future<List<dynamic>> history({required String sessionId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.history(
        bearerToken: bearerToken,
        sessionId: sessionId,
      ),
    );
  }

  /// Stops a session or task via AgentKit.
  Future<Map<String, dynamic>> stop({
    required String sessionId,
    String? taskId,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.stop(
        bearerToken: bearerToken,
        sessionId: sessionId,
        taskId: taskId,
      ),
    );
  }

  /// Clears session data via AgentKit.
  Future<Map<String, dynamic>> clear({required String sessionId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.clear(
        bearerToken: bearerToken,
        sessionId: sessionId,
      ),
    );
  }

  /// Sends tool callback results via AgentKit.
  Future<Map<String, dynamic>> callback({
    required String sessionId,
    required ToolReturn toolReturn,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.callback(
        bearerToken: bearerToken,
        sessionId: sessionId,
        toolReturn: toolReturn,
      ),
    );
  }

  /// Sends streaming tool callback results via AgentKit.
  Future<Map<String, dynamic>> streamCallback({
    required String sessionId,
    required EventToolReturn eventToolReturn,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.streamCallback(
        bearerToken: bearerToken,
        sessionId: sessionId,
        eventToolReturn: eventToolReturn,
      ),
    );
  }

  Future<void> _callback(Session session, ToolReturn toolReturn) async {
    await callback(sessionId: session.sessionId, toolReturn: toolReturn);
  }

  Future<void> _streamCallback(
    Session session,
    EventToolReturn eventToolReturn,
  ) async {
    await streamCallback(
      sessionId: session.sessionId,
      eventToolReturn: eventToolReturn,
    );
  }

  Future<void> _handleFunctionCallEvent(
    Session session,
    String eventData,
    AgentMessageHandler agentMessageHandler,
  ) async {
    final payload = _client._asJsonMap(eventData);
    final functionCallJson = payload['functionCall'];
    if (functionCallJson is! Map) {
      throw FormatException(
        'Invalid functionCall event payload: missing functionCall object.',
      );
    }

    final functionCallMap = Map<String, dynamic>.from(functionCallJson);
    final functionCall = FunctionCall.fromJson(functionCallMap);
    final payloadSessionId = payload['sessionId']?.toString();
    final effectiveSessionId =
        payloadSessionId != null && payloadSessionId.isNotEmpty
        ? payloadSessionId
        : session.sessionId;
    final callbackSession = Session(sessionId: effectiveSessionId);

    if (_isStreamFunctionCall(payload, functionCallMap)) {
      final pendingCallbacks = <Future<void>>[];
      await agentMessageHandler.onStreamFunctionCall(
        effectiveSessionId,
        functionCall,
        (eventToolReturn) {
          pendingCallbacks.add(
            _streamCallback(callbackSession, eventToolReturn),
          );
        },
      );
      for (final pending in pendingCallbacks) {
        await pending;
      }
      return;
    }

    final toolReturn = await agentMessageHandler.onFunctionCall(
      effectiveSessionId,
      functionCall,
    );
    await _callback(callbackSession, toolReturn);
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

/// Entry point for the task-oriented ModelKit API (chat / embedding / asr / tts).
class ModelKitModule {
  ModelKitModule._(this._client);

  final AgentOSSDK _client;

  ModelKitChatClient get chat => _client._modelKit.chat;
  ModelKitEmbeddingClient get embedding => _client._modelKit.embedding;
  ModelKitAsrClient get asr => _client._modelKit.asr;
  ModelKitTtsClient get tts => _client._modelKit.tts;

  Future<List<ModelInfo>> listModels() {
    return _client._modelKit.listModels();
  }

  Future<List<ModelInfo>> listModelsByTask(ModelTask task) {
    return _client._modelKit.listModelsByTask(task);
  }
}

class ToolKitModule {
  ToolKitModule._(this._client);

  final AgentOSSDK _client;

  Future<List<ToolDto>> listTool([String? all]) {
    return _client._toolKit.listTool(all);
  }

  Future<OpenTool?> loadTool(String toolId) {
    return _client._toolKit.loadTool(toolId);
  }

  Future<Stream<ToolLifecycleEventDto>> subscribeToolEvents({
    required String daemonApiKey,
    bool snapshot = true,
  }) {
    return _client._toolKit.subscribeToolEvents(
      daemonApiKey: daemonApiKey,
      snapshot: snapshot,
    );
  }
}

class _AppAuthContext {
  const _AppAuthContext({required this.key, required this.token});

  final _AppAuthCacheKey key;
  final String token;
}

class _AppAuthCacheKey {
  const _AppAuthCacheKey({required this.bundleId, required this.appGroupId});

  final String bundleId;
  final String? appGroupId;

  @override
  bool operator ==(Object other) {
    return other is _AppAuthCacheKey &&
        other.bundleId == bundleId &&
        other.appGroupId == appGroupId;
  }

  @override
  int get hashCode => Object.hash(bundleId, appGroupId);
}
