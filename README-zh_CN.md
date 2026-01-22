# AgentOS Dart SDK

一个轻量的 Dart SDK，用于访问 AgentOS API，仅包含 Root、AgentKit 与 AppKit。
推荐使用统一的 `AgentOSSDK`，无需手动管理 token。

## 功能

- Root API：版本查询
- AgentKit API：LiteAgent 代理接口（版本、Agent CRUD、会话初始化、
  chat 流式/单次、历史记录、stop/clear、OpenTool 列表、回调）
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

## 使用示例

```dart
import 'dart:io';

import 'package:agentos_sdk/agentos_sdk.dart';

Future<void> main() async {
  final baseUrl =
      Platform.environment['AGENTOS_BASEURL'] ?? 'http://localhost:20261';

  final sdk = AgentOSSDK(baseUrl: baseUrl);

  final version = await sdk.agentos.getVersion();
  print('AgentOS version: ${version.version}');

  await sdk.agentos.registerBundle(bundleId: 'com.demo.app');
  final tools = await sdk.agentkit.openToolList();
  print('OpenTool count: ${tools.length}');

  await sdk.agentos.subscribe(_DemoEventHandler());
  await Future<void>.delayed(const Duration(seconds: 1));
}

class _DemoEventHandler extends AgentOSEventHandler {
  @override
  Future<void> onWelcome(Welcome welcome) async {
    print('Welcome bundleId: ${welcome.bundleId}');
  }

  @override
  Future<void> onCall(Call call) async {
    print('Call id: ${call.id}');
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

## API 参考

### AgentOSSDK

| 属性 | 类型 | 说明 |
| --- | --- | --- |
| `agentos` | `AgentOSModule` | Root/AppKit 相关接口，内部处理 token。 |
| `agentkit` | `AgentKitModule` | AgentKit 相关接口，内部处理 token。 |

### AgentOSModule（`sdk.agentos`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getVersion()` | 无 | 获取 AgentOS 服务版本。 |
| `registerBundle({required String bundleId})` | `bundleId` | 注册 App bundle，并在内部保存 token。 |
| `subscribe(AgentOSEventHandler handler)` | `handler` | 使用 handler 订阅 AppKit SSE 事件。 |

### AgentKitModule（`sdk.agentkit`）

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `getAgent({required String agentId})` | `agentId` | 通过 `agentId` 获取 agent。 |
| `createAgent({required Agent agent})` | `agent` | 创建 agent。 |
| `updateAgent({required String agentId, required Agent agent})` | `agentId`, `agent` | 更新 agent（如 `agentId`）。 |
| `deleteAgent({required String agentId})` | `agentId` | 删除 agent（如 `agentId`）。 |
| `initSession({String? agentId, Capability? capability})` | `agentId`, `capability` | 初始化 SessionAgent 会话。 |
| `initSimple({required SimpleCapability simpleCapability})` | `simpleCapability` | 初始化 SimpleAgent 会话。 |
| `chat(Session session, UserTask userTask, AgentMessageHandler agentMessageHandler)` | `session`, `userTask`, `agentMessageHandler` | 启动 SessionAgent 任务，并通过回调处理 SSE 事件。 |
| `chatSimple({required String sessionId, required UserTask userTask})` | `sessionId`, `userTask` | 发送 SimpleAgent 请求并返回一次性响应。 |
| `history({required String sessionId})` | `sessionId` | 获取会话历史消息。 |
| `stop({required String sessionId, String? taskId})` | `sessionId`, `taskId` | 停止会话或任务。 |
| `clear({required String sessionId})` | `sessionId` | 清除会话数据。 |
| `openToolList()` | 无 | 获取可用 OpenTool 列表。 |
| `callback({required String sessionId, required ToolReturn toolReturn})` | `sessionId`, `toolReturn` | 发送工具回调结果。 |
| `streamCallback({required String sessionId, required EventToolReturn eventToolReturn})` | `sessionId`, `eventToolReturn` | 发送流式工具回调结果。 |

### AgentOSEventHandler

| 方法 | 参数 | 说明 |
| --- | --- | --- |
| `onWelcome(Welcome welcome)` | `welcome` | 接收 `welcome` 事件。 |
| `onCall(Call call)` | `call` | 接收 `call` 事件。 |
| `onDone()` | 无 | SSE 流结束时触发。 |
| `onError(Exception error)` | `error` | SSE 流异常时触发。 |

## Token 管理

- `agentos.registerBundle` 会将 token 保存为私有字段。
- `agentkit`/`agentos` 请求会自动使用已保存的 token。

## 配置

- 默认 base URL：`http://localhost:20261`
- 可通过 `AgentOSSDK(baseUrl: ...)`、`ApiClient` 或 `BaseOptions` 覆盖。

## 备注

- 使用 `agentos.registerBundle` 后再调用需要 token 的接口。
- `AgentOSSDK` 对外暴露 `agentos`、`agentkit` 模块，
  便于区分 API。
- 服务端会在 `/agentkit/*` 下代理 LiteAgent 的接口。

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
