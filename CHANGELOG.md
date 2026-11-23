## 0.10.0

- breaking: remove RagKit support, including `sdk.ragkit`, `RagKitModule`,
  `RagKitClient`, and the RagKit request and response types.

## 0.9.1

- feat: register conversation-scoped private App OpenTool callbacks through
  `sdk.harnesskit.registerPrivateTools`, with AppKit token refresh and typed
  registration request and response models.
- feat: add `maxOutputTokens` (the maximum number of tokens a model can generate
  in one response, the platform's `maxTokens`) to `ModelInfo` and `AppModel`, and
  to the `AppModelRegistration` / `AppModelUpdate` request bodies.
- breaking: the gateway generates app model IDs. `AppModelRegistration` no
  longer accepts `id`; the gateway derives a 12-character hashid from the app's
  bundle ID and the model `name` and returns it as `AppModelWriteResult.id`.
  Store it: it is the `modelId` of `updateAppModel` / `unregisterAppModel` /
  `toggleAppModel`
  (looked up only among the calling app's models, otherwise `404`) and the
  `model` of requests. `AppModel.id` and `ModelInfo.id` report the same value.
  A model's `name` is unique within its app: registering an existing `name`
  replaces that model and keeps its id (`updated == true`), and renaming through
  `updateAppModel` keeps the id. A `409` means the id derived from `name` is
  still held by a renamed model of the same app, or `updateAppModel` renames a
  model to a `name` another model of the app already uses.
- feat: `ModelInfo` now reports `isBenefitCard`, `benefitCardId` and
  `benefitCardName` for the models a benefit card serves. A card model keeps
  `source == ModelSource.platform` and its plain `name` / `alias`; the same model
  can be listed once for the plan and once per card, and only `id` and the card
  fields tell them apart. Group card models one group per card (for example
  `Remote · System · {benefitCardName}`, falling back to `benefitCardId`). The
  fields are absent for other models and on gateways that predate them.
- feat: `ModelInfo` now reports `billingType` (`ModelBillingType`: `free` /
  `plan` / `payAsYouGo`) for system models that are not benefit card models.
  It is `null` for benefit card, local, custom and app models, and on gateways
  that predate the field. Pickers can mark each type with a badge.
- feat: `ModelInfo` now reports `source` (`ModelSource`: `local` / `platform` /
  `custom` / `app`), the gateway's mutually exclusive model origin, and `appName`
  for app models. Group and label models by `source` (for example
  `App · {appName}`) instead of combining `isRemote` / `isCustom` /
  `isAppModel`. `ModelInfo.fromJson` derives `source` from those flags with the
  gateway's rules when the gateway predates `source` or reports an unknown
  value, and `ModelInfo(...)` does the same when `source` is omitted, so
  existing constructor calls keep working. `toJson` always writes `source`.

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
