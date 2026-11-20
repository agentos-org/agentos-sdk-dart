import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:opentool_daemon/opentool_daemon_client.dart';
import 'package:opentool_dart/opentool_schema.dart';

import '../agentkit/agent_message_handler.dart';
import '../agentkit/agentkit_client.dart';
import '../agentkit/capability_dto.dart';
import '../agentkit/common_dto.dart';
import '../agentkit/messages_dto.dart';
import '../agentkit/sessions_dto.dart';
import 'agentos_connection_event.dart';
import 'agentos_event_handler.dart';
import '../../utils/api_client.dart';
import '../authkit/authkit_client.dart';
import '../authkit/dto.dart';
import '../harnesskit/dto.dart';
import '../harnesskit/harnesskit_client.dart';
import '../appkit/appkit_client.dart';
import '../appkit/dto.dart';
import '../cronkit/cronkit_client.dart';
import '../cronkit/dto.dart';
import '../discoverykit/discoverykit_client.dart';
import '../discoverykit/dto.dart';
import '../ragkit/dto.dart';
import '../ragkit/ragkit_client.dart';
import '../systemkit/dto.dart';
import '../systemkit/systemkit_client.dart';
import '../modelkit/modelkit_client.dart';
import '../toolkit/toolkit_client.dart';
import '../transferkit/transferkit_client.dart';
import '../transferkit/dto.dart';

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
  late final AuthKitClient _authKitClient = AuthKitClient(
    apiClient: _apiClient,
  );
  late final DiscoveryKitClient _discoveryKit = DiscoveryKitClient(
    apiClient: _apiClient,
  );
  late final TransferKitClient _transferKit = TransferKitClient(
    apiClient: _apiClient,
  );
  late final HarnessKitClient _harnessKit = HarnessKitClient(
    apiClient: _apiClient,
  );
  final Map<_AppAuthCacheKey, String> _appTokens = <_AppAuthCacheKey, String>{};
  final Map<String, _AppAuthCacheKey> _tokenContexts =
      <String, _AppAuthCacheKey>{};
  final Map<_AppAuthCacheKey, Future<String>> _refreshingTokens =
      <_AppAuthCacheKey, Future<String>>{};
  final Map<_AppAuthCacheKey, List<OpenToolServerDeclaration>>
  _appOpenToolDeclarations =
      <_AppAuthCacheKey, List<OpenToolServerDeclaration>>{};
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
  late final AuthKitModule authkit = AuthKitModule._(this);
  late final DiscoveryKitModule discoverykit = DiscoveryKitModule._(this);
  late final TransferKitModule transferkit = TransferKitModule._(this);
  late final HarnessKitModule harnesskit = HarnessKitModule._(this);

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
        opentoolServers:
            _appOpenToolDeclarations[key] ??
            const <OpenToolServerDeclaration>[],
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
    Future<T> Function(String bearerToken) action, {
    bool retryForbidden = true,
  }) async {
    final requestContext = await _requireAppAuthContext();
    try {
      return await action(requestContext.token);
    } catch (error) {
      if ((!retryForbidden &&
              error is DioException &&
              error.response?.statusCode == 403) ||
          !_shouldRecoverAppAuth(error)) {
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
    await agentkit._dispose();
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
  ///
  /// [opentoolServers] declares native OpenTool dependencies. The returned
  /// registrations report `running`, `starting`, or `notFound`; asynchronous
  /// provisioning results are delivered to [AgentOSEventHandler.onAppEvent].
  Future<AccessToken> registerBundle({
    required String bundleId,
    String? appGroupId,
    List<OpenToolServerDeclaration> opentoolServers = const [],
  }) async {
    final key = _AppAuthCacheKey(bundleId: bundleId, appGroupId: appGroupId);
    final info = await _client._appKit.registerBundle(
      bundleId: bundleId,
      appGroupId: appGroupId,
      opentoolServers: opentoolServers,
    );
    _client._appOpenToolDeclarations[key] = List.unmodifiable(opentoolServers);
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
          } else if (event.agentosEventType == AgentOSEventType.appEvent) {
            final payload = _client._asJsonMap(event.data);
            await currentHandler.onAppEvent(AppEvent.fromJson(payload));
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
  final Map<String, Set<_ActiveAgentKitChat>> _activeChats =
      <String, Set<_ActiveAgentKitChat>>{};

  /// Initializes a SessionAgent session via AgentKit.
  Future<Map<String, dynamic>> initSession({Capability? capability}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.initSession(
        bearerToken: bearerToken,
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
    final activeChat = _ActiveAgentKitChat();
    _activeChats
        .putIfAbsent(session.sessionId, () => <_ActiveAgentKitChat>{})
        .add(activeChat);
    activeChat.subscription = stream
        .asyncMap<void>((event) async {
          await _dispatchChatEvent(session, event, agentMessageHandler);
        })
        .listen(
          (_) {},
          onDone: () {
            _removeActiveChat(session.sessionId, activeChat);
            unawaited(_notifyChatDone(agentMessageHandler));
          },
          onError: (Object error, StackTrace stackTrace) {
            _removeActiveChat(session.sessionId, activeChat);
            unawaited(_notifyChatError(agentMessageHandler, error, stackTrace));
          },
          cancelOnError: true,
        );
  }

  void _removeActiveChat(String sessionId, _ActiveAgentKitChat activeChat) {
    final chats = _activeChats[sessionId];
    if (chats == null) return;
    chats.remove(activeChat);
    if (chats.isEmpty) _activeChats.remove(sessionId);
  }

  Future<void> _cancelActiveChats(String sessionId) async {
    final chats = _activeChats.remove(sessionId);
    if (chats == null) return;
    await Future.wait(chats.map((chat) => chat.subscription.cancel()));
  }

  Future<void> _dispose() async {
    final chats = _activeChats.values.expand((value) => value).toList();
    _activeChats.clear();
    await Future.wait(chats.map((chat) => chat.subscription.cancel()));
  }

  Future<void> _dispatchChatEvent(
    Session session,
    AgentEvent event,
    AgentMessageHandler agentMessageHandler,
  ) async {
    if (event.agentEventType == AgentEventType.message) {
      final agentMessage = AgentMessage.fromJson(
        jsonDecode(event.data) as Map<String, dynamic>,
      );
      await agentMessageHandler.onMessage(
        _eventSessionId(agentMessage.sessionId, session.sessionId),
        agentMessage,
      );
    } else if (event.agentEventType == AgentEventType.chunk) {
      final agentMessageChunk = AgentMessageChunk.fromJson(
        jsonDecode(event.data) as Map<String, dynamic>,
      );
      await agentMessageHandler.onChunk(
        _eventSessionId(agentMessageChunk.sessionId, session.sessionId),
        agentMessageChunk,
      );
    } else if (event.agentEventType == AgentEventType.functionCall) {
      await _handleFunctionCallEvent(session, event.data, agentMessageHandler);
    }
  }

  Future<void> _notifyChatDone(AgentMessageHandler handler) async {
    try {
      await handler.onDone();
    } catch (error, stackTrace) {
      await _notifyChatError(handler, error, stackTrace);
    }
  }

  Future<void> _notifyChatError(
    AgentMessageHandler handler,
    Object error,
    StackTrace stackTrace,
  ) async {
    final exception = error is Exception ? error : Exception(error.toString());
    try {
      await handler.onError(exception);
    } catch (callbackError, callbackStackTrace) {
      Zone.current.handleUncaughtError(callbackError, callbackStackTrace);
    }
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
  Future<List<AgentMessage>> history({
    required String sessionId,
    int? page,
    int? pageSize,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.history(
        bearerToken: bearerToken,
        sessionId: sessionId,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  /// Retrieves task-turn summaries for a root session via AgentKit.
  Future<List<HistoryTurnSummaryDto>> historySummary({
    required String sessionId,
    int page = 1,
    int pageSize = 30,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.historySummary(
        bearerToken: bearerToken,
        sessionId: sessionId,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  /// Retrieves process messages for one task turn via AgentKit.
  Future<List<AgentMessage>> historyProcess({
    required String sessionId,
    required String originalTaskId,
    int page = 1,
    int pageSize = 50,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._agentKit.historyProcess(
        bearerToken: bearerToken,
        sessionId: sessionId,
        originalTaskId: originalTaskId,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  /// Stops a session or task via AgentKit.
  ///
  /// A session-level stop also closes active local chat streams. A
  /// task-specific stop leaves the session stream available for other tasks.
  Future<Map<String, dynamic>> stop({
    required String sessionId,
    String? taskId,
  }) async {
    try {
      return await _client._withAppAuthRetry(
        (bearerToken) => _client._agentKit.stop(
          bearerToken: bearerToken,
          sessionId: sessionId,
          taskId: taskId,
        ),
      );
    } finally {
      if (taskId == null) await _cancelActiveChats(sessionId);
    }
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
    final effectiveSessionId = _eventSessionId(
      payload['sessionId']?.toString(),
      session.sessionId,
    );
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

  String _eventSessionId(String? eventSessionId, String fallbackSessionId) {
    return eventSessionId != null && eventSessionId.trim().isNotEmpty
        ? eventSessionId
        : fallbackSessionId;
  }
}

class _ActiveAgentKitChat {
  late final StreamSubscription<void> subscription;
}

/// Entry point for the task-oriented ModelKit API
/// (chat / embedding / asr / tts / decision) and app-model registration.
class ModelKitModule {
  ModelKitModule._(this._client);

  final AgentOSSDK _client;

  ModelKitChatClient get chat => _client._modelKit.chat;
  ModelKitEmbeddingClient get embedding => _client._modelKit.embedding;
  ModelKitAsrClient get asr => _client._modelKit.asr;
  ModelKitTtsClient get tts => _client._modelKit.tts;
  ModelKitDecisionClient get decision => _client._modelKit.decision;

  Future<List<ModelInfo>> listModels() {
    return _client._modelKit.listModels();
  }

  Future<List<ModelInfo>> listModelsByTask(ModelTask task) {
    return _client._modelKit.listModelsByTask(task);
  }

  /// Lists models registered by apps. No app registration needed.
  Future<List<AppModel>> listAppModels() {
    return _client._modelKit.listAppModels();
  }

  /// Registers (or replaces) a model owned by the current app.
  ///
  /// Requires the app to be registered first (`registerApp`); the app token is
  /// attached automatically.
  Future<AppModelWriteResult> registerAppModel({
    required AppModelRegistration request,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._modelKit.registerAppModel(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  /// Partially updates a model owned by the current app.
  Future<AppModelWriteResult> updateAppModel({
    required String modelId,
    required AppModelUpdate request,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._modelKit.updateAppModel(
        bearerToken: bearerToken,
        modelId: modelId,
        request: request,
      ),
    );
  }

  /// Removes a model owned by the current app.
  Future<AppModelWriteResult> unregisterAppModel({required String modelId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._modelKit.unregisterAppModel(
        bearerToken: bearerToken,
        modelId: modelId,
      ),
    );
  }

  /// Enables or disables a model owned by the current app.
  Future<AppModelWriteResult> toggleAppModel({required String modelId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._modelKit.toggleAppModel(
        bearerToken: bearerToken,
        modelId: modelId,
      ),
    );
  }
}

class ToolKitModule {
  ToolKitModule._(this._client);

  final AgentOSSDK _client;

  Future<List<ToolDto>> listTool([String? all]) {
    return listTools(all: all);
  }

  Future<List<ToolDto>> listTools({String? all}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._toolKit.listTools(bearerToken: bearerToken, all: all),
    );
  }

  Future<OpenTool?> loadTool(String toolId) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._toolKit.loadTool(toolId, bearerToken: bearerToken),
    );
  }

  Future<ToolReturn> callTool({
    required String toolId,
    required FunctionCall functionCall,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._toolKit.callTool(
        bearerToken: bearerToken,
        toolId: toolId,
        functionCall: functionCall,
      ),
    );
  }

  Future<Stream<ToolKitStreamEvent>> streamCallTool({
    required String toolId,
    required FunctionCall functionCall,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._toolKit.streamCallTool(
        bearerToken: bearerToken,
        toolId: toolId,
        functionCall: functionCall,
      ),
    );
  }

  @Deprecated('Not exposed by the AgentOS API gateway ToolKit API.')
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

class AuthKitModule {
  AuthKitModule._(this._client);

  final AgentOSSDK _client;

  /// 把第三方 Server 返回的 [launchUri] 交给本机 AgentOS Desktop 展示授权页。
  ///
  /// 这是新 AuthKit 流程的唯一客户端入口。典型用法：
  ///
  /// ```dart
  /// // 1. 先请求自己的 Server 开始登录，拿到 launchUri
  /// final start = await myServer.startAgentOSLogin();
  /// // 2. 交给 SDK 唤起 Desktop（原样透传，不要自行拼接）
  /// final result = await sdk.authkit.openAuthorization(
  ///   launchUri: start.launchUri,
  /// );
  /// if (result.isFailure) {
  ///   // 按 result.errorCode 提示用户（如安装/启动 AgentOS Desktop）
  /// }
  /// // 3. 以自己 Server 的事务状态为准轮询登录结果
  /// ```
  ///
  /// 返回值**不含**任何 OAuth 凭证：authorization code、ID Token、AgentOS
  /// access/refresh token 只在你的 Server 与 AgentOS Server 之间流转。
  /// [AuthorizationPresentationStatus.submitted] 也只代表 Desktop 已提交用户
  /// 决定，不代表登录完成 —— 最终结果必须以你自己 Server 的事务状态为准。
  ///
  /// [waitForDecision] 默认 false，Desktop 展示授权页后立即返回 `opened`。
  Future<AuthorizationPresentationResult> openAuthorization({
    required String launchUri,
    bool waitForDecision = false,
    Duration? decisionTimeout,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._authKitClient.open(
        bearerToken: bearerToken,
        request: OpenAuthorizationRequest(
          launchUri: launchUri,
          waitForDecision: waitForDecision,
          decisionTimeout: decisionTimeout,
        ),
      ),
    );
  }

  /// 本机是否已具备承载授权界面的能力（Desktop 在运行且启动完成）。
  ///
  /// 可在发起登录前调用，以便提前提示用户安装 / 启动 / 解锁 AgentOS Desktop。
  Future<bool> isAuthorizationReady() {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._authKitClient.isReady(bearerToken: bearerToken),
    );
  }
}

class DiscoveryKitModule {
  DiscoveryKitModule._(this._client);

  final AgentOSSDK _client;

  Future<List<PeerDevice>> getPeers() {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._discoveryKit.getPeers(bearerToken: bearerToken),
    );
  }

  Future<Stream<PeerDeviceEvent>> streamPeers() {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._discoveryKit.streamPeers(bearerToken: bearerToken),
    );
  }

  Future<SelfInfo> getSelf() {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._discoveryKit.getSelf(bearerToken: bearerToken),
    );
  }

  Future<DiscoveryRegisterResponse> register({
    DiscoveryRegisterRequest? request,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._discoveryKit.register(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<DiscoveryUnregisterResponse> unregister() {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._discoveryKit.unregister(bearerToken: bearerToken),
    );
  }
}

class TransferKitModule {
  TransferKitModule._(this._client);

  final AgentOSSDK _client;

  Future<TransferSession> send({required TransferSendRequest request}) {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._transferKit.send(bearerToken: bearerToken, request: request),
    );
  }

  Future<List<TransferSession>> listTransfers() {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._transferKit.listTransfers(bearerToken: bearerToken),
    );
  }

  Future<TransferSession> getStatus({required String transferId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.getStatus(
        bearerToken: bearerToken,
        transferId: transferId,
      ),
    );
  }

  Future<Stream<TransferSession>> streamProgress({required String transferId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.streamProgress(
        bearerToken: bearerToken,
        transferId: transferId,
      ),
    );
  }

  Future<StatusResponse> cancel({required String transferId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.cancel(
        bearerToken: bearerToken,
        transferId: transferId,
      ),
    );
  }

  Future<StatusResponse> respond({
    required String transferId,
    required TransferRespondRequest request,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.respond(
        bearerToken: bearerToken,
        transferId: transferId,
        request: request,
      ),
    );
  }

  Future<Stream<IncomingTransferEvent>> receiveStream() {
    return _client._withAppAuthRetry(
      (bearerToken) =>
          _client._transferKit.receiveStream(bearerToken: bearerToken),
    );
  }

  Future<PolicyResponse> setPolicy({required SetPolicyRequest request}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.setPolicy(
        bearerToken: bearerToken,
        request: request,
      ),
    );
  }

  Future<PolicyResponse> getPolicy() {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.getPolicy(bearerToken: bearerToken),
    );
  }

  Future<List<TransferHistoryRecord>> getHistory({
    String? deviceId,
    String? userId,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.getHistory(
        bearerToken: bearerToken,
        deviceId: deviceId,
        userId: userId,
      ),
    );
  }

  Future<StatusResponse> deleteHistory({
    required String recordId,
    String? deviceId,
    String? userId,
  }) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.deleteHistory(
        bearerToken: bearerToken,
        recordId: recordId,
        deviceId: deviceId,
        userId: userId,
      ),
    );
  }

  Future<StatusResponse> clearHistory({String? deviceId, String? userId}) {
    return _client._withAppAuthRetry(
      (bearerToken) => _client._transferKit.clearHistory(
        bearerToken: bearerToken,
        deviceId: deviceId,
        userId: userId,
      ),
    );
  }
}

/// Entry point for the AppKit-authenticated Harness API.
///
/// Register the app with [AgentOSModule.registerBundle] before calling these
/// methods. External Apps use the shared runtime with App-scoped data.
class HarnessKitModule {
  HarnessKitModule._(this._client);

  final AgentOSSDK _client;

  /// Checks whether the authenticated Harness runtime is reachable.
  Future<Map<String, dynamic>> health() => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.health(bearerToken: bearerToken),
  );

  /// Reads the active Harness runtime engine.
  Future<HarnessKitRuntimeInfo> getRuntime() => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.getRuntime(bearerToken: bearerToken),
  );

  /// Switches the active Harness runtime engine.
  Future<HarnessKitEngineSwitchResult> switchEngine({
    required HarnessKitEngineId engine,
  }) => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.switchEngine(
      bearerToken: bearerToken,
      engine: engine,
    ),
  );

  /// Lists saved Harness conversations.
  Future<List<HarnessKitThreadSnapshot>> listThreads() =>
      _client._withAppAuthRetry(
        (bearerToken) =>
            _client._harnessKit.listThreads(bearerToken: bearerToken),
      );

  /// Retrieves one saved conversation.
  Future<HarnessKitThreadSnapshot> getThread({required String threadId}) =>
      _client._withAppAuthRetry(
        (bearerToken) => _client._harnessKit.getThread(
          bearerToken: bearerToken,
          threadId: threadId,
        ),
      );

  /// Renames one saved conversation.
  Future<HarnessKitThreadRenameResult> renameThread({
    required String threadId,
    required String title,
  }) => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.renameThread(
      bearerToken: bearerToken,
      threadId: threadId,
      title: title,
    ),
  );

  /// Deletes one saved conversation.
  Future<HarnessKitThreadDeleteResult> deleteThread({
    required String threadId,
  }) => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.deleteThread(
      bearerToken: bearerToken,
      threadId: threadId,
    ),
  );

  /// Registers or replaces a local App's OpenTool callbacks for one thread.
  ///
  /// The App must connect directly to the local Gateway and provide a local
  /// callback service. The callback token is separate from the AppKit token.
  Future<HarnessKitPrivateToolsRegistrationResult> registerPrivateTools({
    required String threadId,
    required HarnessKitPrivateToolsRegistration registration,
  }) => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.registerPrivateTools(
      bearerToken: bearerToken,
      threadId: threadId,
      registration: registration,
    ),
    retryForbidden: false,
  );

  /// Starts a run on a conversation.
  Future<HarnessKitRunAccepted> startRun({
    required String threadId,
    required HarnessKitRunRequest request,
  }) => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.startRun(
      bearerToken: bearerToken,
      threadId: threadId,
      request: request,
    ),
  );

  /// Submits a command and returns its receipt, including rejected receipts.
  Future<HarnessKitCommandReceipt> submitCommand({
    required String threadId,
    required HarnessKitCommand command,
  }) => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.submitCommand(
      bearerToken: bearerToken,
      threadId: threadId,
      command: command,
    ),
  );

  /// Opens a resumable event stream. Cancel its subscription to close it.
  Future<Stream<HarnessKitEvent>> events({
    required String threadId,
    HarnessKitEventsOptions options = const HarnessKitEventsOptions(),
  }) => _client._withAppAuthRetry(
    (bearerToken) => _client._harnessKit.events(
      bearerToken: bearerToken,
      threadId: threadId,
      options: options,
    ),
  );

  /// Retrieves the final result for a run.
  Future<HarnessKitRunResult> getRunResult({required String runId}) =>
      _client._withAppAuthRetry(
        (bearerToken) => _client._harnessKit.getRunResult(
          bearerToken: bearerToken,
          runId: runId,
        ),
      );

  /// Retrieves the operational snapshot for the Harness runtime.
  Future<HarnessKitOperationalSnapshot> getOperationalSnapshot() =>
      _client._withAppAuthRetry(
        (bearerToken) => _client._harnessKit.getOperationalSnapshot(
          bearerToken: bearerToken,
        ),
      );
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
