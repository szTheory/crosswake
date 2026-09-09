---
phase: 165-efficient-and-maintainable-ci
plan: 12
subsystem: ci
tags: [github-actions, branch-protection, required-checks, compatibility-retirement]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 11
    provides: Explicit approval bound to the exact verified retirement digest
provides:
  - Strict main protection requiring exactly Crosswake CI
  - Compatibility-free PR proof graph retaining forty-four literal proof leaves
  - Exact target-context producer discovery and fail-closed manifest validation
affects: [165-13, branch-protection, release-readiness]
tech-stack:
  added: []
  patterns:
    - Apply one-way authority retirement before deleting migration-only producers
    - Resolve registered authority from the exact target policy rather than display-name substrings
key-files:
  created: []
  modified:
    - .github/workflows/crosswake-ci.yml
    - script/ci_leaf_manifest.json
    - script/check_ci_leaf_manifest.py
    - script/list_merge_blocking_checks.py
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - test/crosswake/proof/phase165_ci_policy_test.exs
    - .github/workflows/release-please.yml
    - .github/workflows/required-checks-audit.yml
key-decisions:
  - "Apply only the approved source-protection digest and immediately require strict target authority containing exactly Crosswake CI."
  - "Keep all forty-four meaningful proof leaves and classify-change while removing every migration-only compatibility conclusion."
actuals:
  tokens: 8309
  tasks: 2
  commits: 4
duration: 18 min
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 12: Authority Retirement and Compatibility Cleanup Summary

**Strict main protection now requires only `Crosswake CI`; all migration-only compatibility conclusions are gone while the forty-four literal proof leaves remain intact.**

## Performance

- **Duration:** 18 min
- **Completed:** 2026-09-09T00:23:30Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Revalidated the exact approved dual-state digest, applied the authorized twenty-seven-context retirement, and immediately proved `strict: true` with exactly `Crosswake CI` required.
- Removed all twenty-seven `compat-*` workflow jobs and all legacy compatibility manifest rows without changing the forty-four proof leaves, `classify-change`, or the umbrella's literal static needs.
- Tightened producer discovery so repository audits select the exact policy target context rather than relying on the historical `merge-blocking` substring convention.
- Preserved the separate release, publish/recovery, scheduled, manual, and advisory workflow boundaries.

## Task Commits

1. **Task 2 RED: require a compatibility-free graph** — `cf06f85e`
2. **Task 2 GREEN: remove compatibility producers and seal exact target discovery** — `29847548`
3. **Rule 3: clear repository-wide actionlint blockers** — `a52e1dbd`
4. **Rule 3 verification: align release trust proof with valid concurrency syntax** — `1c4f129d`

Task 1 changed external branch-protection state only; its exact mutation and immediate target-state audit both passed before Task 2 began.

## Verification Evidence

- Pre-apply live audit: strict dual authority exact; every required context had one producer.
- Apply: exact approved retirement succeeded and exact post-write authority was verified.
- Post-apply live audit: `strict: true`; required contexts exactly `["Crosswake CI"]`; unique target producer.
- Representative live observations remain successful: documentation-only run `34281122602` and full-proof run `34281351379` both recorded a successful umbrella result.
- Manifest checker self-tests: 6 passed.
- Focused manifest/trigger/release-trust ExUnit: 14 passed, 0 failed.
- Repository-wide actionlint: passed for all workflow files.
- Final target live audit: passed with 92 literal local producers and one exact required target producer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Removed two pre-existing repository-wide actionlint blockers**
- **Found during:** Task 2 verification
- **Issue:** `release-please.yml` contained unsupported `concurrency.queue`, and `required-checks-audit.yml` triggered SC2016 for intentional Markdown backticks.
- **Fix:** Removed the invalid no-op queue key and added a narrowly scoped shellcheck directive documenting the intentional literal Markdown.
- **Files modified:** `.github/workflows/release-please.yml`, `.github/workflows/required-checks-audit.yml`
- **Commit:** `a52e1dbd`

**2. [Rule 3 - Blocking issue] Updated the release trust assertion after removing invalid workflow syntax**
- **Found during:** Task 2 verification
- **Issue:** The Phase 165 release-trust test required the unsupported `queue: max` key even though GitHub Actions does not accept it.
- **Fix:** Kept the non-cancelling concurrency assertion and explicitly rejected unsupported queue keys.
- **Files modified:** `test/crosswake/proof/phase165_ci_integrity_test.exs`
- **Commit:** `1c4f129d`

## Issues Encountered

- The repository's pinned Erlang/Elixir versions are not installed locally. Verification used the already-installed compatible `ASDF_ERLANG_VERSION=28.4.1` and `ASDF_ELIXIR_VERSION=1.19.5-otp-28` toolchain without changing the user-owned `.tool-versions` modification.
- The broader Phase 165 aggregate reaches its expected pre-Plan-13 source-binding stop because local compatibility-free workflow bytes have not landed on the remote default branch yet. Plan 13 owns that exact-SHA landing verification; all Plan 12 commands passed.

## Known Stubs

None.

## Threat Flags

None. T-165-08 passed the digest-bound exact-set apply and immediate strict target re-read. T-165-04 passed exact proof/control/needs parity after compatibility deletion.

## Next Phase Readiness

Plan 165-13 can begin after the orchestrator lands these commits and supplies the exact remote-default SHA containing the compatibility-free workflow and manifest.

## Self-Check: PASSED

- All eight modified plan/deviation files exist.
- Commits `cf06f85e`, `29847548`, `a52e1dbd`, and `1c4f129d` exist.
- Live strict target protection and every Plan 12 verification command pass.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
