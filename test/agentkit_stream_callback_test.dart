import 'dart:async';
import 'dart:io';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('AgentKit stream callback routing', () {
    test('message and chunk callbacks use child session ids', () async {
      final interceptor = _AgentKitChatRoutingInterceptor(
        chatBody:
            'event: message\n'
            'data: {"sessionId":"child-message","originalTaskId":"root-task","taskId":"child-task","role":"agent","to":"user","type":"text","content":"done","createTime":"2026-07-12T10:00:00.000Z"}\n'
            '\n'
            'event: chunk\n'
            'data: {"sessionId":"child-chunk","taskId":"child-task","role":"agent","to":"user","type":"reasoning","part":"working","createTime":"2026-07-12T10:00:01.000Z"}\n'
            '\n',
      );
      final sdk = _buildSdk(interceptor);

      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
      final handler = _SessionRoutingHandler();
      await sdk.agentkit.chat(
        Session(sessionId: 'root-session'),
        UserTask(
          content: <Content>[Content(type: 'text', message: 'hello')],
        ),
        handler,
      );

      await handler.done.future.timeout(const Duration(seconds: 2));
      expect(handler.messageSessionIds, <String>['child-message']);
      expect(handler.chunkSessionIds, <String>['child-chunk']);
    });

    test('non-stream function call uses callback once', () async {
      final interceptor = _AgentKitChatRoutingInterceptor(
        functionCallPayload:
            '{"sessionId":"child-sess-456","functionCall":{"id":"call-1","name":"demo_tool","arguments":{"query":"ping"}}}',
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
      expect(
        handler.functionCallSessionIds,
        equals(<String>['child-sess-456']),
      );
      expect(
        interceptor.callbackSessionIds,
        equals(<String>['child-sess-456']),
      );
    });

    test('stream function call uses streamCallback for DATA and DONE', () async {
      final interceptor = _AgentKitChatRoutingInterceptor(
        functionCallPayload:
            '{"sessionId":"child-sess-456","stream":true,"functionCall":{"id":"call-1","name":"demo_tool","arguments":{"query":"ping"}}}',
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
      expect(
        handler.functionCallSessionIds,
        equals(<String>['child-sess-456']),
      );
      expect(
        interceptor.streamCallbackSessionIds,
        equals(<String>['child-sess-456', 'child-sess-456']),
      );
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
  _AgentKitChatRoutingInterceptor({
    String? functionCallPayload,
    String? chatBody,
  }) : chatBody =
           chatBody ??
           'event: functionCall\n'
               'data: $functionCallPayload\n'
               '\n';

  final String chatBody;
  int callbackCount = 0;
  int streamCallbackCount = 0;
  final List<String> streamEvents = <String>[];
  final List<String> callbackSessionIds = <String>[];
  final List<String> streamCallbackSessionIds = <String>[];

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
        chatBody,
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
      callbackSessionIds.add(
        options.queryParameters['sessionId']?.toString() ?? '',
      );
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
      streamCallbackSessionIds.add(
        options.queryParameters['sessionId']?.toString() ?? '',
      );
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

class _SessionRoutingHandler extends AgentMessageHandler {
  final Completer<void> done = Completer<void>();
  final List<String> messageSessionIds = <String>[];
  final List<String> chunkSessionIds = <String>[];

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {
    messageSessionIds.add(sessionId);
  }

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {
    chunkSessionIds.add(sessionId);
  }

  @override
  Future<void> onDone() async {
    if (!done.isCompleted) done.complete();
  }

  @override
  Future<void> onError(Exception e) async {
    if (!done.isCompleted) done.completeError(e);
  }
}

class _NonStreamHandler extends AgentMessageHandler {
  final Completer<void> done = Completer<void>();
  final List<String> functionCallSessionIds = <String>[];

  @override
  Future<ToolReturn> onFunctionCall(
    String sessionId,
    FunctionCall functionCall,
  ) async {
    functionCallSessionIds.add(sessionId);
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
  final List<String> functionCallSessionIds = <String>[];

  @override
  Future<void> onStreamFunctionCall(
    String sessionId,
    FunctionCall functionCall,
    void Function(EventToolReturn) onToolReturn,
  ) async {
    functionCallSessionIds.add(sessionId);
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
