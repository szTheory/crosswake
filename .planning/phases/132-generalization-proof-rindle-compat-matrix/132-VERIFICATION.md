---
phase: 132-generalization-proof-rindle-compat-matrix
verified: 2026-06-26T00:00:00Z
status: passed
closeout: "2026-06-26: human item 1 (compat-doc prose) resolved this session (commit 6b26fd1). Items 2&3 (release-as removal, post-publish clean-room confirmation) were timing-gated, not judgment-gated — transferred to PROOF-03 / Phase 135 as fail-closed CI (staleness guard + auto-cleanup-PR + failure alert; implemented on branch feat/proof-03-release-as-ci-automation, PR #36). No remaining human-judgment gate at the 132 level; goal verified 13/13."
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Read guides/companion_compatibility.md §Engine Dependencies (lines 52-56). The prose states 'rindle is at 0.3.0, and neither satisfies ~> 0.1'. This is factually inconsistent with line 39 of the same doc (~> 0.1 means >= 0.1.0 and < 1.0.0) and with the resolved lock (packages/crosswake_rindle/mix.lock pins rindle 0.3.1, which DOES satisfy ~> 0.1). Decide whether to correct the prose so the engine-pinning guidance matches reality (rindle's 0.3.x line is admitted by ~> 0.1; only rulestead 1.0.0 is outside the cap)."
    expected: "The doc prose accurately describes which live engine releases satisfy the ~> 0.1 cap. rulestead 1.0.0 is correctly outside; rindle 0.3.0/0.3.1 are INSIDE ~> 0.1 (the 132-03 executor relied on exactly this fact to make the rindle companion lane engine-PRESENT)."
    why_human: "Doc prose accuracy / phrasing is a judgment call. It does not affect the drift test (COMPAT-03 keys only on the Requires-crosswake cell, which is correct) or the matrix data (COMPAT-02), so it is not a failed success criterion — but it is a reader-facing inaccuracy a human should rule on."
  - test: "Post-phase runbook (132-04): after the first crosswake_rindle Release PR merges on CI, remove 'release-as': '0.1.0' and the adjacent '_TODO_release_as' field from the packages/crosswake_rindle block in release-please-config.json, then confirm the next release-please run targets the next SemVer rather than re-targeting 0.1.0."
    expected: "release-as removed once the first rindle release is cut; subsequent runs version forward independently of core."
    why_human: "Irreversible CI-only action gated on a future Release PR merge; cannot be verified at phase-close time (no rindle Hex release exists yet by design — the no-publish dress-rehearsal posture)."
    disposition: "CI-automatable, not a human-judgment gate — it is a mechanical post-merge config edit. Tracked by PROOF-03/LIFE-03: a fail-closed release-as staleness guard makes a stale pin RED, and an auto-cleanup-PR strips release-as + _TODO_release_as on release. The only residual human action is merging that one-line PR (main is protected). Recurring-benefit: parametric across all companions (sigra/chimeway/threadline)."
  - test: "After the first crosswake_rindle Release PR merges, confirm clean-room-proof-rindle is green on CI: it installs published crosswake + crosswake_rindle + rindle ~> 0.1 outside the monorepo, compiles --warnings-as-errors, asserts validate_dependency == :ok + doctor exit 0 + the Contracts.media_state_vocabulary/0 canary."
    expected: "clean-room-proof-rindle passes post-publish, proving the published artifact resolves and compiles alongside crosswake."
    why_human: "CI-only, post-publish, irreversible — cannot run locally before the first rindle release is cut (intended no-publish dress-rehearsal posture for this milestone)."
    disposition: "CI-automatable, not a human-judgment gate — the clean-room job already asserts everything (resolvability, --warnings-as-errors compile, doctor exit 0, Contracts canary) and self-reports red/green. Inherently post-publish (can't install an unpublished artifact), so it cannot shift left of publish — but its confirmation becomes 0-touch via an if: failure() alert (PROOF-03/LIFE-03) that opens an issue on red. A human engages only when it actually breaks."
---

# Phase 132: Generalization Proof (rindle) + Compat Matrix Verification Report

**Phase Goal:** The identical extraction recipe runs on `rindle` (including its owned `Contracts.MediaObject` and `Reconciliation`) with no rindle-specific branches added to core; both companions live on Hex with a documented, drift-tested cross-package compatibility matrix.
**Verified:** 2026-06-26
**Status:** passed (closed out 2026-06-26 — see frontmatter `closeout`; item 1 fixed, items 2&3 transferred to PROOF-03/Phase 135)
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is achieved in the codebase. The rindle adapter + owned `Contracts` (incl. `MediaObject`) + `Reconciliation` are extracted into `packages/crosswake_rindle/` with module names preserved; core `lib/` contains exactly one rindle reference (the CompanionGuard MapSet entry — the structural witness, not a branch); the EXTRACT-03 guard and core seam tests are green; the compat matrix doc + bidirectional, drift-detecting, non-vacuous drift test are in place; and the release-please publish pipeline + clean-room lane are fully wired as an independent (non-lockstep) component. The "live on Hex" clause is satisfied by pipeline readiness per the documented no-publish dress-rehearsal posture (PR-context confirmed).

Three items route to human verification — none is a failed success criterion: (1) a reader-facing prose inaccuracy in the compat doc's engine-pinning paragraph, (2) the post-phase `release-as` removal runbook, and (3) the post-publish clean-room CI proof. (2) and (3) are inherently CI-only / future-merge-gated and cannot be closed at phase-close time.

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | rindle mix.exs has env-conditional `crosswake_dep/0` (AST target) + non-vacuity >= 2 packages (132-01) | ✓ VERIFIED | `packages/crosswake_rindle/mix.exs:76-79` resolver `{:crosswake, "~> 0.1"}` / `path: "../.."`; `x-release-please-version` marker line 4; `ls packages/crosswake_*/mix.exs` = 2 |
| 2 | `StubRindleAbsentCompanion` implements full `Crosswake.Companion`, companion_id :rindle (132-01) | ✓ VERIFIED | `test/support/stub_companion.ex:45,60`; `validate_dependency == {:error, [Rindle]}`; core compiles --warnings-as-errors clean |
| 3 | Compat doc shows one row per companion w/ min core version + engine dep + 5 prose sections (COMPAT-02) | ✓ VERIFIED | `guides/companion_compatibility.md` table lines 20-23 (both rows, `~> 0.1`, engine deps); 5 sections (Independent Versioning, Requirement Syntax, Engine Dependencies, Verifying Health, opening) |
| 4 | Drift test fails on missing/mismatched/phantom doc row, bidirectional (COMPAT-03) | ✓ VERIFIED | Behavioral proof: corrupting rindle cell to `~> 9.9` → `version_mismatch` RED (4 tests, 1 failure); revert → 4/0. Stable-id message exact. |
| 5 | Drift test cannot pass vacuously (doc-exists distinct + Path.wildcard >= 2 guard) | ✓ VERIFIED | `phase132_compat_matrix_drift_test.exs` non_vacuity + doc_exists tests; 4 tests 0 failures with 2 real packages |
| 6 | No core `lib/` file statically names `Crosswake.Companions.Rindle`; EXTRACT-03 guard green; registry seam only (SEAM-05) | ✓ VERIFIED | `grep -r` in lib/ → only `companion_guard.ex:40` MapSet entry; `phase130_extraction_guards_test.exs` 12/0 |
| 7 | rindle adapter + Contracts + Reconciliation moved (names preserved); moved tests pass via companions.test (EXTRACT-07) | ✓ VERIFIED | Files at `packages/crosswake_rindle/lib/...`; old core files deleted; rindle lane `mix test` 55/0 (7 excluded) |
| 8 | Core seam tests exercise rindle via StubRindleAbsentCompanion via registry, never alias moved adapter; green in core | ✓ VERIFIED | phase47:7 `alias StubRindleAbsentCompanion, as: Rindle`; companions_test substitutes stub at 150/229, drops moved-adapter `function_exported?`; 13/0 |
| 9 | `CROSSWAKE_RELEASE=1 verify_companion_package.sh crosswake_rindle` passes (line-53 parameterized) | ✓ VERIFIED | Ran live: tarball test/ absent, lib/ present, crosswake dep in metadata, compile --warnings-as-errors clean → "crosswake_rindle OK" |
| 10 | release-please carries crosswake_rindle as separate component, NOT in linked-versions, own manifest baseline (EXTRACT-07 independent versioning) | ✓ VERIFIED | `release-please-config.json` component crosswake_rindle/elixir; plugins linked-versions = [hex, ios-core, android-core] (no rindle); manifest baseline 0.1.0 |
| 11 | Gated publish-hex-rindle: deps.get → compile --warnings-as-errors → test → dry-run → publish, CROSSWAKE_RELEASE=1 | ✓ VERIFIED | `release-please.yml:238` job; `CROSSWAKE_RELEASE: "1"`; steps incl. `hex.publish --dry-run` then `hex.publish`; Hex poll; gated on `rindle_release_created` |
| 12 | clean-room-proof-rindle installs published crosswake + crosswake_rindle + rindle ~> 0.1, compiles, asserts seam + Contracts canary | ✓ VERIFIED (wiring) | `release-please.yml:757` needs [release-please, publish-hex-rindle]; delegates `verify_companion_cleanroom.sh crosswake_rindle <ver> rindle Rindle`; canary `media_state_vocabulary` in script. CI-run is post-publish (human item 3). |
| 13 | "Live on Hex" satisfied by pipeline readiness (no-publish dress-rehearsal posture) | ✓ VERIFIED | Per PR context: pipeline wired + ready; release cuts on first rindle Release PR merge. Package shape, no-core-branches, compat matrix, drift test all verified above. |

**Score:** 13/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `packages/crosswake_rindle/lib/crosswake/companions/rindle.ex` | moved adapter, names preserved, no_warn_undefined | ✓ VERIFIED | module preserved; `@compile {:no_warn_undefined, Rindle}`; runtime-only `Code.ensure_loaded?` probes |
| `packages/crosswake_rindle/lib/crosswake/companions/rindle/contracts.ex` | Contracts incl. MediaObject | ✓ VERIFIED | `MediaObject` defmodule line 87; `media_state_vocabulary/0` line 124 (canary) |
| `packages/crosswake_rindle/lib/crosswake/companions/rindle/reconciliation.ex` | Reconciliation | ✓ VERIFIED | present, 6790 bytes, aliases .Contracts |
| `packages/crosswake_rindle/mix.exs` | crosswake_dep resolver + version marker | ✓ VERIFIED | resolver lines 76-79; marker line 4 |
| `test/support/stub_companion.ex` | StubRindleAbsentCompanion | ✓ VERIFIED | line 45 |
| `guides/companion_compatibility.md` | matrix doc | ✓ VERIFIED | full table + 5 sections + pinned HTML contract |
| `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | drift test | ✓ VERIFIED | 4 tests, AST-parse, bidirectional, drift-detecting |
| `lib/crosswake/companion_guard.ex` | MapSet gains Rindle | ✓ VERIFIED | line 40, prefix-match covers children |
| `.github/workflows/phase132-proof.yml` | 3-job companion lane | ✓ VERIFIED | core-hermetic / engine-absent / engine-present; YAML valid |
| `release-please-config.json` + manifest | independent component | ✓ VERIFIED | separate elixir component, not lockstep, baseline 0.1.0 |
| `.github/workflows/release-please.yml` | publish + clean-room jobs | ✓ VERIFIED | aliases + 2 gated jobs; YAML valid |
| `script/verify_companion_package.sh` | parameterized from $PACKAGE | ✓ VERIFIED | `COMPANION_NAME` derivation line 55; ran green for rindle |
| `script/verify_companion_cleanroom.sh` | rindle Contracts canary | ✓ VERIFIED | PACKAGE-guarded canary line 221+; bash -n clean |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `companion_guard.ex` MapSet | moved rindle source deletion | same-PR rule | ✓ WIRED | commit d278491 adds MapSet entry + deletes source together; guard green |
| `mix.exs` companions.test | crosswake_rindle lane | alias chain | ✓ WIRED | chains rindle lane; `mix test` in package 55/0 |
| moved phase45/72 tests | copied media helpers | Code.require_file `__DIR__`-relative | ✓ WIRED | 5 helpers in test/support/example_host/; lane passes |
| release-please outputs | publish/clean-room jobs | rindle_release_created alias | ✓ WIRED | dot-notation aliases gate both jobs |
| publish-hex-rindle | clean-room-proof-rindle | needs: | ✓ WIRED | clean-room needs [release-please, publish-hex-rindle] |
| `crosswake_dep/0` literal | doc Requires-crosswake cell | drift test AST extract | ✓ WIRED | `~> 0.1` verbatim match; drift detection proven RED/GREEN |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| COMPAT-03 drift test green | `mix test phase132_compat_matrix_drift_test.exs` | 4 tests, 0 failures | ✓ PASS |
| COMPAT-03 detects drift | corrupt rindle cell → `~> 9.9` | version_mismatch RED, 1 failure | ✓ PASS |
| EXTRACT-03 guard green | `mix test phase130_extraction_guards_test.exs` | 12 tests, 0 failures | ✓ PASS |
| Core seam tests green | `mix test companions_test.exs phase47_companion_arc_test.exs` | 13 tests, 0 failures | ✓ PASS |
| rindle companion lane | `mix test` (in package) | 55 tests, 0 failures (7 excluded) | ✓ PASS |
| verify_companion_package rindle | `CROSSWAKE_RELEASE=1 verify_companion_package.sh crosswake_rindle` | OK (test/ excluded, lib/ present, compile clean) | ✓ PASS |
| core compiles clean | `MIX_ENV=test mix compile --warnings-as-errors` | exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| EXTRACT-07 | 132-01, 132-03, 132-04 | rindle extracted by identical recipe (Contracts incl. MediaObject + Reconciliation), goes live on Hex, independently versioned | ✓ SATISFIED | source moved (truth 7), independent release-please component (truth 10), pipeline wired (truths 11-13) |
| SEAM-05 | 132-03 | same checklist, no companion-specific branch in core | ✓ SATISFIED | only core edit is CompanionGuard MapSet (truth 6); EXTRACT-03 guard green |
| COMPAT-02 | 132-02 | adopter reads matrix doc for min core version + matrix | ✓ SATISFIED | truth 3 |
| COMPAT-03 | 132-02 | drift test fails on missing/inconsistent requirement | ✓ SATISFIED | truths 4-5; drift detection behaviorally proven |

All 4 requirement IDs declared in PLAN frontmatter are present in REQUIREMENTS.md (lines 19, 29, 34, 35) and accounted for. No orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `release-please-config.json` | 77 | `_TODO_release_as` field | ℹ️ Info | Intentional, documented post-phase runbook (recipe Step 12f / Pitfall 6); references formal follow-up; tracked in 132-04 post-phase runbook. Not unreferenced debt. |
| `guides/companion_compatibility.md` | 53-54 | prose factual inaccuracy ("rindle 0.3.0 ... neither satisfies ~> 0.1") | ⚠️ Warning | Contradicts line 39 of same doc + lock (rindle 0.3.1 IS in ~> 0.1). Does NOT affect drift test or matrix data. Routed to human verification. |

No TBD/FIXME/XXX debt markers in any phase-modified file.

### Deferred / Pre-Existing (out of scope — not phase-132 gaps)

Two test failures noted in `deferred-items.md` were confirmed pre-existing (failing at base commit 8cf3ad0) and unrelated to rindle:

| # | Item | Verdict |
| - | ---- | ------- |
| 1 | `milestone_transition_reset_test.exs:35` (REQUIREMENTS.md milestone header) | Not phase-132-modified; REQUIREMENTS.md header actually now names v16.0; pre-existing planning-doc assertion |
| 2 | `phase52_operator_truth_test.exs:101` (publish-readiness fixture drift) | Not phase-132-modified; fixture has no rindle reference; pre-existing fixture drift |

### Human Verification Required

See frontmatter `human_verification`. Summary: (1) compat-doc engine-pinning prose accuracy (judgment, reader-facing); (2) post-phase `release-as` removal runbook (post-merge, irreversible); (3) clean-room-proof-rindle CI proof (post-publish, cannot run locally). Items 2-3 are inherent to the no-publish dress-rehearsal posture and cannot be closed at phase-close.

### Gaps Summary

No gaps block goal achievement. Every success criterion and must-have is verified in the codebase with behavioral evidence (drift detection proven RED/GREEN, guard + seam + companion lanes run green, verify script ran live). The phase was initially `human_needed` for three items; **closed out 2026-06-26 to `passed`**: item 1 (doc-prose accuracy) was fixed this session (commit 6b26fd1); items 2&3 were timing-gated CI-only actions (not judgment calls) and are transferred to **PROOF-03 / Phase 135** as fail-closed automation (staleness guard + auto-cleanup-PR + failure alert; PR #36). None was a code defect.

---

_Verified: 2026-06-26_
_Verifier: Claude (gsd-verifier)_
