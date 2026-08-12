## 0.7.0

- breaking: require `opentool_daemon ^0.5.0` and expose its V2 daemon API,
  server, pull, and tool DTOs.
- breaking: align ToolKit server metadata with daemon 0.5 by replacing
  `repo` / `tag` with `namespace` / `version`.
- feat: expose daemon 0.5 tool materialization metadata through `ToolDto`,
  including `materializedArtifactDigest` and `contentState`.
- feat: re-export daemon 0.5 typed pull events, detailed server deletion
  results, and stable `DaemonApiException` client errors.

## 0.6.1

- feat: expose optional AgentKit `Capability` execution limits for LLM requests, tool usage, repeated tool rounds, and task duration.

## 0.6.0

- feat: declare native OpenTool server dependencies during AppKit registration and expose typed registration statuses.
- feat: deliver AppKit `appEvent` notifications with typed OpenTool provisioning success and failure results through the subscription handler.
- breaking: remove the retired AppKit `callApp` event DTO and handler callback.

## 0.5.2

- fix: internally manage AgentKit chat subscriptions so `stop()` and `dispose()` close the HTTP stream without exposing the underlying stream API.
- fix: serialize asynchronous AgentKit event handlers before terminal callbacks.

## 0.5.1

- feat: add typed AgentKit task-turn history summaries and lazy process history APIs.
- feat: expose history summary and process pagination through `AgentKitModule`.
- fix: preserve child session IDs for AgentKit message, chunk, and function-call callbacks.

## 0.5.0

- feat: add typed AgentKit history responses with optional paired pagination.
- feat: expose AgentKit root task and task status metadata with legacy response compatibility.
- fix: use upstream ToolKit server metadata returned by the gateway.

## 0.4.1

- feat: align toolkit SDK with gateway API

## 0.4.0

- feat: add the `ModelKit` API (`sdk.modelkit`) with task-oriented model listing and OpenAI-compatible chat / embedding / asr / tts clients under `/modelkit/*`; document it in README/README-zh_CN and use it in the example.
- feat: add `AgentOSSDK(connectTimeout:, receiveTimeout:)` options for long-running stream configuration.
- feat: add managed AppKit subscription lifecycle with `agentos.subscribe(...)` and `AgentOSSDK.dispose()`.
- feat: keep `agentos.subscribe(AgentOSEventHandler)` signature unchanged while making it idempotent during active subscriptions.
- docs: clarify unified `AgentOSSDK` public import usage, subscription lifecycle, and long-running timeout configuration.
