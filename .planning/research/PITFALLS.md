# Pitfalls Research

**Domain:** CI Honesty / Real-E2E Sweep — Crosswake v12.0
**Researched:** 2026-06-17
**Confidence:** HIGH (evidence drawn entirely from this repo's own failure history, source files, and audit artifacts)

---

## Critical Pitfalls

### Pitfall 1: Test-Only Global Injection Masking a Dead Application

**What goes wrong:**
The E2E test writes mutations directly to `window['crosswake_offline_mutations']` via `page.evaluate()`, then manually fires a `fetch('/study/sync', ...)` call — also via `page.evaluate()`. The application's own offline JS engine is never invoked. The test asserts the server received the sync payload, but it placed that payload there itself. This is exactly the pattern in `offline_sync.spec.ts` lines 21-50: the test fabricates the outbox entry, calls the flush, intercepts the request it just made, and then checks that the ID matches. The application's IndexedDB write path, its outbox listener, and its reconnect handler are all untested. The demo app's compile break (the `CrosswakeExampleWeb` macro module that did not exist) was hidden for exactly this reason — the Playwright run succeeded without the app actually compiling and serving correctly.

**Why it happens:**
When a real offline flow requires timing-sensitive reconnect events and IndexedDB round-trips, it is tempting to shortcut to "assert the network contract" and inject data through the test rather than let the application write it. This produces a green run immediately, which is accepted under deadline pressure.

**How to avoid:**
The E2E test must perform only real user actions (click, keyboard, navigation). No `page.evaluate()` that writes application state. The mutation must originate from a real UI interaction that causes the application's JS to write to IndexedDB. The flush must be triggered by `context.setOffline(false)` alone — the application's own reconnect handler must detect the change and flush. Assert only on server-visible state (the `/_e2e/sync-state/:id` poll) after waiting for the application to act.

**Warning signs:**
- Test contains `page.evaluate()` that assigns to a `window['..._mutations']` or `window['..._outbox']` global.
- Test manually calls `fetch(...)` inside a `page.evaluate()` to trigger the sync rather than waiting for the application to do it.
- The workflow has no `mix compile` step before launching Playwright — a compile break cannot be caught.
- The workflow runs `npx playwright test` directly without a step that would surface a server-startup failure independently.

**Phase to address:**
The phase that replaces the mocked E2E (E2E-01). The compile check and the test rewrite are a single atomic deliverable — they must land together.

---

### Pitfall 2: `context.setOffline` Does Not Simulate a Real Network Change for All Reconnect Handlers

**What goes wrong:**
`context.setOffline(true/false)` operates at the CDP level and intercepts network requests made by the page. It does not reliably trigger the browser's `online`/`offline` DOM events in all configurations, and it does not interact with registered Service Workers or the Background Sync API. If the application's reconnect handler listens to `window.addEventListener('online', ...)` rather than monitoring `fetch` failures, it may never fire. Additionally, Chromium in headless mode and Ubuntu CI runners may have different timing for `online` event propagation after `setOffline(false)`.

The current `playwright.config.ts` sets `serviceWorkers: 'block'` — this is the correct defense for IndexedDB test isolation — but the reconnect trigger is still application-code-dependent.

**Why it happens:**
The CDP `Network.emulateNetworkConditions` behavior is documented as intercepting requests, not as injecting browser lifecycle events. Developers assume `setOffline(false)` is equivalent to a cable being plugged back in. On some Chromium versions it triggers `online` events; on others it does not.

**How to avoid:**
After `context.setOffline(false)`, add an explicit poll for a known UI indicator (e.g., a "Syncing..." status element appearing) before asserting the Ecto state. Do not rely on a bare `waitForRequest` timeout as the only reconnect signal. If the application's JS uses `navigator.onLine` polling instead of the `online` event, document that explicitly in the test and verify it works in CI (Ubuntu/headless Chromium specifically). The `retries: 2` already in `playwright.config.ts` masks flake but does not eliminate it — the fix is a deterministic reconnect assertion, not more retries.

**Warning signs:**
- Test races past `setOffline(false)` with a hard-coded `waitForTimeout()`.
- CI passes locally (macOS Chromium) but flakes on Ubuntu runners.
- The test catches the sync request intermittently — some runs succeed, some time out.

**Phase to address:**
E2E-01 phase (real network-toggling test rewrite). Address the reconnect assertion at the same time as the mutation injection fix.

---

### Pitfall 3: IndexedDB State Leaking Between Test Runs

**What goes wrong:**
IndexedDB persists across page navigations within the same browser context. If a test leaves stale mutation records in the database, a subsequent test will attempt to sync them to the backend. The backend `/_e2e/sync-state/:id` endpoint may return `{ synced: true }` for an ID from a prior run if the database was not cleaned. The result is a false-positive: the test "passes" because old data satisfies the assertion.

The `playwright.config.ts` uses `webServer.command` with `ecto.drop + ecto.create + ecto.migrate` — this resets the Postgres side per run but does not reset IndexedDB, which lives in the browser context for the duration of the test session.

**Why it happens:**
Developers reset the server-side database (visible, explicit) but forget that the client-side IndexedDB is equally stateful and persists within a browser context across tests in the same suite run.

**How to avoid:**
Each test that touches IndexedDB must open a fresh `BrowserContext` (`browser.newContext()`) rather than sharing the default context, or must explicitly delete the test database at the start of the test: `await page.evaluate(() => indexedDB.deleteDatabase('crosswake_offline'))`. The `workers: 1` setting in `playwright.config.ts` prevents parallel context sharing but does not prevent sequential tests from seeing each other's IndexedDB.

**Warning signs:**
- A test that does not write to IndexedDB still returns `synced: true` from the backend check.
- Tests pass individually but fail when run as part of the full suite.
- No `beforeEach` or `browser.newContext()` call in tests that assert on sync state.

**Phase to address:**
E2E-01 phase, test harness setup task.

---

### Pitfall 4: Phase 90 Workflow Does Not Compile the Phoenix App Before Running Playwright

**What goes wrong:**
The `phase90-proof.yml` workflow runs `mix deps.get` and then immediately `npx playwright test`. It never runs `mix compile` or `mix phx.server` in a health-check mode. The `playwright.config.ts` `webServer.command` launches `mix phx.server` as a side effect of Playwright startup — but if the server crashes on startup due to a compile error, Playwright reports a timeout trying to connect to `http://localhost:4002`, not a compile failure. The CI log shows a Playwright connection error, not an Elixir stack trace, making the root cause opaque.

This is the exact mechanism that hid the `CrosswakeExampleWeb` macro module compile break in v6.0: the mocked E2E never actually needed the server to serve anything correctly, so the compile failure was invisible.

**Why it happens:**
Playwright's `webServer` integration swallows server stderr unless `stderr` is explicitly piped. The failure mode appears as a slow startup or port-connection error, not a compile error. The gap between "deps installed" and "server actually running" is silent.

**How to avoid:**
Add an explicit `mix compile --warnings-as-errors` step in the workflow before the Playwright step, run from the `examples/phoenix_host` working directory. This ensures the application compiles cleanly before any E2E test attempts to start the server. Workflow order: deps.get → compile (fail fast, clear error) → Playwright (which starts the server as a subprocess).

**Warning signs:**
- CI shows a "server did not start in time" Playwright error with no Elixir output preceding it.
- The `phase90-proof.yml` workflow has no `mix compile` step.
- Local developer never sees the error because `reuseExistingServer: !process.env.CI` means the server was already running locally.

**Phase to address:**
E2E-01 phase, workflow hardening task. Atomic with the test rewrite.

---

### Pitfall 5: Advisory Lane Masquerading as a Required Gate (or Required Check That Never Runs)

**What goes wrong:**
Two symmetric failure modes exist:

**Advisory-looks-required:** A workflow runs without `continue-on-error: true` but is not listed in GitHub's branch-protection required status checks. The lane runs, appears in the checks list, and developers assume it gates merges. A failure is visible in the PR but does not block merge. This is the current state of `phase90-proof.yml`: it has no `continue-on-error: true`, so it appears required, but its job ID `e2e-offline-sync` is almost certainly not registered in branch protection.

**Required-check-never-runs-means-blocked-forever:** A job is listed in branch-protection required-status-checks, but the workflow's trigger does not fire on that branch or event type. GitHub reports the check as "Expected — Waiting" and the PR cannot merge even though no failure occurred.

**Why it happens:**
Branch protection is configured in GitHub's UI, not in the YAML file. There is no in-repo source of truth for which check contexts are required. Renaming a job (`jobs: e2e-offline-sync` → `jobs: e2e-offline-sync-real`) silently drops it from the required-checks list because GitHub matches by the exact job name string.

**How to avoid:**
- Document required check context names explicitly in the workflow YAML comment, as `brandbook-verify.yml` does: "Add this job's check context to branch-protection required-status-checks."
- Use the GitHub CLI to verify branch protection after any workflow rename: `gh api repos/{owner}/{repo}/branches/main/protection`.
- Mark advisory lanes as non-blocking by **omission from the branch-protection `checks[]` array** (and trigger-scope to `schedule`/`workflow_dispatch` where they should not run per-PR) — **never** via `continue-on-error: true`, which paints a failed lane green and makes it permanently unpromotable (D-02/D-06). Each advisory lane should carry an `advisory-`-prefixed job `name:` and an `echo "::notice"` step so advisors are visually distinct in the GitHub UI; failures surface as honest red.
- For required lanes, add a `name:` field under the job key that matches the registered check context exactly.

**Warning signs:**
- A workflow job has no `name:` field — its check context is the raw job key, which changes if the job is renamed.
- No workflow YAML comment states "this is/is not a required status check."
- `phase90-proof.yml` has no `name:` on the `e2e-offline-sync` job, no `continue-on-error`, and no branch-protection comment.

**Phase to address:**
Branch-protection hardening phase. Address before or alongside E2E-01, since fixing the E2E and marking it required are the same deliverable.

---

### Pitfall 6: Matrix Jobs Create Multiple Check Contexts; Only One May Be Required

**What goes wrong:**
If the E2E workflow is expanded to a matrix (e.g., `matrix: { browser: [chromium, firefox] }`), GitHub creates separate check contexts: `e2e-offline-sync (chromium)` and `e2e-offline-sync (firefox)`. If branch protection requires `e2e-offline-sync (chromium)` and the job is later renamed or the matrix key changes, the required check context silently becomes "Expected — Waiting" forever.

**Why it happens:**
Matrix job names are computed strings. They are not obvious from the workflow YAML alone, and they differ from the bare job key when a matrix is present.

**How to avoid:**
For the v12.0 E2E lane, use a single-browser target (Chromium, as already configured) with no matrix. If multi-browser coverage is added later, the required check must be a separate non-matrix summary job that `needs:` all matrix jobs and is the registered required-check context.

**Warning signs:**
- A matrix exists on the E2E job without a companion `all-passed` summary job.
- Branch protection requires a string like `e2e-offline-sync` but the actual emitted context is `e2e-offline-sync (chromium)`.

**Phase to address:**
Branch-protection hardening phase; document as a constraint in the E2E workflow.

---

### Pitfall 7: Closeout Gate Passing Vacuously When the Archived Phase Path Has No Files

**What goes wrong:**
`CloseoutVerifier.phase_paths/4` builds a wildcard glob for archived phase artifacts:

```
.planning/milestones/#{milestone}-phases/#{phase}-*/#{suffix}
```

If `milestone` in STATE.md is `nil` or stale, `phase_paths/4` returns `archived = []`. `validation_ledger_check/2` then evaluates `problematic = Enum.reject(phases, fn phase -> paths != [] and ... end)` — when `paths == []` the rejection condition is true, so the phase is "problematic." However, the outer `passed` condition also checks `closeout =~ ~r/validation_ledger_status:\s*\n\s*status:\s*(complete|deferred_with_reason|archived)/`. If someone marks `validation_ledger_status: status: deferred_with_reason` in the CLOSEOUT.md, the `deferred` escape hatch triggers and the check passes even though no actual ledger files were found.

The previously observed vacuous-pass pattern is this exact path: empty glob → zero ledgers found → escape-hatch YAML string present → passes. The current code correctly checks `status not in ["resolved", "closed"]`, but the risk remains that `milestone` being `nil` causes `phase_paths/4` to return empty for both the archived and live paths simultaneously.

**Why it happens:**
The escape hatch for `validation-ledger-finalization` deferrals is necessary (ledgers are acknowledged debt), but it fires when the deferred entry exists without requiring that the glob returned anything. "No files found" and "files found, all compliant" produce the same gate result when the deferral is active.

**How to avoid:**
Add an assertion in the check that at least one path was found for each expected phase before declaring it compliant. "No paths found" should produce a distinct error from "paths found but not compliant," so a vacuous pass is impossible. The fix is: if `paths == []` and no deferral is active, fail with "no validation artifacts found" rather than silently passing or silently including in `problematic` where it can be escaped.

**Warning signs:**
- STATE.md has no `milestone:` field or it points to an already-archived milestone.
- `CloseoutVerifier.run/1` emits `observed: ok` for `closeout.validation.ledger` despite no `*-VALIDATION.md` files existing under the milestone phase directory.
- The `expected_phases` frontmatter key is missing from CLOSEOUT.md, causing the fallback to `@v40_phases = ~w(64 65 66 67 68 69)` — phases from a completely different milestone.

**Phase to address:**
LEDG-01 / closeout-gate tightening phase. This is the "tighten-validation-ledger-closeout-gate" quick task carried since v8.0.

---

### Pitfall 8: Hardcoded Phase Lists Break Post-Archival and Cross-Milestone

**What goes wrong:**
`@v40_phases ~w(64 65 66 67 68 69)` is a module-level constant. Any call to `expected_phases/1` that returns an empty list (missing or malformed `expected_phases:` key in CLOSEOUT.md frontmatter) falls through to these hardcoded v4.0 phase numbers — regardless of the milestone being verified. During v12.0 closeout, the verifier would look for phases 64-69 validation ledgers, find none (they are archived under `v4.0-phases/`), and either vacuously pass (via the deferred escape hatch) or produce misleading "missing verification" errors for the wrong phases.

**Why it happens:**
The fallback exists so the verifier does not silently pass on a malformed CLOSEOUT.md. But the specific phase numbers are v4.0-specific and have no meaning for any subsequent milestone.

**How to avoid:**
The fallback should produce a hard error ("expected_phases not found in CLOSEOUT.md frontmatter — cannot determine which phases to verify") rather than silently substituting a stale phase list. For v12.0, ensure the CLOSEOUT.md template includes an explicit `expected_phases:` list populated from the milestone's actual phase numbers.

**Warning signs:**
- A new milestone's CLOSEOUT.md is missing the `expected_phases:` frontmatter key.
- The verifier log references phases 64-69 during a post-v4.0 milestone closeout.
- No error is surfaced despite the CLOSEOUT.md being invalid.

**Phase to address:**
LEDG-01 / closeout-gate tightening phase. Fix the fallback to fail loudly before addressing the vacuous-pass path.

---

### Pitfall 9: Signing a VALIDATION.md to Make the Gate Green Without Actually Validating

**What goes wrong:**
`validation_ledger_check/2` passes when `nyquist_compliant: true` is present in every `*-VALIDATION.md` file for the phase. This is a string-presence check: `read_file(&1) =~ "nyquist_compliant: true"`. A developer can create a minimal VALIDATION.md with that string and no actual validation evidence — no test run references, no requirement-to-evidence mapping, no phase-specific assertions. The gate goes green.

The v3.9 and v8.0 closeouts explicitly carried validation-ledger debt as `deferred_with_reason` rather than forcing this, but the temptation exists at every closeout under time pressure.

**Why it happens:**
The gate checks structure and key presence, not semantic content. There is no cross-reference between what `nyquist_compliant: true` claims and what tests actually ran. It is the fastest path to a passing gate.

**How to avoid:**
Treat `nyquist_compliant: true` as a human attestation, not a mechanical check. The v12.0 LEDG-01 work should decide: either (a) make the check more structural by requiring a `tested_by:` list naming actual test files or CI run IDs, or (b) document explicitly that `nyquist_compliant: true` is a human attestation and that the attestation itself is the accountability mechanism. Do not set `nyquist_compliant: true` without pointing to a specific test or CI run.

**Warning signs:**
- A `*-VALIDATION.md` file contains `nyquist_compliant: true` and fewer than 5 lines total.
- No `tested_by:`, `ci_run:`, or `evidence:` field exists alongside the compliance flag.
- The ledger was added in a commit that also edited the CLOSEOUT.md to close the validation-ledger gap.

**Phase to address:**
LEDG-01 / closeout-gate tightening phase.

---

### Pitfall 10: Stale Deferrals That Accumulate Without Resolution Criteria

**What goes wrong:**
The `prior_validation_debt_check/2` scans prior `v*-CLOSEOUT.md` files for `deferred_with_reason` entries with `scope: validation-ledger-finalization` and `status:` not `resolved` or `closed`. It flags them as unresolved debt. Currently `tighten-validation-ledger-closeout-gate` (LEDG-01) has been carried through v8.0, v9.0, v10.0, and v11.0. Each time it was acknowledged and re-deferred without a `revisit_phase` that ever produced resolution. The `stale_deferral?/2` helper tags such entries as `(stale)` when the revisit_phase directory now exists — but stale is a label, not a blocker. The debt compounds.

**Why it happens:**
Deferrals without concrete acceptance criteria ("we will resolve this when X is true") become permanent background noise. The `revisit_phase` field names a phase but not a condition. When that phase passes without resolving the deferral, no automated mechanism forces resolution.

**How to avoid:**
The v12.0 LEDG-01 work must define a resolution condition, not just create ledger files. The resolution condition should be: "every phase in every active milestone has a `*-VALIDATION.md` with `nyquist_compliant: true` and at least one `tested_by:` or `evidence:` reference." The deferral status should move to `resolved` only when that condition is met for all historically deferred phases. Do not close LEDG-01 by marking the deferral `resolved` in the CLOSEOUT.md while leaving the underlying ledger files absent or empty.

**Warning signs:**
- `prior_validation_debt_check` output shows `(stale)` next to the `tighten-validation-ledger-closeout-gate` entry.
- The LEDG-01 deferral has been carried across more than three milestones with the same `reason:` text and no updated `evidence:`.
- The new milestone's CLOSEOUT.md marks the deferral `status: resolved` but no new `*-VALIDATION.md` files were added in the milestone.

**Phase to address:**
LEDG-01 phase (dedicated closeout-gate tightening). Must produce actual ledger artifacts, not only a status-field edit.

---

### Pitfall 11: Doc-Truth Precedence — Which File Wins When Documents Disagree?

**What goes wrong:**
The milestone context identifies a specific instance: `v1.0-MILESTONE-AUDIT.md` scores v8.0 at 0/10 while `PROJECT.md` marks those same requirements ✓, and `MILESTONES.md` has no v8.0 entry at all. These three documents have different purposes:

- `PROJECT.md` Requirements section: tracks whether a requirement has been validated across all milestones. Its ✓ marks are the authoritative shipped state after resolution — but they can be edited optimistically without verifying the audit file.
- `v1.0-MILESTONE-AUDIT.md`: a point-in-time automated snapshot taken at a specific moment. Its `0/10` score reflects that VERIFICATION.md was missing for phases 99-101 at the time of the audit — not that the requirements are permanently unsatisfied.
- `MILESTONES.md`: a human-curated changelog of completed milestones. v8.0 does not appear here because it was shipped and summarized inline in `PROJECT.md` rather than getting a standalone MILESTONES.md entry.

The trap is treating a stale audit snapshot as the authoritative truth about current state, or treating PROJECT.md ✓ marks as proof that requirements were validated when they may have been marked done without a verification artifact.

**Why it happens:**
There is no documented precedence order. When docs disagree, a reader must infer which is more current or more authoritative, and they will guess wrong. Both conclusions available from reading the two documents are incorrect: "requirements are unresolved today" (from audit) and "there is nothing to fix in E2E" (from PROJECT.md ✓).

**How to avoid:**
Establish and document a precedence rule for this repo:

1. `MILESTONES.md` (human-curated, post-archival) — authoritative for shipped state after a milestone is closed and archived.
2. `PROJECT.md` Requirements section — authoritative during active work; ✓ marks must be backed by a VERIFICATION.md or CI run reference, not assumed to imply perfect proof.
3. `v*-MILESTONE-AUDIT.md` files — point-in-time audit snapshots. A score of `0/10` with `gaps_found` means verification artifacts were missing at audit time, not necessarily that the work was not done. Both can be true simultaneously: the work shipped but the verification artifacts were incomplete; the audit gap is the honest record of that verification debt.

The doc-truth reconciliation task for v12.0 should write this rule down and reconcile the v8.0 discrepancy by adding a MILESTONES.md entry for v8.0 or annotating `v1.0-MILESTONE-AUDIT.md` to note that the requirements were subsequently satisfied post-audit.

**Warning signs:**
- A developer reads `v1.0-MILESTONE-AUDIT.md` and concludes SYNC-01/SYNC-02/SYNC-03 are permanently unvalidated.
- A developer reads PROJECT.md ✓ marks and concludes the E2E is already correct.
- Neither document explains its own authority scope relative to the other.

**Phase to address:**
Doc-truth reconciliation phase (small, standalone). Should precede or accompany the E2E rewrite so "what is the current honest state" is settled before new claims are made.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Fabricate outbox via `page.evaluate()` | Green E2E in hours, no reconnect timing issues | Hides compile breaks; never exercises real JS flush path; gives false confidence on SYNC-01/02 | Never — the entire value of E2E is exercising the application under test |
| Mark `nyquist_compliant: true` without evidence | Unblocks milestone closeout gate | Ledger becomes a bureaucratic ritual; future audits cannot distinguish compliant from placeholder | Only if a specific CI run ID or test name is cited alongside |
| Carry `deferred_with_reason` without a resolution condition | Defers debt without commitment | Debt compounds; `prior_validation_debt_check` perpetually flags stale deferrals; future maintainers cannot tell if "stale" means "fixed" or "forgotten" | Acceptable once per deferral if `revisit_phase` is set; unacceptable across 4+ milestones |
| Make advisory lane non-blocking via `continue-on-error: true` instead of omission from `checks[]` | Appears to suppress advisory failures cleanly | A soft-failed lane resolves as success — counts as pass for required checks and `needs:`, making it permanently unpromotable to a real gate; the honest pattern is omission from `checks[]` (D-02/D-06) | Never — use omission from `checks[]` + optional trigger-scoping, never `continue-on-error` |
| No `mix compile` step before Playwright | Faster workflow setup | Compile errors surface as opaque port-connection timeouts in CI | Never for a merge-blocking lane |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| CDP `setOffline` | Assuming it triggers `window.online` event | Verify with `page.waitForFunction(() => navigator.onLine)` or poll a UI indicator after `setOffline(false)` before asserting |
| Playwright `webServer` + Phoenix | Assuming startup failure shows as a clear error | Add explicit `mix compile` step; server startup failure surfaces as an Elixir error, not a Playwright timeout |
| GitHub branch protection + job rename | Renaming a job drops it from required checks silently | Document required check name in YAML comment; verify via `gh api` after any rename |
| `CloseoutVerifier` + STATE.md | Stale or missing `milestone:` key in STATE.md frontmatter causes `phase_paths/4` to return empty | Verifier should assert `milestone != nil` before evaluating phase artifact globs |
| IndexedDB + Playwright test isolation | Shared context carries IndexedDB state between tests | Use `browser.newContext()` per test or `indexedDB.deleteDatabase(...)` in `beforeEach` |

---

## "Looks Done But Isn't" Checklist

- [ ] **Real E2E:** Playwright test contains no `page.evaluate()` that writes to a `window[...]` global or calls `fetch` directly — verify by grepping test files for `page.evaluate` calls that assign to application state.
- [ ] **Compile gate:** The E2E workflow has an explicit `mix compile --warnings-as-errors` step in `examples/phoenix_host` before the Playwright step.
- [ ] **Branch-protection registered:** The new E2E workflow's job `name:` is listed in the branch-protection required status checks and documented in a YAML comment — verified via `gh api repos/{owner}/{repo}/branches/main/protection`.
- [ ] **Advisory lanes marked:** Every non-required CI lane is non-blocking by omission from the branch-protection `checks[]` array (and trigger-scoped to `schedule`/`workflow_dispatch` where it should not run per-PR) — never via `continue-on-error: true`, which paints failures green (D-02/D-06). Each advisory lane carries an `advisory-`-prefixed job `name:` and an `echo "::notice"` step; failures surface as honest red.
- [ ] **Ledger artifacts exist:** Every phase in v12.0 has a `*-VALIDATION.md` file under the archived phase directory with `nyquist_compliant: true` AND a `tested_by:` or `evidence:` reference to a specific test or CI run.
- [ ] **LEDG-01 deferral resolved:** The `tighten-validation-ledger-closeout-gate` entry in prior CLOSEOUT.md files has `status: resolved` AND the corresponding ledger files now exist (not just the status field changed).
- [ ] **Fallback phase list removed or hardened:** `CloseoutVerifier` does not silently fall back to `@v40_phases` for missing `expected_phases:` frontmatter — it raises or returns a hard error.
- [ ] **Doc precedence documented:** The rules for which document wins when PROJECT.md, a MILESTONE-AUDIT.md, and MILESTONES.md disagree are written down and visible to future maintainers.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Test-only global injection (discovered post-ship) | MEDIUM | Rewrite test; re-run CI; update VERIFICATION.md with actual run ID; add note to PROJECT.md that prior ✓ was from fabricated E2E |
| `setOffline` reconnect flake on CI | LOW | Add explicit UI-indicator poll after `setOffline(false)`; confirm passes 5x on Ubuntu runner without retries |
| IndexedDB state leakage | LOW | Add `beforeEach` database reset; confirm test passes in suite order and reverse order |
| Missing compile gate (compile break discovered late) | LOW | Add `mix compile` step; re-run; accept the embarrassment that a compile break lived in CI |
| Advisory lane masquerading as required | LOW | Remove from branch-protection `checks[]` (omission-from-checks[] pattern, D-02/D-06); add `advisory-`-prefixed job `name:` and `::notice` step; trigger-scope to `schedule`/`workflow_dispatch` if it should not run per-PR; document in YAML comment — do NOT add `continue-on-error: true` (paints failures green, makes lane permanently unpromotable) |
| Vacuous closeout pass | MEDIUM | Add artifact-existence assertion to verifier; re-run closeout verification; create actual ledger files for affected phases |
| Stale deferral accumulation | LOW | Define resolution criteria; create ledger files; mark deferral `status: resolved` with evidence |
| Doc-truth disagreement | LOW | Write precedence rule; add MILESTONES.md entry for v8.0; annotate audit file |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Test-only global injection (Pitfall 1) | E2E-01: Real network-toggling E2E rewrite | Grep test files for `page.evaluate` assigning to application state; CI run shows real IndexedDB write path |
| `setOffline` reconnect timing (Pitfall 2) | E2E-01: Real network-toggling E2E rewrite | Test passes on Ubuntu CI without retries; reconnect assertion polls a UI indicator, not a request race |
| IndexedDB state leakage (Pitfall 3) | E2E-01: Test harness setup | `beforeEach` or new context per test; confirmed by running tests in reverse order with same results |
| Missing compile gate (Pitfall 4) | E2E-01: Workflow hardening | Introduce a deliberate compile error in phoenix_host; confirm CI catches it before Playwright runs |
| Advisory lane masquerading as required (Pitfall 5) | Branch-protection hardening phase | `gh api` shows the E2E job `name:` in required checks; advisory lanes are non-blocking by omission from `checks[]` (not via `continue-on-error`) and carry `advisory-`-prefixed `name:` + `::notice` step |
| Matrix jobs / check-context name drift (Pitfall 6) | Branch-protection hardening phase | Single-browser E2E; no matrix on required job; documented in YAML comment |
| Vacuous pass from empty glob (Pitfall 7) | LEDG-01: Closeout-gate tightening | Verifier emits an error when `phase_paths` returns empty for an expected phase; test with a deliberately missing ledger |
| Hardcoded `@v40_phases` fallback (Pitfall 8) | LEDG-01: Closeout-gate tightening | Verifier raises when `expected_phases` is absent; confirmed by removing the key from a test CLOSEOUT.md |
| Signing VALIDATION.md without evidence (Pitfall 9) | LEDG-01: Closeout-gate tightening | VALIDATION.md schema requires `tested_by:` or `evidence:` field alongside `nyquist_compliant: true` |
| Stale deferrals without resolution criteria (Pitfall 10) | LEDG-01: Closeout-gate tightening | LEDG-01 deferral entry moves to `status: resolved` in prior CLOSEOUT.md files AND new ledger files exist |
| Doc-truth precedence (Pitfall 11) | Doc-truth reconciliation phase | Precedence rule is written and reviewed; v8.0 discrepancy is annotated or resolved |

---

## Sources

- `e2e/offline_sync.spec.ts` (this repo) — direct examination of the fabricated mutation injection pattern at lines 21-50
- `e2e/offline_storage.spec.ts` (this repo) — `addInitScript` storage mock pattern (legitimate for storage boundary tests; distinct from mutation fabrication)
- `examples/phoenix_host/playwright.config.ts` (this repo) — `serviceWorkers: 'block'`, `retries: 2`, `webServer` command chain
- `.github/workflows/phase90-proof.yml` (this repo) — missing compile step, missing job `name:`, no `continue-on-error`, no branch-protection comment
- `.github/workflows/brandbook-verify.yml` (this repo) — correct advisory/required split pattern with `continue-on-error: true` and `::notice`
- `lib/crosswake/planning/closeout_verifier.ex` (this repo) — `@v40_phases` hardcoded fallback at line 28, `phase_paths/4` wildcard glob at lines 563-574, escape hatch in `validation_ledger_check/2`
- `.planning/MILESTONES.md` (this repo) — v6.0 known issues: "hidden by the mocked Playwright closeout"; v8.0-v11.0 carried `tighten-validation-ledger-closeout-gate`
- `.planning/PROJECT.md` Key Decisions (this repo): "Stub a mocked Playwright E2E offline-sync flow for the v6.0 closeout gate — Revisit — mock hid a demo-app compile break"
- `.planning/v1.0-MILESTONE-AUDIT.md` (this repo) — scores v8.0 at 0/10 (phases 99-101 missing VERIFICATION.md); PROJECT.md marks those requirements ✓
- `.planning/milestones/v8.0-ROADMAP.md` (this repo) — "Accepted tech debt: Verification gaps on phase 99, 100, 101 noted in v1.0-MILESTONE-AUDIT.md"
- `.planning/STATE.md` (this repo) — LEDG-01 acknowledged and carried through v11.0 without resolution

---
*Pitfalls research for: CI Honesty / Real-E2E Sweep (v12.0)*
*Researched: 2026-06-17*
