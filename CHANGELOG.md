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
