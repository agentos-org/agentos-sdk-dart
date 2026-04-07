# AgentOS SDK for Dart

A lightweight Dart SDK for the AgentOS API, supporting Root, AgentKit, AppKit,
CronKit, RagKit, LlmKit chat, and ToolKit discovery endpoints. Use the unified
`AgentOSSDK` to avoid managing tokens manually.

## Features

- Root API: version check
- AgentKit API: agent CRUD, session init,
  chat stream/simple, history, stop/clear, callbacks)
- AppKit API: bundle registration and SSE subscription
- CronKit API: cron task CRUD, run history, and scheduler control
- RagKit API: RAG base, document, sync, and query endpoints
- LlmKit API: model listing and OpenAI-compatible chat client at
  `/llmkit/text`
- ToolKit API: tool listing, tool definition loading, and tool lifecycle event
  subscription

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  agentos_sdk: ^0.1.0
```

Then run:

```bash
dart pub get
```

Use a single public import:

```dart
import 'package:agentos_sdk/agentos_sdk.dart';
```

## Usage

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

Future<void> main() async {
  final sdk = AgentOSSDK();

  final version = await sdk.agentos.getVersion();
  print('AgentOS version: ${version.version}');

  final registration = await sdk.agentos.registerBundle(
    bundleId: 'com.demo.app',
    appGroupId: 'com.demo.group',
  );
  print('App token: ${registration.token}');

  await sdk.agentos.subscribe(_DemoEventHandler());
  await Future<void>.delayed(const Duration(seconds: 1));
}

class _DemoEventHandler extends AgentOSEventHandler {
  @override
  Future<void> onWelcome(Welcome welcome) async {
    print('Welcome bundleId: ${welcome.bundleId}');
  }

  @override
  Future<void> onCallApp(Call call) async {
    print('CallApp bundleId: ${call.bundleId}');
  }

  @override
  Future<void> onDone() async {
    print('SSE subscription ended');
  }

  @override
  Future<void> onError(Exception error) async {
    print('Subscribe error: $error');
  }
}
```

### Configure Gateway Address

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(baseUrl: 'http://localhost:8888');
```

### Configure Long-Running Stream Timeouts

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(
  baseUrl: 'http://localhost:8888',
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: Duration.zero, // keep long SSE streams alive
);
```

### Use LlmKit Chat

`agentos_sdk` re-exports `package:dart_openai_sdk/dart_openai_sdk.dart`, so you
can use OpenAI chat request/response types directly.

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(baseUrl: 'http://localhost:8888');

final models = await sdk.llmkit.listModels();
print(models.map((model) => model.alias).toList());

final completion = await sdk.llmkit.chat.create(
  model: 'qwen3-1.7b',
  messages: <OpenAIChatCompletionChoiceMessageModel>[
    OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.user,
      content: <OpenAIChatCompletionChoiceMessageContentItemModel>[
        OpenAIChatCompletionChoiceMessageContentItemModel.text('Hello.'),
      ],
    ),
  ],
);

print(completion.choices.first.message.content?.first.text);
```

## API Reference

### AgentOSSDK

Constructor:

```dart
AgentOSSDK({
  String? baseUrl,
  Duration? connectTimeout,
  Duration? receiveTimeout,
})
```

Use `baseUrl`, `connectTimeout`, and `receiveTimeout` for public configuration.

| Property | Type | Description |
| --- | --- | --- |
| `agentos` | `AgentOSModule` | Root/AppKit endpoints with internal token handling. |
| `agentkit` | `AgentKitModule` | AgentKit endpoints with internal token handling. |
| `cronkit` | `CronKitModule` | CronKit task management endpoints with internal token handling. |
| `ragkit` | `RagKitModule` | RagKit knowledge-base endpoints with internal token handling. |
| `llmkit` | `LlmKitModule` | LlmKit model listing and preconfigured chat client. |
| `toolkit` | `ToolKitModule` | ToolKit discovery endpoints and tool lifecycle event subscription. |
| `dispose()` | `Future<void>` | Releases SDK resources and cancels active AppKit subscription. |

### AgentOSModule (`sdk.agentos`)

| Method | Parameters | Description |
| --- | --- | --- |
| `getVersion()` | none | Fetches AgentOS service version. |
| `getRoot()` | none | Fetches AgentOS gateway metadata. |
| `getReady()` | none | Fetches AgentOS readiness status. |
| `registerBundle({required String bundleId, String? appGroupId})` | `bundleId`, `appGroupId` | Registers an app bundle, stores the bearer token internally, and returns token metadata. |
| `subscribe(AgentOSEventHandler handler)` | `handler` | Subscribes to AppKit SSE events using a handler implementation. |

### CronKitModule (`sdk.cronkit`)

| Method | Parameters | Description |
| --- | --- | --- |
| `getTask({required String cronId})` | `cronId` | Fetches a cron task by ID. |
| `listTasks({bool? enabled, int? offset, int? limit})` | `enabled`, `offset`, `limit` | Lists visible cron tasks for the current app group. |
| `createTask({required CronTaskCreateRequest request})` | `request` | Creates a cron task. |
| `updateTask({required CronTaskUpdateRequest request})` | `request` | Updates a cron task owned by the current app. |
| `deleteTask({required String cronId})` | `cronId` | Deletes a cron task owned by the current app. |
| `enableTask({required String cronId})` | `cronId` | Explicitly enables a cron task and returns its updated status. |
| `disableTask({required String cronId})` | `cronId` | Explicitly disables a cron task and returns its updated status. |
| `runTaskNow({required String cronId, DateTime? scheduledAt})` | `cronId`, `scheduledAt` | Triggers an immediate run for a cron task. |
| `getRun({required String runId})` | `runId` | Fetches one cron run record by ID. |
| `listRuns({String? cronId, DateTime? after, DateTime? before, int? offset, int? limit})` | `cronId`, `after`, `before`, `offset`, `limit` | Lists cron task runs visible to the current app group. |
| `listRunMessages({required String runId, int? offset, int? limit})` | `runId`, `offset`, `limit` | Lists persisted `AgentMessage` records for a cron run. |
| `deleteRun({required String runId})` | `runId` | Deletes one cron run and its persisted messages. |

`CronTaskCreateRequest.spec` and `CronTask.spec` use the CronKit schema:

```dart
CronSpec(
  systemPrompt: 'You are a scheduled agent.',
  content: <Content>[
    Content(type: ContentType.text, message: 'Generate the daily summary.'),
  ],
  modelId: 'gpt-4o', // optional request input
)
```

- `modelId` is an optional request field used by CronKit to resolve the backing model.
- `modelName` is an optional response field returned in `CronTask.spec` after resolution.

### AgentKitModule (`sdk.agentkit`)

| Method | Parameters | Description |
| --- | --- | --- |
| `getAgent({required String agentId})` | `agentId` | Retrieves an agent by `agentId`. |
| `createAgent({required Agent agent})` | `agent` | Creates an agent with the provided payload. |
| `updateAgent({required String agentId, required Agent agent})` | `agentId`, `agent` | Updates an agent by `agentId`. |
| `deleteAgent({required String agentId})` | `agentId` | Deletes an agent by `agentId`. |
| `initSession({String? agentId, Capability? capability})` | `agentId`, `capability` | Initializes a SessionAgent session. |
| `initSimple({required SimpleCapability simpleCapability})` | `simpleCapability` | Initializes a SimpleAgent session. |
| `chat(Session session, UserTask userTask, AgentMessageHandler agentMessageHandler)` | `session`, `userTask`, `agentMessageHandler` | Starts a SessionAgent task and delivers SSE events to the handler callbacks. |
| `chatSimple({required String sessionId, required UserTask userTask})` | `sessionId`, `userTask` | Executes a SimpleAgent request and returns a one-time response. |
| `history({required String sessionId})` | `sessionId` | Retrieves message history for a session. |
| `stop({required String sessionId, String? taskId})` | `sessionId`, `taskId` | Stops a session or task. |
| `clear({required String sessionId})` | `sessionId` | Clears session data. |
| `callback({required String sessionId, required ToolReturn toolReturn})` | `sessionId`, `toolReturn` | Sends tool callback results. |
| `streamCallback({required String sessionId, required EventToolReturn eventToolReturn})` | `sessionId`, `eventToolReturn` | Sends streaming tool callback results. |

### RagKitModule (`sdk.ragkit`)

| Method | Parameters | Description |
| --- | --- | --- |
| `getBase({required String baseId})` | `baseId` | Fetches a RAG base by ID. |
| `listBases({int? offset, int? limit})` | `offset`, `limit` | Lists RAG bases visible to the current app group. |
| `createBase({required RagBaseCreateRequest request})` | `request` | Creates a RAG base. |
| `updateBase({required RagBaseUpdateRequest request})` | `request` | Updates a RAG base owned by the current app. |
| `deleteBase({required String baseId})` | `baseId` | Deletes a RAG base owned by the current app. |
| `getDocument({required String baseId, required String documentId})` | `baseId`, `documentId` | Fetches one RAG document. |
| `listDocuments({required String baseId, int? offset, int? limit})` | `baseId`, `offset`, `limit` | Lists documents inside a RAG base. |
| `upsertDocument({required RagUpsertDocumentRequest request})` | `request` | Creates or updates one markdown document. |
| `upsertDocuments({required RagUpsertDocumentsRequest request})` | `request` | Batch creates or updates markdown documents. |
| `deleteDocument({required String baseId, required String documentId})` | `baseId`, `documentId` | Deletes one RAG document. |
| `syncDocument({required String baseId, required String documentId})` | `baseId`, `documentId` | Triggers embeddings sync for one document. |
| `syncBase({required String baseId})` | `baseId` | Triggers embeddings sync for one base. |
| `retryFailed({String? baseId})` | `baseId` | Retries failed document sync jobs, optionally scoped to one base. |
| `query({required RagQueryRequest request})` | `request` | Runs a semantic query against one RAG base. |

### LlmKitModule (`sdk.llmkit`)

| Method/Property | Type | Description |
| --- | --- | --- |
| `listModels()` | `Future<List<LlmModelInfo>>` | Fetches available LLM models from `/llmkit/models`. |
| `chat` | `LlmKitChatClient` | Preconfigured OpenAI-compatible chat client using `{baseUrl}/llmkit/text`. |

### ToolKitModule (`sdk.toolkit`)

| Method | Parameters | Description |
| --- | --- | --- |
| `listTool([String? all])` | `all` | Lists available tools from `/toolkit/list`. |
| `loadTool(String toolId)` | `toolId` | Loads an `OpenTool` definition from `/toolkit/{toolId}/load`. |
| `subscribeToolEvents({required String daemonApiKey, bool snapshot = true})` | `daemonApiKey`, `snapshot` | Subscribes to `/toolkit/events` and streams `ToolLifecycleEventDto` updates. |

### AgentOSEventHandler

| Method | Parameters | Description |
| --- | --- | --- |
| `onWelcome(Welcome welcome)` | `welcome` | Receives `welcome` events. |
| `onCallApp(Call call)` | `call` | Receives `callApp` events. |
| `onDone()` | none | Called when the SSE stream ends. |
| `onError(Exception error)` | `error` | Called when the SSE stream errors. |

### Subscription Lifecycle

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(baseUrl: 'http://localhost:8888');

await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
await sdk.agentos.subscribe(myHandler); // app start

// app stop/dispose
await sdk.dispose();
```

### AgentKit Schema Notes

- `UserTask` supports passthrough fields:
  - `extraSystemPrompt`
  - `llmConfig`
- `LLMConfig` supports:
  - `contextWindowSize`
  - `supportsToolCall` (read/write)
  - `supportsReasoning` (read/write)
  - read compatibility for `supportsToolCalling` and `supportsDeepThinking`
- `Capability` supports:
  - `llmConfigList`
  - `toolReturnPackMinLength`
- `AgentMessage.completions` supports `limits`:
  - `maxTokens`
  - `contextWindowSize`

### AgentMessageHandler (Tool Callback)

- Implement `onFunctionCall(...)` for non-stream tool calls. The SDK sends the
  returned value via `/agentkit/callback`.
- Implement `onStreamFunctionCall(...)` for stream tool calls. The SDK sends
  each event via `/agentkit/streamCallback`.

```dart
class MyHandler extends AgentMessageHandler {
  @override
  Future<void> onStreamFunctionCall(
    String sessionId,
    FunctionCall functionCall,
    void Function(EventToolReturn) onToolReturn,
  ) async {
    onToolReturn(
      EventToolReturn(
        event: EventType.DATA,
        toolReturn: ToolReturn(
          id: functionCall.id,
          result: <String, dynamic>{'partial': '...'},
        ),
      ),
    );
    onToolReturn(
      EventToolReturn(
        event: EventType.DONE,
        toolReturn: ToolReturn(
          id: functionCall.id,
          result: <String, dynamic>{'ok': true},
        ),
      ),
    );
  }

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {}
  @override
  Future<void> onChunk(String sessionId, AgentMessageChunk chunk) async {}
  @override
  Future<void> onDone() async {}
  @override
  Future<void> onError(Exception error) async {}
}
```

## Token Handling

- `agentos.registerBundle` stores the bearer token internally.
- `agentkit`/`agentos` requests use the stored token automatically.

## Configuration

- Base URL is managed by the SDK and defaults to `http://localhost:8888`.

## Notes

- Call `agentos.registerBundle` before using `agentkit`/`agentos` APIs that
  require a token.
- `AgentOSSDK` exposes module properties (`agentos`, `agentkit`, `llmkit`,
  `toolkit`) for clearer separation of API areas.
- AgentKit endpoints are exposed under `/agentkit/*`.
- `sdk.llmkit.chat` currently exposes chat only and targets
  `/llmkit/text/chat/completions` by default.
- `sdk.toolkit.subscribeToolEvents(...)` requires a daemon API key and streams
  tool lifecycle events via SSE.
- External integrations should use only `package:agentos_sdk/agentos_sdk.dart`
  and avoid importing `package:agentos_sdk/src/...`.

## Development

```bash
dart format .
dart analyze
dart test
```

Regenerate JSON models when DTOs change:

```bash
dart run build_runner build --delete-conflicting-outputs
```
