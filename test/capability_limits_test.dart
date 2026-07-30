import 'package:agentos_sdk/agentos_sdk.dart';
import 'package:agentos_sdk/src/client/agentkit/agentkit_client.dart';
import 'package:agentos_sdk/src/utils/api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  const limits = <String, int>{
    'maxLlmRequests': 32,
    'maxToolRounds': 8,
    'maxToolCalls': 20,
    'maxConsecutiveIdenticalToolRounds': 2,
    'maxTaskDurationSeconds': 120,
  };

  Capability capability() => Capability(
    systemPrompt: 'You are an assistant',
    maxLlmRequests: limits['maxLlmRequests'],
    maxToolRounds: limits['maxToolRounds'],
    maxToolCalls: limits['maxToolCalls'],
    maxConsecutiveIdenticalToolRounds:
        limits['maxConsecutiveIdenticalToolRounds'],
    maxTaskDurationSeconds: limits['maxTaskDurationSeconds'],
  );

  group('Capability execution limits', () {
    test('serializes all execution limit fields', () {
      final json = capability().toJson();

      for (final entry in limits.entries) {
        expect(json[entry.key], entry.value);
      }
    });

    test('deserializes all execution limit fields', () {
      final value = Capability.fromJson(<String, dynamic>{
        'systemPrompt': 'You are an assistant',
        ...limits,
      });

      expect(value.maxLlmRequests, 32);
      expect(value.maxToolRounds, 8);
      expect(value.maxToolCalls, 20);
      expect(value.maxConsecutiveIdenticalToolRounds, 2);
      expect(value.maxTaskDurationSeconds, 120);
    });

    test('omits absent execution limits and preserves non-positive values', () {
      final absent = Capability(systemPrompt: 'No limits').toJson();
      final nonPositive = Capability(
        systemPrompt: 'Server validates limits',
        maxLlmRequests: 0,
        maxToolRounds: -1,
      ).toJson();

      for (final key in limits.keys) {
        expect(absent, isNot(contains(key)));
      }
      expect(nonPositive['maxLlmRequests'], 0);
      expect(nonPositive['maxToolRounds'], -1);
    });

    test('passes execution limits through AgentKit request bodies', () async {
      final interceptor = _RequestBodyInterceptor();
      final dio = Dio(BaseOptions(baseUrl: 'http://fake.local'))
        ..interceptors.add(interceptor);
      final client = AgentKitClient(apiClient: ApiClient(dio: dio));
      final value = capability();
      final agent = Agent(name: 'limited-agent', capability: value);

      await client.initSession(bearerToken: 'token', capability: value);
      await client.createAgent(bearerToken: 'token', agent: agent);
      await client.updateAgent(
        bearerToken: 'token',
        agentId: 'agent-1',
        agent: agent,
      );

      final initSessionBody = interceptor.bodies['/agentkit/initSession']!;
      final createCapability =
          interceptor.bodies['/agentkit/agent/create']!['capability']
              as Map<String, dynamic>;
      final updateCapability =
          interceptor.bodies['/agentkit/agent/update']!['capability']
              as Map<String, dynamic>;

      for (final entry in limits.entries) {
        expect(initSessionBody[entry.key], entry.value);
        expect(createCapability[entry.key], entry.value);
        expect(updateCapability[entry.key], entry.value);
      }
    });
  });
}

class _RequestBodyInterceptor extends Interceptor {
  final Map<String, Map<String, dynamic>> bodies =
      <String, Map<String, dynamic>>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    bodies[options.path] = Map<String, dynamic>.from(options.data as Map);
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{},
      ),
    );
  }
}
