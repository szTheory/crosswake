# Phase 166 — UI Review

**Audited:** 2026-09-09
**Baseline:** Abstract 6-pillar standards (no Phase 166 UI-SPEC.md)
**Screenshots:** Not captured (no HTTP 200 dev server on ports 3000, 5173, or 8080; port 8080 returned 301)
**Scope:** Contributor-facing verification/doctor output, repository-mode browser proof, and the offline-study behavior changed by Phase 166. Brand/showcase polish and Android feature work are explicitly out of scope.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Verification output is bounded and actionable, but an adjacent offline compatibility message exposes a JavaScript exception name instead of learner-facing recovery copy. |
| 2. Visuals | 4/4 | Scope pass: Phase 166 changed no markup, imagery, hierarchy, or icon treatment; no visual defect is attributable to this infrastructure phase. |
| 3. Color | 4/4 | Scope pass: no Phase 166 color-token or style change exists. |
| 4. Typography | 4/4 | Scope pass: no Phase 166 typography change exists. |
| 5. Spacing | 4/4 | Scope pass: no Phase 166 spacing or layout change exists. |
| 6. Experience Design | 2/4 | Repository proof is deterministic and offline replay races are reduced, but initialization failure is visually indistinguishable from a safe paused state and repository-mode browser failures cannot retain a first-failure trace. |

**Overall: 21/24**

The 4/4 scores for Visuals, Color, Typography, and Spacing are scope passes, not claims that the pre-existing example UI exceeds a new design contract. Phase 166 introduced no changes in those dimensions.

---

## Top 3 Priority Fixes

1. **Render offline initialization failure as an explicit unavailable/error state** — a learner can currently see the normal “Saved answers paused” presentation even though study activation will reject with `CW-OFFLINE-INITIALIZATION` — add a privacy-safe `initialization_failed` presentation with recovery guidance and cover it in Playwright.
2. **Retain a trace for repository-mode browser failures** — repository verification sets retries to zero while the shared trace policy is `on-first-retry`, so the exact clean-checkout lane cannot produce a trace for its only failed attempt — use `trace: repositoryVerify ? 'retain-on-failure' : 'on-first-retry'` while keeping artifacts invocation-owned.
3. **Remove exception jargon from the visible compatibility status** — `QuotaExceededError handled gracefully.` describes implementation rather than the user outcome — reuse the plain-language storage recovery copy and keep the exception class only in private test assertions or structured diagnostics.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** `examples/phoenix_host/priv/static/offline_study.js:677` writes `QuotaExceededError handled gracefully.` into `#status`. If that compatibility node is exposed, the wording is technical, congratulates the implementation, and gives the learner no action. The adjacent message at lines 668-675 already has the useful recovery instruction; the compatibility status should use the same plain-language outcome.
- **Pass:** `script/verify_repository.mjs:165-170` emits one deterministic line per purpose, uses the closed `PASS`/`FAIL`/`BLOCKED` vocabulary, and gives exactly one corrective command for non-pass results. Purpose IDs are appropriate for a maintainer-facing terminal surface and child logs remain private.
- **Pass:** learner-facing replay copy at `examples/phoenix_host/priv/static/offline_study.js:21-26` avoids scope references, mutation IDs, replay jargon, and raw answers. “Saved on this iPhone,” “Syncing saved answers,” and “Some saved answers need review” communicate outcomes rather than internals.

### Pillar 2: Visuals (4/4)

- **Scope pass, not applicable:** the Phase 166 frontend-like diff is limited to `offline_study.js`, two Playwright specs, and `playwright.config.ts`; it adds no DOM, icon, imagery, or hierarchy changes. No visual regression can be attributed to this phase.
- Screenshots were unavailable because ports 3000 and 5173 did not respond and port 8080 returned a redirect rather than a page suitable for the configured capture gate. This score therefore does not certify the pre-existing rendered example host.

### Pillar 3: Color (4/4)

- **Scope pass, not applicable:** Phase 166 adds no CSS, Tailwind class, color literal, or design-token change. Existing inline styling in the offline example predates this phase and is not counted as a Phase 166 defect.

### Pillar 4: Typography (4/4)

- **Scope pass, not applicable:** Phase 166 changes no font family, size, weight, line height, or typographic hierarchy. Terminal output remains plain text by design and does not depend on color or font styling to convey status.

### Pillar 5: Spacing (4/4)

- **Scope pass, not applicable:** Phase 166 changes no padding, margin, gap, width, breakpoint, or layout rule. Repository output is line-oriented and bounded to one record per purpose.

### Pillar 6: Experience Design (2/4)

- **WARNING:** `examples/phoenix_host/priv/static/offline_study.js:150-188` resolves the new initialization barrier to `false` after any startup exception, but the catch path renders the ordinary `sync_paused` state and writes “Sync is paused.” A subsequent host activation fails with `CW-OFFLINE-INITIALIZATION` at lines 63-69. This is fail-closed technically but not visibly explicit: a learner cannot distinguish safely paused saved work from a study surface that never initialized. Add a distinct non-sensitive unavailable state, disable answer controls, and provide a retry/reload instruction.
- **WARNING:** `examples/phoenix_host/playwright.config.ts:27` forces zero retries in repository mode while line 46 keeps `trace: 'on-first-retry'`. With no retry, a browser failure in the canonical lane has no trace, weakening the contributor recovery experience. Retain a trace on failure inside the already invocation-owned results root.
- **Pass:** `examples/phoenix_host/priv/static/offline_study.js:78-83` now checks for queued mutations before replay, avoiding an empty replay transition and unnecessary “Syncing” announcement.
- **Pass:** the changed rejected-replay test at `examples/phoenix_host/e2e/offline_sync.spec.ts:781-817` waits until the offline mutation is durably queued before reconnecting, so the visible “needs review” state proves the intended retained-work behavior rather than a race.
- **Pass:** status rendering at `examples/phoenix_host/priv/static/offline_study.js:424-461` preserves focus, uses an existing polite atomic status region, hides the activity indicator outside active sync, validates the recovery destination, and announces only changed states. Tests cover focus preservation, redaction, retained rejected work, fenced/disabled work, and one announcement per state.
- **Pass:** contributor proof at `script/verify_repository.mjs:165-170` preserves independent-stage results and explicit blocked states; repository mode at `examples/phoenix_host/playwright.config.ts:5-34,76` requires absolute invocation-owned artifact paths, starts a fresh server, and avoids retry-masked first-attempt behavior.

---

## Registry Safety

Not applicable: `components.json` is absent, so shadcn and third-party registry checks do not apply.

## Files Audited

- `AGENTS.md` and all eight governing project/workstream files it requires
- `166-CONTEXT.md`
- `166-01-PLAN.md` through `166-08-PLAN.md`
- `166-01-SUMMARY.md` through `166-08-SUMMARY.md`
- `examples/phoenix_host/priv/static/offline_study.js`
- `examples/phoenix_host/e2e/offline_storage.spec.ts`
- `examples/phoenix_host/e2e/offline_sync.spec.ts`
- `examples/phoenix_host/playwright.config.ts`
- `script/verify_repository.sh`
- `script/verify_repository.mjs`
- `script/repository_verification_stages.json`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/formatter.ex`
- `lib/crosswake/doctor/finding_policy.ex`
- `lib/mix/tasks/crosswake.doctor.ex`
- `lib/mix/tasks/crosswake.install.ex`
- Phase 166 repository/browser/offline/doctor/install regression tests identified by the plan summaries and phase diff

