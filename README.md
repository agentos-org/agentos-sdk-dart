# AgentOS SDK for Dart

A lightweight Dart SDK for the AgentOS API, supporting Root, AgentKit, and
AppKit endpoints. Use the unified `AgentOSSDK` to avoid managing tokens
manually.

## Features

- Root API: version check
- AgentKit API: LiteAgent proxy endpoints (version, agent CRUD, session init,
  chat stream/simple, history, stop/clear, OpenTool list, callbacks)
- AppKit API: bundle registration and SSE subscription

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

## Usage

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

## API Reference

### AgentOSSDK

| Property | Type | Description |
| --- | --- | --- |
| `agentos` | `AgentOSModule` | Root/AppKit endpoints with internal token handling. |
| `agentkit` | `AgentKitModule` | AgentKit endpoints with internal token handling. |

### AgentOSModule (`sdk.agentos`)

| Method | Parameters | Description |
| --- | --- | --- |
| `getVersion()` | none | Fetches AgentOS service version. |
| `registerBundle({required String bundleId})` | `bundleId` | Registers an app bundle and stores the bearer token internally. |
| `subscribe(AgentOSEventHandler handler)` | `handler` | Subscribes to AppKit SSE events using a handler implementation. |

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
| `openToolList()` | none | Lists available OpenTools. |
| `callback({required String sessionId, required ToolReturn toolReturn})` | `sessionId`, `toolReturn` | Sends tool callback results. |
| `streamCallback({required String sessionId, required EventToolReturn eventToolReturn})` | `sessionId`, `eventToolReturn` | Sends streaming tool callback results. |

### AgentOSEventHandler

| Method | Parameters | Description |
| --- | --- | --- |
| `onWelcome(Welcome welcome)` | `welcome` | Receives `welcome` events. |
| `onCall(Call call)` | `call` | Receives `call` events. |
| `onDone()` | none | Called when the SSE stream ends. |
| `onError(Exception error)` | `error` | Called when the SSE stream errors. |

## Token Handling

- `agentos.registerBundle` stores the bearer token internally.
- `agentkit`/`agentos` requests use the stored token automatically.

## Configuration

- Default base URL: `http://localhost:20261`
- Override via `AgentOSSDK(baseUrl: ...)`, `ApiClient`, or `BaseOptions`.

## Notes

- Call `agentos.registerBundle` before using `agentkit`/`agentos` APIs that
  require a token.
- `AgentOSSDK` exposes module properties (`agentos`, `agentkit`) for
  clearer separation of API areas.
- The server proxies LiteAgent endpoints under `/agentkit/*`.

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
