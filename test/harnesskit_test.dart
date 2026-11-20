import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

const _privateToolsRegistration = HarnessKitPrivateToolsRegistration(
  endpoint: 'http://127.0.0.1:8123/',
  token: '12345678-1234-1234-1234-123456789abc',
  specification: <String, dynamic>{
    'opentool': '1.0.0',
    'info': <String, dynamic>{'title': 'App tools', 'version': '1.0.0'},
    'functions': <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'list_assets',
        'description': 'List assets',
        'parameters': <dynamic>[],
        'return': <String, dynamic>{
          'name': 'result',
          'schema': <String, dynamic>{'type': 'object'},
        },
      },
    ],
  },
);

void main() {
  group('HarnessKitModule', () {
    test('uses the AppKit token for runtime and thread requests', () async {
      final interceptor = _HarnessKitInterceptor();
      final sdk = _buildSdk(interceptor);
      addTearDown(sdk.dispose);

      await sdk.agentos.registerBundle(bundleId: 'com.example.harness');
      final runtime = await sdk.harnesskit.getRuntime();
      final threads = await sdk.harnesskit.listThreads();

      expect(runtime.engine, 'agentos');
      expect(threads, hasLength(1));
      expect(threads.single.threadId, 'thread-1');
      expect(interceptor.requests.map((request) => request.path), <String>[
        '/appkit/register',
        '/harnesskit/v1/runtime/harness-engine',
        '/harnesskit/v1/threads',
      ]);
      expect(
        interceptor.requests[1].headers[HttpHeaders.authorizationHeader],
        'Bearer token-1',
      );
    });

    test('returns rejected command receipts from HTTP 400', () async {
      final interceptor = _HarnessKitInterceptor(rejectCommand: true);
      final sdk = _buildSdk(interceptor);
      addTearDown(sdk.dispose);
      await sdk.agentos.registerBundle(bundleId: 'com.example.harness');

      final receipt = await sdk.harnesskit.submitCommand(
        threadId: 'thread-1',
        command: const HarnessKitCommand(
          type: 'submit_turn',
          commandId: 'command-1',
          extra: <String, dynamic>{'input': 'hello'},
        ),
      );

      expect(receipt.commandId, 'command-1');
      expect(receipt.status, 'rejected');
      expect(receipt.reason, 'thread_busy');
      expect(interceptor.requests.last.data, <String, dynamic>{
        'type': 'submit_turn',
        'commandId': 'command-1',
        'threadId': 'thread-1',
        'input': 'hello',
      });
    });

    test(
      'resumes the event stream from afterSequence and filters by runId',
      () async {
        final interceptor = _HarnessKitInterceptor();
        final sdk = _buildSdk(interceptor);
        addTearDown(sdk.dispose);
        await sdk.agentos.registerBundle(bundleId: 'com.example.harness');

        final stream = await sdk.harnesskit.events(
          threadId: 'thread-1',
          options: const HarnessKitEventsOptions(
            afterSequence: 12,
            runId: 'run-1',
          ),
        );
        final events = await stream.toList();

        expect(events, hasLength(1));
        expect(events.single.sequence, 13);
        expect(events.single.type, 'run.started');
        expect(interceptor.requests.last.queryParameters, <String, dynamic>{
          'afterSequence': 12,
          'runId': 'run-1',
        });
      },
    );

    test('refreshes an expired AppKit token and retries the request', () async {
      final interceptor = _HarnessKitInterceptor(expireFirstRuntimeToken: true);
      final sdk = _buildSdk(interceptor);
      addTearDown(sdk.dispose);
      await sdk.agentos.registerBundle(bundleId: 'com.example.harness');

      final runtime = await sdk.harnesskit.getRuntime();

      expect(runtime.engine, 'agentos');
      expect(interceptor.registrationCount, 2);
      expect(
        interceptor.requests
            .where((request) => request.path.endsWith('/harness-engine'))
            .map((request) => request.headers[HttpHeaders.authorizationHeader]),
        <String>['Bearer token-1', 'Bearer token-2'],
      );
    });

    test('registers private tools for the encoded thread', () async {
      final interceptor = _HarnessKitInterceptor();
      final sdk = _buildSdk(interceptor);
      addTearDown(sdk.dispose);
      await sdk.agentos.registerBundle(bundleId: 'com.example.harness');

      final result = await sdk.harnesskit.registerPrivateTools(
        threadId: 'thread/a',
        registration: _privateToolsRegistration,
      );

      expect(result.toolId, 'app-private:abc123');
      final request = interceptor.requests.last;
      expect(request.method, 'PUT');
      expect(request.path, '/harnesskit/v1/threads/thread%2Fa/private-tools');
      expect(
        request.headers[HttpHeaders.authorizationHeader],
        'Bearer token-1',
      );
      expect(request.data, <String, dynamic>{
        'endpoint': 'http://127.0.0.1:8123/',
        'token': '12345678-1234-1234-1234-123456789abc',
        'specification': _privateToolsRegistration.specification,
      });
    });

    test(
      'refreshes AppKit credentials without changing the callback token',
      () async {
        final interceptor = _HarnessKitInterceptor(
          expireFirstPrivateToolsToken: true,
        );
        final sdk = _buildSdk(interceptor);
        addTearDown(sdk.dispose);
        await sdk.agentos.registerBundle(bundleId: 'com.example.harness');

        final result = await sdk.harnesskit.registerPrivateTools(
          threadId: 'thread-1',
          registration: _privateToolsRegistration,
        );

        expect(result.toolId, 'app-private:abc123');
        expect(interceptor.registrationCount, 2);
        final requests = interceptor.requests
            .where((request) => request.path.endsWith('/private-tools'))
            .toList();
        expect(requests, hasLength(2));
        expect(
          requests.map(
            (request) => request.headers[HttpHeaders.authorizationHeader],
          ),
          <String>['Bearer token-1', 'Bearer token-2'],
        );
        expect(requests.map((request) => request.data['token']), <String>[
          _privateToolsRegistration.token,
          _privateToolsRegistration.token,
        ]);
        expect(requests.last.data, requests.first.data);
      },
    );

    test('propagates private tool access denial without refreshing', () async {
      final interceptor = _HarnessKitInterceptor(forbidPrivateTools: true);
      final sdk = _buildSdk(interceptor);
      addTearDown(sdk.dispose);
      await sdk.agentos.registerBundle(bundleId: 'com.example.harness');

      await expectLater(
        sdk.harnesskit.registerPrivateTools(
          threadId: 'thread-1',
          registration: _privateToolsRegistration,
        ),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'status code',
            HttpStatus.forbidden,
          ),
        ),
      );
      expect(interceptor.registrationCount, 1);
      expect(interceptor.privateToolsRequestCount, 1);
    });

    test('omits unspecified model config fields and preserves extensions', () {
      final request = HarnessKitRunRequest(
        requestId: 'request-1',
        goal: 'hello',
        llmConfig: const HarnessKitLlmConfig(model: 'model-1'),
        extra: const <String, dynamic>{'queueMode': 'append'},
      );

      final json = request.toJson();

      expect(json['queueMode'], 'append');
      expect(json['llmConfig'], <String, dynamic>{'model': 'model-1'});
      expect(json.containsKey('actorId'), isFalse);
    });
  });
}

AgentOSSDK _buildSdk(_HarnessKitInterceptor interceptor) {
  final dio = Dio(BaseOptions(baseUrl: 'http://harness.test'))
    ..interceptors.add(interceptor);
  return AgentOSSDK(apiClient: ApiClient(dio: dio));
}

class _HarnessKitInterceptor extends Interceptor {
  _HarnessKitInterceptor({
    this.rejectCommand = false,
    this.expireFirstRuntimeToken = false,
    this.expireFirstPrivateToolsToken = false,
    this.forbidPrivateTools = false,
  });

  final bool rejectCommand;
  final bool expireFirstRuntimeToken;
  final bool expireFirstPrivateToolsToken;
  final bool forbidPrivateTools;
  final List<RequestOptions> requests = <RequestOptions>[];
  int registrationCount = 0;
  int runtimeRequestCount = 0;
  int privateToolsRequestCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    if (options.path == '/appkit/register') {
      registrationCount++;
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: HttpStatus.ok,
          data: <String, dynamic>{'token': 'token-$registrationCount'},
        ),
      );
      return;
    }

    if (options.path == '/harnesskit/v1/runtime/harness-engine') {
      runtimeRequestCount++;
      if (expireFirstRuntimeToken && runtimeRequestCount == 1) {
        handler.reject(
          _error(options, HttpStatus.unauthorized, <String, dynamic>{
            'error': <String, dynamic>{'message': 'invalid app token'},
          }),
        );
        return;
      }
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: HttpStatus.ok,
          data: <String, dynamic>{
            'status': 'ready',
            'engine': 'agentos',
            'availableEngines': <String>['agentos'],
            'switching': false,
          },
        ),
      );
      return;
    }

    if (options.path == '/harnesskit/v1/threads') {
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: HttpStatus.ok,
          data: <String, dynamic>{
            'threads': <Map<String, dynamic>>[
              <String, dynamic>{
                'threadId': 'thread-1',
                'updatedAt': '2026-10-09T00:00:00Z',
                'messages': <dynamic>[],
              },
            ],
          },
        ),
      );
      return;
    }

    if (options.path.startsWith('/harnesskit/v1/threads/') &&
        options.path.endsWith('/private-tools')) {
      privateToolsRequestCount++;
      if (forbidPrivateTools) {
        handler.reject(
          _error(options, HttpStatus.forbidden, <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'harness_host_access_forbidden',
              'message': 'Access forbidden',
            },
          }),
        );
        return;
      }
      if (expireFirstPrivateToolsToken && privateToolsRequestCount == 1) {
        handler.reject(
          _error(options, HttpStatus.unauthorized, <String, dynamic>{
            'error': <String, dynamic>{'message': 'invalid app token'},
          }),
        );
        return;
      }
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: HttpStatus.ok,
          data: <String, dynamic>{'toolId': 'app-private:abc123'},
        ),
      );
      return;
    }

    if (options.path == '/harnesskit/v1/threads/thread-1/commands' &&
        rejectCommand) {
      handler.reject(
        _error(options, HttpStatus.badRequest, <String, dynamic>{
          'commandId': 'command-1',
          'status': 'rejected',
          'threadId': 'thread-1',
          'reason': 'thread_busy',
        }),
      );
      return;
    }

    if (options.path == '/harnesskit/v1/threads/thread-1/events') {
      final bytes = utf8.encode(
        'event: run.started\n'
        'data: ${jsonEncode(<String, dynamic>{'eventId': 'event-13', 'threadId': 'thread-1', 'runId': 'run-1', 'sequence': 13, 'timestamp': '2026-10-09T00:00:00Z', 'type': 'run.started', 'lifecycle': 'started', 'data': <String, dynamic>{}})}\n\n',
      );
      handler.resolve(
        Response<ResponseBody>(
          requestOptions: options,
          statusCode: HttpStatus.ok,
          data: ResponseBody(
            Stream<Uint8List>.value(Uint8List.fromList(bytes)),
            HttpStatus.ok,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>['text/event-stream'],
            },
          ),
        ),
      );
      return;
    }

    handler.reject(_error(options, HttpStatus.notFound, <String, dynamic>{}));
  }

  DioException _error(RequestOptions options, int statusCode, Object data) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: statusCode,
          data: data,
        ),
      );
}
