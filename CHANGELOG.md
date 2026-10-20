## 0.9.0

- feat: add HarnessKit runtime, thread, run, command, result, and operational
  snapshot APIs with AppKit token handling and resumable SSE events.
- feat: return rejected HarnessKit command receipts from HTTP 400 responses.
- feat: add ModelKit decision inference. `ModelTask.decision`,
  `Modality.decisions`, `ModelInfo.supportsDecisionInference` and
  `sdk.modelkit.decision.create(...)` (`POST /modelkit/decision`) with typed
  `DecisionQuestion` (`choice` / `score` / `noul`), `DecisionResponse`,
  `DecisionAnswer` and `DecisionUsage`.
- feat: add app model registration. `sdk.modelkit.listAppModels()`,
  `registerAppModel`, `updateAppModel`, `unregisterAppModel` and
  `toggleAppModel` for `/modelkit/app-models`. Write calls reuse the app token
  from `registerBundle` and refresh it once on `401`. `ModelKitClient` exposes
  the same methods with an explicit `bearerToken`.
- feat: app models use namespaced IDs. The gateway exposes a registered model as
  `<id>@<bundleId>`; `AppModel.qualifiedId` and
  `AppModelWriteResult.qualifiedId` carry it (store it and use it as `model` in
  requests). `AppModel.qualifiedId` falls back to `id` for gateways that predate
  namespaced IDs. `id` only has to be unique within the app, and registration
  now rejects ids outside `[A-Za-z0-9._-]` (64 characters) with `400`. A `409`
  now means the `name` is already used by another model of the same app; an id
  that belongs to another app no longer conflicts, and updating/removing such an
  id is a `404`.
- feat: `ModelInfo` now reports `isAppModel` and `appBundleId` for models
  registered by apps.
- fix: models with `decisions` output are no longer reported as `text` output.

## 0.8.0

- breaking: align AgentKit with LiteAgent 0.4 by removing persisted agent
  management APIs and the legacy `agentId` session initializer.
- breaking: replace `Capability.sessionList` with recursive inline
  `subAgentList`, and remove retired reflection DTOs and message fields.
- breaking: remove retired AgentKit OpenSpec protocols and `openToolId`, and
  align the default `supportsReasoning` value with LiteAgent 0.4.
- feat: support Agent Skills markdown documents and extended provider-specific
  LLM configuration fields in AgentKit capabilities.
- breaking: align CronKit with the updated kernel contract by removing task
  `userId`.
- feat: expose all CronKit concurrency policies and document reusable LiteAgent
  sessions with IANA timezone scheduling.

## 0.7.0

- breaking: require `opentool_daemon ^0.5.0` and expose its V2 daemon API,
  server, pull, and tool DTOs.
- breaking: align ToolKit server metadata with daemon 0.5 by replacing
  `repo` / `tag` with `namespace` / `version`.
- feat: expose daemon 0.5 tool materialization metadata through `ToolDto`,
  including `materializedArtifactDigest` and `contentState`.
- feat: re-export daemon 0.5 typed pull events, detailed server deletion
  results, and stable `DaemonApiException` client errors.
- fix: accept both V2 `namespace` / `version` and legacy `repo` / `tag`
  metadata in AppKit OpenTool registration and provisioning responses.

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
