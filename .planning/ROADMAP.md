# Roadmap: Crosswake

## Milestones

- ✅ **v8.0 Offline Sync Hardening and UI Polish** — Phases 99-101 (shipped 2026-06-11)
- ✅ **v9.0 Brand System & Visual Identity** — Phases 102-106 (shipped 2026-06-13)
- ✅ **v10.0 Brand Normalization** — Phases 107-109 (shipped 2026-06-14)
- ✅ **v11.0 Release & Distribution Truth** — Phases 110-111 (shipped 2026-06-17)
- [ ] **v12.0 CI Honesty & Real-E2E Sweep** — Phases 112-115 (active)

## Phases

<details>
<summary>✅ v8.0 Offline Sync Hardening and UI Polish (Phases 99-101) — SHIPPED 2026-06-11</summary>

- [x] Phase 99: Real Network-Toggling E2E Tests (2/2 plans) — completed 2026-06-11
- [x] Phase 100: Storage Budget Enforcement (2/2 plans) — completed 2026-06-11
- [x] Phase 101: Offline UI Consolidation & Polish (2/2 plans) — completed 2026-06-11

</details>

<details>
<summary>✅ v9.0 Brand System & Visual Identity (Phases 102-106) — SHIPPED 2026-06-13</summary>

- [x] Phase 102: Brand Audit & Token Foundation (4/4 plans) — completed 2026-06-12
- [x] Phase 103: Logo Tournament (4/4 plans) — completed 2026-06-12
- [x] Phase 104: Logo Refinement & Production Suite (3/3 plans) — completed 2026-06-12
- [x] Phase 105: HTML Brand Book (3/3 plans) — completed 2026-06-12
- [x] Phase 106: Collateral, Integration & Closeout (2/2 plans) — completed 2026-06-13

Full phase detail archived in `.planning/milestones/v9.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v10.0 Brand Normalization (Phases 107-109) — SHIPPED 2026-06-14</summary>

- [x] Phase 107: Token Source & Distribution (3/3 plans) — completed 2026-06-13
- [x] Phase 108: Consumer Normalization (4/4 plans) — completed 2026-06-14
- [x] Phase 109: Drift-Prevention Gate (3/3 plans) — completed 2026-06-14

Full phase detail archived in `.planning/milestones/v10.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v11.0 Release & Distribution Truth (Phases 110-111) — SHIPPED 2026-06-17</summary>

- [x] Phase 110: Native Publish & Lockstep Infrastructure (3/3 plans) — completed 2026-06-14
- [x] Phase 111: Generator Rewire, Clean-Room Proof & Release (5/5 plans) — completed 2026-06-17

First lockstep release: `crosswake 0.1.2` live on Hex + Maven Central + SwiftPM mirror from one release-please run. All 11 v1 requirements complete (PUB-01..03, LOCK-01/02, GEN-01/02, PROOF-01/02, DOCS-01, REL-01).

Full phase detail archived in `.planning/milestones/v11.0-ROADMAP.md`.

</details>

### v12.0 CI Honesty & Real-E2E Sweep (Phases 112-115) — ACTIVE

- [ ] **Phase 112: Real Offline Outbox Flush** - Make the demo app actually flush the IndexedDB outbox on reconnect
- [ ] **Phase 113: Honest E2E Rewrite + Compile Gate** - Replace the fraudulent test with one that exercises real app behavior, with a compile gate
- [ ] **Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard** - Lock the lane as a required status check and structurally prevent reversion
- [ ] **Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth** - Tighten the verifier, create missing ledgers, settle v8.0 doc contradictions

## Phase Details

### Phase 112: Real Offline Outbox Flush
**Goal**: The demo app's `offline_study.js` manages a real IndexedDB mutation queue and flushes it to the server on reconnect — so any test that runs against it exercises the app's own code path, not a test-injected fabrication
**Depends on**: Phase 111 (v11.0 complete)
**Requirements**: E2E-01, E2E-02
**Success Criteria** (what must be TRUE):
  1. A user clicking a flashcard rating control while offline causes `offline_study.js` to write a record to the IndexedDB `mutations` store (via `queueMutation()`) in the server-contract shape `{client_mutation_id, card_id, rating}`, with `client_mutation_id` from `crypto.randomUUID()`
  2. When network connectivity is restored, `offline_study.js` automatically drains the IndexedDB `mutations` store by POSTing to `/study/sync`, deletes records on 2xx, and leaves them queued on failure — without any test or external caller triggering the flush
  3. The `StudySessionLive` `sync_outbox` mock handler and its "Simulate Network Sync" button are removed entirely from `study_session_live.ex`
  4. `mix test` passes with the mock removed — no test depends on the deleted mock handler
**Plans**: 2 plans
Plans:
- [ ] 112-01-PLAN.md — Real IndexedDB outbox flush + Good/Hard rating controls + honest sync status (offline_study.js, index.html.heex)
- [ ] 112-02-PLAN.md — De-mock study_session_live.ex (remove sync_outbox handler/button/assigns); mix test stays green

### Phase 113: Honest E2E Rewrite + Compile Gate
**Goal**: `offline_sync.spec.ts` proves the full offline→reconnect→reconcile loop using only the app's own code paths, and the CI workflow fails loudly on a demo-app compile break instead of masking it as a Playwright port timeout
**Depends on**: Phase 112
**Requirements**: E2E-03, E2E-04
**Success Criteria** (what must be TRUE):
  1. `offline_sync.spec.ts` contains zero `page.evaluate()` calls that write to app state or invoke app-owned behavior — mutation queuing and outbox flushing are driven exclusively by real UI interaction and the app's own reconnect handler
  2. The test reads the `client_mutation_id` from IndexedDB (observation) and confirms it matches the Ecto row via `expect.poll` on `/_e2e/sync-state/:id` — the ID the test asserts is the one the app generated, not one the test minted
  3. The test asserts the IndexedDB outbox is empty after a successful flush, and a duplicate-flush case (same `client_mutation_id` posted twice) results in exactly one Ecto row
  4. `phase90-proof.yml` runs `mix compile --warnings-as-errors` in `examples/phoenix_host` before the Playwright step, so a compile break produces a compile error rather than a Playwright connection timeout
**Plans**: TBD

### Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard
**Goal**: The offline-sync E2E lane is a registered required status check that blocks merges on failure, and a structural CI check prevents any future PR from silently reverting the test to injection-based fabrication
**Depends on**: Phase 113 (requires ≥1 green run of the renamed job on `main`)
**Requirements**: GATE-01, GUARD-01, GUARD-02
**Success Criteria** (what must be TRUE):
  1. The offline-sync E2E job is named `merge-blocking-offline-sync-e2e` and is registered as a required status check on `main` with all existing required checks preserved in the branch-protection `checks` array (replaced, not appended); a `script/register-e2e-gate.sh` or workflow comment carries the exact `gh api ... PATCH` command for the harness-blocked case
  2. Every non-required CI lane carries `continue-on-error: true` and a `::notice` marking its advisory status; the advisory/required split is unambiguous in the workflow YAML
  3. A merge-blocking structural check (`script/check-e2e-honesty.mjs` or equivalent) scans `offline_sync.spec.ts` for the three injection anti-patterns (`window['crosswake_offline_mutations']`, `page.evaluate` calling `fetch(`, test-minted UUID asserted before any IndexedDB read) and fails the build if any reappear
  4. The `/_e2e/sync-state/:id` endpoint is confirmed mounted only under `:test`/`:e2e` environments (never `:prod`), verified by a `routes_test.exs` assertion or equivalent, and its test-only purpose is stated in the controller module docstring
**Plans**: TBD
**UI hint**: no

### Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth
**Goal**: The GSD closeout verifier fails closed instead of passing vacuously, every phase the tightened gate flags has a real `VALIDATION.md`, and the three planning documents that contradict each other about v8.0 converge on a single authoritative truth
**Depends on**: Nothing (independent of the E2E/gate track; GATE-02 must precede DEBT-01 within this phase)
**Requirements**: GATE-02, DEBT-01, DOC-01
**Success Criteria** (what must be TRUE):
  1. `CloseoutVerifier` raises on missing or malformed `expected_phases:` frontmatter in `CLOSEOUT.md` (no silent fallback to `@v40_phases`), and `validation_ledger_check/2` returns a blocking result when an expected phase resolves to zero ledger files with no active deferral
  2. Every phase previously flagged for a missing ledger (v3.6: 48/49/52/53; v3.8: 54-58; v3.9: 62/63) has a `*-VALIDATION.md` containing `nyquist_compliant: true` and a `tested_by:`/`evidence:` field citing a concrete CI run, test file, or artifact — not a bare attestation
  3. Stale deferral entries for this scope are flipped to `status: resolved` with evidence citations, and `mix closeout.verify` passes with no `(stale)` entries for the v3.6/v3.8/v3.9 scope
  4. A document-precedence rule is recorded in a canonical location establishing `MILESTONES.md` > `PROJECT.md` Requirements ✓ > `v*-MILESTONE-AUDIT.md`; `MILESTONES.md` gains a v8.0 entry consistent with PROJECT.md's SYNC-01/02/03 ✓; `v1.0-MILESTONE-AUDIT.md` is annotated (not overwritten) to note its `0/10` reflects verification gaps accepted as tech debt, subsequently satisfied
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 99. Real Network-Toggling E2E Tests | v8.0 | 2/2 | Complete | 2026-06-11 |
| 100. Storage Budget Enforcement | v8.0 | 2/2 | Complete | 2026-06-11 |
| 101. Offline UI Consolidation & Polish | v8.0 | 2/2 | Complete | 2026-06-11 |
| 102. Brand Audit & Token Foundation | v9.0 | 4/4 | Complete | 2026-06-12 |
| 103. Logo Tournament | v9.0 | 4/4 | Complete | 2026-06-12 |
| 104. Logo Refinement & Production Suite | v9.0 | 3/3 | Complete | 2026-06-12 |
| 105. HTML Brand Book | v9.0 | 3/3 | Complete | 2026-06-12 |
| 106. Collateral, Integration & Closeout | v9.0 | 2/2 | Complete | 2026-06-13 |
| 107. Token Source & Distribution | v10.0 | 3/3 | Complete | 2026-06-13 |
| 108. Consumer Normalization | v10.0 | 4/4 | Complete | 2026-06-14 |
| 109. Drift-Prevention Gate | v10.0 | 3/3 | Complete | 2026-06-14 |
| 110. Native Publish & Lockstep Infrastructure | v11.0 | 3/3 | Complete | 2026-06-14 |
| 111. Generator Rewire, Clean-Room Proof & Release | v11.0 | 5/5 | Complete | 2026-06-17 |
| 112. Real Offline Outbox Flush | v12.0 | 0/2 | Not started | - |
| 113. Honest E2E Rewrite + Compile Gate | v12.0 | 0/TBD | Not started | - |
| 114. Merge-Blocking CI Gate + Permanent Honesty Guard | v12.0 | 0/TBD | Not started | - |
| 115. Closeout-Verifier Honesty + Ledger Backlog + Doc Truth | v12.0 | 0/TBD | Not started | - |
