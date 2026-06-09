# Phase 93: Native Shell Propagation - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

The iOS and Android native shells carry `thread_id` across the full activation sequence so that Native → Bridge → Phoenix correlation is complete end-to-end. Both shells inject `X-Crosswake-Thread-Id` on the initial WebView load and expose `window.crosswakeBridge.threadId` to the JS bridge.

</domain>

<decisions>
## Implementation Decisions

### Native Thread ID Lifecycle
- **D-01:** **Mint on cold start:** Generate a standard UUIDv4 immediately upon `CrosswakeShell` / `ActivationCoordinator` initialization.
- **D-02:** **Scope to the shell instance:** Store it as an in-memory property on the `LiveViewSession` or `CrosswakeShellConfig`. Do not persist it to disk. This allows it to survive backgrounding/foregrounding but reset on force-kills.

### Bridge JS Injection Method
- **D-03:** **Unify on Document-Start Injection:** iOS must append `window.crosswakeBridge.threadId = "\(threadId)";` to the existing `WKUserScript` with `.atDocumentStart`.
- **D-04:** **Fix Android Race Condition:** Android must migrate off the `onPageStarted` injection. Use `WebViewCompat.addDocumentStartJavaScript()` (from AndroidX WebKit) to inject capabilities and `threadId`, matching iOS's deterministic timing.

### Activation Continuations
- **D-05:** **Override on explicit inbound Thread ID:** If an explicit `thread_id` is present in a deep link or notification payload, it overrides the shell's active in-memory Thread ID. The subsequent `URLRequest` loaded into the WebView must include the new `X-Crosswake-Thread-Id` header, and the `.atDocumentStart` JS script must be updated with the new ID.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Threadline Capstone
- `.planning/threads/threadline-audit.md` — Canonical definition of the v7.0 Threadline capstone.
- `guides/threadline.md` — Threadline documentation and posture rules.

</canonical_refs>

<code_context>
## Existing Code Insights

### Established Patterns
- **iOS Injection:** The iOS `LiveViewContainerViewController` already uses `WKUserScript` with `.atDocumentStart` for injection.
- **Android Injection (To Be Fixed):** Android currently uses `evaluateJavascript` inside `onPageStarted`, which introduces a LiveSocket boot race condition. This phase corrects it.

</code_context>

<specifics>
## Specific Ideas

- Unifying on Document-Start Injection (`WebViewCompat.addDocumentStartJavaScript()`) on Android is a key improvement to prevent flaky bug reports in Phoenix land by eliminating the LiveSocket boot race condition.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 93-Native Shell Propagation*
*Context gathered: 2026-06-09*
