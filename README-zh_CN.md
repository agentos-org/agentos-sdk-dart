# AgentOS SDK for Dart

一个轻量的 Dart SDK，用于访问 AgentOS API，支持 Root、AgentKit、AppKit、
CronKit、RagKit、LlmKit chat 和 ToolKit 发现接口。推荐使用统一的 `AgentOSSDK`，
无需手动管理 token。

## 功能

- Root API：版本查询
- AgentKit API：Agent CRUD、会话初始化、
  chat 流式/单次、历史记录、stop/clear、回调
- AppKit API：bundle 注册与 SSE 订阅
- CronKit API：定时任务 CRUD、运行记录与调度器控制
- RagKit API：知识库、文档、同步与查询接口
- LlmKit API：模型列表与指向 `/llmkit/text` 的 OpenAI 兼容 chat 客户端
- ToolKit API：tool 列表、tool 定义读取与 tool 生命周期事件订阅

## 快速开始

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  agentos_sdk: ^0.1.0
```

然后执行：

```bash
dart pub get
```

统一使用一个公开入口导入：

```dart
import 'package:agentos_sdk/agentos_sdk.dart';
```

## 使用示例

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

### 配置网关地址

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(baseUrl: 'http://localhost:8888');
```

### 配置长连接流超时

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(
  baseUrl: 'http://localhost:8888',
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: Duration.zero, // 保持长时间 SSE 流连接
);
```

### 使用 LlmKit Chat

`agentos_sdk` 会重新导出 `package:dart_openai_sdk/dart_openai_sdk.dart`，
因此可以直接使用 OpenAI chat 的请求和响应类型。

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

## API 参考

### AgentOSSDK

构造函数：

```dart
AgentOSSDK({
  String? baseUrl,
  Duration? connectTimeout,
  Duration? receiveTimeout,
})
```

可通过 `baseUrl`、`connectTimeout` 和 `receiveTimeout` 进行公开配置。

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `agentos` | `AgentOSModule` | Root/AppKit 相关接口，内部处理 token。 |
| `agentkit` | `AgentKitModule` | AgentKit 相关接口，内部处理 token。 |
| `cronkit` | `CronKitModule` | CronKit 相关接口，内部处理 token。 |
| `ragkit` | `RagKitModule` | RagKit 知识库接口，内部处理 token。 |
| `llmkit` | `LlmKitModule` | LlmKit 模型列表与预配置 chat 客户端。 |
| `toolkit` | `ToolKitModule` | ToolKit 发现接口与 tool 生命周期事件订阅。 |
| `dispose()` | `Future<void>` | 释放 SDK 资源并取消当前 AppKit 订阅。 |

### AgentOSModule（`sdk.agentos`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getVersion()` | 无 | 获取 AgentOS 服务版本。 |
| `getRoot()` | 无 | 获取 AgentOS 网关元信息。 |
| `getReady()` | 无 | 获取 AgentOS 就绪状态。 |
| `registerBundle({required String bundleId, String? appGroupId})` | `bundleId`, `appGroupId` | 注册 app bundle，在内部保存 bearer token，并返回 token 元信息。 |
| `subscribe(AgentOSEventHandler handler)` | `handler` | 使用 handler 订阅 AppKit SSE 事件。 |

### CronKitModule（`sdk.cronkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getTask({required String cronId})` | `cronId` | 通过 `cronId` 获取定时任务。 |
| `listTasks({bool? enabled, int? offset, int? limit})` | `enabled`, `offset`, `limit` | 获取当前 app group 可见的定时任务列表。 |
| `createTask({required CronTaskCreateRequest request})` | `request` | 创建定时任务。 |
| `updateTask({required CronTaskUpdateRequest request})` | `request` | 更新当前 app 拥有的定时任务。 |
| `deleteTask({required String cronId})` | `cronId` | 删除当前 app 拥有的定时任务。 |
| `enableTask({required String cronId})` | `cronId` | 显式启用定时任务，并返回最新状态。 |
| `disableTask({required String cronId})` | `cronId` | 显式禁用定时任务，并返回最新状态。 |
| `runTaskNow({required String cronId, DateTime? scheduledAt})` | `cronId`, `scheduledAt` | 立即触发一次定时任务运行。 |
| `getRun({required String runId})` | `runId` | 通过 `runId` 获取单条运行记录。 |
| `listRuns({String? cronId, DateTime? after, DateTime? before, int? offset, int? limit})` | `cronId`, `after`, `before`, `offset`, `limit` | 获取当前 app group 可见的运行记录列表。 |
| `listRunMessages({required String runId, int? offset, int? limit})` | `runId`, `offset`, `limit` | 获取某次运行持久化保存的 `AgentMessage` 记录。 |
| `deleteRun({required String runId})` | `runId` | 删除某次运行及其持久化消息记录。 |

`CronTaskCreateRequest.spec` 和 `CronTask.spec` 使用 CronKit 的任务 schema：

```dart
CronSpec(
  systemPrompt: 'You are a scheduled agent.',
  content: <Content>[
    Content(type: ContentType.text, message: 'Generate the daily summary.'),
  ],
  modelId: 'gpt-4o', // 可选请求输入
)
```

- `modelId` 是可选请求字段，CronKit 会用它解析底层模型配置。
- `modelName` 是可选返回字段，会出现在 `CronTask.spec` 中，表示最终解析后的模型名。

### AgentKitModule（`sdk.agentkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getAgent({required String agentId})` | `agentId` | 通过 `agentId` 获取 agent。 |
| `createAgent({required Agent agent})` | `agent` | 使用给定负载创建 agent。 |
| `updateAgent({required String agentId, required Agent agent})` | `agentId`, `agent` | 按 `agentId` 更新 agent。 |
| `deleteAgent({required String agentId})` | `agentId` | 按 `agentId` 删除 agent。 |
| `initSession({String? agentId, Capability? capability})` | `agentId`, `capability` | 初始化 SessionAgent 会话。 |
| `initSimple({required SimpleCapability simpleCapability})` | `simpleCapability` | 初始化 SimpleAgent 会话。 |
| `chat(Session session, UserTask userTask, AgentMessageHandler agentMessageHandler)` | `session`, `userTask`, `agentMessageHandler` | 启动 SessionAgent 任务，并通过回调处理 SSE 事件。 |
| `chatSimple({required String sessionId, required UserTask userTask})` | `sessionId`, `userTask` | 执行 SimpleAgent 请求并返回一次性响应。 |
| `history({required String sessionId})` | `sessionId` | 获取会话历史消息。 |
| `stop({required String sessionId, String? taskId})` | `sessionId`, `taskId` | 停止会话或任务。 |
| `clear({required String sessionId})` | `sessionId` | 清除会话数据。 |
| `callback({required String sessionId, required ToolReturn toolReturn})` | `sessionId`, `toolReturn` | 发送工具回调结果。 |
| `streamCallback({required String sessionId, required EventToolReturn eventToolReturn})` | `sessionId`, `eventToolReturn` | 发送流式工具回调结果。 |

### RagKitModule（`sdk.ragkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getBase({required String baseId})` | `baseId` | 按 ID 获取知识库。 |
| `listBases({int? offset, int? limit})` | `offset`, `limit` | 获取当前 app group 可见的知识库列表。 |
| `createBase({required RagBaseCreateRequest request})` | `request` | 创建知识库。 |
| `updateBase({required RagBaseUpdateRequest request})` | `request` | 更新当前 app 拥有的知识库。 |
| `deleteBase({required String baseId})` | `baseId` | 删除当前 app 拥有的知识库。 |
| `getDocument({required String baseId, required String documentId})` | `baseId`, `documentId` | 获取单个文档。 |
| `listDocuments({required String baseId, int? offset, int? limit})` | `baseId`, `offset`, `limit` | 获取某个知识库内的文档列表。 |
| `upsertDocument({required RagUpsertDocumentRequest request})` | `request` | 创建或更新单个 Markdown 文档。 |
| `upsertDocuments({required RagUpsertDocumentsRequest request})` | `request` | 批量创建或更新 Markdown 文档。 |
| `deleteDocument({required String baseId, required String documentId})` | `baseId`, `documentId` | 删除单个文档。 |
| `syncDocument({required String baseId, required String documentId})` | `baseId`, `documentId` | 触发单个文档的向量同步。 |
| `syncBase({required String baseId})` | `baseId` | 触发整个知识库的向量同步。 |
| `retryFailed({String? baseId})` | `baseId` | 重试失败的文档同步任务，可选限制到单个知识库。 |
| `query({required RagQueryRequest request})` | `request` | 对指定知识库执行语义查询。 |

### LlmKitModule（`sdk.llmkit`）

| 方法/属性 | 类型 | 说明 |
| --- | --- | --- |
| `listModels()` | `Future<List<LlmModelInfo>>` | 从 `/llmkit/models` 获取可用模型列表。 |
| `chat` | `LlmKitChatClient` | 预配置的 OpenAI 兼容 chat 客户端，默认使用 `{baseUrl}/llmkit/text`。 |

### ToolKitModule（`sdk.toolkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `listTool([String? all])` | `all` | 从 `/toolkit/list` 获取当前可用 tools 列表。 |
| `loadTool(String toolId)` | `toolId` | 从 `/toolkit/{toolId}/load` 读取 `OpenTool` 定义。 |
| `subscribeToolEvents({required String daemonApiKey, bool snapshot = true})` | `daemonApiKey`, `snapshot` | 订阅 `/toolkit/events`，持续接收 `ToolLifecycleEventDto` 生命周期事件。 |

### AgentOSEventHandler

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `onWelcome(Welcome welcome)` | `welcome` | 接收 `welcome` 事件。 |
| `onCallApp(Call call)` | `call` | 接收 `callApp` 事件。 |
| `onDone()` | 无 | SSE 流结束时触发。 |
| `onError(Exception error)` | `error` | SSE 流异常时触发。 |

### 订阅生命周期

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(baseUrl: 'http://localhost:8888');

await sdk.agentos.registerBundle(
  bundleId: 'com.demo.app',
  appGroupId: 'com.demo.group',
);
await sdk.agentos.subscribe(myHandler); // app 启动

// app 停止/释放
await sdk.dispose();
```

### AgentKit Schema 说明

- `UserTask` 支持透传字段：
  - `extraSystemPrompt`
  - `llmConfig`
- `LLMConfig` 支持：
  - `contextWindowSize`
  - `supportsToolCall`（可读/可写）
  - `supportsReasoning`（可读/可写）
  - 读取兼容 `supportsToolCalling` 和 `supportsDeepThinking`
- `Capability` 支持：
  - `llmConfigList`
  - `toolReturnPackMinLength`
- `AgentMessage.completions` 支持 `limits`：
  - `maxTokens`
  - `contextWindowSize`

### AgentMessageHandler（工具回调）

- 实现 `onFunctionCall(...)` 处理非流式工具调用。SDK 会将返回值发送到 `/agentkit/callback`。
- 实现 `onStreamFunctionCall(...)` 处理流式工具调用。SDK 会将每个事件发送到 `/agentkit/streamCallback`。

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

## Token 管理

- `agentos.registerBundle` 会将 bearer token 保存到 SDK 内部。
- `agentkit`/`agentos`/`cronkit` 请求会自动使用已保存的 token。

## 配置

- Base URL 由 SDK 统一管理，默认值为 `http://localhost:8888`。

## 备注

- 在调用需要 token 的 `agentkit`/`agentos`/`cronkit` 接口前，请先调用 `agentos.registerBundle`。
- `AgentOSSDK` 对外暴露模块属性（`agentos`、`agentkit`、`cronkit`、`llmkit`、`toolkit`），便于按 API 领域区分。
- AgentKit 接口通过 `/agentkit/*` 对外提供。
- CronKit 接口通过 `/cronkit/*` 对外提供。
- `sdk.llmkit.chat` 当前仅暴露 chat，默认请求
  `/llmkit/text/chat/completions`。
- `sdk.toolkit.subscribeToolEvents(...)` 需要 daemon API key，并通过 SSE
  持续推送 tool 生命周期事件。
- 外部集成应仅使用 `package:agentos_sdk/agentos_sdk.dart`，避免导入 `package:agentos_sdk/src/...`。

## 开发命令

```bash
dart format .
dart analyze
dart test
```

DTO 变更后重新生成：

```bash
dart run build_runner build --delete-conflicting-outputs
```
