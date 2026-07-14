import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/client/agentkit/agentkit_client.dart';
import 'package:agentos_sdk/src/client/appkit/appkit_client.dart';
import 'package:agentos_sdk/src/client/cronkit/cronkit_client.dart';
import 'package:agentos_sdk/src/client/systemkit/systemkit_client.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('DTO', () {
    test('parses and serializes token usage contextUsageRatio', () {
      final usage = TokenUsage.fromJson(<String, dynamic>{
        'promptTokens': 10,
        'completionTokens': 20,
        'totalTokens': 30,
        'contextUsageRatio': 0.42,
      });

      expect(usage.contextUsageRatio, equals(0.42));
      expect(usage.toJson()['contextUsageRatio'], equals(0.42));
    });

    test('parses user task passthrough fields for liteagent', () {
      final task = UserTask.fromJson(<String, dynamic>{
        'content': <Map<String, dynamic>>[
          <String, dynamic>{'type': 'text', 'message': 'hello'},
        ],
        'isChunk': true,
        'extraSystemPrompt': 'safety first',
        'llmConfig': <String, dynamic>{
          'baseUrl': 'http://127.0.0.1:9527/v1',
          'apiKey': 'sk-test',
          'model': 'qwen-max',
          'supportsToolCall': true,
          'supportsReasoning': true,
          'contextWindowSize': 32768,
        },
      });

      expect(task.extraSystemPrompt, equals('safety first'));
      expect(task.llmConfig, isNotNull);
      expect(task.llmConfig!.supportsToolCall, isTrue);
      expect(task.llmConfig!.supportsReasoning, isTrue);
      expect(task.llmConfig!.contextWindowSize, equals(32768));
    });

    test('supports llmConfig modelId mode', () {
      final config = LLMConfig(modelId: 'qwen3-8b');
      final payload = config.toJson();
      expect(payload['modelId'], equals('qwen3-8b'));
      expect(payload.containsKey('model'), isFalse);
      expect(payload.containsKey('baseUrl'), isFalse);
      expect(payload.containsKey('apiKey'), isFalse);
    });

    test('supports llmConfig custom mode with baseUrl/apiKey/model', () {
      final config = LLMConfig(
        baseUrl: 'http://127.0.0.1:60000',
        apiKey: 'sk-custom',
        model: 'explicit-model',
      );
      final payload = config.toJson();
      expect(payload['baseUrl'], equals('http://127.0.0.1:60000'));
      expect(payload['apiKey'], equals('sk-custom'));
      expect(payload['model'], equals('explicit-model'));
      expect(payload.containsKey('modelId'), isFalse);
    });

    test('allows llmConfig without core fields for auto/fallback mode', () {
      final config = LLMConfig(temperature: 0.66);
      final payload = config.toJson();
      expect(payload['temperature'], equals(0.66));
      expect(payload['supportsToolCall'], isTrue);
      expect(payload['supportsReasoning'], isTrue);
      expect(payload.containsKey('modelId'), isFalse);
      expect(payload.containsKey('baseUrl'), isFalse);
      expect(payload.containsKey('apiKey'), isFalse);
      expect(payload.containsKey('model'), isFalse);
    });

    test('parses completions limits passthrough fields for liteagent', () {
      final message = AgentMessage.fromJson(<String, dynamic>{
        'sessionId': 's1',
        'originalTaskId': 'root-task',
        'taskId': 't1',
        'role': 'assistant',
        'to': 'client',
        'type': 'text',
        'content': 'ok',
        'createTime': DateTime.utc(2026, 1, 1).toIso8601String(),
        'completions': <String, dynamic>{
          'usage': <String, dynamic>{
            'promptTokens': 10,
            'completionTokens': 20,
            'totalTokens': 30,
          },
          'id': 'cmpl-1',
          'model': 'qwen',
          'limits': <String, dynamic>{
            'maxTokens': 4096,
            'contextWindowSize': 8192,
          },
        },
      });

      expect(message.completions?.limits?.maxTokens, equals(4096));
      expect(message.completions?.limits?.contextWindowSize, equals(8192));
      expect(message.originalTaskId, equals('root-task'));
      expect(message.toJson()['originalTaskId'], equals('root-task'));
    });

    test('falls back originalTaskId and parses task status taskId', () {
      final message = AgentMessage.fromJson(<String, dynamic>{
        'sessionId': 's1',
        'taskId': 'legacy-task',
        'role': 'assistant',
        'to': 'client',
        'type': 'taskStatus',
        'content': <String, dynamic>{'status': 'done', 'taskId': 'child-task'},
        'createTime': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
      final taskStatus = TaskStatus.fromJson(
        Map<String, dynamic>.from(message.content as Map),
      );

      expect(message.originalTaskId, equals('legacy-task'));
      expect(message.toJson()['originalTaskId'], equals('legacy-task'));
      expect(taskStatus.status, equals('done'));
      expect(taskStatus.taskId, equals('child-task'));
      expect(taskStatus.toJson()['taskId'], equals('child-task'));
    });

    test('round-trips history turn summaries with nested DTOs', () {
      final summary = HistoryTurnSummaryDto.fromJson(<String, dynamic>{
        'originalTaskId': 'root-task',
        'sessionId': 'root-session',
        'userMessage': <String, dynamic>{
          'sessionId': 'root-session',
          'originalTaskId': 'root-task',
          'taskId': 'root-task',
          'role': 'user',
          'to': 'agent',
          'type': 'text',
          'content': 'hello',
          'createTime': '2026-07-12T10:00:00.000Z',
        },
        'finalMessage': null,
        'status': HistoryTurnStatus.running,
        'error': null,
        'createdAt': '2026-07-12T10:00:00.000Z',
        'completedAt': null,
        'durationMs': null,
        'usage': <String, dynamic>{
          'promptTokens': 10,
          'completionTokens': 2,
          'totalTokens': 12,
          'contextUsageRatio': null,
        },
        'processMessageCount': 3,
      });

      expect(summary.userMessage, isA<AgentMessage>());
      expect(summary.usage, isA<TokenUsage>());
      final json = summary.toJson();
      expect(json['userMessage'], isA<Map<String, dynamic>>());
      expect(json['usage'], isA<Map<String, dynamic>>());
      expect(json['finalMessage'], isNull);
      expect(json['error'], isNull);
      expect(json['completedAt'], isNull);
      expect(json['durationMs'], isNull);
      expect(HistoryTurnSummaryDto.fromJson(json).toJson(), equals(json));
    });
  });

  group('AgentOSSDK configuration', () {
    test('uses the new gateway default base url', () async {
      final apiClient = ApiClient();

      expect(apiClient.dio.options.baseUrl, equals('http://localhost:8888'));
    });

    test(
      'accepts custom api client and overrides baseUrl when provided',
      () async {
        final interceptor = _CaptureBaseUrlInterceptor();
        final dio = Dio(BaseOptions(baseUrl: 'http://old.local'))
          ..interceptors.add(interceptor);
        final sdk = AgentOSSDK(
          baseUrl: 'http://new.local:8888',
          apiClient: ApiClient(dio: dio),
        );

        final version = await sdk.agentos.getVersion();

        expect(version.version, equals('1.2.3'));
        expect(interceptor.lastBaseUrl, equals('http://new.local:8888'));
      },
    );

    test('applies connect and receive timeout overrides', () async {
      final interceptor = _CaptureOptionsInterceptor();
      final apiClient = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'http://old.local'))
          ..interceptors.add(interceptor),
      );
      final sdk = AgentOSSDK(
        baseUrl: 'http://timeout.local',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: Duration.zero,
        apiClient: apiClient,
      );

      final version = await sdk.agentos.getVersion();

      expect(version.version, equals('1.2.3'));
      expect(interceptor.lastBaseUrl, equals('http://timeout.local'));
      expect(
        interceptor.lastConnectTimeout,
        equals(const Duration(seconds: 30)),
      );
      expect(interceptor.lastReceiveTimeout, equals(Duration.zero));
    });
  });

  group('AgentOSSDK subscription lifecycle', () {
    test('dispose stops receiving subsequent events', () async {
      final interceptor = _DelayedAppKitInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(interceptor);
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));
      final handler = _CountingEventHandler();

      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      await sdk.agentos.subscribe(handler);

      await handler.firstWelcome.future.timeout(const Duration(seconds: 2));
      await sdk.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(handler.welcomeCount, equals(1));
      expect(handler.callAppCount, equals(0));
    });

    test('emits connected after subscribe is established', () async {
      final interceptor = _ScriptedAppKitInterceptor(
        subscribePlans: const <_SubscribePlan>[_SubscribePlan.stream()],
      );
      final sdk = AgentOSSDK(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
            ..interceptors.add(interceptor),
        ),
      );
      final recorder = _ConnectionEventRecorder(sdk.agentos.connectionEvents);

      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      await sdk.agentos.subscribe(_CountingEventHandler());

      await recorder.waitForCount(1);

      expect(
        recorder.statuses,
        equals(<AgentOSSubscribeConnectionStatus>[
          AgentOSSubscribeConnectionStatus.connected,
        ]),
      );

      await sdk.dispose();
      await recorder.dispose();
      await interceptor.dispose();
    });

    test(
      'emits disconnected when passive close happens without auto reconnect',
      () async {
        final interceptor = _ScriptedAppKitInterceptor(
          subscribePlans: const <_SubscribePlan>[_SubscribePlan.stream()],
        );
        final sdk = AgentOSSDK(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
              ..interceptors.add(interceptor),
          ),
        );
        final recorder = _ConnectionEventRecorder(sdk.agentos.connectionEvents);

        await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
        await sdk.agentos.subscribe(
          _CountingEventHandler(),
          options: const AgentOSSubscribeOptions(autoReconnect: false),
        );
        await recorder.waitForCount(1);

        await interceptor.closeStream(0);
        await recorder.waitForCount(2);

        expect(
          recorder.statuses,
          equals(<AgentOSSubscribeConnectionStatus>[
            AgentOSSubscribeConnectionStatus.connected,
            AgentOSSubscribeConnectionStatus.disconnected,
          ]),
        );

        await sdk.dispose();
        await recorder.dispose();
        await interceptor.dispose();
      },
    );

    test(
      'emits reconnecting and reconnected after idle subscribe reconnects',
      () async {
        final interceptor = _ScriptedAppKitInterceptor(
          subscribePlans: const <_SubscribePlan>[
            _SubscribePlan.stream(),
            _SubscribePlan.stream(),
          ],
        );
        final sdk = AgentOSSDK(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
              ..interceptors.add(interceptor),
          ),
        );
        final recorder = _ConnectionEventRecorder(sdk.agentos.connectionEvents);
        final handler = _CountingEventHandler();

        await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
        await sdk.agentos.subscribe(
          handler,
          options: const AgentOSSubscribeOptions(
            reconnectDelay: Duration(milliseconds: 10),
          ),
        );
        await handler.firstWelcome.future.timeout(const Duration(seconds: 2));
        await recorder.waitForCount(1);

        await interceptor.closeStream(0);
        await recorder.waitForCount(4);

        expect(
          recorder.statuses,
          equals(<AgentOSSubscribeConnectionStatus>[
            AgentOSSubscribeConnectionStatus.connected,
            AgentOSSubscribeConnectionStatus.reconnecting,
            AgentOSSubscribeConnectionStatus.reconnected,
            AgentOSSubscribeConnectionStatus.connected,
          ]),
        );
        expect(handler.welcomeCount, equals(2));

        await sdk.dispose();
        await recorder.dispose();
        await interceptor.dispose();
      },
    );

    test('emits disconnected after reconnect attempts are exhausted', () async {
      final interceptor = _ScriptedAppKitInterceptor(
        subscribePlans: const <_SubscribePlan>[
          _SubscribePlan.stream(),
          _SubscribePlan.networkError(),
          _SubscribePlan.networkError(),
        ],
      );
      final sdk = AgentOSSDK(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
            ..interceptors.add(interceptor),
        ),
      );
      final recorder = _ConnectionEventRecorder(sdk.agentos.connectionEvents);

      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      await sdk.agentos.subscribe(
        _CountingEventHandler(),
        options: const AgentOSSubscribeOptions(
          maxReconnectAttempts: 2,
          reconnectDelay: Duration(milliseconds: 10),
        ),
      );
      await recorder.waitForCount(1);

      await interceptor.closeStream(0);
      await recorder.waitForCount(3);

      expect(
        recorder.statuses,
        equals(<AgentOSSubscribeConnectionStatus>[
          AgentOSSubscribeConnectionStatus.connected,
          AgentOSSubscribeConnectionStatus.reconnecting,
          AgentOSSubscribeConnectionStatus.disconnected,
        ]),
      );

      await sdk.dispose();
      await recorder.dispose();
      await interceptor.dispose();
    });

    test(
      'refreshes app auth before restoring subscribe after passive close',
      () async {
        final interceptor = _ScriptedAppKitInterceptor(
          subscribePlans: const <_SubscribePlan>[
            _SubscribePlan.stream(),
            _SubscribePlan.unauthorized(),
            _SubscribePlan.stream(),
          ],
        );
        final sdk = AgentOSSDK(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
              ..interceptors.add(interceptor),
          ),
        );
        final recorder = _ConnectionEventRecorder(sdk.agentos.connectionEvents);
        final handler = _CountingEventHandler();

        await sdk.agentos.registerBundle(
          bundleId: 'com.demo.app',
          appGroupId: 'group-a',
        );
        await sdk.agentos.subscribe(
          handler,
          options: const AgentOSSubscribeOptions(
            reconnectDelay: Duration(milliseconds: 10),
          ),
        );
        await recorder.waitForCount(1);

        await interceptor.closeStream(0);
        await recorder.waitForCount(4);

        expect(
          recorder.statuses,
          equals(<AgentOSSubscribeConnectionStatus>[
            AgentOSSubscribeConnectionStatus.connected,
            AgentOSSubscribeConnectionStatus.reconnecting,
            AgentOSSubscribeConnectionStatus.reconnected,
            AgentOSSubscribeConnectionStatus.connected,
          ]),
        );
        expect(interceptor.registerCount, equals(2));
        expect(
          interceptor.subscribeTokens,
          equals(<String>['token-v1', 'token-v1', 'token-v2']),
        );
        expect(handler.welcomeCount, equals(2));

        await sdk.dispose();
        await recorder.dispose();
        await interceptor.dispose();
      },
    );
  });

  group('SystemKitClient', () {
    test('fetches version from /version', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_VersionInterceptor());
      final client = ApiClient(dio: dio);
      final root = SystemKitClient(apiClient: client);

      final version = await root.getVersion();

      expect(version.version, equals('1.2.3'));
    });

    test('fetches readiness from /ready', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_VersionInterceptor());
      final client = ApiClient(dio: dio);
      final root = SystemKitClient(apiClient: client);

      final readiness = await root.getReady();

      expect(readiness.ready, isTrue);
      expect(readiness.liteAgentReady, isTrue);
    });
  });

  group('AgentKitClient', () {
    test('creates agent, initializes session, and chats simple', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_AgentKitInterceptor());
      final client = AgentKitClient(apiClient: ApiClient(dio: dio));

      final agent = await client.createAgent(
        bearerToken: 'token-123',
        agent: Agent(
          name: 'demo-agent',
          capability: Capability(
            systemPrompt: 'demo',
            llmConfig: LLMConfig(
              baseUrl: 'http://llm.local',
              apiKey: 'sk-test',
              model: 'demo-model',
            ),
          ),
        ),
      );
      expect(agent['agentId'], equals('agent-abc'));

      final session = await client.initSession(
        bearerToken: 'token-123',
        agentId: 'agent-abc',
      );
      expect(session['sessionId'], equals('sess-123'));

      final reply = await client.chatSimple(
        bearerToken: 'token-123',
        sessionId: 'sess-123',
        userTask: UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
      );
      expect(reply['sessionId'], equals('sess-123'));
      expect(reply['content'], equals('hello'));
    });

    test('streams chat events', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_AgentKitInterceptor());
      final client = AgentKitClient(apiClient: ApiClient(dio: dio));

      final events = await (await client.chat(
        bearerToken: 'token-123',
        sessionId: 'sess-123',
        userTask: UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
      )).toList();

      expect(events, isNotEmpty);
      expect(
        events.map((e) => e.agentEventType),
        containsAll(<String>['message', 'chunk', 'functionCall']),
      );
      expect(events.first.data, contains('hello'));
      final functionCallEvent = events.firstWhere(
        (event) => event.agentEventType == 'functionCall',
      );
      expect(functionCallEvent.data, contains('"functionCall"'));
    });

    test('retrieves typed paginated history', () async {
      final interceptor = _AgentKitInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(interceptor);
      final client = AgentKitClient(apiClient: ApiClient(dio: dio));

      final messages = await client.history(
        bearerToken: 'token-123',
        sessionId: 'sess-123',
        page: 2,
        pageSize: 50,
      );

      expect(interceptor.historyPage, equals(2));
      expect(interceptor.historyPageSize, equals(50));
      expect(messages, hasLength(1));
      expect(messages.single.originalTaskId, equals('root-task'));
      expect(messages.single.taskId, equals('child-task'));
    });

    test('rejects incomplete or invalid history pagination', () async {
      final client = AgentKitClient(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
            ..interceptors.add(_AgentKitInterceptor()),
        ),
      );

      expect(
        () => client.history(
          bearerToken: 'token-123',
          sessionId: 'sess-123',
          page: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => client.history(
          bearerToken: 'token-123',
          sessionId: 'sess-123',
          page: 0,
          pageSize: 50,
        ),
        throwsArgumentError,
      );
      expect(
        () => client.history(
          bearerToken: 'token-123',
          sessionId: 'sess-123',
          page: 1,
          pageSize: 0,
        ),
        throwsArgumentError,
      );
    });

    test('retrieves typed summary and process history', () async {
      final interceptor = _AgentKitInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(interceptor);
      final client = AgentKitClient(apiClient: ApiClient(dio: dio));

      final summaries = await client.historySummary(
        bearerToken: 'token-123',
        sessionId: 'root-session',
        page: 2,
        pageSize: 25,
      );
      final process = await client.historyProcess(
        bearerToken: 'token-123',
        sessionId: 'root-session',
        originalTaskId: 'root-task',
        page: 3,
        pageSize: 40,
      );

      expect(summaries.single.status, HistoryTurnStatus.done);
      expect(summaries.single.userMessage, isA<AgentMessage>());
      expect(summaries.single.usage, isA<TokenUsage>());
      expect(process.single.sessionId, 'child-session');
      expect(interceptor.historySummaryQuery, <String, dynamic>{
        'sessionId': 'root-session',
        'page': 2,
        'pageSize': 25,
      });
      expect(interceptor.historyProcessQuery, <String, dynamic>{
        'sessionId': 'root-session',
        'originalTaskId': 'root-task',
        'page': 3,
        'pageSize': 40,
      });
    });

    test('validates summary and process history parameters', () async {
      final client = AgentKitClient(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
            ..interceptors.add(_AgentKitInterceptor()),
        ),
      );

      for (final call in <Future<void> Function()>[
        () async => client.historySummary(
          bearerToken: 'token-123',
          sessionId: 'root-session',
          page: 0,
        ),
        () async => client.historySummary(
          bearerToken: 'token-123',
          sessionId: 'root-session',
          pageSize: 201,
        ),
        () async => client.historyProcess(
          bearerToken: 'token-123',
          sessionId: 'root-session',
          originalTaskId: '  ',
        ),
        () async => client.historyProcess(
          bearerToken: 'token-123',
          sessionId: 'root-session',
          originalTaskId: 'root-task',
          pageSize: 0,
        ),
      ]) {
        expect(call, throwsArgumentError);
      }
    });

    test(
      'exposes summary and process history through AgentKitModule',
      () async {
        final interceptor = _AgentKitInterceptor();
        final sdk = AgentOSSDK(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
              ..interceptors.add(interceptor),
          ),
        );
        await sdk.agentos.registerBundle(bundleId: 'com.demo.app');

        final summaries = await sdk.agentkit.historySummary(
          sessionId: 'root-session',
        );
        final process = await sdk.agentkit.historyProcess(
          sessionId: 'root-session',
          originalTaskId: 'root-task',
        );

        expect(summaries.single.originalTaskId, 'root-task');
        expect(process.single.sessionId, 'child-session');
        expect(interceptor.historySummaryQuery?['page'], 1);
        expect(interceptor.historySummaryQuery?['pageSize'], 30);
        expect(interceptor.historyProcessQuery?['page'], 1);
        expect(interceptor.historyProcessQuery?['pageSize'], 50);
      },
    );

    test('stop closes the active underlying SSE stream', () async {
      final streamCancelled = Completer<void>();
      final source = StreamController<Uint8List>(
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      final sdk = _buildAgentKitLifecycleSdk(source.stream);
      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');

      await sdk.agentkit.chat(
        Session(sessionId: 'root-session'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
        _LifecycleAgentMessageHandler(),
      );
      final result = await sdk.agentkit.stop(sessionId: 'root-session');

      await streamCancelled.future.timeout(const Duration(seconds: 2));
      expect(result['status'], 'ok');
    });

    test('dispose closes all active AgentKit SSE streams', () async {
      final streamCancelled = Completer<void>();
      final source = StreamController<Uint8List>(
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      final sdk = _buildAgentKitLifecycleSdk(source.stream);
      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      await sdk.agentkit.chat(
        Session(sessionId: 'root-session'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
        _LifecycleAgentMessageHandler(),
      );

      await sdk.dispose();

      await streamCancelled.future.timeout(const Duration(seconds: 2));
    });

    test('task-specific stop keeps the session SSE stream active', () async {
      final streamCancelled = Completer<void>();
      final source = StreamController<Uint8List>(
        onCancel: () {
          if (!streamCancelled.isCompleted) streamCancelled.complete();
        },
      );
      final sdk = _buildAgentKitLifecycleSdk(source.stream);
      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      await sdk.agentkit.chat(
        Session(sessionId: 'root-session'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
        _LifecycleAgentMessageHandler(),
      );

      await sdk.agentkit.stop(sessionId: 'root-session', taskId: 'child-task');

      expect(streamCancelled.isCompleted, isFalse);
      await sdk.dispose();
      await streamCancelled.future.timeout(const Duration(seconds: 2));
    });

    test('chat awaits event handlers before notifying done', () async {
      final source = Stream<Uint8List>.value(
        Uint8List.fromList(utf8.encode(_agentKitMessageSse)),
      );
      final sdk = _buildAgentKitLifecycleSdk(source);
      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      final handler = _OrderedAgentMessageHandler();

      await sdk.agentkit.chat(
        Session(sessionId: 'root-session'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
        handler,
      );

      await handler.messageStarted.future.timeout(const Duration(seconds: 2));
      expect(handler.events, <String>['message:start']);
      handler.releaseMessage.complete();
      await handler.done.future.timeout(const Duration(seconds: 2));
      expect(handler.events, <String>['message:start', 'message:end', 'done']);
    });

    test('chat routes asynchronous handler failures to onError', () async {
      final source = Stream<Uint8List>.value(
        Uint8List.fromList(utf8.encode(_agentKitMessageSse)),
      );
      final sdk = _buildAgentKitLifecycleSdk(source);
      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      final handler = _ThrowingAgentMessageHandler();

      await sdk.agentkit.chat(
        Session(sessionId: 'root-session'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
        handler,
      );

      final error = await handler.error.future.timeout(
        const Duration(seconds: 2),
      );
      expect(error.toString(), contains('message handler failed'));
      expect(handler.doneCalled, isFalse);
    });
  });

  group('ToolKitModule', () {
    test('lists tools from /toolkit/list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_ToolKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));
      await sdk.agentos.registerBundle(bundleId: 'com.demo.toolkit');

      final tools = await sdk.toolkit.listTool();

      expect(tools.length, equals(2));
      expect(tools.first.id, equals('tool-weather'));
      expect(tools.first.status, equals('running'));
      expect(tools.first.serverId, equals('server-weather'));
      expect(tools.first.server?.repo, equals('opentool-server-weather'));
      expect(tools.first.server?.name, equals('opentool-server-weather'));
      expect(tools.first.server?.tag, equals('0.1.0'));
      expect(tools[1].alias, equals('calendar'));
      expect(tools[1].server, isNull);
    });

    test('loads tool definition from /toolkit/{toolId}/load', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_ToolKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));
      await sdk.agentos.registerBundle(bundleId: 'com.demo.toolkit');

      final tool = await sdk.toolkit.loadTool('tool-weather');

      expect(tool, isNotNull);
      expect(tool!.opentool, equals('1.0.0'));
      expect(tool.info.title, equals('Weather Tool'));
      expect(tool.server?.url, equals('http://127.0.0.1:9100'));
    });

    test('calls tool function via /toolkit/{toolId}/call', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_ToolKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));
      await sdk.agentos.registerBundle(bundleId: 'com.demo.toolkit');

      final result = await sdk.toolkit.callTool(
        toolId: 'tool-weather',
        functionCall: FunctionCall(
          id: 'call-001',
          name: 'status',
          arguments: <String, dynamic>{'depth': 1},
        ),
      );

      expect(result.id, equals('call-001'));
      expect(result.result['ok'], isTrue);
    });

    test(
      'streams tool function events via /toolkit/{toolId}/streamCall',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
          ..interceptors.add(_ToolKitInterceptor());
        final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));
        await sdk.agentos.registerBundle(bundleId: 'com.demo.toolkit');

        final events = await (await sdk.toolkit.streamCallTool(
          toolId: 'tool-weather',
          functionCall: FunctionCall(
            id: 'call-002',
            name: 'status',
            arguments: <String, dynamic>{'depth': 2},
          ),
        )).toList();

        expect(
          events.map((event) => event.event),
          equals(<String>['START', 'DATA', 'DONE']),
        );
        expect(events[1].data['ok'], isTrue);
      },
    );
  });

  group('AppKitClient', () {
    test('registers bundle and subscribes to SSE events', () async {
      final interceptor = _AppKitInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(interceptor);
      final client = AppKitClient(apiClient: ApiClient(dio: dio));

      final token = await client.registerBundle(
        bundleId: 'com.demo.app',
        appGroupId: 'com.demo.group',
      );
      expect(token.token, equals('sk-demo'));
      expect(token.bundleId, equals('com.demo.app'));
      expect(token.appGroupId, equals('com.demo.group'));
      expect(interceptor.lastBundleId, equals('com.demo.app'));
      expect(interceptor.lastAppGroupId, equals('com.demo.group'));

      final events = await (await client.subscribe(
        bearerToken: token.token,
      )).toList();

      expect(events, isNotEmpty);
      expect(
        events.map((e) => e.agentosEventType),
        containsAll(<String>['welcome', 'callApp']),
      );
      expect(events.first.data, contains('bundleId'));
    });
  });

  group('CronKitClient', () {
    test('manages cron tasks and runs through sdk module', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_CronKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));

      final registration = await sdk.agentos.registerBundle(
        bundleId: 'com.demo.app',
        appGroupId: 'com.demo.group',
      );
      expect(registration.token, equals('sk-demo'));

      final created = await sdk.cronkit.createTask(
        request: CronTaskCreateRequest(
          name: 'daily-report',
          schedule: '0 9 * * *',
          timezone: 'Asia/Shanghai',
          spec: CronSpec(
            systemPrompt: 'system',
            content: <Content>[
              Content(type: ContentType.text, message: 'prompt'),
            ],
            modelId: 'gpt-4o',
          ),
        ),
      );
      expect(created.cronId, equals('cron-1'));
      expect(created.spec.content.single.message, equals('prompt'));
      expect(created.spec.modelId, equals('gpt-4o'));
      expect(created.spec.modelName, equals('gpt-4o'));

      final listed = await sdk.cronkit.listTasks(enabled: true, limit: 10);
      expect(listed, hasLength(1));
      expect(listed.first.cronId, equals('cron-1'));
      expect(listed.first.spec, isNotNull);
      expect(listed.first.spec!.modelId, equals('gpt-4o'));
      expect(listed.first.spec!.modelName, equals('gpt-4o'));

      final fetched = await sdk.cronkit.getTask(cronId: 'cron-1');
      expect(fetched.name, equals('daily-report'));
      expect(fetched.spec.modelId, equals('gpt-4o'));
      expect(fetched.spec.modelName, equals('gpt-4o'));

      final updated = await sdk.cronkit.updateTask(
        request: CronTaskUpdateRequest(
          cronId: 'cron-1',
          enabled: false,
          timezone: 'UTC',
        ),
      );
      expect(updated.enabled, isFalse);
      expect(updated.timezone, equals('UTC'));

      final disabled = await sdk.cronkit.disableTask(cronId: 'cron-1');
      expect(disabled.enabled, isFalse);
      expect(disabled.status, equals('paused'));

      final enabled = await sdk.cronkit.enableTask(cronId: 'cron-1');
      expect(enabled.enabled, isTrue);
      expect(enabled.status, equals('active'));

      final run = await sdk.cronkit.runTaskNow(
        cronId: 'cron-1',
        scheduledAt: DateTime.utc(2026, 1, 1, 1, 2, 3),
      );
      expect(run.runId, equals('run-1'));
      expect(run.cronId, equals('cron-1'));
      expect(run.trigger, equals('manual'));
      expect(run.modelId, equals('gpt-4o'));
      expect(run.hasDisplayableResult, isTrue);
      expect(run.displayMessageId, equals('msg-1'));
      expect(run.displayText, equals('Daily report ready'));

      final runDetail = await sdk.cronkit.getRun(runId: 'run-1');
      expect(runDetail.status, equals('success'));
      expect(runDetail.trigger, equals('scheduler'));
      expect(runDetail.modelId, equals('gpt-4o-mini'));
      expect(runDetail.hasDisplayableResult, isTrue);

      final runs = await sdk.cronkit.listRuns(cronId: 'cron-1', limit: 5);
      expect(runs, hasLength(1));
      expect(runs.first.runId, equals('run-1'));
      expect(runs.first.trigger, equals('scheduler'));
      expect(runs.first.modelId, equals('gpt-4o-mini'));
      expect(runs.first.hasDisplayableResult, isTrue);
      expect(runs.first.displayText, equals('Daily report ready'));

      final runMessages = await sdk.cronkit.listRunMessages(
        runId: 'run-1',
        limit: 10,
      );
      expect(runMessages, hasLength(1));
      expect(runMessages.first.message.content, equals('done'));

      final deletedRun = await sdk.cronkit.deleteRun(runId: 'run-1');
      expect(deletedRun.deleted, isTrue);
      expect(deletedRun.runId, equals('run-1'));

      final deleted = await sdk.cronkit.deleteTask(cronId: 'cron-1');
      expect(deleted.deleted, isTrue);
      expect(deleted.cronId, equals('cron-1'));
    });

    test('supports direct cronkit client usage', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_CronKitInterceptor());
      final client = CronKitClient(apiClient: ApiClient(dio: dio));

      final tasks = await client.listTasks(
        bearerToken: 'sk-demo',
        enabled: true,
      );

      expect(tasks, hasLength(1));
      expect(tasks.first.name, equals('daily-report'));
    });
  });

  group('AgentOSSDK app auth recovery', () {
    test('re-registers and retries agentkit request after 401', () async {
      final interceptor = _AppAuthRecoveryInterceptor();
      final sdk = AgentOSSDK(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
            ..interceptors.add(interceptor),
        ),
      );

      await sdk.agentos.registerBundle(
        bundleId: 'com.demo.app',
        appGroupId: 'group-a',
      );

      final session = await sdk.agentkit.initSession();

      expect(session['sessionId'], equals('sess-recovered'));
      expect(
        interceptor.registerCountFor('com.demo.app', 'group-a'),
        equals(2),
      );
      expect(
        interceptor.tokensUsedFor('/agentkit/initSession'),
        equals(<String>['token-group-a-v1', 'token-group-a-v2']),
      );
    });

    test(
      're-registers and retries cronkit request after invalid app token text',
      () async {
        final interceptor = _AppAuthRecoveryInterceptor();
        final sdk = AgentOSSDK(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
              ..interceptors.add(interceptor),
          ),
        );

        await sdk.agentos.registerBundle(
          bundleId: 'com.demo.app',
          appGroupId: 'group-a',
        );

        final tasks = await sdk.cronkit.listTasks(limit: 10);

        expect(tasks, hasLength(1));
        expect(
          interceptor.registerCountFor('com.demo.app', 'group-a'),
          equals(2),
        );
        expect(
          interceptor.tokensUsedFor('/cronkit/task/list'),
          equals(<String>['token-group-a-v1', 'token-group-a-v2']),
        );
        expect(
          interceptor.registerRequestsFor('com.demo.app', 'group-a'),
          equals(<String>['com.demo.app::group-a', 'com.demo.app::group-a']),
        );
      },
    );

    test('deduplicates concurrent refresh for the same app auth key', () async {
      final interceptor = _AppAuthRecoveryInterceptor();
      final sdk = AgentOSSDK(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
            ..interceptors.add(interceptor),
        ),
      );

      await sdk.agentos.registerBundle(
        bundleId: 'com.demo.app',
        appGroupId: 'group-a',
      );

      final results = await Future.wait(<Future<dynamic>>[
        sdk.cronkit.listTasks(limit: 10),
        sdk.cronkit.getTask(cronId: 'cron-1'),
        sdk.agentkit.initSession(),
      ]);

      expect(results, hasLength(3));
      expect(
        interceptor.registerCountFor('com.demo.app', 'group-a'),
        equals(2),
      );
    });

    test('does not mix tokens across different appGroupId values', () async {
      final interceptor = _AppAuthRecoveryInterceptor();
      final sdk = AgentOSSDK(
        apiClient: ApiClient(
          dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
            ..interceptors.add(interceptor),
        ),
      );

      await sdk.agentos.registerBundle(
        bundleId: 'com.demo.app',
        appGroupId: 'group-a',
      );
      await sdk.agentos.registerBundle(
        bundleId: 'com.demo.app',
        appGroupId: 'group-b',
      );

      final tasks = await sdk.cronkit.listTasks(limit: 10);

      expect(tasks, hasLength(1));
      expect(
        interceptor.registerCountFor('com.demo.app', 'group-a'),
        equals(1),
      );
      expect(
        interceptor.registerCountFor('com.demo.app', 'group-b'),
        equals(2),
      );
      expect(
        interceptor.tokensUsedFor('/cronkit/task/list'),
        equals(<String>['token-group-b-v1', 'token-group-b-v2']),
      );
    });

    test(
      'shares refreshed token across cronkit, agentkit, and subscribe',
      () async {
        final interceptor = _AppAuthRecoveryInterceptor();
        final sdk = AgentOSSDK(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://fake.local'))
              ..interceptors.add(interceptor),
          ),
        );

        await sdk.agentos.registerBundle(
          bundleId: 'com.demo.app',
          appGroupId: 'group-a',
        );

        final tasks = await sdk.cronkit.listTasks(limit: 10);
        expect(tasks, hasLength(1));

        final session = await sdk.agentkit.initSession();
        expect(session['sessionId'], equals('sess-recovered'));

        final handler = _CountingEventHandler();
        await sdk.agentos.subscribe(handler);
        await handler.firstWelcome.future.timeout(const Duration(seconds: 2));

        expect(
          interceptor.registerCountFor('com.demo.app', 'group-a'),
          equals(2),
        );
        expect(
          interceptor.tokensUsedFor('/agentkit/initSession'),
          equals(<String>['token-group-a-v2']),
        );
        expect(
          interceptor.tokensUsedFor('/appkit/subscribe'),
          equals(<String>['token-group-a-v2']),
        );
      },
    );
  });

  group('RagKitClient', () {
    test(
      'manages rag bases, documents, sync, and query through sdk module',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
          ..interceptors.add(_RagKitInterceptor());
        final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));

        final registration = await sdk.agentos.registerBundle(
          bundleId: 'com.demo.app',
          appGroupId: 'com.demo.group',
        );
        expect(registration.token, equals('sk-demo'));

        final createdBase = await sdk.ragkit.createBase(
          request: RagBaseCreateRequest(
            baseId: 'product-docs',
            name: 'Product Docs',
            metadata: <String, dynamic>{'domain': 'docs'},
          ),
        );
        expect(createdBase.id, equals('product-docs'));

        final bases = await sdk.ragkit.listBases(limit: 10);
        expect(bases, hasLength(1));
        expect(bases.first.name, equals('Product Docs'));

        final base = await sdk.ragkit.getBase(baseId: 'product-docs');
        expect(base.docsName, equals('docs_product_docs'));

        final updatedBase = await sdk.ragkit.updateBase(
          request: RagBaseUpdateRequest(
            baseId: 'product-docs',
            name: 'Product Docs v2',
          ),
        );
        expect(updatedBase.name, equals('Product Docs v2'));

        final upsertedDocument = await sdk.ragkit.upsertDocument(
          request: RagUpsertDocumentRequest(
            baseId: 'product-docs',
            documentId: 'intro',
            title: 'Introduction',
            markdown: '# Intro',
          ),
        );
        expect(upsertedDocument.id, equals('intro'));
        expect(upsertedDocument.syncStatus, equals('synced'));

        final batch = await sdk.ragkit.upsertDocuments(
          request: RagUpsertDocumentsRequest(
            baseId: 'product-docs',
            sync: false,
            documents: <RagMarkdownDocumentInput>[
              RagMarkdownDocumentInput(
                documentId: 'faq',
                title: 'FAQ',
                markdown: '# FAQ',
              ),
            ],
          ),
        );
        expect(batch.successCount, equals(1));

        final documents = await sdk.ragkit.listDocuments(
          baseId: 'product-docs',
          limit: 10,
        );
        expect(documents, hasLength(1));
        expect(documents.first.id, equals('intro'));

        final document = await sdk.ragkit.getDocument(
          baseId: 'product-docs',
          documentId: 'intro',
        );
        expect(document.contentHash, equals('hash-1'));

        final syncResult = await sdk.ragkit.syncDocument(
          baseId: 'product-docs',
          documentId: 'intro',
        );
        expect(syncResult.syncStatus, equals('synced'));

        final syncBase = await sdk.ragkit.syncBase(baseId: 'product-docs');
        expect(syncBase.totalCount, equals(1));

        final retryFailed = await sdk.ragkit.retryFailed(
          baseId: 'product-docs',
        );
        expect(retryFailed.failedCount, equals(0));

        final query = await sdk.ragkit.query(
          request: RagQueryRequest(
            baseId: 'product-docs',
            query: 'How do I ingest markdown?',
            limit: 5,
          ),
        );
        expect(query.hits, hasLength(1));
        expect(query.hits.first.documentId, equals('intro'));
        expect(query.hits.first.segments.first.headingPath, equals('Intro'));

        final deletedDocument = await sdk.ragkit.deleteDocument(
          baseId: 'product-docs',
          documentId: 'intro',
        );
        expect(deletedDocument.deleted, isTrue);

        final deletedBase = await sdk.ragkit.deleteBase(baseId: 'product-docs');
        expect(deletedBase.deleted, isTrue);
      },
    );

    test('supports direct ragkit client usage', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_RagKitInterceptor());
      final client = RagKitClient(apiClient: ApiClient(dio: dio));

      final result = await client.query(
        bearerToken: 'sk-demo',
        request: RagQueryRequest(baseId: 'product-docs', query: 'markdown'),
      );

      expect(result.baseId, equals('product-docs'));
      expect(result.hits.single.title, equals('Introduction'));
    });
  });
}

class _VersionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/version') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'version': '1.2.3'},
        ),
      );
      return;
    }
    if (options.path == '/ready') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'ready': true,
            'liteAgentReady': true,
            'llmConfigured': true,
          },
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

class _CaptureBaseUrlInterceptor extends Interceptor {
  String? lastBaseUrl;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastBaseUrl = options.baseUrl;
    if (options.path == '/version') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'version': '1.2.3'},
        ),
      );
      return;
    }
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

class _CaptureOptionsInterceptor extends Interceptor {
  String? lastBaseUrl;
  Duration? lastConnectTimeout;
  Duration? lastReceiveTimeout;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastBaseUrl = options.baseUrl;
    lastConnectTimeout = options.connectTimeout;
    lastReceiveTimeout = options.receiveTimeout;
    if (options.path == '/version') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'version': '1.2.3'},
        ),
      );
      return;
    }
    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

class _ConnectionEventRecorder {
  _ConnectionEventRecorder(Stream<AgentOSSubscribeConnectionEvent> stream) {
    _subscription = stream.listen((event) => _events.add(event));
  }

  final List<AgentOSSubscribeConnectionEvent> _events =
      <AgentOSSubscribeConnectionEvent>[];
  late final StreamSubscription<AgentOSSubscribeConnectionEvent> _subscription;

  List<AgentOSSubscribeConnectionStatus> get statuses =>
      _events.map((event) => event.status).toList(growable: false);

  Future<void> waitForCount(int count) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (_events.length < count) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for $count connection events, got $_events');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> dispose() => _subscription.cancel();
}

enum _SubscribePlanType { stream, unauthorized, networkError }

class _SubscribePlan {
  const _SubscribePlan.stream()
    : type = _SubscribePlanType.stream,
      emitWelcome = true,
      message = null;

  const _SubscribePlan.unauthorized()
    : type = _SubscribePlanType.unauthorized,
      emitWelcome = false,
      message = 'invalid app token';

  const _SubscribePlan.networkError()
    : type = _SubscribePlanType.networkError,
      emitWelcome = false,
      message = 'socket closed';

  final _SubscribePlanType type;
  final bool emitWelcome;
  final String? message;
}

class _ScriptedAppKitInterceptor extends Interceptor {
  _ScriptedAppKitInterceptor({required this.subscribePlans});

  final List<_SubscribePlan> subscribePlans;
  final List<StreamController<Uint8List>> _controllers =
      <StreamController<Uint8List>>[];
  final List<String> subscribeTokens = <String>[];
  int registerCount = 0;
  int _subscribeRequestIndex = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      registerCount += 1;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'token': 'token-v$registerCount'},
        ),
      );
      return;
    }

    if (options.path != '/appkit/subscribe') {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 404,
            data: 'Unhandled path ${options.path}',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    final bearer = (options.headers[HttpHeaders.authorizationHeader] ?? '')
        .toString();
    final token = bearer.startsWith('Bearer ')
        ? bearer.substring('Bearer '.length)
        : '';
    subscribeTokens.add(token);

    final plan = subscribePlans[_subscribeRequestIndex];
    _subscribeRequestIndex += 1;
    switch (plan.type) {
      case _SubscribePlanType.stream:
        final controller = StreamController<Uint8List>();
        _controllers.add(controller);
        if (plan.emitWelcome) {
          scheduleMicrotask(() {
            if (!controller.isClosed) {
              controller.add(
                Uint8List.fromList(
                  utf8.encode('event: welcome\ndata: {"bundleId":"demo"}\n\n'),
                ),
              );
            }
          });
        }
        handler.resolve(
          Response<ResponseBody>(
            requestOptions: options,
            statusCode: 200,
            data: ResponseBody(
              controller.stream,
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['text/event-stream'],
              },
            ),
          ),
        );
        return;
      case _SubscribePlanType.unauthorized:
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: <String, dynamic>{'error': plan.message},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      case _SubscribePlanType.networkError:
        handler.reject(
          DioException(
            requestOptions: options,
            message: plan.message,
            type: DioExceptionType.connectionError,
          ),
        );
        return;
    }
  }

  Future<void> closeStream(int index) async {
    await _controllers[index].close();
  }

  Future<void> dispose() async {
    for (final controller in _controllers) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }
}

class _DelayedAppKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'token': 'sk-demo'},
        ),
      );
      return;
    }

    if (options.path == '/appkit/subscribe') {
      final stream = _delayedSseStream();
      final body = ResponseBody(
        stream,
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['text/event-stream'],
        },
      );
      handler.resolve(
        Response<ResponseBody>(
          requestOptions: options,
          statusCode: 200,
          data: body,
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  Stream<Uint8List> _delayedSseStream() async* {
    yield Uint8List.fromList(
      utf8.encode('event: welcome\ndata: {"bundleId":"demo"}\n\n'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    yield Uint8List.fromList(
      utf8.encode(
        'event: callApp\n'
        'data: {"bundleId":"com.demo.app","contentList":[{"type":"text","message":"ping"}]}\n\n',
      ),
    );
  }
}

class _CountingEventHandler extends AgentOSEventHandler {
  int welcomeCount = 0;
  int callAppCount = 0;
  final Completer<void> firstWelcome = Completer<void>();

  @override
  Future<void> onWelcome(Welcome welcome) async {
    welcomeCount += 1;
    if (!firstWelcome.isCompleted) {
      firstWelcome.complete();
    }
  }

  @override
  Future<void> onCallApp(Call call) async {
    callAppCount += 1;
  }

  @override
  Future<void> onDone() async {}

  @override
  Future<void> onError(Exception error) async {}
}

const String _agentKitMessageSse =
    'event: message\n'
    'data: {"sessionId":"child-session","originalTaskId":"root-task","taskId":"child-task","role":"agent","to":"user","type":"text","content":"done","createTime":"2026-07-14T10:00:00.000Z"}\n'
    '\n';

AgentOSSDK _buildAgentKitLifecycleSdk(Stream<Uint8List> chatStream) {
  final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
    ..interceptors.add(_AgentKitLifecycleInterceptor(chatStream));
  return AgentOSSDK(apiClient: ApiClient(dio: dio));
}

class _AgentKitLifecycleInterceptor extends Interceptor {
  _AgentKitLifecycleInterceptor(this.chatStream);

  final Stream<Uint8List> chatStream;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'token': 'sk-demo'},
        ),
      );
      return;
    }

    if (options.path == '/agentkit/chat') {
      handler.resolve(
        Response<ResponseBody>(
          requestOptions: options,
          statusCode: 200,
          data: ResponseBody(
            chatStream,
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>['text/event-stream'],
            },
          ),
        ),
      );
      return;
    }

    if (options.path == '/agentkit/stop') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'status': 'ok'},
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

class _LifecycleAgentMessageHandler extends AgentMessageHandler {
  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {}

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {}

  @override
  Future<void> onDone() async {}

  @override
  Future<void> onError(Exception error) async {}
}

class _OrderedAgentMessageHandler extends _LifecycleAgentMessageHandler {
  final List<String> events = <String>[];
  final Completer<void> messageStarted = Completer<void>();
  final Completer<void> releaseMessage = Completer<void>();
  final Completer<void> done = Completer<void>();

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {
    events.add('message:start');
    messageStarted.complete();
    await releaseMessage.future;
    events.add('message:end');
  }

  @override
  Future<void> onDone() async {
    events.add('done');
    done.complete();
  }
}

class _ThrowingAgentMessageHandler extends _LifecycleAgentMessageHandler {
  final Completer<Exception> error = Completer<Exception>();
  bool doneCalled = false;

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {
    throw StateError('message handler failed');
  }

  @override
  Future<void> onDone() async {
    doneCalled = true;
  }

  @override
  Future<void> onError(Exception error) async {
    if (!this.error.isCompleted) this.error.complete(error);
  }
}

class _AgentKitInterceptor extends Interceptor {
  int? historyPage;
  int? historyPageSize;
  Map<String, dynamic>? historySummaryQuery;
  Map<String, dynamic>? historyProcessQuery;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'token': 'sk-demo'},
        ),
      );
      return;
    }

    final bearer = (options.headers[HttpHeaders.authorizationHeader] ?? '')
        .toString();
    if (!bearer.startsWith('Bearer ')) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: 'Missing bearer',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (options.path == '/agentkit/agent/create') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'agentId': 'agent-abc'},
        ),
      );
      return;
    }

    if (options.path == '/agentkit/initSession') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'sessionId': 'sess-123'},
        ),
      );
      return;
    }

    if (options.path == '/agentkit/chat/simple') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'sessionId': 'sess-123', 'content': 'hello'},
        ),
      );
      return;
    }

    if (options.path == '/agentkit/history') {
      historyPage = options.queryParameters['page'] as int?;
      historyPageSize = options.queryParameters['pageSize'] as int?;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'sessionId': 'sess-123',
              'originalTaskId': 'root-task',
              'parentTaskId': 'root-task',
              'taskId': 'child-task',
              'role': 'agent',
              'to': 'user',
              'type': 'text',
              'content': 'done',
              'createTime': DateTime.utc(2026, 7, 10).toIso8601String(),
            },
          ],
        ),
      );
      return;
    }

    if (options.path == '/agentkit/history/summary') {
      historySummaryQuery = Map<String, dynamic>.from(options.queryParameters);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'originalTaskId': 'root-task',
              'sessionId': 'root-session',
              'userMessage': <String, dynamic>{
                'sessionId': 'root-session',
                'originalTaskId': 'root-task',
                'taskId': 'root-task',
                'role': 'user',
                'to': 'agent',
                'type': 'text',
                'content': 'hello',
                'createTime': '2026-07-12T10:00:00.000Z',
              },
              'finalMessage': null,
              'status': 'done',
              'error': null,
              'createdAt': '2026-07-12T10:00:00.000Z',
              'completedAt': '2026-07-12T10:00:05.000Z',
              'durationMs': 5000,
              'usage': <String, dynamic>{
                'promptTokens': 10,
                'completionTokens': 2,
                'totalTokens': 12,
              },
              'processMessageCount': 4,
            },
          ],
        ),
      );
      return;
    }

    if (options.path == '/agentkit/history/process') {
      historyProcessQuery = Map<String, dynamic>.from(options.queryParameters);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'sessionId': 'child-session',
              'originalTaskId': 'root-task',
              'parentTaskId': 'root-task',
              'taskId': 'child-task',
              'role': 'agent',
              'to': 'user',
              'type': 'reasoning',
              'content': 'working',
              'createTime': '2026-07-12T10:00:01.000Z',
            },
          ],
        ),
      );
      return;
    }

    if (options.path == '/agentkit/chat') {
      final body = ResponseBody.fromString(
        'event: agentmessage\n'
        'data: {"content":"hello"}\n'
        '\n'
        'event: agentmessagechunk\n'
        'data: {"content":"he"}\n'
        '\n'
        'event: functionCall\n'
        'data: {"sessionId":"sess-123","functionCall":{"id":"call-1","name":"demo_tool","arguments":{"query":"ping"}}}\n'
        '\n',
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['text/event-stream'],
        },
      );
      handler.resolve(
        Response<ResponseBody>(
          requestOptions: options,
          statusCode: 200,
          data: body,
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

class _AppKitInterceptor extends Interceptor {
  String? lastBundleId;
  String? lastAppGroupId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      final payload = options.data as Map<String, dynamic>;
      lastBundleId = payload['bundleId']?.toString();
      lastAppGroupId = payload['appGroupId']?.toString();
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: lastBundleId?.isEmpty ?? true ? 400 : 200,
          data: <String, String>{
            'token': 'sk-demo',
            'bundleId': lastBundleId ?? '',
            'appGroupId': lastAppGroupId ?? lastBundleId ?? '',
          },
        ),
      );
      return;
    }

    final bearer = (options.headers[HttpHeaders.authorizationHeader] ?? '')
        .toString();
    if (!bearer.startsWith('Bearer ')) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: 'Missing bearer',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (options.path == '/appkit/subscribe') {
      final body = ResponseBody.fromString(
        'event: welcome\n'
        'data: {"bundleId":"demo"}\n'
        '\n'
        'event: callApp\n'
        'data: {"bundleId":"com.demo.app","contentList":[{"type":"text","message":"ping"}]}\n'
        '\n',
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['text/event-stream'],
        },
      );
      handler.resolve(
        Response<ResponseBody>(
          requestOptions: options,
          statusCode: 200,
          data: body,
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}

class _CronKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      final payload = options.data as Map<String, dynamic>;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{
            'token': 'sk-demo',
            'bundleId': payload['bundleId']?.toString() ?? '',
            'appGroupId':
                payload['appGroupId']?.toString() ??
                payload['bundleId']?.toString() ??
                '',
          },
        ),
      );
      return;
    }

    final bearer = (options.headers[HttpHeaders.authorizationHeader] ?? '')
        .toString();
    if (!bearer.startsWith('Bearer ')) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: 'Missing bearer',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (options.path == '/cronkit/task/create') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['name'], equals('daily-report'));
      expect(payload['schedule'], equals('0 9 * * *'));
      expect(payload['timezone'], equals('Asia/Shanghai'));
      expect(payload['spec']['systemPrompt'], equals('system'));
      expect(payload['spec']['content'], isA<List<dynamic>>());
      expect(payload['spec']['modelId'], equals('gpt-4o'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _cronTaskJson(),
        ),
      );
      return;
    }

    if (options.path == '/cronkit/task/list') {
      expect(options.queryParameters['enabled'], isTrue);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[_cronTaskListItemJson()],
        ),
      );
      return;
    }

    if (options.path == '/cronkit/task') {
      expect(options.queryParameters['cronId'], equals('cron-1'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _cronTaskJson(),
        ),
      );
      return;
    }

    if (options.path == '/cronkit/task/update') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['cronId'], equals('cron-1'));
      expect(payload['enabled'], isFalse);
      expect(payload['timezone'], equals('UTC'));
      final data = _cronTaskJson()
        ..['enabled'] = false
        ..['timezone'] = 'UTC';
      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: data),
      );
      return;
    }

    if (options.path == '/cronkit/task/setEnabled') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['cronId'], equals('cron-1'));
      expect(payload['enabled'], isA<bool>());
      final enabled = payload['enabled'] as bool;
      final data = _cronTaskJson()
        ..['enabled'] = enabled
        ..['status'] = enabled ? 'active' : 'paused';
      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: data),
      );
      return;
    }

    if (options.path == '/cronkit/task/runNow') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['cronId'], equals('cron-1'));
      expect(
        payload['scheduledAt'],
        equals(DateTime.utc(2026, 1, 1, 1, 2, 3).toIso8601String()),
      );
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'runId': 'run-1',
            'cronId': 'cron-1',
            'trigger': 'manual',
            'status': 'success',
            'modelId': 'gpt-4o',
            'scheduledAt': DateTime.utc(2026, 1, 1, 1).toIso8601String(),
            'startedAt': DateTime.utc(2026, 1, 1, 1, 0, 1).toIso8601String(),
            'hasDisplayableResult': true,
            'finishedAt': DateTime.utc(2026, 1, 1, 1, 0, 2).toIso8601String(),
            'liteAgentSessionId': 'session-1',
            'result': <String, dynamic>{'ok': true},
            'displayMessageId': 'msg-1',
            'displayText': 'Daily report ready',
          },
        ),
      );
      return;
    }

    if (options.path == '/cronkit/run') {
      expect(options.queryParameters['runId'], equals('run-1'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'runId': 'run-1',
            'cronId': 'cron-1',
            'trigger': 'scheduler',
            'status': 'success',
            'modelId': 'gpt-4o-mini',
            'scheduledAt': DateTime.utc(2026, 1, 1, 1).toIso8601String(),
            'startedAt': DateTime.utc(2026, 1, 1, 1, 0, 1).toIso8601String(),
            'hasDisplayableResult': true,
            'finishedAt': DateTime.utc(2026, 1, 1, 1, 0, 2).toIso8601String(),
            'liteAgentSessionId': 'session-1',
            'result': <String, dynamic>{'ok': true},
            'displayMessageId': 'msg-1',
            'displayText': 'Daily report ready',
          },
        ),
      );
      return;
    }

    if (options.path == '/cronkit/run/list') {
      expect(options.queryParameters['cronId'], equals('cron-1'));
      expect(options.queryParameters['limit'], equals(5));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'runId': 'run-1',
              'cronId': 'cron-1',
              'trigger': 'scheduler',
              'status': 'success',
              'modelId': 'gpt-4o-mini',
              'scheduledAt': DateTime.utc(2026, 1, 1, 1).toIso8601String(),
              'startedAt': DateTime.utc(2026, 1, 1, 1, 0, 1).toIso8601String(),
              'hasDisplayableResult': true,
              'finishedAt': DateTime.utc(2026, 1, 1, 1, 0, 2).toIso8601String(),
              'displayText': 'Daily report ready',
            },
          ],
        ),
      );
      return;
    }

    if (options.path == '/cronkit/run/messages') {
      expect(options.queryParameters['runId'], equals('run-1'));
      expect(options.queryParameters['limit'], equals(10));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'messageId': 'msg-1',
              'runId': 'run-1',
              'cronId': 'cron-1',
              'timestamp': DateTime.utc(2026, 1, 1, 1, 0, 1).toIso8601String(),
              'message': <String, dynamic>{
                'sessionId': 'session-1',
                'taskId': 'task-1',
                'role': 'assistant',
                'to': 'user',
                'type': 'text',
                'content': 'done',
                'createTime': DateTime.utc(
                  2026,
                  1,
                  1,
                  1,
                  0,
                  1,
                ).toIso8601String(),
              },
            },
          ],
        ),
      );
      return;
    }

    if (options.path == '/cronkit/run/delete') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['runId'], equals('run-1'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'deleted': true, 'runId': 'run-1'},
        ),
      );
      return;
    }

    if (options.path == '/cronkit/task/delete') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['cronId'], equals('cron-1'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'deleted': true, 'cronId': 'cron-1'},
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  Map<String, dynamic> _cronTaskJson() => <String, dynamic>{
    'cronId': 'cron-1',
    'name': 'daily-report',
    'schedule': '0 9 * * *',
    'source': 'appkit|owner=com.demo.app|group=com.demo.group',
    'userId': 'user-1',
    'sessionId': 'session-1',
    'timezone': 'Asia/Shanghai',
    'enabled': true,
    'status': 'active',
    'concurrency': 'skipIfRunning',
    'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
    'updatedAt': DateTime.utc(2026, 1, 1, 0, 1).toIso8601String(),
    'lastRunAt': DateTime.utc(2026, 1, 1, 8).toIso8601String(),
    'nextRunAt': DateTime.utc(2026, 1, 2, 9).toIso8601String(),
    'spec': <String, dynamic>{
      'systemPrompt': 'system',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'text', 'message': 'prompt'},
      ],
      'timeoutSeconds': 3600,
      'modelId': 'gpt-4o',
      'modelName': 'gpt-4o',
    },
  };

  Map<String, dynamic> _cronTaskListItemJson() => <String, dynamic>{
    'cronId': 'cron-1',
    'name': 'daily-report',
    'schedule': '0 9 * * *',
    'enabled': true,
    'status': 'active',
    'spec': <String, dynamic>{
      'systemPrompt': 'system',
      'content': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'text', 'message': 'prompt'},
      ],
      'timeoutSeconds': 3600,
      'modelId': 'gpt-4o',
      'modelName': 'gpt-4o',
    },
    'lastRunAt': DateTime.utc(2026, 1, 1, 8).toIso8601String(),
    'nextRunAt': DateTime.utc(2026, 1, 2, 9).toIso8601String(),
  };
}

class _AppAuthRecoveryInterceptor extends Interceptor {
  final Map<String, int> _registerCounts = <String, int>{};
  final Map<String, List<String>> _registerRequests = <String, List<String>>{};
  final Map<String, List<String>> _tokensByPath = <String, List<String>>{};
  final Set<String> _failedTokens = <String>{};

  int registerCountFor(String bundleId, String? appGroupId) {
    return _registerCounts[_key(bundleId, appGroupId)] ?? 0;
  }

  List<String> tokensUsedFor(String path) {
    return List<String>.from(_tokensByPath[path] ?? const <String>[]);
  }

  List<String> registerRequestsFor(String bundleId, String? appGroupId) {
    return List<String>.from(
      _registerRequests[_key(bundleId, appGroupId)] ?? const <String>[],
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      final payload = Map<String, dynamic>.from(options.data as Map);
      final bundleId = payload['bundleId']?.toString() ?? '';
      final appGroupId = payload['appGroupId']?.toString();
      final key = _key(bundleId, appGroupId);
      _registerRequests
          .putIfAbsent(key, () => <String>[])
          .add('$bundleId::${appGroupId ?? '<null>'}');
      final count = (_registerCounts[key] ?? 0) + 1;
      _registerCounts[key] = count;
      final groupSegment = appGroupId ?? 'default';
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{
            'token': 'token-$groupSegment-v$count',
            'bundleId': bundleId,
            if (appGroupId != null) 'appGroupId': appGroupId,
          },
        ),
      );
      return;
    }

    final bearer = (options.headers[HttpHeaders.authorizationHeader] ?? '')
        .toString();
    if (!bearer.startsWith('Bearer ')) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: 'Missing bearer',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    final token = bearer.substring('Bearer '.length);
    _tokensByPath.putIfAbsent(options.path, () => <String>[]).add(token);

    if (_shouldFailOnce(token)) {
      if (options.path.startsWith('/agentkit/')) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: <String, dynamic>{'error': 'invalid app token'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }
      if (options.path.startsWith('/cronkit/')) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 500,
              data: 'invalid app token',
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }
    }

    if (options.path == '/agentkit/initSession') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{'sessionId': 'sess-recovered'},
        ),
      );
      return;
    }

    if (options.path == '/appkit/subscribe') {
      final body = ResponseBody.fromString(
        'event: welcome\n'
        'data: {"bundleId":"demo"}\n'
        '\n',
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['text/event-stream'],
        },
      );
      handler.resolve(
        Response<ResponseBody>(
          requestOptions: options,
          statusCode: 200,
          data: body,
        ),
      );
      return;
    }

    if (options.path == '/cronkit/task/list') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'cronId': 'cron-1',
              'name': 'daily-report',
              'schedule': '0 9 * * *',
              'enabled': true,
              'status': 'active',
            },
          ],
        ),
      );
      return;
    }

    if (options.path == '/cronkit/task') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'cronId': 'cron-1',
            'name': 'daily-report',
            'schedule': '0 9 * * *',
            'source': 'appkit|owner=com.demo.app|group=recovered',
            'timezone': 'Asia/Shanghai',
            'enabled': true,
            'status': 'active',
            'concurrency': 'skipIfRunning',
            'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
            'updatedAt': DateTime.utc(2026, 1, 1, 0, 1).toIso8601String(),
            'spec': <String, dynamic>{
              'systemPrompt': 'system',
              'content': <Map<String, dynamic>>[
                <String, dynamic>{'type': 'text', 'message': 'prompt'},
              ],
            },
          },
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  bool _shouldFailOnce(String token) {
    return token.endsWith('-v1') && _failedTokens.add(token);
  }

  String _key(String bundleId, String? appGroupId) {
    return '$bundleId::${appGroupId ?? '<null>'}';
  }
}

class _RagKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      final payload = options.data as Map<String, dynamic>;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, String>{
            'token': 'sk-demo',
            'bundleId': payload['bundleId']?.toString() ?? '',
            'appGroupId':
                payload['appGroupId']?.toString() ??
                payload['bundleId']?.toString() ??
                '',
          },
        ),
      );
      return;
    }

    final bearer = (options.headers[HttpHeaders.authorizationHeader] ?? '')
        .toString();
    if (options.path.startsWith('/ragkit/') &&
        !bearer.startsWith('Bearer sk-demo')) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: 'Missing bearer',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (options.path == '/ragkit/base/create') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['baseId'], equals('product-docs'));
      expect(payload['name'], equals('Product Docs'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragBaseJson(),
        ),
      );
      return;
    }

    if (options.path == '/ragkit/base/list') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[_ragBaseListItemJson()],
        ),
      );
      return;
    }

    if (options.path == '/ragkit/base') {
      expect(options.queryParameters['baseId'], equals('product-docs'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragBaseJson(),
        ),
      );
      return;
    }

    if (options.path == '/ragkit/base/update') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['baseId'], equals('product-docs'));
      final data = _ragBaseJson()..['name'] = 'Product Docs v2';
      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: data),
      );
      return;
    }

    if (options.path == '/ragkit/base/delete') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['baseId'], equals('product-docs'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'deleted': true, 'baseId': 'product-docs'},
        ),
      );
      return;
    }

    if (options.path == '/ragkit/document/upsert') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['baseId'], equals('product-docs'));
      expect(payload['documentId'], equals('intro'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragDocumentJson(),
        ),
      );
      return;
    }

    if (options.path == '/ragkit/document/upsertBatch') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['baseId'], equals('product-docs'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragBatchResultJson(),
        ),
      );
      return;
    }

    if (options.path == '/ragkit/document/list') {
      expect(options.queryParameters['baseId'], equals('product-docs'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[_ragDocumentListItemJson()],
        ),
      );
      return;
    }

    if (options.path == '/ragkit/document') {
      expect(options.queryParameters['baseId'], equals('product-docs'));
      expect(options.queryParameters['documentId'], equals('intro'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragDocumentJson(),
        ),
      );
      return;
    }

    if (options.path == '/ragkit/document/delete') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['baseId'], equals('product-docs'));
      expect(payload['documentId'], equals('intro'));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'deleted': true,
            'baseId': 'product-docs',
            'documentId': 'intro',
          },
        ),
      );
      return;
    }

    if (options.path == '/ragkit/sync/document') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragDocumentSyncResultJson(),
        ),
      );
      return;
    }

    if (options.path == '/ragkit/sync/base' ||
        options.path == '/ragkit/sync/retryFailed') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragBatchResultJson(),
        ),
      );
      return;
    }

    if (options.path == '/ragkit/query') {
      final payload = options.data as Map<String, dynamic>;
      expect(payload['baseId'], equals('product-docs'));
      expect(payload['query'], isNotEmpty);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _ragQueryResultJson(),
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  Map<String, dynamic> _ragBaseJson() {
    return <String, dynamic>{
      'id': 'product-docs',
      'name': 'Product Docs',
      'docsName': 'docs_product_docs',
      'docsId': 'docs-1',
      'metadata': <String, dynamic>{'domain': 'docs'},
      'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
    };
  }

  Map<String, dynamic> _ragBaseListItemJson() {
    return <String, dynamic>{
      'id': 'product-docs',
      'name': 'Product Docs',
      'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
    };
  }

  Map<String, dynamic> _ragDocumentJson() {
    return <String, dynamic>{
      'id': 'intro',
      'baseId': 'product-docs',
      'title': 'Introduction',
      'markdown': '# Intro',
      'contentHash': 'hash-1',
      'metadata': <String, dynamic>{'source': 'manual'},
      'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
      'indexedAt': DateTime.utc(2026, 1, 2, 0, 5).toIso8601String(),
      'syncStatus': 'synced',
    };
  }

  Map<String, dynamic> _ragDocumentListItemJson() {
    return <String, dynamic>{
      'id': 'intro',
      'baseId': 'product-docs',
      'title': 'Introduction',
      'updatedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
      'indexedAt': DateTime.utc(2026, 1, 2, 0, 5).toIso8601String(),
      'syncStatus': 'synced',
    };
  }

  Map<String, dynamic> _ragDocumentSyncResultJson() {
    return <String, dynamic>{
      'baseId': 'product-docs',
      'documentId': 'intro',
      'syncStatus': 'synced',
      'keptCount': 1,
      'updatedCount': 1,
      'insertedCount': 0,
      'deletedCount': 0,
      'syncedAt': DateTime.utc(2026, 1, 2, 0, 5).toIso8601String(),
    };
  }

  Map<String, dynamic> _ragBatchResultJson() {
    return <String, dynamic>{
      'totalCount': 1,
      'successCount': 1,
      'failedCount': 0,
      'skippedCount': 0,
      'processedAt': DateTime.utc(2026, 1, 2, 0, 6).toIso8601String(),
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'baseId': 'product-docs',
          'documentId': 'intro',
          'status': 'success',
          'syncStatus': 'synced',
        },
      ],
    };
  }

  Map<String, dynamic> _ragQueryResultJson() {
    return <String, dynamic>{
      'baseId': 'product-docs',
      'query': 'How do I ingest markdown?',
      'hits': <Map<String, dynamic>>[
        <String, dynamic>{
          'documentId': 'intro',
          'title': 'Introduction',
          'score': 0.98,
          'snippet': 'Hello world',
          'segments': <Map<String, dynamic>>[
            <String, dynamic>{
              'segmentId': 'seg-1',
              'score': 0.98,
              'text': 'Hello world',
              'headingPath': 'Intro',
            },
          ],
        },
      ],
    };
  }
}

class _ToolKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'token': 'toolkit-token',
            'bundleId': 'com.demo.toolkit',
          },
        ),
      );
      return;
    }

    if (options.path == '/toolkit/list') {
      _expectToolKitAuth(options);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'tool-weather',
              'alias': 'weather',
              'host': '127.0.0.1',
              'port': 9100,
              'status': 'running',
              'serverId': 'server-weather',
              'server': <String, dynamic>{
                'repo': 'opentool-server-weather',
                'name': 'opentool-server-weather',
                'tag': '0.1.0',
              },
            },
            <String, dynamic>{
              'id': 'tool-calendar',
              'alias': 'calendar',
              'host': '127.0.0.1',
              'port': 9200,
              'status': 'stopped',
              'serverId': 'server-calendar',
            },
          ],
        ),
      );
      return;
    }

    if (options.path == '/toolkit/tool-weather/load') {
      _expectToolKitAuth(options);
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'opentool': '1.0.0',
            'info': <String, dynamic>{
              'title': 'Weather Tool',
              'description': 'Provides weather lookup',
              'version': '0.1.0',
            },
            'server': <String, dynamic>{'url': 'http://127.0.0.1:9100'},
            'functions': <Map<String, dynamic>>[],
          },
        ),
      );
      return;
    }

    if (options.path == '/toolkit/tool-weather/call') {
      _expectToolKitAuth(options);
      expect(options.data, isA<Map<String, dynamic>>());
      final data = Map<String, dynamic>.from(options.data as Map);
      expect(data['id'], equals('call-001'));
      expect(data['name'], equals('status'));
      expect(data['arguments'], equals(<String, dynamic>{'depth': 1}));
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'id': 'call-001',
            'result': <String, dynamic>{'ok': true},
          },
        ),
      );
      return;
    }

    if (options.path == '/toolkit/tool-weather/streamCall') {
      _expectToolKitAuth(options);
      expect(options.responseType, equals(ResponseType.stream));
      expect(options.data, isA<Map<String, dynamic>>());
      final data = Map<String, dynamic>.from(options.data as Map);
      expect(data['id'], equals('call-002'));
      expect(data['name'], equals('status'));
      final body = ResponseBody.fromString(
        'event: START\n'
        'data: {"name":"status"}\n'
        '\n'
        'event: DATA\n'
        'data: {"ok":true}\n'
        '\n'
        'event: DONE\n'
        'data: {"done":"status"}\n'
        '\n',
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['text/event-stream'],
        },
      );
      handler.resolve(
        Response<ResponseBody>(
          requestOptions: options,
          statusCode: 200,
          data: body,
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: 'Unhandled path ${options.path}',
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  void _expectToolKitAuth(RequestOptions options) {
    expect(
      options.headers[HttpHeaders.authorizationHeader],
      equals('Bearer toolkit-token'),
    );
  }
}
