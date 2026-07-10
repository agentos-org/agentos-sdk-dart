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
  /// Body: {"bundleId":"com.mydomain.myapp","appGroupId":"com.mydomain.shared"}
  final registration = await sdk.agentos.registerBundle(
    bundleId: bundleId,
    appGroupId: 'com.mydomain.shared',
  );
  print(
    'Registered bundle (bundleId: ${registration.bundleId}, appGroupId: ${registration.appGroupId})',
  );

  if (args.length >= 2 && args.first == '--history') {
    final messages = await sdk.agentkit.history(
      sessionId: args[1],
      page: 1,
      pageSize: 50,
    );
    for (final message in messages) {
      print(
        'History task ${message.taskId} '
        '(root: ${message.originalTaskId}): ${message.content}',
      );
    }
  }

  sdk.agentos.connectionEvents.listen((event) {
    print(
      'Subscribe connection status: ${event.status.name}'
      '${event.attempt > 0 ? ' (attempt ${event.attempt})' : ''}',
    );
  });

  print('Subscribe AgentOS event...');

  /// HTTP:
  /// GET http://localhost:8888/appkit/subscribe
  /// Headers: Authorization: Bearer <token from registerBundle>
  /// Response: text/event-stream (SSE)
  await sdk.agentos.subscribe(_DemoEventHandler());

  /// HTTP:
  /// GET http://localhost:8888/modelkit/models
  final models = await sdk.modelkit.listModels();
  print(
    'Available modelkit models: ${models.map((m) => "${m.alias}(${m.task.name})").join(", ")}',
  );

  /// HTTP:
  /// POST http://localhost:8888/modelkit/chat/v1/chat/completions
  final chatCompletion = await sdk.modelkit.chat.create(
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
