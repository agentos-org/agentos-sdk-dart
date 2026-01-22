import 'dart:io';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('RootClient', () {
    test('fetches version from /version', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(_VersionInterceptor());
      final client = ApiClient(dio: dio);
      final root = RootClient(apiClient: client);

      final version = await root.getVersion();

      expect(version.version, equals('1.2.3'));
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
          content: <Content>[
            Content(type: 'text', message: 'hello'),
          ],
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
          content: <Content>[
            Content(type: 'text', message: 'hello'),
          ],
        ),
      ))
          .toList();

      expect(events, isNotEmpty);
      expect(
        events.map((e) => e.agentEventType),
        containsAll(<String>['message', 'chunk']),
      );
      expect(events.first.data, contains('hello'));
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
      ))
          .toList();

      expect(events, isNotEmpty);
      expect(
        events.map((e) => e.agentosEventType),
        containsAll(<String>['welcome', 'call']),
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
          data: <String, String>{
            'sessionId': 'sess-123',
            'content': 'hello',
          },
        ),
      );
      return;
    }

    if (options.path == '/agentkit/chat') {
      final body = ResponseBody.fromString(
        'event: message\n'
        'data: {"content":"hello"}\n'
        '\n'
        'event: chunk\n'
        'data: {"content":"he"}\n'
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
        'event: call\n'
        'data: {"id":"call-1","from":"agentos","contentList":[{"type":"text","message":"ping"}]}\n'
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
