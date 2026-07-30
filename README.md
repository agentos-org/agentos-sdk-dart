# AgentOS SDK for Dart

A lightweight Dart SDK for the AgentOS API, supporting Root, AgentKit, AppKit,
CronKit, RagKit, ModelKit (chat / embedding / asr / tts), and ToolKit discovery
endpoints. Use the unified `AgentOSSDK` to avoid managing tokens manually.

## Features

- Root API: version check
- AgentKit API: agent CRUD, session init,
  chat stream/simple, history, stop/clear, callbacks)
- AppKit API: bundle registration and SSE subscription
- CronKit API: cron task CRUD, run history, and scheduler control
- RagKit API: RAG base, document, sync, and query endpoints
- ModelKit API: task-oriented model listing and OpenAI-compatible chat /
  embedding / asr / tts clients under `/modelkit/*`
- ToolKit API: tool listing, tool definition loading, and tool lifecycle event
  subscription

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  agentos_sdk: ^0.6.1
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
    opentoolServers: const <OpenToolServerDeclaration>[
      OpenToolServerDeclaration(
        ref: 'websearch',
        name: 'opentool-server-websearch',
      ),
    ],
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
  Future<void> onAppEvent(AppEvent event) async {
    final success = event.openToolProvisionSuccess;
    if (success != null) {
      print('OpenTool ${success.ref} is ready: ${success.id}');
      return;
    }
    final failure = event.openToolProvisionFailure;
    if (failure != null) {
      print('OpenTool ${failure.ref} failed: ${failure.error.message}');
    }
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

### Use ModelKit Chat

`agentos_sdk` re-exports `package:dart_openai_sdk/dart_openai_sdk.dart`, so you
can use OpenAI chat request/response types directly.

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(baseUrl: 'http://localhost:8888');

final models = await sdk.modelkit.listModels();
print(models.map((model) => '${model.alias} (${model.task.name})').toList());

// Or filter by task:
final chatModels = await sdk.modelkit.listModelsByTask(ModelTask.chat);

final completion = await sdk.modelkit.chat.create(
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

`sdk.modelkit` returns `ModelInfo`, classified by `task` + `capabilities`.

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
| `modelkit` | `ModelKitModule` | ModelKit task-oriented model listing and chat / embedding / asr / tts clients. |
| `toolkit` | `ToolKitModule` | ToolKit discovery endpoints and tool lifecycle event subscription. |
| `dispose()` | `Future<void>` | Releases SDK resources and cancels active AppKit subscription. |

### AgentOSModule (`sdk.agentos`)

| Method | Parameters | Description |
| --- | --- | --- |
| `getVersion()` | none | Fetches AgentOS service version. |
| `getRoot()` | none | Fetches AgentOS gateway metadata. |
| `getReady()` | none | Fetches AgentOS readiness status. |
| `registerBundle({required String bundleId, String? appGroupId, List<OpenToolServerDeclaration> opentoolServers = const []})` | `bundleId`, `appGroupId`, `opentoolServers` | Registers an app bundle, declares native OpenTool server dependencies, stores the bearer token internally, and returns registration statuses. |
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
| `history({required String sessionId, int? page, int? pageSize})` | `sessionId`, `page`, `pageSize` | Retrieves typed message history. Supply positive, 1-based `page` and `pageSize` together for pagination, or omit both for the complete history. |
| `historySummary({required String sessionId, int page = 1, int pageSize = 30})` | `sessionId`, `page`, `pageSize` | Retrieves summary-first task history. |
| `historyProcess({required String sessionId, required String originalTaskId, int page = 1, int pageSize = 50})` | `sessionId`, `originalTaskId`, `page`, `pageSize` | Lazily retrieves process messages for one task turn. |
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

### ModelKitModule (`sdk.modelkit`)

| Method/Property | Type | Description |
| --- | --- | --- |
| `listModels()` | `Future<List<ModelInfo>>` | Fetches available models from `/modelkit/models`. |
| `listModelsByTask(ModelTask task)` | `Future<List<ModelInfo>>` | Returns models filtered by task (`chat` / `embedding` / `asr` / `tts`). |
| `chat` | `ModelKitChatClient` | OpenAI-compatible chat client using `{baseUrl}/modelkit/chat`. |
| `embedding` | `ModelKitEmbeddingClient` | OpenAI-compatible embeddings client under `/modelkit/embedding`. |
| `asr` | `ModelKitAsrClient` | Speech-to-text client under `/modelkit/asr`. |
| `tts` | `ModelKitTtsClient` | Text-to-speech client under `/modelkit/tts`. |

`ModelInfo` describes each model with `task` (`ModelTask`), `inputModalities` /
`outputModalities` (`Modality`), and `capabilities` (`ModelCapabilities`:
`vision` / `toolCall` / `stream` / `reasoning`). In particular,
`capabilities.reasoning` is a `bool`. Convenience getters `hasVision`,
`supportsChatInference`, and `isVisionLanguage` are provided.

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
| `onAppEvent(AppEvent event)` | `event` | Receives AppKit business events, including asynchronous OpenTool provisioning success and failure results. |
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

`Capability` also accepts these optional execution limits. The SDK forwards
provided integer values unchanged, omits `null` values, and leaves validation
and defaults to the server.

| Field | Meaning | Server default |
| --- | --- | --- |
| `maxLlmRequests` | Maximum LLM requests for one tool-based task. | `64` |
| `maxToolRounds` | Maximum tool-call rounds for one task. | `16` |
| `maxToolCalls` | Maximum total tool calls for one task. | `64` |
| `maxConsecutiveIdenticalToolRounds` | Maximum consecutive rounds with identical tool calls. | `3` |
| `maxTaskDurationSeconds` | Maximum duration of one tool-based task, in seconds. | `300` |

```dart
final capability = Capability(
  systemPrompt: 'You are an assistant',
  maxLlmRequests: 32,
  maxToolRounds: 8,
  maxToolCalls: 20,
  maxConsecutiveIdenticalToolRounds: 2,
  maxTaskDurationSeconds: 120,
);

await sdk.agentkit.initSession(capability: capability);

final agent = Agent(name: 'limited-agent', capability: capability);
await sdk.agentkit.createAgent(agent: agent);
await sdk.agentkit.updateAgent(agentId: 'agent-id', agent: agent);
```

- `AgentMessage.completions` supports `limits`:
  - `maxTokens`
  - `contextWindowSize`
- `AgentMessage.originalTaskId` identifies the root task and falls back to
  `taskId` when reading older responses.
- `TaskStatus.taskId` identifies the task associated with a status update.

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

`chat(...)` keeps the SSE subscription inside the SDK and exposes events only
through `AgentMessageHandler`. Event callbacks are processed serially, so
`onDone()` runs only after the final event callback completes.

```dart
await sdk.agentkit.chat(
  Session(sessionId: sessionId),
  userTask,
  myHandler,
);

// Stops the remote task and closes active local chat streams for the session.
await sdk.agentkit.stop(sessionId: sessionId);
```

`AgentOSSDK.dispose()` also closes every active AgentKit chat stream. The public
API does not expose the underlying Dart stream subscription.

- `CallbackOpenTool.timeout` is an optional positive timeout in seconds. The
  gateway uses its compatibility default when the value is omitted or invalid.
- `callback(...)` and `streamCallback(...)` may return `status: ignored` with
  `reason: callback_expired` or `callback_completed` for late results.

## Token Handling

- `agentos.registerBundle` stores the bearer token internally.
- `agentkit`/`agentos` requests use the stored token automatically.

## Configuration

- Base URL is managed by the SDK and defaults to `http://localhost:8888`.

## Notes

- Call `agentos.registerBundle` before using `agentkit`/`agentos` APIs that
  require a token.
- `AgentOSSDK` exposes module properties (`agentos`, `agentkit`, `cronkit`,
  `ragkit`, `modelkit`, `toolkit`) for clearer separation of API areas.
- AgentKit endpoints are exposed under `/agentkit/*`.
- `sdk.modelkit.chat` targets `/modelkit/chat/...`.
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
