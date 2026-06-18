---
phase: 114-merge-blocking-ci-gate-permanent-honesty-guard
plan: "02"
subsystem: testing
tags: [guard, ast, typescript, playwright, e2e, honesty-check, fabrication-prevention]

requires:
  - phase: 113-honest-e2e-rewrite
    provides: honest offline_sync.spec.ts with IndexedDB-outbox real path (no injection)

provides:
  - script/check-e2e-honesty.mjs: AST-based structural honesty guard (GUARD-01)
  - typescript pinned as explicit devDependency in examples/phoenix_host/package.json
  - CI guard-01-e2e-honesty job runs npm ci to install typescript before the check

affects:
  - 114-03-PLAN.md (GUARD-02 prod-route-absence)
  - 114-04-PLAN.md (GATE-01 branch-protection registration)
  - 114-05-PLAN.md (closeout / registration runbook)

tech-stack:
  added: [typescript@^5.9.3 (explicit devDependency pin)]
  patterns:
    - "AST-based guard via TypeScript compiler API (createRequire from sub-package node_modules)"
    - "createRequire(path.join(REPO_ROOT, 'examples/phoenix_host/package.json')) resolves typescript without a root-level package.json"
    - "guard-01 CI job: npm ci --prefix examples/phoenix_host before running Node ESM script"

key-files:
  created:
    - script/check-e2e-honesty.mjs
  modified:
    - examples/phoenix_host/package.json
    - examples/phoenix_host/package-lock.json
    - .github/workflows/offline-sync-e2e-gate.yml

key-decisions:
  - "Resolved typescript via createRequire from examples/phoenix_host rather than a root-level package.json — keeps the guard zero-new-dependency at the repo root while reusing the sub-package install"
  - "Added npm ci --prefix examples/phoenix_host step to guard-01 CI job (not in plan) — necessary because typescript is not globally available in ubuntu-latest runners and does not install transitively from @playwright/test in v1.60.0"
  - "OBSERVATION_ONLY comment NOT used as a gate condition — shapes banned by AST structure unconditionally (D-05 satisfied)"

patterns-established:
  - "fetch-in-evaluate scan: descends only into page.evaluate first argument, so IndexedDB reads and window.dispatchEvent in the same callback are never flagged"
  - "anti-rename/delete: exit 1 if spec path absent — file existence is checked before AST parse"

requirements-completed: [GUARD-01]

duration: 5min
completed: 2026-06-18
status: complete
---

# Phase 114 Plan 02: AST Honesty Guard Summary

**GUARD-01 structural honesty check shipped: TypeScript compiler API script bans three fabrication shapes unconditionally in offline_sync.spec.ts, exits 1 on missing spec, and typescript is pinned as explicit devDependency**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-18T06:38:00Z
- **Completed:** 2026-06-18T06:42:51Z
- **Tasks:** 2 completed
- **Files modified:** 4

## Accomplishments

- `script/check-e2e-honesty.mjs`: Node ESM script using `ts.createSourceFile` (AST, not regex) bans inject-global, fetch-in-evaluate, and minted-uuid fabrication shapes unconditionally — no bypassable `// OBSERVATION_ONLY` allowlist (D-05 satisfied)
- Exits 1 if `examples/phoenix_host/e2e/offline_sync.spec.ts` is absent (anti-rename/delete evasion)
- All legitimate observation constructs pass: IndexedDB reads and `window.dispatchEvent(new Event('online'))` inside `page.evaluate`, `page.request.post` outside `page.evaluate`
- `typescript@^5.9.3` pinned explicitly in `examples/phoenix_host/package.json` devDependencies (T-114-06 mitigation)
- CI `guard-01-e2e-honesty` job updated to run `npm ci --prefix examples/phoenix_host` before the honesty check

## Task Commits

1. **Task 1: Author the AST honesty check script** — `17ae00d` (feat)
2. **Task 2: Pin typescript in the demo-app devDependencies** — `fda0494` (chore)

## Files Created/Modified

- `script/check-e2e-honesty.mjs` — GUARD-01: AST-based honesty check, 3 banned fabrication rules, missing-file detection, clear WHY messages referencing REQUIREMENTS.md GUARD-01 and phase 112-113 rewrite
- `examples/phoenix_host/package.json` — typescript@^5.9.3 added to devDependencies
- `examples/phoenix_host/package-lock.json` — lockfile updated with explicit typescript dep
- `.github/workflows/offline-sync-e2e-gate.yml` — guard-01 job: added npm ci step before honesty check

## Decisions Made

1. **Resolved typescript via `createRequire`** — The script uses `createRequire(path.join(REPO_ROOT, 'examples/phoenix_host/package.json'))` to resolve the `typescript` module from the sub-package's `node_modules`. This avoids creating a root-level `package.json` while cleanly using the pinned typescript dep.

2. **Added `npm ci --prefix examples/phoenix_host` to guard-01 CI job** — This was not in the plan, but necessary: `typescript` is not globally available on `ubuntu-latest` runners and does not install transitively from `@playwright/test` v1.60.0 (the transitive dep was dropped in a Playwright major). Without this step, the CI job would fail with `ERR_MODULE_NOT_FOUND`. The `~2s` timing estimate in the research synthesis assumed the transitive dep was present — the actual job will take ~10s with the install step. This is a Rule 3 auto-fix (blocking issue).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `npm ci` step to guard-01 CI job**
- **Found during:** Task 1 (honesty check script)
- **Issue:** `typescript` is not globally available in the CI runner environment and does not install transitively from `@playwright/test` v1.60.0. Running `node script/check-e2e-honesty.mjs` without any install step failed with `ERR_MODULE_NOT_FOUND: Cannot find package 'typescript'`.
- **Fix:** Added `run: npm ci --prefix examples/phoenix_host` step to the `guard-01-e2e-honesty` job in `offline-sync-e2e-gate.yml` before the honesty check step.
- **Files modified:** `.github/workflows/offline-sync-e2e-gate.yml`
- **Verification:** Script runs locally after `npm ci` in examples/phoenix_host; all acceptance criteria pass (exit 0 on honest spec, exit 1 on all three fabrication shapes and missing-file case)
- **Committed in:** `17ae00d` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The auto-fix is necessary for the CI job to function. The guard-01 job now takes ~10s instead of the ~2s estimate due to the install step, but correctness is preserved.

## Issues Encountered

None beyond the Rule 3 auto-fix documented above.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. The script is a read-only file scanner. The typescript devDependency pin is a first-party toolchain dep already present transitively (T-114-SC noted as ASSUMED-legit in plan threat model).

## Known Stubs

None — the honesty check script is fully functional and wired to the real spec path.

## Next Phase Readiness

- GUARD-01 structural check is complete and verified locally
- Ready for Plan 114-03 (GUARD-02: prod-route-absence check) and Plan 114-04 (GATE-01 CI workflow aggregator)
- The guard-01 CI job requires the workflow change in `offline-sync-e2e-gate.yml` to go green on `main` before branch-protection registration (Plan 114-04/05)

## Self-Check

- [x] `script/check-e2e-honesty.mjs` exists
- [x] `examples/phoenix_host/package.json` contains `"typescript"`
- [x] Task 1 commit `17ae00d` exists
- [x] Task 2 commit `fda0494` exists
- [x] Honesty check exits 0 on current honest spec
- [x] Honesty check exits 1 on inject-global, fetch-in-evaluate, minted-uuid, and missing-file cases

## Self-Check: PASSED

---
*Phase: 114-merge-blocking-ci-gate-permanent-honesty-guard*
*Completed: 2026-06-18*
