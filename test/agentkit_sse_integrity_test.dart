import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/client/agentkit/agentkit_client.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('AgentKit SSE integrity', () {
    test('follows SSE data-line and CRLF framing rules', () async {
      final client = _clientForBytes(
        utf8.encode(
          'event: agentmessage\r\n'
          'data: first line\r\n'
          'data: second line\r\n'
          '\r\n',
        ),
      );

      final events = await (await _chat(client)).toList();

      expect(events, hasLength(1));
      expect(events.single.agentEventType, AgentEventType.message);
      expect(events.single.data, 'first line\nsecond line');
    });

    test(
      'preserves a 100 KiB payload across hostile byte boundaries',
      () async {
        final html = _htmlWithUtf8Size(100 * 1024);
        final expectedHash = _sha256(html);
        final sseBytes = _functionCallSse(html);
        final client = _clientForChunks(_hostileChunks(sseBytes));

        final events = await (await _chat(client)).toList();
        final receivedHtml = _functionCallHtml(events.single);

        expect(utf8.encode(receivedHtml), hasLength(100 * 1024));
        expect(_sha256(receivedHtml), expectedHash);
        expect(receivedHtml, html);
      },
    );

    test(
      'preserves a 1 MiB payload through public chat and callback',
      () async {
        final html = _htmlWithUtf8Size(1024 * 1024);
        final expectedHash = _sha256(html);
        final server = await _IntegritySseServer.start(_functionCallSse(html));
        addTearDown(server.close);
        final sdk = AgentOSSDK(
          baseUrl: server.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 30),
        );
        addTearDown(sdk.dispose);
        final handler = _IntegrityHandler();

        await sdk.agentos.registerBundle(bundleId: 'com.example.integrity');
        await sdk.agentkit.chat(
          Session(sessionId: 'sess-123'),
          UserTask(
            content: <Content>[Content(type: 'text', message: 'build html')],
          ),
          handler,
        );
        await handler.done.future.timeout(const Duration(seconds: 30));
        final receivedHtml = handler.html!;

        expect(server.registrationCount, 1);
        expect(server.chatRequestCount, 1);
        expect(server.callbackCount, 1);
        expect(utf8.encode(receivedHtml), hasLength(1024 * 1024));
        expect(_sha256(receivedHtml), expectedHash);
        expect(receivedHtml, html);
      },
    );
  });
}

Future<Stream<AgentEvent>> _chat(AgentKitClient client) {
  return client.chat(
    bearerToken: 'token-123',
    sessionId: 'sess-123',
    userTask: UserTask(
      content: <Content>[Content(type: 'text', message: 'build html')],
    ),
  );
}

AgentKitClient _clientForBytes(List<int> bytes) {
  return _clientForChunks(Stream<Uint8List>.value(Uint8List.fromList(bytes)));
}

AgentKitClient _clientForChunks(Stream<Uint8List> chunks) {
  final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
    ..interceptors.add(_SseResponseInterceptor(chunks));
  return AgentKitClient(apiClient: ApiClient(dio: dio));
}

String _htmlWithUtf8Size(int targetBytes) {
  const prefix = '<!doctype html><html><body>你好🙂';
  const suffix = '终点🚀</body></html>';
  final fixedBytes = utf8.encode(prefix).length + utf8.encode(suffix).length;
  if (targetBytes < fixedBytes) {
    throw ArgumentError.value(targetBytes, 'targetBytes', 'is too small');
  }
  return '$prefix${List<String>.filled(targetBytes - fixedBytes, 'x').join()}'
      '$suffix';
}

Uint8List _functionCallSse(String html) {
  final payload = jsonEncode(<String, dynamic>{
    'sessionId': 'sess-123',
    'functionCall': <String, dynamic>{
      'id': 'call-html',
      'name': 'render_html',
      'arguments': <String, dynamic>{'html': html},
    },
  });
  return Uint8List.fromList(
    utf8.encode('event: functionCall\r\ndata: $payload\r\n\r\n'),
  );
}

String _functionCallHtml(AgentEvent event) {
  expect(event.agentEventType, AgentEventType.functionCall);
  final payload = jsonDecode(event.data) as Map<String, dynamic>;
  final functionCall = payload['functionCall'] as Map<String, dynamic>;
  final arguments = functionCall['arguments'] as Map<String, dynamic>;
  return arguments['html'] as String;
}

String _sha256(String value) => sha256.convert(utf8.encode(value)).toString();

Stream<Uint8List> _hostileChunks(Uint8List bytes) async* {
  var offset = 0;

  // The beginning includes the first multi-byte HTML characters. Sending it
  // byte-by-byte guarantees that UTF-8 code points cross transport chunks.
  final bytewiseEnd = bytes.length < 512 ? bytes.length : 512;
  while (offset < bytewiseEnd) {
    yield Uint8List.sublistView(bytes, offset, offset + 1);
    offset += 1;
  }

  const sizes = <int>[2, 3, 5, 8, 13, 1024, 4093, 16384];
  var sizeIndex = 0;
  while (offset < bytes.length) {
    final size = sizes[sizeIndex % sizes.length];
    final end = offset + size < bytes.length ? offset + size : bytes.length;
    yield Uint8List.sublistView(bytes, offset, end);
    offset = end;
    sizeIndex += 1;
  }
}

class _SseResponseInterceptor extends Interceptor {
  _SseResponseInterceptor(this.chunks);

  final Stream<Uint8List> chunks;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(
      Response<ResponseBody>(
        requestOptions: options,
        statusCode: HttpStatus.ok,
        data: ResponseBody(
          chunks,
          HttpStatus.ok,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[
              'text/event-stream; charset=utf-8',
            ],
          },
        ),
      ),
    );
  }
}

class _IntegritySseServer {
  _IntegritySseServer._(this._server, this._bytes);

  final HttpServer _server;
  final Uint8List _bytes;
  int registrationCount = 0;
  int chatRequestCount = 0;
  int callbackCount = 0;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  static Future<_IntegritySseServer> start(Uint8List bytes) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _IntegritySseServer._(server, bytes);
    server.listen(fixture._handleRequest);
    return fixture;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/appkit/register') {
      registrationCount += 1;
      await request.drain<void>();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.contentTypeHeader, 'application/json')
        ..write(jsonEncode(<String, String>{'token': 'token-123'}));
      await request.response.close();
      return;
    }

    if (request.uri.path == '/agentkit/callback') {
      callbackCount += 1;
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      expect(body['id'], 'call-html');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.contentTypeHeader, 'application/json')
        ..write('{}');
      await request.response.close();
      return;
    }

    if (request.uri.path != '/agentkit/chat') {
      await request.drain<void>();
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    chatRequestCount += 1;
    await request.drain<void>();
    request.response
      ..statusCode = HttpStatus.ok
      ..bufferOutput = false
      ..headers.set(
        HttpHeaders.contentTypeHeader,
        'text/event-stream; charset=utf-8',
      );

    const chunkSize = 16 * 1024;
    var offset = 0;
    while (offset < _bytes.length) {
      final end = offset + chunkSize < _bytes.length
          ? offset + chunkSize
          : _bytes.length;
      request.response.add(Uint8List.sublistView(_bytes, offset, end));
      await request.response.flush();
      offset = end;
    }
    await request.response.close();
  }

  Future<void> close() => _server.close(force: true);
}

class _IntegrityHandler extends AgentMessageHandler {
  final Completer<void> done = Completer<void>();
  String? html;

  @override
  Future<ToolReturn> onFunctionCall(
    String sessionId,
    FunctionCall functionCall,
  ) async {
    expect(sessionId, 'sess-123');
    html = functionCall.arguments['html'] as String;
    return ToolReturn(
      id: functionCall.id,
      result: <String, dynamic>{'received': true},
    );
  }

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {}

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {}

  @override
  Future<void> onDone() async {
    if (!done.isCompleted) done.complete();
  }

  @override
  Future<void> onError(Exception error) async {
    if (!done.isCompleted) done.completeError(error);
  }
}
