import 'dart:async';
import 'dart:io';

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
  /// Body: {"bundleId":"com.mydomain.myapp","appGroupId":"com.mydomain.shared","opentoolServers":[{"ref":"websearch","name":"opentool-server-websearch"}]}
  final registration = await sdk.agentos.registerBundle(
    bundleId: bundleId,
    appGroupId: 'com.mydomain.shared',
    opentoolServers: const <OpenToolServerDeclaration>[
      OpenToolServerDeclaration(
        ref: 'websearch',
        name: 'opentool-server-websearch',
      ),
    ],
  );
  print(
    'Registered bundle (bundleId: ${registration.bundleId}, appGroupId: ${registration.appGroupId})',
  );
  for (final server in registration.opentoolServers) {
    print(
      'OpenTool ${server.ref}: ${server.status}'
      '${server.id == null ? '' : ' (${server.id})'}',
    );
  }

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

  if (args.length >= 2 && args.first == '--agent-chat') {
    final handler = _DemoAgentMessageHandler();
    await sdk.agentkit.chat(
      Session(sessionId: args[1]),
      UserTask(
        content: <Content>[Content(type: 'text', message: userMessage)],
        isChunk: true,
      ),
      handler,
    );
    print('Agent chat started. Press Enter to cancel.');
    final shouldStop = await Future.any<bool>(<Future<bool>>[
      handler.done.then((_) => false),
      stdin.first.then((_) => true),
    ]);
    if (shouldStop) {
      await sdk.agentkit.stop(sessionId: args[1]);
    }
    await sdk.dispose();
    return;
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
  Future<void> onAppEvent(AppEvent event) async {
    final success = event.openToolProvisionSuccess;
    if (success != null) {
      print('OpenTool ${success.ref} is ready: ${success.id}');
      return;
    }
    final failure = event.openToolProvisionFailure;
    if (failure != null) {
      print(
        'OpenTool ${failure.ref} failed: '
        '${failure.error.code} ${failure.error.message}',
      );
    }
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

class _DemoAgentMessageHandler extends AgentMessageHandler {
  final Completer<void> _done = Completer<void>();

  Future<void> get done => _done.future;

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {
    print('[$sessionId] ${agentMessage.content}');
  }

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {
    stdout.write(agentMessageChunk.part);
  }

  @override
  Future<void> onDone() async {
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> onError(Exception error) async {
    stderr.writeln('Agent chat failed: $error');
    if (!_done.isCompleted) _done.complete();
  }
}
