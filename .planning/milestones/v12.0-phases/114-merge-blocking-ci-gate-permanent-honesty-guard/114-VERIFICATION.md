---
phase: 114-merge-blocking-ci-gate-permanent-honesty-guard
verified: 2026-06-18T07:06:02Z
status: passed
score: 7/7
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard — Verification Report

**Phase Goal:** The offline-sync E2E lane is a registered required status check that blocks merges on failure, and a structural CI check prevents any future PR from silently reverting the test to injection-based fabrication.
**Verified:** 2026-06-18T07:06:02Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

All truths are drawn from the ROADMAP.md Phase 114 Success Criteria, merged with the must_haves in plan frontmatter. Coverage: GATE-01 (plans 01, 04, 05), GUARD-01 (plan 02), GUARD-02 (plan 03).

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Job `merge-blocking-offline-sync-e2e` exists, uses `if: always()`, `needs` all three sibling jobs, and rolls up via `re-actors/alls-green` — making it the sole required-check target | VERIFIED | Workflow line 127: `if: always()`, line 129: `needs: [guard-01-e2e-honesty, guard-02-prod-route-absence, e2e-proof]`, line 133: `uses: re-actors/alls-green@release/v1`, line 135: `jobs: ${{ toJSON(needs) }}`. Four job keys confirmed via `grep -cE` returning 4. |
| 2 | `script/register-e2e-gate.sh` ships a GET-then-replace registration script with green-first preflight (exit 2), DRY_RUN support, `unique_by(.context)` idempotency, drops old `e2e-offline-sync`, adds `merge-blocking-offline-sync-e2e` with `app_id 15368`, and the workflow header carries the exact `gh api PATCH` one-liner + ordering runbook | VERIFIED | `bash -n` passes; file is executable; `unique_by(.context)`, `exit 2`, `DRY_RUN`, OLD_CHECK, NEW_CHECK, `15368`, and `required_status_checks` all confirmed by grep. Workflow header comment at lines 8–31 carries the ordering runbook and the equivalent PATCH one-liner. DRY_RUN exits before preflight (line 58–62) before the preflight block (lines 64–82). |
| 3 | Advisory lanes are non-blocking by omission from `checks[]` (never via `continue-on-error: true`); REQUIREMENTS.md GATE-01 and ROADMAP.md Phase 114 SC-2 both state omission/trigger-scoping wording; PITFALLS.md prescriptive rows corrected | VERIFIED | REQUIREMENTS.md line 27 contains "omission from the branch-protection `checks[]` array" and does not contain "keeps `continue-on-error: true`". ROADMAP.md line 116 mirrors the omission/trigger-scoping wording. Zero `phase90-proof.yml` filename refs remain outside the 114 phase dir (REMAIN=0 confirmed). |
| 4 | `script/check-e2e-honesty.mjs` parses `offline_sync.spec.ts` via the TypeScript compiler API (AST via `createRequire` + `ts.createSourceFile`), bans all three fabrication shapes unconditionally, exits 1 on missing spec, and passes the current honest spec | VERIFIED | `ts = requireFrom('typescript')` + `ts.createSourceFile` confirmed. All three rules present: `inject-global` (crosswake_offline_mutations), `fetch-in-evaluate` (isEvaluate + isNetwork scan), `minted-uuid` (randomUUID + uuid import). Missing-file: `existsSync` + `process.exit(1)`. No `OBSERVATION_ONLY` gate (D-05 satisfied). Behavioral: `node script/check-e2e-honesty.mjs` exits 0 on honest spec (confirmed by spot-check). Missing-file case exits 1 (confirmed by spot-check). |
| 5 | `typescript` is pinned as an explicit devDependency in `examples/phoenix_host/package.json`; `guard-01-e2e-honesty` CI job runs `npm ci --prefix examples/phoenix_host` before the honesty check | VERIFIED | `"typescript": "^5.9.3"` found in package.json devDependencies. Workflow line 53: `run: npm ci --prefix examples/phoenix_host` precedes the honesty check step at line 55. |
| 6 | `router_test.exs` asserts the `/_e2e/sync-state/:client_mutation_id` route is compiled under `:test`, wired to `SyncStateController :show`, verb `:get` — using `Phoenix.Router.routes/1` without `~p` | VERIFIED | File exists. Contains `Phoenix.Router.routes()`, asserts `verb == :get`, `plug == CrosswakeExample.E2E.SyncStateController`, `plug_opts == :show`. No `~p` sigil. Behavioral: `mix test router_test.exs sync_state_controller_test.exs` — 3 tests, 0 failures (run confirmed). |
| 7 | `sync_state_controller_test.exs` inserts >=2 distinct `client_mutation_id` rows and asserts `count == 1` per id (guarding the whole-table aggregate footgun); `router.ex` carries the `/_e2e` namespace comment; the `Mix.env() in [:test, :e2e]` gate is unchanged; controller `@moduledoc` states test-only purpose | VERIFIED | Test inserts `id_a` and `id_b` (two distinct rows), calls `SyncStateController.show/2` for each, asserts `count == 1` both times. Second test asserts `synced: false, count: 0` for missing id. `router.ex` line 378: `# /_e2e is the reserved test-harness namespace — compile-time gated OUT of prod beams.` above `if Mix.env() in [:test, :e2e] do` (unchanged). `sync_state_controller.ex` `@moduledoc`: "Test-only endpoint for asserting server-side sync state in E2E specs. Mounted only in :test and :e2e environments." |

**Score:** 7/7 truths verified (0 present-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/offline-sync-e2e-gate.yml` | Four-job aggregator topology; `merge-blocking-offline-sync-e2e` sole required check | VERIFIED | Exists; 4 job keys confirmed; aggregator wired with `if: always()`, `needs`, `alls-green`; `permissions: contents: read`; archaeology comment present; renamed via `git mv` with history preserved (git log --follow shows 5 commits including pre-rename history). |
| `script/check-e2e-honesty.mjs` | AST-based honesty guard; 3 banned shapes; missing-file exit 1 | VERIFIED | Exists; uses TypeScript compiler API via `createRequire`; all three rules implemented; missing-file detection present; passes honest spec (exit 0), exits 1 on missing file. |
| `script/register-e2e-gate.sh` | GET-then-replace branch-protection with green-first preflight | VERIFIED | Exists; `bash -n` clean; executable; GET-then-replace with `unique_by(.context)`; DRY_RUN support; `exit 2` preflight; correct parameters. |
| `examples/phoenix_host/test/crosswake_example/router_test.exs` | Route-presence assertion under `:test` | VERIFIED | Exists; `Phoenix.Router.routes/1` introspection; asserts verb/plug/plug_opts; no `~p`; passes in ExUnit. |
| `examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs` | Count-scoping proof; `count == 1` with >=2 distinct rows | VERIFIED | Exists; 2 distinct rows inserted; asserts `count == 1` per id; non-existent id returns `synced: false, count: 0`; deterministic cleanup via `on_exit`. |
| `.planning/REQUIREMENTS.md` (GATE-01 amendment) | Omission-from-checks[] wording, no `continue-on-error` prescription | VERIFIED | Contains "omission from the branch-protection"; does not contain "keeps `continue-on-error: true`". |
| `examples/phoenix_host/package.json` | Explicit `typescript` devDependency pin | VERIFIED | `"typescript": "^5.9.3"` present in devDependencies. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `.github/workflows/offline-sync-e2e-gate.yml` | `script/check-e2e-honesty.mjs` | `guard-01-e2e-honesty` runs `node script/check-e2e-honesty.mjs` | WIRED | Workflow line 55 confirms exact invocation. |
| `.github/workflows/offline-sync-e2e-gate.yml` | `examples/phoenix_host/test/crosswake_example/router_test.exs` | `e2e-proof` runs `mix test ... router_test.exs sync_state_controller_test.exs` | WIRED | Workflow line 113 confirms both test files are referenced. |
| `script/register-e2e-gate.sh` | `.github/workflows/offline-sync-e2e-gate.yml` | Registers `merge-blocking-offline-sync-e2e` (the aggregator job name) as the required check | WIRED | Script `NEW_CHECK` var matches the aggregator job name in the workflow. Workflow header comment references `script/register-e2e-gate.sh`. |
| `examples/phoenix_host/test/crosswake_example/router_test.exs` | `examples/phoenix_host/lib/crosswake_example/router.ex` | `Phoenix.Router.routes(CrosswakeExample.Router)` finds the `/_e2e` route | WIRED | Test calls `CrosswakeExample.Router |> Phoenix.Router.routes()`; router.ex line 379 compiles the route under `:test`. ExUnit run passes. |
| `examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs` | `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` | Directly invokes `SyncStateController.show/2` | WIRED | Test calls `CrosswakeExample.E2E.SyncStateController.show(conn, ...)` and decodes the JSON response. ExUnit run passes with real Repo queries confirmed in debug output. |

### Data-Flow Trace (Level 4)

Not applicable — phase deliverables are CI workflow files, shell scripts, and ExUnit tests. No React/Vue/Svelte components or data-rendering UI artifacts were produced.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `check-e2e-honesty.mjs` exits 0 on honest spec | `node script/check-e2e-honesty.mjs` | `exit=0`; "E2E honesty check passed" | PASS |
| `check-e2e-honesty.mjs` exits 1 on missing spec | Temporarily renamed spec; ran script | `exit code on missing spec: 1` | PASS |
| GUARD-02 ExUnit tests pass | `mix test router_test.exs sync_state_controller_test.exs` | 3 tests, 0 failures | PASS |
| `register-e2e-gate.sh` parses clean | `bash -n script/register-e2e-gate.sh` | Parses clean; file executable | PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| GATE-01 | 114-01, 114-04, 114-05 | E2E job named `merge-blocking-offline-sync-e2e`; registered as required check; register script ships; advisory lanes by omission | SATISFIED | Workflow has the aggregator job; register-e2e-gate.sh ships; REQUIREMENTS.md corrected; workflow header carries PATCH one-liner + runbook |
| GUARD-01 | 114-02 | AST honesty guard scans spec for three fabrication shapes; fails on missing spec | SATISFIED | `script/check-e2e-honesty.mjs` uses TypeScript compiler API; all three rules implemented; missing-file exit 1 confirmed |
| GUARD-02 | 114-03 | `/_e2e` endpoint confirmed test-only; router_test.exs asserts presence; controller test proves count scoping; router.ex documents namespace | SATISFIED | router_test.exs passes; controller test proves count==1 with 2 rows; router.ex comment present; @moduledoc states test-only |

**Note on GATE-02, DEBT-01, DOC-01:** These requirements map to Phase 115 per REQUIREMENTS.md traceability table. They are correctly deferred — not a gap for Phase 114.

### Anti-Patterns Found

No TBD/FIXME/XXX markers found in any Phase 114 deliverable. No stub implementations detected. No placeholder values — the `[placeholder: plan 114-05 will paste ...]` comment in the workflow was replaced by plan 114-05 (confirmed: workflow header contains the actual runbook, not a placeholder).

No `continue-on-error: true` in the workflow. No `grep -v` in the guard-02 prod-route-absence step. No `~p` sigil in router_test.exs.

### Human Verification Required

None. All must-haves are verifiable from the codebase and behavioral spot-checks. The branch-protection registration (running `script/register-e2e-gate.sh` to actually mutate GitHub's API) is a documented post-merge runbook step (D-06) explicitly scoped to "harness-blocked, run out-of-band by maintainer" — this is by design, not a gap. The script and workflow comment that enable the registration are present and correct.

### Gaps Summary

No gaps. All seven observable truths verified. All five plans' artifacts exist, are substantive (not stubs), and are wired. Three behavioral spot-checks pass. ExUnit test suite passes (3 tests, 0 failures). Requirement IDs GATE-01, GUARD-01, and GUARD-02 are fully covered.

---

_Verified: 2026-06-18T07:06:02Z_
_Verifier: Claude (gsd-verifier)_
