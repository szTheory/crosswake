---
phase: 135-ci-ops-hardening-release-as-automation-proof-03
verified: 2026-06-28T19:08:46Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 135: CI-Ops Hardening — Release-As Automation (PROOF-03) Verification Report

**Phase Goal:** The two post-publish companion-release follow-ups (one-shot `release-as` removal and clean-room-proof confirmation) are CI-enforced with no recurring human step, parametric across every `crosswake_*` companion; the only intentional human gate is merging the Release PR (the irreversible `hex.publish` go/no-go).

**Verified:** 2026-06-28T19:08:46Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: check_release_as_staleness.sh exits 1 (RED) against a stale pin and exits 0 (GREEN) after removal — demonstrated RED→GREEN in one hermetic test via GIT_DIR temp-repo injection | VERIFIED | Test "SC1: staleness guard turns RED on a stale pin and GREEN after removal" passes. Script uses bare `git rev-parse` at line 59 (no `--git-dir`), so `GIT_DIR` env injection correctly redirects tag lookup to the temp repo. Confirmed exit 1 + "STALE" on stale pin; exit 0 on green config. |
| 2 | SC2: strip_release_as.py strips release-as + _TODO_release_as on run 1 and is a no-op on run 2 (idempotent), proven against a fixture where release-as is NOT the last key | VERIFIED | Test "SC2: strip_release_as.py strips both keys then is a no-op" passes. Fixture has `extra-files` after `release-as` (avoids trailing-comma JSONDecodeError). Run 1: exit 0, output contains "stripped", both keys absent from parsed result, `component` and `extra-files` keys survive (minimal-diff). Run 2: exit 0, output contains "no change". |
| 3 | SC2 wiring: release-as-cleanup job structurally wired in .github/workflows/release-please.yml (invokes strip_release_as.py for each crosswake_* component) | VERIFIED | Test "SC2: release-as-cleanup job is wired in release-please.yml" passes. File contains `release-as-cleanup` at line 795, `strip_release_as.py crosswake_rulestead` at line 820, `strip_release_as.py crosswake_rindle` at line 823. |
| 4 | SC3: release-failure-alert job exists with `if: ${{ failure() }}` and needs the four companion publish + clean-room-proof jobs; anti-pattern `if: always()` is absent | VERIFIED | Test "SC3: release-failure-alert is wired with if: failure() over the four companion jobs" passes. Job at line 842; `if: ${{ failure() }}` at line 853; all four needs (publish-hex-rulestead, publish-hex-rindle, clean-room-proof-rulestead, clean-room-proof-rindle) at lines 849–852. `if: always()` is absent from the entire workflow file (grep returned 0 matches). |
| 5 | SC4: script/extract_companion.md Step 12f references the CI automation (PROOF-03, CI-automated, release-as-cleanup, merge-blocking-release-as-staleness) so future companions inherit 0-human release ops | VERIFIED | Test "SC4: extract_companion.md Step 12f references the CI automation (PROOF-03)" passes. Step 12f present at line 360; contains "PROOF-03", "CI-automated", "release-as-cleanup", "merge-blocking-release-as-staleness". |
| 6 | SC5: register_required_checks.sh is dry-run-default, parametric (list_merge_blocking_checks.py), idempotent (unique_by(.context)); check_required_checks_registered.sh is fail-closed (exit 1 GAP, exit 3 UNVERIFIED); merge-blocking-release-as-staleness appears in live discovery output (no 20-lane hardcode) | VERIFIED | Test "SC5: registration tooling is dry-run-default, parametric, idempotent and detector is fail-closed" passes. DRY_RUN="${DRY_RUN:-1}" at line 37 of register script; `list_merge_blocking_checks.py` invoked at line 40; `unique_by(.context)` at line 94. Detector has `list_merge_blocking_checks.py` at line 27, `exit 1` at line 51, `exit 3` at line 37. Live run of `python3 script/list_merge_blocking_checks.py` exits 0 and emits `merge-blocking-release-as-staleness` (20 lanes total, none hardcoded in the test). |
| 7 | Both previously-deferred core-hermetic tests (milestone_transition_reset, phase52_operator_truth) are confirmed GREEN by the proof test via nested mix test calls | VERIFIED | Tests "deferred core-hermetic failures are now green: milestone_transition_reset" and "deferred core-hermetic failures are now green: phase52_operator_truth" both pass. Each runs `mix test <file> --seed 0` via System.cmd and asserts exit 0. |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

### Deferred Items

None. All ROADMAP Success Criteria (SC1–SC5 plus deferred-failures self-assertion) are met in this phase.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/crosswake/proof/phase135_ci_ops_proof_test.exs` | Hermetic ExUnit proof lane, 9 tests | VERIFIED | File exists, 628 lines, module `Crosswake.Proof.Phase135CiOpsProofTest`, `async: true`, no `@moduletag`, 9 tests, all green |
| `script/check_release_as_staleness.sh` | SC1 staleness guard script | VERIFIED | Exists, uses bare `git rev-parse` (GIT_DIR-compatible), prints STALE/exit 1 on stale, OK/exit 0 on clean |
| `script/strip_release_as.py` | SC2 idempotent strip script | VERIFIED | Exists; behavior confirmed via SC2 test |
| `.github/workflows/release-please.yml` | Contains release-as-cleanup + release-failure-alert jobs | VERIFIED | release-as-cleanup at line 795; release-failure-alert at line 842 |
| `script/extract_companion.md` | Step 12f with PROOF-03 references | VERIFIED | Step 12f at line 360, all anchors present |
| `script/register_required_checks.sh` | Dry-run-default, parametric, idempotent registrar | VERIFIED | DRY_RUN default, list_merge_blocking_checks.py, unique_by(.context) all confirmed |
| `script/check_required_checks_registered.sh` | Fail-closed detector (exit 1/exit 3) | VERIFIED | list_merge_blocking_checks.py, exit 1, exit 3 all confirmed |
| `script/list_merge_blocking_checks.py` | Live discovery, emits merge-blocking-release-as-staleness | VERIFIED | Exits 0, emits 20 lanes including merge-blocking-release-as-staleness |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| SC1 test | `script/check_release_as_staleness.sh` | `System.cmd("bash", [...], env: [{"GIT_DIR", git_dir} | rest])` + bare `git rev-parse` in script (line 59) | VERIFIED | GIT_DIR injection confirmed: script has no `--git-dir` flag, inherits env; test builds env via `System.get_env() |> Map.put("GIT_DIR", git_dir) |> Map.to_list()` preserving PATH |
| SC2 test | `script/strip_release_as.py` | `System.cmd("python3", ["script/strip_release_as.py", component, config_path])` + `Jason.decode!` result | VERIFIED | Run 1 strips; run 2 is no-op; parsed result confirms key removal |
| SC2-wiring test | `.github/workflows/release-please.yml` | `File.read!` + `String.contains?` on job name + invocation strings | VERIFIED | All three strings present at inspected lines |
| SC3 test | `.github/workflows/release-please.yml` | `File.read!` + positive `String.contains?` for failure() and four needs + `refute String.contains?` for always() | VERIFIED | `if: ${{ failure() }}` at line 853; `if: always()` absent (0 grep hits) |
| SC4 test | `script/extract_companion.md` | `File.read!` + `String.contains?` for five anchors | VERIFIED | All five anchors confirmed |
| SC5 test | `script/register_required_checks.sh`, `script/check_required_checks_registered.sh`, `script/list_merge_blocking_checks.py` | `File.read!` for structural asserts + `System.cmd("python3", ...)` for live discovery | VERIFIED | All structural anchors present; live discovery exits 0 with correct output |
| Deferred tests | `test/crosswake/planning/milestone_transition_reset_test.exs`, `test/crosswake/proof/phase52_operator_truth_test.exs` | `System.cmd("mix", ["test", file, "--seed", "0"])` → assert exit 0 | VERIFIED | Both nested mix test calls exit 0 |

---

## Data-Flow Trace (Level 4)

Not applicable. This phase produces an ExUnit proof test (pure assertion/structural analysis), not a component that renders dynamic data. No data-flow trace required.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Proof test lane fully green (9 tests) | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs --seed 0` | 9 tests, 0 failures (1.8s) | PASS |
| Full hermetic suite remains green | `mix test` | 1182 tests, 0 failures, 10 excluded (17.0s) | PASS |
| Real release-please-config.json untouched | `git status --porcelain release-please-config.json` | (empty output) | PASS |
| Only test file + planning docs added (no production code changed) | `git diff 3dc440b..HEAD --stat` | 2 files: 135-01-SUMMARY.md + test/crosswake/proof/phase135_ci_ops_proof_test.exs | PASS |
| Live SC5 discovery script exits 0 with staleness lane | `python3 script/list_merge_blocking_checks.py` | exit 0, 20 lanes, `merge-blocking-release-as-staleness` present | PASS |

---

## Probe Execution

No phase-declared probes. The phase's verification contract specified direct `mix test` commands, executed above.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PROOF-03 | 135-01-PLAN.md | Two post-publish companion-release follow-ups CI-enforced (staleness guard, auto-cleanup PR, failure alert, recipe Step 12f, parametric registration) — no recurring human step | SATISFIED | All 5 SCs verified by proof test lane (9/9 tests green); REQUIREMENTS.md shows PROOF-03 marked `[x]` complete |

---

## Prohibitions Verified

| Prohibition | Status | Evidence |
|-------------|--------|---------|
| SC3: alert job must use `if: ${{ failure() }}`, NOT `if: always()` | VERIFIED — not violated | `if: always()` absent from entire workflow (0 grep hits); `if: ${{ failure() }}` confirmed at line 853 |
| SC1: test must NOT reference real repo tags — only synthetic tag in temp repo | VERIFIED — not violated | Test creates temp git repo via `System.tmp_dir!() + System.unique_integer([:positive])`, tags `crosswake_rulestead-v0.1.0` only in that temp repo; GIT_DIR isolation prevents cross-contamination |
| SC2: test must NOT mutate real release-please-config.json | VERIFIED — not violated | `git status --porcelain release-please-config.json` returns empty; test writes only to temp config at `Path.join(tmp_dir, "release-please-config.json")` |
| SC5: test must NOT hardcode all 20 merge-blocking lane names | VERIFIED — not violated | SC5 test asserts only `exit 0` + `String.contains?(output, "merge-blocking-release-as-staleness")`; no 20-lane list in test source |

---

## Anti-Patterns Found

None.

Scan of `test/crosswake/proof/phase135_ci_ops_proof_test.exs` (the only file modified by this phase):
- No TBD/FIXME/XXX markers
- No placeholder/coming-soon/not-yet-implemented comments
- No `return null` / empty-return stubs (this is Elixir, not applicable)
- No hardcoded empty data that flows to rendering
- The `async: true` flag is intentional and documented: each test owns unique `System.unique_integer([:positive])` temp paths, no shared state

---

## Human Verification Required

None. All must-haves were verifiable programmatically:

- SC1 RED→GREEN was demonstrated by running the actual script against a temp git repo fixture (not a structural read)
- Deferred-failure green was demonstrated by nested `mix test` calls asserting exit 0 (not structural reads)
- All structural assertions (SC2 wiring, SC3, SC4, SC5) use `File.read!` + `String.contains?`/`refute` on the landed artifacts
- SC5 live discovery was confirmed by running `python3 script/list_merge_blocking_checks.py` directly

No visual, user-flow, or external-service verification items arise from this phase.

---

## Deferred / Out-of-Scope (Not Gaps)

These items are intentionally deferred and do not affect the phase verdict:

1. **v16.0 → origin sync:** Local `main` is ~100 commits ahead of `origin/main`. Planned for one catch-up PR at milestone boundary.
2. **`DRY_RUN=0` admin required-check registration:** `register_required_checks.sh` defaults to `DRY_RUN=1`. Actual branch-protection mutation requires admin `gh` auth scope — the legitimate human gate (D-03). Not recurring toil.
3. **Live-fire of real cleanup PR + alert issue (D-03):** `release-as-cleanup` fires automatically on the next companion release. `release-failure-alert` opens only on actual publish failure. SC5 closes on tooling correctness (dry-run-default, parametric, idempotent, fail-closed, live discovery output) without requiring a real companion release.

---

## Audit-Then-Prove Verdict

D-01 (audit-then-prove) confirmed: all five PROOF-03 production artifacts pre-existed on local `main` (landed 2026-06-26). Every SC audited GREEN; **no production code was changed** by this phase. The deliverable is the proof test, which is now merge-blocking via the hermetic untagged ExUnit lane.

---

_Verified: 2026-06-28T19:08:46Z_
_Verifier: Claude (gsd-verifier)_
