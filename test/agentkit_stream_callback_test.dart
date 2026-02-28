import 'dart:async';
import 'dart:io';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('AgentKit stream callback routing', () {
    test('non-stream function call uses callback once', () async {
      final interceptor = _AgentKitChatRoutingInterceptor(
        functionCallPayload:
            '{"sessionId":"sess-123","functionCall":{"id":"call-1","name":"demo_tool","arguments":{"query":"ping"}}}',
      );
      final sdk = _buildSdk(interceptor);

      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      final handler = _NonStreamHandler();
      await sdk.agentkit.chat(
        Session(sessionId: 'sess-123'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
          isChunk: true,
        ),
        handler,
      );

      await handler.done.future.timeout(const Duration(seconds: 2));
      await _waitForCondition(() => interceptor.callbackCount == 1);

      expect(interceptor.callbackCount, equals(1));
      expect(interceptor.streamCallbackCount, equals(0));
    });

    test('stream function call uses streamCallback for DATA and DONE', () async {
      final interceptor = _AgentKitChatRoutingInterceptor(
        functionCallPayload:
            '{"sessionId":"sess-123","stream":true,"functionCall":{"id":"call-1","name":"demo_tool","arguments":{"query":"ping"}}}',
      );
      final sdk = _buildSdk(interceptor);

      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      final handler = _StreamSuccessHandler();
      await sdk.agentkit.chat(
        Session(sessionId: 'sess-123'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
          isChunk: true,
        ),
        handler,
      );

      await handler.done.future.timeout(const Duration(seconds: 2));
      await _waitForCondition(() => interceptor.streamCallbackCount == 2);

      expect(interceptor.callbackCount, equals(0));
      expect(interceptor.streamCallbackCount, equals(2));
      expect(
        interceptor.streamEvents,
        equals(<String>[EventType.DATA, EventType.DONE]),
      );
      expect(interceptor.streamEvents, isNot(contains(EventType.ERROR)));
    });

    test('missing tool emits stream ERROR', () async {
      final handler = _DefaultStreamHandler();
      final events = <EventToolReturn>[];
      final functionCall = FunctionCall.fromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'missing_tool',
        'arguments': <String, dynamic>{},
      });

      await handler.onStreamFunctionCall('sess-123', functionCall, events.add);

      expect(events.length, equals(1));
      expect(events.single.event, equals(EventType.ERROR));
    });

    test('tool stream exception emits stream ERROR', () async {
      final handler = _DefaultStreamHandler(tool: _ThrowingTool());
      final events = <EventToolReturn>[];
      final functionCall = FunctionCall.fromJson(<String, dynamic>{
        'id': 'call-1',
        'name': 'unstable_tool',
        'arguments': <String, dynamic>{},
      });

      await handler.onStreamFunctionCall('sess-123', functionCall, events.add);

      expect(events.length, equals(1));
      expect(events.single.event, equals(EventType.ERROR));
    });
  });
}

AgentOSSDK _buildSdk(_AgentKitChatRoutingInterceptor interceptor) {
  final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
    ..interceptors.add(interceptor);
  return AgentOSSDK(apiClient: ApiClient(dio: dio));
}

Future<void> _waitForCondition(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
  Duration interval = const Duration(milliseconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met before timeout');
    }
    await Future<void>.delayed(interval);
  }
}

class _AgentKitChatRoutingInterceptor extends Interceptor {
  _AgentKitChatRoutingInterceptor({required this.functionCallPayload});

  final String functionCallPayload;
  int callbackCount = 0;
  int streamCallbackCount = 0;
  final List<String> streamEvents = <String>[];

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

    if (options.path == '/agentkit/chat') {
      final body = ResponseBody.fromString(
        'event: functionCall\n'
        'data: $functionCallPayload\n'
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

    if (options.path == '/agentkit/callback') {
      callbackCount += 1;
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'ok': true},
        ),
      );
      return;
    }

    if (options.path == '/agentkit/streamCallback') {
      streamCallbackCount += 1;
      final payload = Map<String, dynamic>.from(options.data as Map);
      streamEvents.add(payload['event']?.toString() ?? '');
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'ok': true},
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

class _NonStreamHandler extends AgentMessageHandler {
  final Completer<void> done = Completer<void>();

  @override
  Future<ToolReturn> onFunctionCall(
    String sessionId,
    FunctionCall functionCall,
  ) async {
    return ToolReturn(
      id: functionCall.id,
      result: <String, dynamic>{'ok': true},
    );
  }

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {}

  @override
  Future<void> onDone() async {
    if (!done.isCompleted) {
      done.complete();
    }
  }

  @override
  Future<void> onError(Exception e) async {
    if (!done.isCompleted) {
      done.completeError(e);
    }
  }

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {}
}

class _StreamSuccessHandler extends AgentMessageHandler {
  final Completer<void> done = Completer<void>();

  @override
  Future<void> onStreamFunctionCall(
    String sessionId,
    FunctionCall functionCall,
    void Function(EventToolReturn) onToolReturn,
  ) async {
    onToolReturn(
      EventToolReturn(
        event: EventType.DATA,
        toolReturn: ToolReturn(
          id: functionCall.id,
          result: <String, dynamic>{'token': 'partial'},
        ),
      ),
    );
    onToolReturn(
      EventToolReturn(
        event: EventType.DONE,
        toolReturn: ToolReturn(
          id: functionCall.id,
          result: <String, dynamic>{'final': true},
        ),
      ),
    );
  }

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {}

  @override
  Future<void> onDone() async {
    if (!done.isCompleted) {
      done.complete();
    }
  }

  @override
  Future<void> onError(Exception e) async {
    if (!done.isCompleted) {
      done.completeError(e);
    }
  }

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {}
}

class _DefaultStreamHandler extends AgentMessageHandler {
  _DefaultStreamHandler({super.tool});

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {}

  @override
  Future<void> onDone() async {}

  @override
  Future<void> onError(Exception e) async {}

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {}
}

class _ThrowingTool extends Tool {
  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic>? arguments,
  ) async {
    return <String, dynamic>{'ok': true};
  }

  @override
  Future<void> streamCall(
    String name,
    Map<String, dynamic>? arguments,
    void Function(String event, Map<String, dynamic> data) onEvent,
  ) async {
    throw Exception('stream failed');
  }
}
