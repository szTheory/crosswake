# Phase 93: Native Shell Propagation - Discussion Log

**Date:** 2026-06-09
**Status:** Completed via one-shot deep research

## Discussion Summary

The user requested a deep, one-shot research process to generate a cohesive set of recommendations for three implementation gray areas for Native Shell Propagation:
1. Native Thread ID Lifecycle
2. Bridge JS Injection Method
3. Activation Continuations

A subagent performed an architectural analysis of the Elixir OSS DNA, the existing iOS/Android native shell implementations, and the project vision. The result was a set of recommendations mapping to explicit developer ergonomics, timing precision (avoiding race conditions), and the principle of least surprise.

### 1. Native Thread ID Lifecycle
- **Options Evaluated:** Lazy minting vs. Launch minting; In-Memory vs. Persisted storage.
- **Selection:** Mint on cold start and scope to the shell instance in memory.
- **Rationale:** Ensures 100% correlation of the activation sequence while avoiding pseudo "device ID" telemetry bloat that comes with persisting across hard restarts.

### 2. Bridge JS Injection Method
- **Options Evaluated:** `onPageStarted` (async) vs. `.atDocumentStart` (sync).
- **Selection:** Unify on Document-Start injection across both platforms.
- **Rationale:** The Android implementation currently uses `onPageStarted` which causes a LiveSocket boot race condition. Using `WebViewCompat.addDocumentStartJavaScript()` brings deterministic injection timing parity with iOS.

### 3. Activation Continuations
- **Options Evaluated:** Ignore inbound IDs vs. Override current ID.
- **Selection:** Override active in-memory Thread ID with the explicit inbound Thread ID (e.g. from deep link/push).
- **Rationale:** Treats explicit inbound contexts as the new session truth, preserving the server's telemetry continuation without losing subsequent user actions.

---
*Note: This log is for human retrospective use only and is not consumed by downstream agents.*