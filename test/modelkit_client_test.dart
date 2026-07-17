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
