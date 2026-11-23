# AgentOS SDK for Dart

一个轻量的 Dart SDK，用于访问 AgentOS API，支持 Root、AgentKit、AppKit、
AuthKit、CronKit、DiscoveryKit、HarnessKit、ModelKit（chat / embedding / asr / tts / decision，及 app model 注册）、
ToolKit 和 TransferKit 接口。推荐使用统一的 `AgentOSSDK`，无需手动管理 token。

## 功能

- Root API：版本查询
- AgentKit API：Agent CRUD、会话初始化、
  chat 流式/单次、历史记录、stop/clear、回调
- AppKit API：bundle 注册与 SSE 订阅
- HarnessKit API：runtime 引擎、thread、run、command 与可续传 SSE 事件
- AuthKit API：将第三方登录授权请求投递到本机 AgentOS Desktop
- CronKit API：定时任务 CRUD、运行记录与调度器控制
- DiscoveryKit API：附近设备发现、设备流、注册/注销
- ModelKit API：基于任务的模型列表，`/modelkit/*` 下的 OpenAI 兼容
  chat / embedding / asr / tts 客户端，带类型问题的 decision 推理，以及外部
  app model 注册
- ToolKit API：tool 列表、tool 定义读取与 tool 生命周期事件订阅
- TransferKit API：设备间文件传输、进度流、接收策略与传输历史

## 快速开始

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  agentos_sdk: ^0.9.1
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
      print('OpenTool ${success.ref} 已就绪：${success.id}');
      return;
    }
    final failure = event.openToolProvisionFailure;
    if (failure != null) {
      print('OpenTool ${failure.ref} 启动失败：${failure.error.message}');
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

### 使用 ModelKit Chat

`agentos_sdk` 会重新导出 `package:dart_openai_sdk/dart_openai_sdk.dart`，
因此可以直接使用 OpenAI chat 的请求和响应类型。

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(baseUrl: 'http://localhost:8888');

final models = await sdk.modelkit.listModels();
print(models.map((model) => '${model.alias} (${model.task.name})').toList());

// 也可以按任务过滤：
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

`sdk.modelkit` 返回的是 `ModelInfo`，以 `task` + `capabilities` 分类。

每个 `ModelInfo` 还带有 `source`（`ModelSource`），表示模型互斥的来源。请按它分组/
打标签，而不要再组合 `isRemote` / `isCustom` / `isAppModel` 自行推导：

| `ModelSource` | 含义 | 建议分组 |
| --- | --- | --- |
| `local` | 在本机运行 | 本地模型 |
| `platform` | AgentOS 平台提供的远端模型 | 平台模型，另为每张权益卡单独分组 `远端 · 系统 · {benefitCardName}`（见下） |
| `custom` | 用户自行配置的远端模型 | 自定义模型 |
| `app` | 第三方 app 注册的模型 | `App · {appName}`（每个 app 一组） |

```dart
final groups = <String, List<ModelInfo>>{};
for (final model in await sdk.modelkit.listModels()) {
  final title = model.source == ModelSource.app
      ? 'App · ${model.appName ?? model.appBundleId}'
      : model.source.wireName;
  groups.putIfAbsent(title, () => <ModelInfo>[]).add(model);
}
```

app 模型还会带有 `appBundleId` 与 `appName`（app 的可读名称，用作分组标题；
`appName` 仅在网关返回时才有值，缺失时请回退到 `appBundleId`）。对于尚未提供
`source` 的旧网关，或 `source` 为未知值时，会按网关的规则由旧布尔字段推导。

由权益卡提供的模型仍保持 `source == ModelSource.platform` 与原样的 `name` / `alias`，并额外带有
`isBenefitCard`、`benefitCardId` 与 `benefitCardName`（`benefitCardName` 仅在网关返回时才有值，
缺失时请回退到 `benefitCardId`）。同一个模型可能在套餐和每张权益卡下各出现一次，请用 `id`
或权益卡字段区分，并让每张权益卡各自成组：

```dart
String systemGroupTitle(ModelInfo model) => model.isBenefitCard
    ? '远端 · 系统 · ${model.benefitCardName ?? model.benefitCardId}'
    : '远端 · 系统';
```

非权益卡的系统模型还会带有 `billingType`（`ModelBillingType.free`、`plan` 或 `payAsYouGo`；
未知时以及其他模型均为 `null`），选择器可以为每种类型加一个小标识。

网关已知时，`ModelInfo` 还会带有 `contextWindowSize` 与 `maxOutputTokens`（模型单次
响应最多可生成的 token 数），否则为 `null`。只有 chat 模型才会返回 `maxOutputTokens`
（embedding、ASR、TTS、decision 模型不生成文本，该值为 `null`）；返回了 `contextWindowSize`
的 chat 模型一定会返回 `maxOutputTokens`，模型自身没有该值时与 `contextWindowSize` 相同。
App 注册模型时可通过
`AppModelRegistration(contextWindowSize: 32768, maxOutputTokens: 4096)` 同时设置
两者；`AppModel` 会原样返回，`AppModelUpdate` 也可以修改。

### 使用 ModelKit Decision

Decision 模型（`ModelTask.decision`，由 llama.cpp `/v1/systemone` 提供）不生成
文本，而是针对给定的 `state`，对带类型问题的选项打分。`POST /modelkit/decision`
不需要 app token。

```dart
final decisionModels = await sdk.modelkit.listModelsByTask(ModelTask.decision);

final response = await sdk.modelkit.decision.create(
  model: decisionModels.first.name, // 可选，缺省时由网关选择默认模型
  state: <String, dynamic>{'text': '我的订单迟迟不到，太让人生气了！'},
  questions: <String, DecisionQuestion>{
    // 单选（选项 -> 描述）
    'route': DecisionQuestion.choice(
      instructions: '应该交给哪个团队处理？',
      options: const <String, String>{
        'billing': '支付与发票',
        'support': '商品或物流问题',
      },
    ),
    // 有序评分，2-10 个等级描述
    'urgency': DecisionQuestion.score(
      instructions: '这件事有多紧急？',
      levels: const <String>['低', '中', '高'],
    ),
    // 是/否判断
    'angry': DecisionQuestion.noul(instructions: '用户是否生气了？'),
  },
  // images: ['data:image/png;base64,...'], // 支持图片输入的模型可用
);

final route = response.answers['route']!;
print('${route.choice}（置信度：${route.confidence}）');
print('urgency: ${response.answers['urgency']!.score}');
print('angry: ${response.answers['angry']!.noul}');
print('tokens: ${response.usage?.inputTokens} / ${response.usage?.outputTokens}');
```

`DecisionAnswer` 提供 `choice`、`score`、`noul`、`confidence`、`probabilities`、
`legend`；其中 `probabilities` / `legend` 按服务端返回内容原样透传，`raw` 保存
完整的答案对象。

### 注册 App Model

App 可以把自己的模型注册到网关。注册后的模型会出现在 `listModels()` /
`listModelsByTask()` 中，并带有 `isAppModel == true` 与所属的 `appBundleId`。

```dart
await sdk.agentos.registerBundle(bundleId: 'com.example.app');

// 注册（或替换）模型，只有 `name` 必填。
final result = await sdk.modelkit.registerAppModel(
  request: const AppModelRegistration(
    name: 'my-router',
    task: ModelTask.decision,
    baseUrl: 'http://127.0.0.1:9000',
    apiKey: 'upstream-secret', // 由服务端保存，不会再返回
  ),
);
print(result.updated); // 替换了该 app 已有的同名模型时为 true

// 模型 id 由网关生成（12 位，基于你的 bundle ID 与模型 `name`）。请保存它：
// 下面的维护接口都用它，请求的 `model` 里使用它就能精确路由到这个模型。
final modelId = result.id!; // 例如 '6f78dcce6717'

// 局部更新：未设置的字段保持不变。
await sdk.modelkit.updateAppModel(
  modelId: modelId,
  request: const AppModelUpdate(description: '分流客服工单'),
);

// 启用/停用，无需删除。
await sdk.modelkit.toggleAppModel(modelId: modelId);

// 列出所有 app 注册的模型（公开接口，无需 token）。
final appModels = await sdk.modelkit.listAppModels();
print(appModels.map((m) => '${m.id} by ${m.appBundleId} disabled=${m.isDisabled}'));

await sdk.modelkit.unregisterAppModel(modelId: modelId);
```

写操作会自动附带 app token，并在 `401` 时刷新一次。失败时抛出带服务端状态码的
`DioException`：`401` token 无效，`403` `appBundleId` 不匹配，`404` id 不存在
（id 只在你自己 app 的模型里查找），`409` 由 `name` 生成的 id 仍被你 app 里一个
已改名的模型占用（或 `update` 把模型改成你 app 下另一个模型已用的 `name`），
`400` 请求体非法、缺少 `name`、`task` 未知，或 bundle ID 含 `[A-Za-z0-9._-]` 以外
的字符（长度上限 128）。

模型 `name` 在你的 app 内唯一：注册已注册过的 `name` 会替换该模型并返回同一个
id；用 `updateAppModel` 改名时 id 保持不变。

Decision 模型会被服务端规范化：输入为 `text`（可选 `image`），输出为
`decisions`，`stream` / `tool_call` / `reasoning` 均为 `false`。

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
| `authkit` | `AuthKitModule` | 将第三方登录授权投递到本机 Desktop。 |
| `cronkit` | `CronKitModule` | CronKit 相关接口，内部处理 token。 |
| `discoverykit` | `DiscoveryKitModule` | DiscoveryKit 附近设备发现接口。 |
| `harnesskit` | `HarnessKitModule` | Harness runtime、thread、run、command 和事件接口。 |
| `modelkit` | `ModelKitModule` | ModelKit 基于任务的模型列表、chat / embedding / asr / tts / decision 客户端与 app model 注册。 |
| `toolkit` | `ToolKitModule` | ToolKit 发现接口与 tool 生命周期事件订阅。 |
| `transferkit` | `TransferKitModule` | TransferKit 文件传输接口。 |
| `dispose()` | `Future<void>` | 释放 SDK 资源并取消当前 AppKit 订阅。 |

### AgentOSModule（`sdk.agentos`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getVersion()` | 无 | 获取 AgentOS 服务版本。 |
| `getRoot()` | 无 | 获取 AgentOS 网关元信息。 |
| `getReady()` | 无 | 获取 AgentOS 就绪状态。 |
| `registerBundle({required String bundleId, String? appGroupId, List<OpenToolServerDeclaration> opentoolServers = const []})` | `bundleId`, `appGroupId`, `opentoolServers` | 注册 app bundle、声明原生 OpenTool server 依赖，在内部保存 bearer token，并返回注册状态。 |
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

Cron 任务可以复用已有 LiteAgent session，并按 IANA 时区计算调度时间：

```dart
await sdk.cronkit.createTask(
  request: CronTaskCreateRequest(
    name: '每日摘要',
    schedule: '0 9 * * *',
    sessionId: 'existing-liteagent-session',
    timezone: 'Asia/Shanghai',
    concurrency: CronTaskConcurrency.skipIfRunning,
    spec: CronSpec(
      systemPrompt: 'You are a scheduled agent.',
      content: <Content>[
        Content(type: ContentType.text, message: 'Generate the daily summary.'),
      ],
      modelId: 'gpt-4o',
    ),
  ),
);
```

- `sessionId` 为可选字段；提供后定时执行会复用该 session，否则 kernel 会在任务执行时初始化 LiteAgent session。
- `timezone` 接受 `Asia/Shanghai` 等 IANA 时区；Cron 按该时区计算，`lastRunAt`、`nextRunAt` 和 run 时间均以 UTC 序列化。
- `CronTaskConcurrency` 支持 `allow`、`skipIfRunning` 和 `replace`。
- `modelId` 是可选请求字段，CronKit 会用它解析底层模型配置。
- `modelName` 是可选返回字段，会出现在 `CronTask.spec` 中，表示最终解析后的模型名。

### AuthKitModule（`sdk.authkit`）

将第三方登录授权请求投递到本机 AgentOS Desktop。SDK **不实现** OAuth 端点，
也**不返回** authorization code、ID Token 或 access token —— 这些只在你的
Server 与 AgentOS Server 之间流转。

**典型流程：**

1. 你的 Server 向 AgentOS Server 创建授权请求，并把 `launchUri` 返回给 Client。
2. Client 调用 `sdk.authkit.openAuthorization(launchUri: ...)` 在本机 Desktop 展示授权页。
3. 轮询你自己 Server 的登录事务状态，获取最终结果。

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `openAuthorization({required String launchUri, bool waitForDecision = false, Duration? decisionTimeout})` | `launchUri`, `waitForDecision`, `decisionTimeout` | 将 Server 返回的 `launchUri` **原样透传**给本机 Desktop，返回 `AuthorizationPresentationResult`。 |
| `isAuthorizationReady()` | 无 | 探测本机 Desktop 是否已运行且可展示授权界面。 |

`openAuthorization` 返回 `AuthorizationPresentationResult`：

| 状态 | 含义 |
| --- | --- |
| `opened` | 授权页已展示，用户尚未做出选择（`waitForDecision` 为 false 时的默认结果）。 |
| `submitted` | 用户已同意，Desktop 已将决定提交给 AgentOS Server。**不代表登录已完成。** |
| `denied` | 用户已拒绝。 |
| `failed` | 本机投递失败，详见 `errorCode`。 |

常见 `errorCode`：

| 错误码 | 含义 |
| --- | --- |
| `desktop_not_running` | 本机 Desktop 网关不可达。 |
| `desktop_not_ready` | Desktop 正在启动，授权界面尚未就绪。 |
| `desktop_not_logged_in` | Desktop 未登录 AgentOS 账号。 |
| `invalid_launch_uri` | `launchUri` 必须原样使用 Server 返回值，不要自行拼接。 |
| `authorization_expired` | 授权请求已过期，需重新发起登录。 |
| `authorization_not_found` | 授权请求不存在或已被处理。 |

示例：

```dart
await sdk.agentos.registerBundle(bundleId: 'com.demo.app');

if (!await sdk.authkit.isAuthorizationReady()) {
  // 提示用户安装 / 启动 / 登录 AgentOS Desktop
}

final start = await myBackend.startAgentOSLogin(); // Server 从 AgentOS Server 取得 launchUri
final result = await sdk.authkit.openAuthorization(
  launchUri: start.launchUri,
);
if (result.isFailure) {
  print('AuthKit error: ${result.errorCode}');
} else {
  // 轮询你自己 Server 的登录事务状态
}
```

端到端联调示例见 [`example/authkit_test_harness/`](example/authkit_test_harness/README.md)。

### DiscoveryKitModule（`sdk.discoverykit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getPeers()` | 无 | 返回附近设备的快照列表。 |
| `streamPeers()` | 无 | 返回设备事件的 SSE 流（joined/left/updated）。 |
| `getSelf()` | 无 | 返回本机设备信息和注册状态。 |
| `register({DiscoveryRegisterRequest? request})` | `request` | 注册当前 app 到附近发现。 |
| `unregister()` | 无 | 从附近发现中注销当前 app。 |

### TransferKitModule（`sdk.transferkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `send({required TransferSendRequest request})` | `request` | 向目标设备发起文件传输。 |
| `listTransfers()` | 无 | 列出活跃的传输会话。 |
| `getStatus({required String transferId})` | `transferId` | 获取指定传输的状态。 |
| `streamProgress({required String transferId})` | `transferId` | 返回传输进度的 SSE 流。 |
| `cancel({required String transferId})` | `transferId` | 取消活跃的传输。 |
| `respond({required String transferId, required TransferRespondRequest request})` | `transferId`, `request` | 接受或拒绝一个传入的传输请求。 |
| `receiveStream()` | 无 | 返回传入传输事件的 SSE 流。 |
| `setPolicy({required SetPolicyRequest request})` | `request` | 设置文件接收策略（autoAccept / requireConfirm）。 |
| `getPolicy()` | 无 | 获取当前文件接收策略。 |
| `getHistory({String? deviceId, String? userId})` | `deviceId`, `userId` | 获取传输历史列表。 |
| `deleteHistory({required String recordId, String? deviceId, String? userId})` | `recordId`, `deviceId`, `userId` | 删除指定传输历史记录。 |
| `clearHistory({String? deviceId, String? userId})` | `deviceId`, `userId` | 清空所有传输历史。 |

### HarnessKitModule（`sdk.harnesskit`）

先调用 `agentos.registerBundle` 注册 App，再通过 Gateway 使用 HarnessKit。外部 App 共享 runtime，会话按 bundle ID 隔离；切换引擎及读取全局运行状态仅限内置 Harness App。

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `health()` | 无 | 检查 Harness runtime 是否可用。 |
| `getRuntime()` / `switchEngine({required String engine})` | `engine` | 查询或切换当前 runtime 引擎。 |
| `listThreads()` / `getThread({required String threadId})` | `threadId` | 列出会话或读取会话快照。 |
| `renameThread({required String threadId, required String title})` / `deleteThread({required String threadId})` | `threadId`, `title` | 重命名或删除会话。 |
| `registerPrivateTools({required String threadId, required HarnessKitPrivateToolsRegistration registration})` | `threadId`, `registration` | 为会话注册或替换本地 App 私有工具。 |
| `startRun({required String threadId, required HarnessKitRunRequest request})` | `threadId`, `request` | 启动 run 并返回其 ID。 |
| `submitCommand({required String threadId, required HarnessKitCommand command})` | `threadId`, `command` | 提交 command 并返回回执；HTTP 400 的拒绝回执也会正常返回。 |
| `events({required String threadId, HarnessKitEventsOptions options})` | `threadId`, `afterSequence`, `runId` | 打开 SSE 事件流，可按序号续传；取消订阅即可关闭连接。 |
| `getRunResult({required String runId})` / `getOperationalSnapshot()` | `runId` | 查询 run 结果或 runtime 状态快照。 |

请求和响应 DTO 可从 SDK 公开入口导入。可运行示例：
`dart run example/agentos_sdk_dart_example.dart --harness`。

#### App 私有工具

外部 App 通过本机回环地址直接连接 Gateway 时，可以为自己的会话注册 OpenTool 函数。先在 `127.0.0.1` 启动回调服务，再提交服务根地址、UUID 形状的回调 token 和 OpenTool JSON：

```dart
final binding = await sdk.harnesskit.registerPrivateTools(
  threadId: 'research-thread',
  registration: HarnessKitPrivateToolsRegistration(
    endpoint: 'http://127.0.0.1:8123/',
    token: callbackToken, // 与回调服务配置的 token 一致。
    specification: <String, dynamic>{
      'opentool': '1.0.0',
      'info': <String, dynamic>{'title': 'App tools', 'version': '1.0.0'},
      'functions': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'list_assets',
          'description': 'List app assets',
          'parameters': <dynamic>[],
          'return': <String, dynamic>{
            'name': 'result',
            'schema': <String, dynamic>{'type': 'object'},
          },
        },
      ],
    },
  ),
);
print(binding.toolId);
```

`endpoint` 必须是 `http://127.0.0.1:<port>/` 根地址。回调 token 与 AppKit token 独立，调用回调服务时作为 Bearer token 使用。服务需要提供 `GET /private-tools/opentool/version`（健康检查返回 HTTP 200）、`POST /private-tools/opentool/call`；流式函数还需提供 `POST /private-tools/opentool/streamCall`。调用请求包含 `jsonrpc: "2.0.0"`、`id`、`method` 和 `params`；响应包含相同的 `jsonrpc`、`id` 以及 `result` 或 `error`。流式响应使用 SSE JSON 数据事件，并以 `DONE` 事件结束。

返回的 `toolId` 标识该会话的工具。若 run 使用 `toolPolicy.allowedToolIds`，需将其加入允许列表；可以通过 `HarnessKitRunRequest.extra` 传入 policy。同一会话再次注册会替换绑定；绑定保存在内存中，Harness 重启后需要重新注册，会话删除或连续两次健康检查失败也会移除绑定。远程连接和内置 Harness App 不能注册此类回调。

示例程序提供 `--harness-private-tools` 选项；回调服务需要由 App 单独提供。

### AgentKitModule（`sdk.agentkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `initSession({Capability? capability})` | `capability` | 初始化 SessionAgent 会话，可携带递归嵌套的内联子 Agent。 |
| `initSimple({required SimpleCapability simpleCapability})` | `simpleCapability` | 初始化 SimpleAgent 会话。 |
| `chat(Session session, UserTask userTask, AgentMessageHandler agentMessageHandler)` | `session`, `userTask`, `agentMessageHandler` | 启动 SessionAgent 任务，并通过回调处理 SSE 事件。 |
| `chatSimple({required String sessionId, required UserTask userTask})` | `sessionId`, `userTask` | 执行 SimpleAgent 请求并返回一次性响应。 |
| `history({required String sessionId, int? page, int? pageSize})` | `sessionId`、`page`、`pageSize` | 获取强类型会话历史。分页时必须成对传入正整数 `page` 和 `pageSize`，页码从 1 开始；两者都省略时获取完整历史。 |
| `historySummary({required String sessionId, int page = 1, int pageSize = 30})` | `sessionId`、`page`、`pageSize` | 按任务摘要优先获取历史。 |
| `historyProcess({required String sessionId, required String originalTaskId, int page = 1, int pageSize = 50})` | `sessionId`、`originalTaskId`、`page`、`pageSize` | 懒加载指定任务轮次的过程消息。 |
| `stop({required String sessionId, String? taskId})` | `sessionId`, `taskId` | 停止会话或任务。 |
| `clear({required String sessionId})` | `sessionId` | 清除会话数据。 |
| `callback({required String sessionId, required ToolReturn toolReturn})` | `sessionId`, `toolReturn` | 发送工具回调结果。 |
| `streamCallback({required String sessionId, required EventToolReturn eventToolReturn})` | `sessionId`, `eventToolReturn` | 发送流式工具回调结果。 |

### ModelKitModule（`sdk.modelkit`）

| 方法/属性 | 类型 | 说明 |
| --- | --- | --- |
| `listModels()` | `Future<List<ModelInfo>>` | 从 `/modelkit/models` 获取可用模型列表。 |
| `listModelsByTask(ModelTask task)` | `Future<List<ModelInfo>>` | 按任务（`chat` / `embedding` / `asr` / `tts` / `decision`）过滤模型。 |
| `chat` | `ModelKitChatClient` | OpenAI 兼容 chat 客户端，使用 `{baseUrl}/modelkit/chat`。 |
| `embedding` | `ModelKitEmbeddingClient` | `/modelkit/embedding` 下的 OpenAI 兼容 embeddings 客户端。 |
| `asr` | `ModelKitAsrClient` | `/modelkit/asr` 下的语音转文字客户端。 |
| `tts` | `ModelKitTtsClient` | `/modelkit/tts` 下的文字转语音客户端。 |
| `decision` | `ModelKitDecisionClient` | `decision.create({model, state, questions, images, extra})` → `POST /modelkit/decision`，返回 `DecisionResponse`。 |
| `listAppModels()` | `Future<List<AppModel>>` | 通过 `GET /modelkit/app-models` 列出 app 注册的模型（公开接口）。 |
| `registerAppModel({required AppModelRegistration request})` | `Future<AppModelWriteResult>` | 注册或替换 app model（`POST /modelkit/app-models`，需 app token）。 |
| `updateAppModel({required String modelId, required AppModelUpdate request})` | `Future<AppModelWriteResult>` | 局部更新自己的 app model（`PUT /modelkit/app-models/<id>`）。 |
| `unregisterAppModel({required String modelId})` | `Future<AppModelWriteResult>` | 删除自己的 app model（`DELETE /modelkit/app-models/<id>`）。 |
| `toggleAppModel({required String modelId})` | `Future<AppModelWriteResult>` | 启用/停用自己的 app model（`POST /modelkit/app-models/<id>/toggle`）。 |

`ModelInfo` 通过 `task`（`ModelTask`）、`inputModalities` / `outputModalities`
（`Modality`）以及 `capabilities`（`ModelCapabilities`：`vision` / `toolCall` /
`stream` / `reasoning`）描述每个模型，并提供 `hasVision`、
`supportsChatInference`、`supportsDecisionInference`、`isVisionLanguage` 等便捷
getter。`source`（`ModelSource`：`local` / `platform` / `custom` / `app`）是模型互斥的
来源。App 注册的模型还会带有 `isAppModel`、`appBundleId` 与 `appName`；权益卡模型还会带有
`isBenefitCard`、`benefitCardId` 与 `benefitCardName`；其他平台模型还会带有 `billingType`。

`ModelKitClient`（`ModelKitClient(apiClient: ...)`）提供同样的 app model 方法，
但需要显式传入 `bearerToken:`，而不是自动使用 app token。

### ToolKitModule（`sdk.toolkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `listTool([String? all])` | `all` | 从 `/toolkit/list` 获取当前可用 tools 列表。 |
| `loadTool(String toolId)` | `toolId` | 从 `/toolkit/{toolId}/load` 读取 `OpenTool` 定义。 |
| `subscribeToolEvents({required String daemonApiKey, bool snapshot = true})` | `daemonApiKey`, `snapshot` | 订阅 `/toolkit/events`，持续接收 `ToolLifecycleEventDto` 生命周期事件。 |

`listTool` / `listTools` 返回 daemon 0.5 的 `ToolDto`。其中可选的 `server`
标识使用 `namespace`、`name`、`version`；若 daemon 提供，
`materializedArtifactDigest` 表示已物化内容的摘要，`contentState` 表示该内容
是否为最新。SDK 同时重新导出 daemon 0.5 client API，包括用于能力协商的
`VersionDto.apiVersion` 和 `VersionDto.capabilities`，以及类型化的 `PullEvent`
事件流、详细的 `ServerDeleteResultDto` 删除结果和稳定的
`DaemonApiException` 异常。

### AgentOSEventHandler

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `onWelcome(Welcome welcome)` | `welcome` | 接收 `welcome` 事件。 |
| `onAppEvent(AppEvent event)` | `event` | 接收 AppKit 业务事件，包括异步 OpenTool 拉起成功和失败结果。 |
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

`Capability` 还支持以下可选执行限制。SDK 会原样透传已提供的整数值，
省略值为 `null` 的字段；字段校验与默认值均由服务端负责。

| 字段 | 含义 | 服务端默认值 |
| --- | --- | --- |
| `maxLlmRequests` | 单个工具型任务的大模型请求次数上限。 | `64` |
| `maxToolRounds` | 单个任务的工具调用轮数上限。 | `16` |
| `maxToolCalls` | 单个任务的工具调用总数上限。 | `64` |
| `maxConsecutiveIdenticalToolRounds` | 连续相同工具调用轮数上限。 | `3` |
| `maxTaskDurationSeconds` | 单个工具型任务最长执行秒数。 | `300` |

```dart
const plannerSkillMarkdown = '''
---
name: planner
description: 将工作拆分成清晰步骤。
---
执行前先规划任务。
''';

final capability = Capability(
  systemPrompt: '你是一个助手',
  skills: <String>[plannerSkillMarkdown],
  maxLlmRequests: 32,
  maxToolRounds: 8,
  maxToolCalls: 20,
  maxConsecutiveIdenticalToolRounds: 2,
  maxTaskDurationSeconds: 120,
);

await sdk.agentkit.initSession(
  capability: Capability(
    systemPrompt: '协调团队',
    subAgentList: <Agent>[
      Agent(name: 'limited-agent', capability: capability),
    ],
  ),
);
```

- `AgentMessage.completions` 支持 `limits`：
  - `maxTokens`
  - `contextWindowSize`
- `AgentMessage.originalTaskId` 标识根任务；读取旧响应时会回退为 `taskId`。
- `TaskStatus.taskId` 标识状态更新关联的任务。

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

`chat(...)` 将 SSE 订阅保留在 SDK 内部，只通过 `AgentMessageHandler`
向外提供事件。SDK 会串行处理事件回调，因此只有最后一个事件回调完成后
才会调用 `onDone()`。

```dart
await sdk.agentkit.chat(
  Session(sessionId: sessionId),
  userTask,
  myHandler,
);

// 停止远端任务，并关闭该 session 的本地活跃聊天流。
await sdk.agentkit.stop(sessionId: sessionId);
```

`AgentOSSDK.dispose()` 也会关闭所有活跃的 AgentKit 聊天流。公开 API
不会暴露底层 Dart stream subscription。

- `CallbackOpenTool.timeout` 是可选的正整数秒数；省略或值非法时，网关使用兼容默认值。
- 迟到的结果可能使 `callback(...)` 或 `streamCallback(...)` 返回
  `status: ignored`，原因为 `callback_expired` 或 `callback_completed`。

## Token 管理

- `agentos.registerBundle` 会将 bearer token 保存到 SDK 内部。
- `agentkit`/`agentos`/`cronkit` 请求会自动使用已保存的 token。

## 配置

- Base URL 由 SDK 统一管理，默认值为 `http://localhost:8888`。

## 备注

- 在调用需要 token 的 `agentkit`/`agentos`/`authkit`/`discoverykit`/`transferkit` 接口前，请先调用 `agentos.registerBundle`。
- `authkit.openAuthorization` 只负责在本机展示授权页；登录是否成功以你自己 Server 的事务状态为准。
- `AgentOSSDK` 对外暴露模块属性（`agentos`、`agentkit`、`authkit`、`cronkit`、
  `discoverykit`、`modelkit`、`toolkit`、`transferkit`），便于按 API 领域区分。
- AgentKit 接口通过 `/agentkit/*` 对外提供。
- CronKit 接口通过 `/cronkit/*` 对外提供。
- `sdk.modelkit.chat` 请求 `/modelkit/chat/...`。
- `sdk.modelkit.decision` 请求 `/modelkit/decision`；app model 管理请求
  `/modelkit/app-models`。只有 app model 的写操作需要先调用
  `agentos.registerBundle`。
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
