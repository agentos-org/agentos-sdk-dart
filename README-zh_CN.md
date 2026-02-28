# AgentOS SDK for Dart

一个轻量的 Dart SDK，用于访问 AgentOS API，支持 Root、AgentKit 和 AppKit 接口。
推荐使用统一的 `AgentOSSDK`，无需手动管理 token。

## 功能

- Root API：版本查询
- AgentKit API：Agent CRUD、会话初始化、
  chat 流式/单次、历史记录、stop/clear、回调
- AppKit API：bundle 注册与 SSE 订阅

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

  await sdk.agentos.registerBundle(bundleId: 'com.demo.app');

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

final sdk = AgentOSSDK(baseUrl: 'https://agentos.example.com');
```

### 配置长连接流超时

```dart
import 'package:agentos_sdk/agentos_sdk.dart';

final sdk = AgentOSSDK(
  baseUrl: 'https://agentos.example.com',
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: Duration.zero, // 保持长时间 SSE 流连接
);
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
| `dispose()` | `Future<void>` | 释放 SDK 资源并取消当前 AppKit 订阅。 |

### AgentOSModule（`sdk.agentos`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getVersion()` | 无 | 获取 AgentOS 服务版本。 |
| `getRoot()` | 无 | 获取 AgentOS 网关元信息。 |
| `getReady()` | 无 | 获取 AgentOS 就绪状态。 |
| `registerBundle({required String bundleId})` | `bundleId` | 注册 app bundle，并在内部保存 bearer token。 |
| `subscribe(AgentOSEventHandler handler)` | `handler` | 使用 handler 订阅 AppKit SSE 事件。 |

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

final sdk = AgentOSSDK(baseUrl: 'https://agentos.example.com');

await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
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
- `agentkit`/`agentos` 请求会自动使用已保存的 token。

## 配置

- Base URL 由 SDK 统一管理，默认值为 `http://localhost:20261`。

## 备注

- 在调用需要 token 的 `agentkit`/`agentos` 接口前，请先调用 `agentos.registerBundle`。
- `AgentOSSDK` 对外暴露模块属性（`agentos`、`agentkit`），便于按 API 领域区分。
- AgentKit 接口通过 `/agentkit/*` 对外提供。
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
