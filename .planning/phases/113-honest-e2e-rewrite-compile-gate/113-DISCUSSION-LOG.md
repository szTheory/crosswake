# Phase 113 Discussion Log — Honest E2E Rewrite + Compile Gate

**Date:** 2026-06-17
**Mode:** advisor (research-backed), calibration `minimal_decisive` (USER-PROFILE: `opinionated`, technical). NON_TECHNICAL_OWNER=false (explicit `technical_background: true` + `practical-detailed:technical` override).

## How this was decided

User requested (twice, emphatically) deep multi-subagent research per gray area — pros/cons/tradeoffs, idiomatic Elixir/Plug/Ecto/Phoenix + Playwright fit, cross-ecosystem lessons (right & wrong), DX, footguns, least-surprise, SWE/DevOps/SRE lenses, project-DNA/`prompts/`+`research/` coherence — then a single coherent decisive set.

### Wave 1 — 4 parallel advisor agents (Sonnet), one per gray area
1. **Test isolation** (IndexedDB + non-sandboxed Ecto) → `beforeEach` `addInitScript(deleteDatabase)`; no reset endpoint, no SQL.Sandbox (architecturally impossible for app-driven fetch without injection); per-test unique `client_mutation_id` for Ecto. DB name `crosswake_offline_study`.
2. **Idempotency proof** ("exactly one row") → extend `/_e2e/sync-state/:id` with `count`; duplicate POST via `page.request.post` (APIRequestContext, GUARD-01-safe) replaying the IndexedDB-read app id; assert `count===1` (+ optional `accepted_count===0`). Compared vs separate endpoint and vs response-only assertion (rejected: weaker than a DB count; MySQL footgun).
3. **Compile gate** → `MIX_ENV=test mix compile --warnings-as-errors` before Playwright; mandatory test env (mounts `_e2e` route + `test/support`); fix pre-existing warnings in-scope; don't restructure the job. Cited Phoenix/Ecto/Oban/Req OSS CI idioms.
4. **Sibling-spec hygiene** → fix `offline_storage.spec.ts` `#btn-pass`→`#btn-good` (lane red today) + full text string; no `data-testid` (scope creep); TODO-001 stays Phase 115.

### Wave 2 — 2 agents (Sonnet): project-DNA/JTBD coherence audit + adversarial red-team
- **Coherence audit** (mined `prompts/` DNA + `research/ADOPTION-PROOF-STRATEGY`, `JTBD`, `PITFALLS`, `SUMMARY`): all 5 decisions coherent with the "every green check proves what it claims" thesis. Surfaced gaps: (a) missing `waitForResponse('/study/sync')` deterministic reconnect assertion (PITFALLS Pitfall 2); (b) explicit outbox-empty assertion (E2E-03e); (c) **the proof doesn't demonstrate the Offline-Island socketless boundary** — the *primary* adoption claim per ADOPTION-PROOF-STRATEGY → added D-06; (d) lock DB name to a shared constant. Plus test-as-documentation DX (D-07).
- **Red-team** (read the actual code, tried to break each): caught two **deterministic-failure** bugs —
  - D-02 bare `Repo.aggregate` (no `where`) counts the whole table → >1 in multi-test runs. **Fix: scope to the id.**
  - D-03 `context.setOffline(false)` does NOT fire `window 'online'`; app `flushOutbox` (offline_study.js:280) hangs forever → 100% timeout, burns all retries. **Fix: `page.evaluate(() => window.dispatchEvent(new Event('online')))`** (and `page.dispatchEvent` can't target window). Classified as legitimate environment simulation, GUARD-01-safe, REQUIRED by E2E-03.
  - Confirmed: `APIRequestContext` unaffected by `setOffline` (duplicate POST works while/after offline toggling); `:api` pipeline has no CSRF; `--warnings-as-errors` ignores hex deps but DOES flag the parent path-dep lib; D-05 has no drift beyond lines 89/92.

### Verification done inline (not delegated)
- DB name `crosswake_offline_study` (offline_study.js:3) ✓
- `window.addEventListener('online', flushOutbox)` (offline_study.js:280) ✓ + three triggers (on-load drain :287, optimistic :307)
- `_e2e` scope compile-gated `if Mix.env() in [:test, :e2e]` ✓
- `sync_events/1` returns `%{accepted_count, accepted_records, rejected}`, `on_conflict: :nothing` ✓
- `offline_storage.spec.ts:89` clicks dead `#btn-pass` → lane red ✓

## Decisions captured → see 113-CONTEXT.md
D-01 isolation · D-02 scoped count + duplicate-POST sequence · D-03 honest rewrite + `online` dispatch + `waitForResponse` · D-04 compile gate + pre-flight · D-05 sibling-spec hygiene · D-06 socketless-boundary assertion (recommended) · D-07 test-as-documentation DX.

## Deferred
`data-testid` convention; TODO-001 (mix-test flakiness → Phase 115); D-06 may defer if socket-detection surface is awkward.

## Scope creep redirected
None raised by the user. D-06 (boundary assertion) and D-07 (DX) strengthen the same test, not new capabilities. `data-testid` and TODO-001 explicitly deferred to avoid widening Phase 113.
