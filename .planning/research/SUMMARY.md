# Project Research Summary

**Project:** Crosswake — v12.0 CI Honesty & Real-E2E Sweep
**Domain:** Internal CI / test-honesty hardening (Phoenix-native Elixir OSS library; offline-sync Playwright E2E + GitHub Actions gating + GSD closeout verifier)
**Researched:** 2026-06-17
**Confidence:** HIGH

## Executive Summary

This is not a feature milestone — it is a proof-honesty milestone. A repo-truth sweep found that several "green" CI surfaces do not prove what they claim. The flagship case is `examples/phoenix_host/e2e/offline_sync.spec.ts`: it calls the real `context.setOffline(true)` (added in v8.0) but then **injects a mutation into `window['crosswake_offline_mutations']` — a global the app never reads — and manually fires `fetch('/study/sync')` from `page.evaluate()`**. The application's IndexedDB outbox and reconnect path are never invoked, and the "the sync ID matches" assertion is circular (the test creates the ID, sends it, and verifies it returns). All four researchers independently reached the same verdict: the test is structurally fraudulent on **two** axes (mutation injection *and* flush trigger), and either alone makes it worthless as proof.

The good news is the gap is precisely bounded and the server side is already correct: `SyncController` → `Study.sync_events/1` already implements idempotency via `on_conflict: :nothing, conflict_target: :client_mutation_id`, and the `/_e2e/sync-state/:id` verification endpoint already exists (router-scoped to `:test`/`:e2e`). The missing piece is purely client-side: `offline_study.js` has `queueMutation()` but **no `flushOutbox()` and no reconnect listener**, and `study_session_live.ex:31` papers over this with a comment-acknowledged mock. So v12.0 is a small, well-understood change surface (three files modified, none created) plus three adjacent honesty cleanups: make the lane merge-blocking, close the long-carried validation-ledger debt (LEDG-01), and reconcile the v8.0 documentation that disagrees with itself.

The main risks are subtle test-infrastructure gotchas rather than unknowns: Playwright's `setOffline(false)` does **not** fire the browser `online` event, the demo app's stored mutation shape doesn't match the server contract, and the CI workflow still has the exact structural hole that let v6.0's mock hide a compile break (no `mix compile` before Playwright — a compile failure surfaces as a port timeout). Each has a known, cheap mitigation captured below.

## Key Findings

### Recommended Stack

No new frameworks and no Playwright upgrade. `@playwright/test` 1.60.0 already has every API needed; `playwright.config.ts` is already correct (service workers blocked, `retries: 2` in CI, trace on first retry, Phoenix auto-booted). Branch protection on `szTheory/crosswake` is **classic checks (not rulesets)** — confirmed via live `gh api` — so gating is a one-line PATCH, with the critical caveat that the `checks` array is *replaced, not appended* (must list all three checks).

**Core techniques:**
- **Playwright `context.setOffline(true/false)`** — real CDP network-layer offline; the genuine toggle already in use.
- **`setOffline(false)` + `page.evaluate(() => window.dispatchEvent(new Event('online')))`** — REQUIRED two-step: CDP `setOffline` does NOT dispatch the browser `online` event, and `navigator.onLine` does not auto-update (override via `addInitScript`/`evaluate`). This is the load-bearing gotcha.
- **`page.waitForResponse('/study/sync')` + `expect.poll`** — confirm the server *accepted* the app-driven POST before polling the Ecto `/_e2e/sync-state/:id` endpoint; replaces the current `waitForRequest`/manual-fetch pattern.
- **`gh api repos/szTheory/crosswake/branches/main/protection` PATCH** — add the renamed `merge-blocking-*` E2E job to required checks (all three checks in the array; job must run green on `main` once first).

### Expected Features (what an *honest* E2E requires)

**Must have (table stakes for honesty):**
- **Mutation via real UI** — click the actual Pass/Fail flashcard control so `offline_study.js` writes to the IndexedDB outbox; no `window[]` injection.
- **App-driven flush** — a real `flushOutbox()` in `offline_study.js` triggered by reconnect; the test must NOT fire `fetch` itself.
- **Read-back idempotency key** — assert against the `client_mutation_id` the *app* generated (read from IndexedDB), not one the test minted; if the app's UUID generation breaks, the lookup must fail on the right assertion.
- **Compile honesty** — `mix compile --warnings-as-errors` before Playwright in `offline-sync-e2e-gate.yml`, so a demo-app compile break fails loudly instead of as a port timeout (the v6.0 failure mode, still live).
- **Merge-blocking** — the lane is a registered required status check, not an undocumented advisory.

**Legitimate vs illegitimate test doubles (the honesty criterion):** reading the SUT's own IndexedDB state via `page.evaluate` is *observation* (legitimate — `offline_storage.spec.ts`'s `QuotaExceededError` stub is the established in-repo precedent); *writing* to SUT state or *triggering* SUT-owned behavior via `page.evaluate` is *injection* (illegitimate — what today's test does).

**Should have (differentiators):** outbox-cleared-after-flush assertion; duplicate-flush idempotency test (POST twice, assert one row); `beforeEach` IndexedDB reset for isolation.

### Architecture Approach

Pure modification milestone — three files change, none created; the server is already correct and untouched.

**Components touched:**
1. **`offline_study.js`** — add `flushOutbox()` (drain IndexedDB outbox → POST `/study/sync`) + reconnect listener; **fix the payload shape** from `{type, payload:{cardId, result:'pass'/'fail'}}` to the server contract `{client_mutation_id, card_id, rating:'good'/'hard'}`, generating `client_mutation_id` via `crypto.randomUUID()` at *queue* time (not POST time). This shape fix is a hard prerequisite for everything downstream.
2. **`study_session_live.ex`** — remove the `sync_outbox` mock (line 31 "here we mock it"). Independent of the JS change; can parallelize.
3. **`offline_sync.spec.ts`** — delete the injection + manual-fetch lines; drive via real UI click → `setOffline(false)` + `dispatchEvent('online')` → `waitForResponse` → `expect.poll` Ecto.

**Hard build-order dependency (all four agents agree):** payload-shape fix → `flushOutbox()` + reconnect handler → de-mock LiveView → test rewrite → CI gate.

### Critical Pitfalls

1. **CDP `setOffline(false)` doesn't fire `online`** — without the explicit `dispatchEvent('online')`, the app's reconnect handler never runs and the test hangs/false-fails. (Symptom already visible as `retries: 2` masking flake.)
2. **The v6.0 compile-break mechanism is still structurally present** — `offline-sync-e2e-gate.yml` runs Playwright with no prior `mix compile`; a compile failure looks like a Playwright port timeout. Add `mix compile --warnings-as-errors`.
3. **Branch-protection PATCH replaces the checks array** — omitting the existing two checks silently un-gates them; a job *rename* without re-registration silently drops the required check. Run green on `main` once, then PATCH with all three.
4. **Closeout verifier hardcoded-phase fallback** — a `CLOSEOUT.md` missing `expected_phases:` frontmatter falls back to a hardcoded phase set (`@v40_phases`/`@v39_phases` per source), globbing an empty path → zero ledgers found → vacuous pass. Make the fallback hard-error.
5. **Stale-but-not-blocking deferral** — LEDG-01 has been carried verbatim through v8.0→v11.0 (four milestones) with the same `reason:` text; `stale_deferral?/2` labels it stale but stale does not block merge. Needs explicit resolution criteria + real VALIDATION.md files, not another carry.

## Implications for Roadmap

Suggested structure: **4–5 phases**, continuing numbering from v11.0 (last phase **111** → start at **112**).

### Phase 112: Real Offline Outbox Flush (app change)
**Rationale:** Hard prerequisite — the test cannot be honest until the app it tests actually flushes on reconnect.
**Delivers:** payload-shape fix + `client_mutation_id` via `crypto.randomUUID()`; `flushOutbox()` + reconnect listener in `offline_study.js`; de-mocked `study_session_live.ex`.
**Avoids:** Pitfall — fixing the test before the app exists would just move the fabrication.

### Phase 113: Honest E2E Rewrite + Workflow Compile Gate
**Rationale:** Depends on 112; atomic unit — a fabricated test that compiles is still dishonest, so the test rewrite and the `mix compile` workflow fix ship together.
**Delivers:** rewritten `offline_sync.spec.ts` (real UI → `setOffline(false)`+`dispatchEvent('online')` → `waitForResponse` → `expect.poll` Ecto; outbox-cleared + duplicate-flush idempotency assertions; `beforeEach` reset); `mix compile --warnings-as-errors` added to `offline-sync-e2e-gate.yml`.
**Uses:** Playwright 1.60.0 APIs from STACK.md.

### Phase 114: Merge-Blocking CI Gate
**Rationale:** Last E2E step; requires ≥1 green run of the renamed `merge-blocking-*` job on `main` before registration.
**Delivers:** job `name:` + `merge-blocking-*` convention; documented required/advisory posture; branch-protection PATCH (all three checks) — or a scripted/documented path if the toggle is harness-blocked (historical constraint in this environment).

### Phase 115: LEDG-01 Closeout-Gate Honesty + Doc-Truth Reconciliation
**Rationale:** Fully independent of the E2E track; can parallelize, but must complete before milestone close. Closes 4-milestone-old debt.
**Delivers:** hard-error fallback in `closeout_verifier.ex`; artifact-existence assertion; resolution criteria for the stale deferral; the actual missing VALIDATION.md files (v3.6 48/49/52/53, v3.8 54-58, v3.9 62/63); LEDG-01 marked `status: resolved` with evidence; STATE.md reconciled; v8.0 doc-truth settled (authoritative doc chosen among PROJECT.md / v1.0-MILESTONE-AUDIT.md / MILESTONES.md, with a MILESTONES.md v8.0 entry added).

### Phase Ordering Rationale
- 112 before 113 before 114: strict app → test → gate dependency chain (cannot prove or gate what the app doesn't yet do).
- 115 parallelizable: touches the GSD verifier + planning docs, disjoint from the demo-app/E2E files.
- Doc-truth reconciliation should land before/with the E2E work so "current honest state" is settled before new proof claims are written.

### Research Flags
**No phases need deeper research during planning** — all patterns are documented and verified against source. Remaining open items are *requirements decisions*, not research gaps (see Gaps below). Skip research-phase for all phases.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Playwright APIs verified vs official docs; branch protection vs live `gh api` |
| Features | HIGH | Both bypasses confirmed by reading `offline_sync.spec.ts` + `offline_study.js` |
| Architecture | HIGH | Every file inspected; server idempotency (`on_conflict: :nothing`) read directly |
| Pitfalls | HIGH | Verifier footguns + workflow gap confirmed by direct source inspection |

**Overall confidence:** HIGH

### Gaps to Address (requirements decisions, not research gaps)
- **Reconnect-trigger surface (DECISION):** FEATURES recommends the LiveView `reconnected()` Hook as primary (server-confirmed-reachable, avoids a network-back-but-socket-stale race). ARCHITECTURE found the `/offline` island page has **no LiveView socket** (`put_root_layout(false)`), so the Hook is architecturally impossible there — `window 'online'` is the only viable trigger given the current route structure. Requirements must either confirm `window 'online'` for v12.0 or commit to migrating the study UI onto a LiveView route. **Recommendation: `window 'online'` only — do not expand scope to a route migration.**
- **`study_session_live.ex` mock (DECISION):** remove the `sync_outbox` handler entirely (recommended) vs. keep it as a labeled "Manual Sync" escape hatch.
- **VALIDATION.md evidence schema (DECISION):** exact field names alongside `nyquist_compliant: true` (e.g. `tested_by:`, `evidence:`) — settle before Phase 115.
- **`/_e2e/sync-state/:id` (VERIFY):** confirm it is exercised by a real IndexedDB-originated mutation (it may have only ever served the mocked flow).

## Sources

### Primary (HIGH confidence)
- Direct source inspection: `offline_sync.spec.ts`, `offline_storage.spec.ts`, `offline_study.js`, `study_session_live.ex`, `router.ex`, `closeout_verifier.ex`, `offline-sync-e2e-gate.yml`, `brandbook-verify.yml`.
- Playwright official docs — `setOffline`, `waitForResponse`, `expect.poll`, `addInitScript`.
- GitHub REST docs + live `gh api` — branch-protection `checks` array (app_id 15368, two existing checks).
- Phoenix LiveView JS interop docs (hexdocs) — `reconnected()` Hook semantics.

### Secondary (MEDIUM confidence)
- Community source for CDP `setOffline` not firing `online` (consistent with documented CDP behavior; `dispatchEvent` is the standard workaround).

---
*Research completed: 2026-06-17*
*Ready for roadmap: yes*
