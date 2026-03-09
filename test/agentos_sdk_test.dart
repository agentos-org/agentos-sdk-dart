import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/client/agentkit/agentkit_client.dart';
import 'package:agentos_sdk/src/client/appkit/appkit_client.dart';
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
      expect(payload.containsKey('modelId'), isFalse);
      expect(payload.containsKey('baseUrl'), isFalse);
      expect(payload.containsKey('apiKey'), isFalse);
      expect(payload.containsKey('model'), isFalse);
    });

    test('parses completions limits passthrough fields for liteagent', () {
      final message = AgentMessage.fromJson(<String, dynamic>{
        'sessionId': 's1',
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
    });
  });

  group('AgentOSSDK configuration', () {
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
  });

  group('LlmKitModule', () {
    test('lists available text models from /llmkit/models', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_LlmKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));

      final models = await sdk.llmkit.listModels();

      expect(models.length, equals(2));
      expect(models.first.id, equals('qwen3-8b'));
      expect(models.first.type, equals('textGeneration'));
      expect(models.first.alias, equals('qwen3-8b'));
      expect(models.first.contextWindowSize, equals(8192));
      expect(models.first.isRemote, isFalse);
      expect(models[1].id, equals('remote-gpt'));
      expect(models[1].name, equals('gpt-4.1'));
      expect(models[1].alias, equals('gpt-4.1'));
      expect(models[1].isRemote, isTrue);
      expect(models[1].isCustom, isTrue);
    });

    test('configures llmkit chat to use the text endpoint by default', () {
      final sdk = AgentOSSDK(baseUrl: 'http://fake.local:8888');

      expect(
        sdk.llmkit.chat.baseUrl,
        equals('http://fake.local:8888/llmkit/text'),
      );
    });
  });

  group('ToolKitModule', () {
    test('lists tools from /toolkit/list', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_ToolKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));

      final tools = await sdk.toolkit.listTool();

      expect(tools.length, equals(2));
      expect(tools.first.id, equals('tool-weather'));
      expect(tools.first.status, equals('running'));
      expect(tools[1].alias, equals('calendar'));
    });

    test('loads tool definition from /toolkit/{toolId}/load', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_ToolKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));

      final tool = await sdk.toolkit.loadTool('tool-weather');

      expect(tool, isNotNull);
      expect(tool!.opentool, equals('1.0.0'));
      expect(tool.info.title, equals('Weather Tool'));
      expect(tool.server?.url, equals('http://127.0.0.1:9100'));
    });

    test('subscribes to tool lifecycle events from /toolkit/events', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_ToolKitInterceptor());
      final sdk = AgentOSSDK(apiClient: ApiClient(dio: dio));

      final events = await (await sdk.toolkit.subscribeToolEvents(
        daemonApiKey: 'daemon-key',
      )).toList();

      expect(events, hasLength(2));
      expect(events.first.type, equals('tool.snapshot'));
      expect(events.first.reason, equals('snapshot'));
      expect(events.first.tool.id, equals('tool-weather'));
      expect(events.last.type, equals('tool.ready'));
      expect(events.last.reason, equals('started'));
      expect(events.last.tool.status, equals('running'));
    });
  });

  group('AppKitClient', () {
    test('registers bundle and subscribes to SSE events', () async {
      final interceptor = _AppKitInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(interceptor);
      final client = AppKitClient(apiClient: ApiClient(dio: dio));

      final token = await client.registerBundle(bundleId: 'com.demo.app');
      expect(token.token, equals('sk-demo'));
      expect(interceptor.lastBundleId, equals('com.demo.app'));

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

class _AgentKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/appkit/register') {
      final payload = options.data as Map<String, dynamic>;
      lastBundleId = payload['bundleId']?.toString();
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: lastBundleId?.isEmpty ?? true ? 400 : 200,
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

class _LlmKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/llmkit/models') {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'qwen3-8b',
              'name': 'qwen3-8b',
              'alias': 'qwen3-8b',
              'description': 'text model',
              'type': 'textGeneration',
              'contextWindowSize': 8192,
              'isRemote': false,
              'isCustom': false,
            },
            <String, dynamic>{
              'id': 'remote-gpt',
              'name': 'gpt-4.1',
              'alias': 'gpt-4.1',
              'description': 'remote custom model',
              'type': 'textGeneration',
              'contextWindowSize': 128000,
              'isRemote': true,
              'isCustom': true,
            },
          ],
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

class _ToolKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/toolkit/list') {
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

    if (options.path == '/toolkit/events') {
      expect(options.queryParameters['snapshot'], equals('1'));
      expect(options.headers[TOOL_API_KEY_HEADER], equals('daemon-key'));
      final body = ResponseBody.fromString(
        'event: ready\n'
        'data: {}\n'
        '\n'
        'event: tool.snapshot\n'
        'data: {"type":"tool.snapshot","reason":"snapshot","tool":{"id":"tool-weather","alias":"weather","host":"127.0.0.1","port":9100,"status":"running","serverId":"server-weather"},"occurredAt":"2026-03-09T00:00:00.000Z"}\n'
        '\n'
        'event: tool.ready\n'
        'data: {"type":"tool.ready","reason":"started","tool":{"id":"tool-weather","alias":"weather","host":"127.0.0.1","port":9100,"status":"running","serverId":"server-weather"},"occurredAt":"2026-03-09T00:00:01.000Z"}\n'
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
