---
phase: 195-pipeline-repair-and-hygiene
plan: 04
subsystem: infra
tags: [ci, secret-masking, github-actions, node-test]
requires:
  - phase: 195-03
    provides: PR queue drained, main at 7bd8daf
provides:
  - "maskSecretShapes exported from script/verify_repository.mjs, used once by rootProofFailureTail"
  - "test/js/ci_secret_masking.test.mjs: spawned-child tail test, derived-secret static guard, dynamic runner-mask emulation"
  - "::add-mask:: for Maven TOKEN and AUTH in maven-publish-fire-drill.yml"
affects: [195-05, 195-09]
requirements-completed: [REL-03]
actuals:
  tokens: 45000
  tasks: 2
  commits: 5
  plan_head_before: 7bd8daf09fe44ae7d5804aa9a7f6f6ff1e1396a4
  plan_head_after: d8c32f1000926e42ffa263fa43fe35ca35398424
completed: 2026-10-25
status: complete
---

# Phase 195 Plan 04: Secret masking Summary

**Root-proof failure tail now masks Bearer, secret-access-key, cookie and short values via one exported `maskSecretShapes`, the Maven fire-drill derived TOKEN/AUTH are masked before use, and both protections go red when removed.**

Branch `ci/recurring-lanes-and-secret-masking` (local only, not pushed).

## Commits

- 578f8dc5 docs(195): record PR1 landing and queue evidence (carried files plus STATE/REQUIREMENTS progress)
- 2bec01b2 ci: mask bearer, secret-access-key, cookie and short secret values in the root-proof failure tail
- 4bc332c7 ci: record mask-removed control for root-proof tail masking
- cfff9e37 ci: mask secret-derived values before any echo in workflows
- d8c32f10 ci: record derived-secret mask-removed control

## Evidence

- Task 1 RED: `node --test test/js/ci_secret_masking.test.mjs` rc 1 (no `maskSecretShapes` export). GREEN: 4 pass.
- Tail control (mask skipped in rootProofFailureTail): rc 1, `leaked` message present, restored clean.
- Task 2 RED: live-tree guard reported 2 findings on origin/main (Maven TOKEN, AUTH) and the dynamic derivation leaked 2 values. GREEN after two add-mask lines: 11 pass, 0 fail.
- Derived control (add-mask lines deleted from the workflow): rc 1, `leaked` present, restored clean.
- Full suite `node --test test/js/*.mjs`: rc 0, 148 pass, 0 fail.
- Order check in the workflow: TOKEN assignment line 153, mask 154, next use 155 (the AUTH assignment, which is itself masked on line 156).
- Privacy scan on all changed sources and evidence: rc 0 (5 files clean).
- `git diff origin/main --stat -- .github/workflows`: only maven-publish-fire-drill.yml (+2).
- Guard classification lines are in `195-EVIDENCE/mask-control-195.txt`: both guards are delta-only and merge-blocking, findings on origin/main 2, on branch 0.

## Deviations from Plan

**1. [Rule 3 - Blocking] Local `@playwright/test` missing** - 3 pre-existing playwright_repository_mode tests failed with module-not-found before my change. Ran `npm ci --prefix examples/phoenix_host` (the same lockfile step Crosswake CI runs before the JS suite; node_modules is gitignored). Suite then passed.

**2. [Design choice] Transitivity capped at one level** - The plan's one-level rule, applied literally to the live tree, would also flag DEPLOYMENT_ID, STATUS_JSON and STATE (derived through the authenticated curl calls). Those are not secrets, and masking STATE would corrupt log text. The guard treats depth-1 (from a secret-bound key) and depth-2 (from a depth-1 value, e.g. AUTH from TOKEN) as derived; depth-2 values are not sources. Measured main findings are therefore the 2 the plan expected.

**3. [Layout] Extra evidence commits** - Control evidence was committed as separate `ci:` commits after each code commit, because the plan requires committing code before running the controls.

## Notes

- Crosswake CI does not run on push to main (pull_request only), so there is no push-event CI result for 7bd8daf. Recorded as fact; the pull_request run on #238's head was green (plan 03).
- Audit: other secret-bound keys (HEX_API_KEY, REL17_POLICY_READ_TOKEN, MIRROR_DEPLOY_KEY, Maven signing keys, and so on) are passed through unchanged and are auto-masked by Actions. Only TOKEN and AUTH were derived.
- Flagged assumption stands: the guard is line-based, so a multi-line or heredoc derivation would escape it; the non-empty floor (at least 1 live assignment) keeps it from passing silently if parsing breaks.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Files exist: script/verify_repository.mjs, test/js/ci_secret_masking.test.mjs, 195-EVIDENCE/mask-control-195.txt, secret-derivation-audit-195.txt. Commits 578f8dc5, 2bec01b2, 4bc332c7, cfff9e37, d8c32f10 are ancestors of HEAD.
