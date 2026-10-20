import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('ModelCapabilities', () {
    test('fromJson parses reasoning true', () {
      final capabilities = ModelCapabilities.fromJson(<String, dynamic>{
        'reasoning': true,
      });

      expect(capabilities.reasoning, isTrue);
    });

    test('fromJson parses reasoning false', () {
      final capabilities = ModelCapabilities.fromJson(<String, dynamic>{
        'reasoning': false,
      });

      expect(capabilities.reasoning, isFalse);
    });

    test('fromJson defaults missing reasoning to false', () {
      final capabilities = ModelCapabilities.fromJson(<String, dynamic>{});

      expect(capabilities.reasoning, isFalse);
    });

    test('toJson outputs reasoning', () {
      const capabilities = ModelCapabilities(reasoning: true);

      expect(capabilities.toJson()['reasoning'], isTrue);
    });
  });

  group('ModelKitModule', () {
    test('listModels preserves capabilities.reasoning', () async {
      final sdk = _buildSdk();

      final models = await sdk.modelkit.listModels();

      expect(models, hasLength(3));
      expect(models[0].capabilities.reasoning, isTrue);
      expect(models[1].capabilities.reasoning, isFalse);
      expect(models[2].capabilities.reasoning, isFalse);
      expect(
        (models[0].toJson()['capabilities']
            as Map<String, dynamic>)['reasoning'],
        isTrue,
      );
    });

    test('listModelsByTask preserves capabilities.reasoning', () async {
      final sdk = _buildSdk();

      final models = await sdk.modelkit.listModelsByTask(ModelTask.chat);

      expect(models, hasLength(1));
      expect(models.single.name, equals('glm-5.1'));
      expect(models.single.capabilities.reasoning, isTrue);
    });
  });

  group('decision models', () {
    test('listModels keeps the decisions output modality', () async {
      final recorder = _RecordingInterceptor((options) {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'sys-1',
            'name': 'systemone',
            'alias': 'systemone',
            'task': 'decision',
            'input': <String>['text', 'image'],
            'output': <String>['decisions'],
            'capabilities': <String, dynamic>{
              'stream': false,
              'tool_call': false,
              'reasoning': false,
            },
            'isRemote': false,
          },
          <String, dynamic>{
            'id': 'app-1',
            'name': 'app-chat',
            'alias': 'app-chat',
            'task': 'chat',
            'isAppModel': true,
            'appBundleId': 'com.demo.app',
          },
          <String, dynamic>{
            'id': 'chat-1',
            'name': 'plain',
            'alias': 'plain',
            'task': 'chat',
          },
        ];
      });
      final models = await ModelKitClient(
        apiClient: _apiClient(recorder),
      ).listModels();

      final decision = models[0];
      expect(decision.task, ModelTask.decision);
      expect(decision.supportsDecisionInference, isTrue);
      expect(decision.supportsChatInference, isFalse);
      expect(decision.outputModalities, <Modality>[Modality.decisions]);
      expect(decision.inputModalities, <Modality>[
        Modality.text,
        Modality.image,
      ]);
      expect(decision.capabilities.stream, isFalse);
      expect(decision.toJson()['output'], <String>['decisions']);

      expect(models[1].isAppModel, isTrue);
      expect(models[1].appBundleId, 'com.demo.app');
      expect(models[1].toJson()['isAppModel'], isTrue);
      expect(models[2].isAppModel, isFalse);
      expect(models[2].appBundleId, isNull);
      expect(models[2].toJson().containsKey('isAppModel'), isFalse);
    });

    test('DecisionQuestion factories build the matching criteria', () {
      expect(
        DecisionQuestion.choice(
          instructions: 'route?',
          options: const <String, String>{'chat': 'small talk'},
        ).toJson(),
        <String, dynamic>{
          'type': 'choice',
          'instructions': 'route?',
          'criteria': <String, String>{'chat': 'small talk'},
        },
      );
      expect(
        DecisionQuestion.score(
          instructions: 'urgency?',
          levels: const <String>['low', 'mid', 'high'],
        ).toJson(),
        <String, dynamic>{
          'type': 'score',
          'instructions': 'urgency?',
          'criteria': <String>['low', 'mid', 'high'],
        },
      );
      expect(
        DecisionQuestion.noul(
          instructions: 'angry?',
          trueMeaning: 'yes',
          falseMeaning: 'no',
        ).toJson(),
        <String, dynamic>{
          'type': 'noul',
          'instructions': 'angry?',
          'criteria': <String, String>{'true': 'yes', 'false': 'no'},
        },
      );
      expect(
        DecisionQuestion.noul(instructions: 'angry?').toJson(),
        <String, dynamic>{'type': 'noul', 'instructions': 'angry?'},
      );
    });

    test(
      'decision.create posts the typed questions and parses answers',
      () async {
        final recorder = _RecordingInterceptor((options) {
          return <String, dynamic>{
            'model': 'systemone',
            'answers': <String, dynamic>{
              'route': <String, dynamic>{
                'type': 'choice',
                'choice': 'chat',
                'probabilities': <String, dynamic>{'chat': 0.9, 'search': 0.1},
                'confidence': 0.9,
              },
              'urgency': <String, dynamic>{
                'type': 'score',
                'score': 3.5,
                'probabilities': <double>[0.1, 0.2, 0.7],
              },
              'angry': <String, dynamic>{
                'type': 'noul',
                'noul': 0.12,
                'legend': <String, dynamic>{'true': 'yes'},
              },
            },
            'usage': <String, dynamic>{'input_tokens': 21, 'output_tokens': 4},
          };
        });
        final client = ModelKitClient(apiClient: _apiClient(recorder));

        final response = await client.decision.create(
          model: 'systemone',
          state: <String, dynamic>{'text': 'hello'},
          questions: <String, DecisionQuestion>{
            'route': DecisionQuestion.choice(
              instructions: 'route?',
              options: const <String, String>{
                'chat': 'small talk',
                'search': 'lookup',
              },
            ),
            'urgency': DecisionQuestion.score(
              instructions: 'urgency?',
              levels: const <String>['low', 'mid', 'high'],
            ),
            'angry': DecisionQuestion.noul(instructions: 'angry?'),
          },
          images: const <String>['data:image/png;base64,AAAA'],
          extra: const <String, dynamic>{'temperature': 0},
        );

        final request = recorder.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/modelkit/decision');
        expect(request.headers.containsKey('authorization'), isFalse);
        final body = request.data as Map<String, dynamic>;
        expect(body['model'], 'systemone');
        expect(body['state'], <String, dynamic>{'text': 'hello'});
        expect(body['images'], <String>['data:image/png;base64,AAAA']);
        expect(body['temperature'], 0);
        expect((body['questions'] as Map<String, dynamic>).keys, <String>[
          'route',
          'urgency',
          'angry',
        ]);
        expect(
          (body['questions'] as Map<String, dynamic>)['route'],
          <String, dynamic>{
            'type': 'choice',
            'instructions': 'route?',
            'criteria': <String, String>{
              'chat': 'small talk',
              'search': 'lookup',
            },
          },
        );

        expect(response.model, 'systemone');
        expect(response.usage?.inputTokens, 21);
        expect(response.usage?.outputTokens, 4);
        final route = response.answers['route']!;
        expect(route.type, DecisionQuestionType.choice);
        expect(route.choice, 'chat');
        expect(route.confidence, 0.9);
        expect(route.probabilities, <String, dynamic>{
          'chat': 0.9,
          'search': 0.1,
        });
        final urgency = response.answers['urgency']!;
        expect(urgency.type, DecisionQuestionType.score);
        expect(urgency.score, 3.5);
        expect(urgency.choice, isNull);
        final angry = response.answers['angry']!;
        expect(angry.type, DecisionQuestionType.noul);
        expect(angry.noul, 0.12);
        expect(angry.legend, <String, dynamic>{'true': 'yes'});
        expect(angry.raw['type'], 'noul');
      },
    );

    test('decision.create omits unset optional fields', () async {
      final recorder = _RecordingInterceptor(
        (options) => <String, dynamic>{'answers': <String, dynamic>{}},
      );
      final client = ModelKitClient(apiClient: _apiClient(recorder));

      final response = await client.decision.create(
        state: 'plain text state',
        questions: <String, DecisionQuestion>{
          'q': DecisionQuestion.noul(instructions: 'ok?'),
        },
      );

      final body = recorder.requests.single.data as Map<String, dynamic>;
      expect(body.keys.toSet(), <String>{'state', 'questions'});
      expect(body['state'], 'plain text state');
      expect(response.answers, isEmpty);
      expect(response.usage, isNull);
    });

    test('decision.create surfaces the server status and body', () async {
      final recorder = _RecordingInterceptor(
        (options) => _httpError(options, 400, <String, dynamic>{
          'error': 'invalid questions',
        }),
      );
      final client = ModelKitClient(apiClient: _apiClient(recorder));

      await expectLater(
        client.decision.create(
          state: 's',
          questions: <String, DecisionQuestion>{
            'q': DecisionQuestion.noul(instructions: 'ok?'),
          },
        ),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 400)
              .having((e) => e.response?.data, 'body', <String, dynamic>{
                'error': 'invalid questions',
              }),
        ),
      );
    });
  });

  group('app models', () {
    test('listAppModels is public and parses every field', () async {
      final recorder = _RecordingInterceptor((options) {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'app-model-1',
            'qualifiedId': 'app-model-1@com.demo.app',
            'name': 'router',
            'alias': 'router',
            'description': 'routes requests',
            'task': 'decision',
            'provider': 'openai_compatible',
            'input': <String>['text'],
            'output': <String>['decisions'],
            'capabilities': <String, dynamic>{
              'stream': false,
              'tool_call': false,
              'reasoning': false,
            },
            'baseUrl': 'http://127.0.0.1:9000',
            'hasApiKey': true,
            'contextWindowSize': 8192,
            'isDisabled': true,
            'appBundleId': 'com.demo.app',
            'appName': 'Demo',
          },
        ];
      });
      final models = await ModelKitClient(
        apiClient: _apiClient(recorder),
      ).listAppModels();

      final request = recorder.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/modelkit/app-models');
      expect(request.headers.containsKey('authorization'), isFalse);

      final model = models.single;
      expect(model.id, 'app-model-1');
      expect(model.qualifiedId, 'app-model-1@com.demo.app');
      expect(model.task, ModelTask.decision);
      expect(model.outputModalities, <Modality>[Modality.decisions]);
      expect(model.capabilities.stream, isFalse);
      expect(model.baseUrl, 'http://127.0.0.1:9000');
      expect(model.hasApiKey, isTrue);
      expect(model.contextWindowSize, 8192);
      expect(model.isDisabled, isTrue);
      expect(model.appBundleId, 'com.demo.app');
      expect(model.appName, 'Demo');
    });

    test(
      'listAppModels falls back to the bare id when the gateway predates '
      'qualifiedId',
      () async {
        final recorder = _RecordingInterceptor(
          (options) => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'legacy-1',
              'name': 'legacy',
              'appBundleId': 'com.demo.app',
            },
          ],
        );
        final models = await ModelKitClient(
          apiClient: _apiClient(recorder),
        ).listAppModels();

        expect(models.single.id, 'legacy-1');
        expect(models.single.qualifiedId, 'legacy-1');
      },
    );

    test(
      'registerAppModel sends the bearer token and a minimal body',
      () async {
        final recorder = _RecordingInterceptor(
          (options) => <String, dynamic>{
            'success': true,
            'id': 'router',
            'qualifiedId': 'router@com.demo.app',
          },
        );
        final client = ModelKitClient(apiClient: _apiClient(recorder));

        final result = await client.registerAppModel(
          bearerToken: 'token-1',
          request: const AppModelRegistration(
            id: 'router',
            name: 'router',
            task: ModelTask.decision,
            baseUrl: 'http://127.0.0.1:9000',
            apiKey: 'secret',
          ),
        );

        final request = recorder.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/modelkit/app-models');
        expect(request.headers['authorization'], 'Bearer token-1');
        expect(request.data, <String, dynamic>{
          'id': 'router',
          'name': 'router',
          'task': 'decision',
          'baseUrl': 'http://127.0.0.1:9000',
          'apiKey': 'secret',
        });
        expect(result.success, isTrue);
        expect(result.id, 'router');
        expect(result.qualifiedId, 'router@com.demo.app');
        expect(result.updated, isFalse);
      },
    );

    test(
      'registerAppModel serializes optional fields and updated flag',
      () async {
        final recorder = _RecordingInterceptor(
          (options) => <String, dynamic>{
            'success': true,
            'id': 'chat-1',
            'updated': true,
          },
        );
        final client = ModelKitClient(apiClient: _apiClient(recorder));

        final result = await client.registerAppModel(
          bearerToken: 'token-1',
          request: const AppModelRegistration(
            id: 'chat-1',
            name: 'chat',
            alias: 'Chat',
            description: 'd',
            task: ModelTask.chat,
            provider: 'openai_compatible',
            inputModalities: <Modality>[Modality.text, Modality.image],
            outputModalities: <Modality>[Modality.text],
            stream: true,
            toolCall: true,
            reasoning: false,
            contextWindowSize: 32768,
            appBundleId: 'com.demo.app',
            appName: 'Demo',
          ),
        );

        expect(recorder.requests.single.data, <String, dynamic>{
          'id': 'chat-1',
          'name': 'chat',
          'alias': 'Chat',
          'description': 'd',
          'task': 'chat',
          'provider': 'openai_compatible',
          'input': <String>['text', 'image'],
          'output': <String>['text'],
          'capabilities': <String, dynamic>{
            'stream': true,
            'tool_call': true,
            'reasoning': false,
          },
          'contextWindowSize': 32768,
          'appBundleId': 'com.demo.app',
          'appName': 'Demo',
        });
        expect(result.updated, isTrue);
      },
    );

    test('registerAppModel keeps the status of name conflicts', () async {
      final recorder = _RecordingInterceptor(
        (options) => _httpError(options, 409, <String, dynamic>{
          'error': 'name already used by another model of this app',
        }),
      );
      final client = ModelKitClient(apiClient: _apiClient(recorder));

      await expectLater(
        client.registerAppModel(
          bearerToken: 'token-1',
          request: const AppModelRegistration(id: 'x', name: 'x'),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            409,
          ),
        ),
      );
    });

    test('updateAppModel sends a partial body to the encoded path', () async {
      final recorder = _RecordingInterceptor(
        (options) => <String, dynamic>{'success': true},
      );
      final client = ModelKitClient(apiClient: _apiClient(recorder));

      final result = await client.updateAppModel(
        bearerToken: 'token-1',
        modelId: 'team/router 1',
        request: const AppModelUpdate(
          name: 'renamed',
          task: ModelTask.decision,
          reasoning: false,
        ),
      );

      final request = recorder.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/modelkit/app-models/team%2Frouter%201');
      expect(request.headers['authorization'], 'Bearer token-1');
      expect(request.data, <String, dynamic>{
        'name': 'renamed',
        'task': 'decision',
        'capabilities': <String, dynamic>{'reasoning': false},
      });
      expect(result.success, isTrue);
      expect(result.id, isNull);
    });

    test(
      'unregisterAppModel and toggleAppModel hit the owner routes',
      () async {
        final recorder = _RecordingInterceptor(
          (options) => <String, dynamic>{'success': true},
        );
        final client = ModelKitClient(apiClient: _apiClient(recorder));

        await client.unregisterAppModel(bearerToken: 'token-1', modelId: 'm1');
        await client.toggleAppModel(bearerToken: 'token-1', modelId: 'm1');

        final delete = recorder.requests[0];
        expect(delete.method, 'DELETE');
        expect(delete.path, '/modelkit/app-models/m1');
        expect(delete.headers['authorization'], 'Bearer token-1');

        final toggle = recorder.requests[1];
        expect(toggle.method, 'POST');
        expect(toggle.path, '/modelkit/app-models/m1/toggle');
        expect(toggle.headers['authorization'], 'Bearer token-1');
        expect(toggle.data, isNull);
      },
    );
  });

  group('ModelKitModule app model auth', () {
    test('write calls use the registered app token', () async {
      final recorder = _RecordingInterceptor((options) {
        if (options.path == '/appkit/register') {
          return <String, dynamic>{'token': 'token-v1'};
        }
        return <String, dynamic>{'success': true, 'id': 'router'};
      });
      final sdk = AgentOSSDK(apiClient: _apiClient(recorder));
      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');

      await sdk.modelkit.registerAppModel(
        request: const AppModelRegistration(id: 'router', name: 'router'),
      );
      await sdk.modelkit.updateAppModel(
        modelId: 'router',
        request: const AppModelUpdate(name: 'r2'),
      );
      await sdk.modelkit.toggleAppModel(modelId: 'router');
      await sdk.modelkit.unregisterAppModel(modelId: 'router');

      final writes = recorder.requests
          .where((r) => r.path.startsWith('/modelkit/app-models'))
          .toList();
      expect(writes.map((r) => r.method).toList(), <String>[
        'POST',
        'PUT',
        'POST',
        'DELETE',
      ]);
      for (final request in writes) {
        expect(request.headers['authorization'], 'Bearer token-v1');
      }
    });

    test('a 401 re-registers the bundle and retries once', () async {
      var registerCount = 0;
      final recorder = _RecordingInterceptor((options) {
        if (options.path == '/appkit/register') {
          registerCount += 1;
          return <String, dynamic>{'token': 'token-v$registerCount'};
        }
        if (options.headers['authorization'] == 'Bearer token-v1') {
          return _httpError(options, 401, <String, dynamic>{
            'error': 'unauthorized',
          });
        }
        return <String, dynamic>{'success': true, 'id': 'router'};
      });
      final sdk = AgentOSSDK(apiClient: _apiClient(recorder));
      await sdk.agentos.registerBundle(bundleId: 'com.demo.app');

      final result = await sdk.modelkit.registerAppModel(
        request: const AppModelRegistration(id: 'router', name: 'router'),
      );

      expect(result.id, 'router');
      expect(registerCount, 2);
      final attempts = recorder.requests
          .where((r) => r.path == '/modelkit/app-models')
          .map((r) => r.headers['authorization'])
          .toList();
      expect(attempts, <String>['Bearer token-v1', 'Bearer token-v2']);
    });

    test('write calls require registerBundle first', () async {
      final recorder = _RecordingInterceptor((options) => <String, dynamic>{});
      final sdk = AgentOSSDK(apiClient: _apiClient(recorder));

      await expectLater(
        sdk.modelkit.toggleAppModel(modelId: 'router'),
        throwsA(isA<StateError>()),
      );
      expect(recorder.requests, isEmpty);
    });

    test('listAppModels and decision need no registration', () async {
      final recorder = _RecordingInterceptor((options) {
        if (options.path == '/modelkit/app-models') {
          return <Map<String, dynamic>>[];
        }
        return <String, dynamic>{'answers': <String, dynamic>{}};
      });
      final sdk = AgentOSSDK(apiClient: _apiClient(recorder));

      expect(await sdk.modelkit.listAppModels(), isEmpty);
      final response = await sdk.modelkit.decision.create(
        state: 's',
        questions: <String, DecisionQuestion>{
          'q': DecisionQuestion.noul(instructions: 'ok?'),
        },
      );
      expect(response.answers, isEmpty);
    });
  });
}

ApiClient _apiClient(Interceptor interceptor) {
  final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
    ..interceptors.add(interceptor);
  return ApiClient(dio: dio);
}

DioException _httpError(RequestOptions options, int status, Object? body) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

/// Resolves every request with the value returned by [_responder] (or rejects
/// when it returns a [DioException]) and records the requests it saw.
class _RecordingInterceptor extends Interceptor {
  _RecordingInterceptor(this._responder);

  final Object? Function(RequestOptions options) _responder;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    final result = _responder(options);
    if (result is DioException) {
      handler.reject(result);
      return;
    }
    handler.resolve(
      Response<dynamic>(requestOptions: options, statusCode: 200, data: result),
    );
  }
}

AgentOSSDK _buildSdk() {
  final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
    ..interceptors.add(_ModelKitInterceptor());
  return AgentOSSDK(apiClient: ApiClient(dio: dio));
}

class _ModelKitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET' && options.path == '/modelkit/models') {
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '03bafcf5fd66',
              'name': 'glm-5.1',
              'alias': 'glm-5.1_Jan',
              'task': 'chat',
              'capabilities': <String, dynamic>{
                'vision': true,
                'tool_call': true,
                'stream': true,
                'reasoning': true,
              },
              'isRemote': true,
              'isCustom': true,
            },
            <String, dynamic>{
              'id': 'embedding-1',
              'name': 'embedding-model',
              'alias': 'embedding-model',
              'task': 'embedding',
              'capabilities': <String, dynamic>{'reasoning': false},
            },
            <String, dynamic>{
              'id': 'asr-1',
              'name': 'asr-model',
              'alias': 'asr-model',
              'task': 'asr',
              'capabilities': <String, dynamic>{},
            },
          ],
        ),
      );
      return;
    }
    handler.reject(
      DioException(
        requestOptions: options,
        message: 'Unexpected request: ${options.method} ${options.path}',
      ),
    );
  }
}
