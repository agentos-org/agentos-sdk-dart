import 'package:agentos_sdk/agentos_sdk.dart';

Future<void> main(List<String> args) async {
  final bundleId = "com.mydomain.myapp";
  final llmModel = "qwen3-1.7b";
  final userMessage = "Hello.";

  final sdk = AgentOSSDK();

  /// HTTP:
  /// GET http://localhost:8888/version
  final version = await sdk.agentos.getVersion();
  print('AgentOS API version: ${version.version}');

  /// HTTP:
  /// POST http://localhost:8888/appkit/register
  /// Body: {"bundleId":"com.mydomain.myapp"}
  await sdk.agentos.registerBundle(bundleId: bundleId);
  print('Registered bundle (bundleId: $bundleId)');

  print('Subscribe AgentOS event...');

  /// HTTP:
  /// GET http://localhost:8888/appkit/subscribe
  /// Headers: Authorization: Bearer <token from registerBundle>
  /// Response: text/event-stream (SSE)
  await sdk.agentos.subscribe(_DemoEventHandler());

  /// HTTP:
  /// GET http://localhost:8888/llmkit/models
  final models = await sdk.llmkit.listModels();
  print('Available llmkit models: ${models.map((m) => m.alias).join(", ")}');

  /// HTTP:
  /// POST http://localhost:8888/llmkit/text/chat/completions
  final chatCompletion = await sdk.llmkit.chat.create(
    model: llmModel,
    messages: <OpenAIChatCompletionChoiceMessageModel>[
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: <OpenAIChatCompletionChoiceMessageContentItemModel>[
          OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
        ],
      ),
    ],
  );
  print(chatCompletion.choices.first.message.content?.first.text);
}

class _DemoEventHandler extends AgentOSEventHandler {
  @override
  Future<void> onWelcome(Welcome welcome) async {
    print('Welcome bundleId: ${welcome.bundleId}');
  }

  @override
  Future<void> onCallApp(Call call) async {
    print('CallApp event for ${call.bundleId}: ${call.contentList}');
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
