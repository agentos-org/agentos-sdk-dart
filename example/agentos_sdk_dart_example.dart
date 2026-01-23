import 'package:agentos_sdk/agentos_sdk.dart';

Future<void> main(List<String> args) async {
  final bundleId = "com.mydomain.myapp";
  /// TODO: Replace with the model you want the agent to use.
  final llmModel = "qwen3-1.7b";
  /// TODO: Adjust the system prompt for your agent.
  final systemPrompt = "You are a helpful assistant.";
  /// TODO: Replace with the user message you want to send.
  final userMessage = "Hello.";

  final sdk = AgentOSSDK();

  /// HTTP:
  /// GET http://localhost:20261/version
  final version = await sdk.agentos.getVersion();
  print('AgentOS API version: ${version.version}');

  /// HTTP:
  /// POST http://localhost:20261/appkit/register
  /// Body: {"bundleId":"com.mydomain.myapp"}
  await sdk.agentos.registerBundle(bundleId: bundleId);
  print('Registered bundle (bundleId: $bundleId)');

  print('Subscribe AgentOS event...');
  /// HTTP:
  /// GET http://localhost:20261/appkit/subscribe
  /// Headers: Authorization: Bearer <token from registerBundle>
  /// Response: text/event-stream (SSE)
  await sdk.agentos.subscribe(_DemoEventHandler());

  final capability = Capability(
    llmConfig: LLMConfig(
      model: llmModel,
    ),
    systemPrompt: systemPrompt,
  );
  /// HTTP:
  /// POST http://localhost:20261/agentkit/initSession
  /// Headers: Authorization: Bearer <token from registerBundle>
  /// Body:
  /// {
  ///   "systemPrompt":"You are a helpful assistant.",
  ///   "llmConfig":{
  ///     "baseUrl":"http://localhost:8888/llmkit/text",
  ///     "apiKey":"sk-...",
  ///     "model":"qwen3-1.7b",
  ///     "temperature":0.0,
  ///     "maxTokens":4096,
  ///     "topP":1.0
  ///   }
  /// }
  final session = await sdk.agentkit.initSession(
    capability: capability
  );
  final sessionId = session['sessionId']?.toString() ?? '';
  print('Session id: $sessionId');

  /// HTTP:
  /// POST http://localhost:20261/agentkit/chat?sessionId=<sessionId>
  /// Headers: Authorization: Bearer <token from registerBundle>
  /// Body:
  /// {"isChunk":true,"content":[{"type":"text","message":"Hello."}]}
  /// Response: text/event-stream (SSE)
  await sdk.agentkit.chat(
    Session(sessionId: sessionId),
    UserTask(
      isChunk: true,
      content: <Content>[
        Content(type: ContentType.text, message: userMessage),
      ],
    ),
    _DemoMessageHandler()
  );
}

class _DemoEventHandler extends AgentOSEventHandler {
  @override
  Future<void> onWelcome(Welcome welcome) async {
    print('Welcome bundleId: ${welcome.bundleId}');
  }

  @override
  Future<void> onCall(Call call) async {
    print('Call event: ${call.id}');
  }

  @override
  Future<void> onDone() async {
    print('SSE subscription ended');
  }

  @override
  Future<void> onError(Exception error) async {
    print('Failed to subscribe: $error');
  }
}

class _DemoMessageHandler extends AgentMessageHandler {
  @override
  Future<void> onChunk(String sessionId, AgentMessageChunk agentMessageChunk) async {
    print("sessionId: $sessionId; chunk: ${agentMessageChunk.toJson()}");
  }

  @override
  Future<void> onDone() async {
    print("DONE");
  }

  @override
  Future<void> onError(Exception e) async {
    print("ERROR: ${e.toString()}");
  }

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {
    print("sessionId: $sessionId; message: ${agentMessage.toJson()}");
  }

}
