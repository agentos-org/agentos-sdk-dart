# AuthKit Test Harness

用 `agentos_sdk` 模拟**第三方应用 + 第三方 Server**，对接**真实 AgentOS Server** 做联调。

| 命令 | 角色 |
|------|------|
| `bin/server.dart` | 第三方 Server：S2 创建授权请求、收 callback、`/oauth2/token` 兑换 |
| `bin/new_flow_client.dart` | 第三方 Client：`openAuthorization` + 轮询事务 |

参考文档：

- [第三方客户端 OAuth2 登录与可信客户端授权接入说明](../../../docs/第三方客户端%20OAuth2%20登录与可信客户端授权接入说明.md)
- [authkit-migration-plan-zh_CN.md](../../../docs/authkit-migration-plan-zh_CN.md)

## 安装

```bash
cd agentos-sdk-dart/example/authkit_test_harness
dart pub get
```

## 配置

编辑 `lib/harness_config.dart`：

| 字段 | 说明 |
|------|------|
| `agentosServerBase` | AgentOS Server 地址，须与 Desktop 登录环境一致 |
| `clientId` | 后端注册的 OAuth client_id |
| `bundleId` | 应用 bundleId，须与注册信息一致 |
| `publicBase` | 第三方 Server 对外地址（callback 前缀） |

## 联调步骤

**前置：**

1. OAuth `client_id` 已在 AgentOS 注册，`redirect_uri` 包含 `HarnessConfig.callbackUri`（默认 `http://127.0.0.1:9999/auth/agentos/callback`）
2. AgentOS Desktop 已启动，并**已登录**同一 AgentOS 环境

**终端 1 — 第三方 Server：**

```bash
dart run bin/server.dart
```

**终端 2 — 第三方 Client：**

```bash
dart run bin/new_flow_client.dart
```

在 Desktop 弹窗里点允许/拒绝，终端 2 会轮询到结果并 `complete` 领取 `access_token`。

## 链路

```text
new_flow_client
  → POST harness-server /auth/agentos/start
      → 真实 AgentOS S2（PKCE + state + nonce）
  → sdk.authkit.openAuthorization(launchUri)
      → Desktop → 真实 AgentOS S3/S4
      → Desktop callback → harness-server /auth/agentos/callback
      → harness-server → 真实 /oauth2/token
  → 轮询 transaction → complete
```

## API

**第三方 Server（harness 提供）**

| 方法 | 路径 |
|------|------|
| POST | `/auth/agentos/start` |
| GET | `/auth/agentos/callback` |
| GET | `/auth/agentos/transactions/{id}`（Bearer: `transactionSecret`） |
| POST | `/auth/agentos/transactions/{id}/complete` |

**AgentOS Server（真实环境，由 harness server 与 Desktop 调用）**

| 方法 | 路径 |
|------|------|
| POST | `/api/v1/third/oauth2/app-authorization-requests` |
| GET | `/api/v1/third/oauth2/app-authorization-requests/{requestId}` |
| POST | `/api/v1/third/oauth2/app-authorization-requests/{requestId}/decision?approved=true` |
| POST | `/oauth2/token` |

## 已知简化

harness 的第三方 Server 仍是内存实现，但 **AgentOS 侧全部走真实 API**。以下由第三方自行完善：

- `transactionSecret` 哈希存储
- ID Token 签名验证（JWKS）
- Back-Channel Logout 接收
- 生产 HTTPS callback
