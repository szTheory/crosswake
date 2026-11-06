---
phase: 198-android-foreign-host-proof
verified: 2026-11-06T03:00:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - ".github/workflows/crosswake-ci.yml"
  - "guides/parity_ledger.md"
  - "lib/crosswake/parity_ledger.ex"
  - "packages/crosswake-shell-core-android/build.gradle.kts"
  - "script/android_foreign_promotion.sh"
  - "script/check_kotlin_test_floor.py"
  - "script/verify_android_foreign_host.sh"
covered_digest: "v4:sha256:4f84373ed2e423f7166338bd6c77a2de6ef539716c382a2e9c12d0a63abd6c15"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 198: Android foreign-host proof Verification Report

**Phase Goal:** A cross-platform team can see which existing contracts Android honors, generated from the same vectors as iOS, and a generated Android shell built in a foreign Gradle project resolves the published Maven artifact and passes JVM tests.
**Verified:** 2026-11-06 (branch `feat/198-android-foreign-host-proof`, local HEAD 44fac9e0, PR 270 head 9b96b483)
**Status:** passed
**Re-verification:** No, initial verification

Plain-language summary: I re-ran the cheap local checks myself and read the code and CI record instead of relying on the SUMMARY files. Every success criterion holds at JVM-hermetic and Gradle-on-Linux evidence, which is the ceiling AGENTS.md allows. Nothing changed in the repo other than this file. The one open bookkeeping item is that REQUIREMENTS.md AND-03 is still unticked. Three scope items for the user are listed at the end.

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Parity ledger with Android column is generated from the bridge corpus and `priv/contract_vectors/*.json` (regeneration gives no diff); a test asserts Swift and Kotlin share the vector-set hash and fails on mismatch (D-01 amendment applied) | VERIFIED | `guides/parity_ledger.md` exists with an "Android evidence" column and a per-vector table. `mix crosswake.docs.sync --check` passed (rc 0, no diff). The three bridge corpus copies hash identically (3b64c8d8...e0064c0), and that hash appears in the generated Kotlin `VectorSet.SHA256` constant. `test/crosswake/parity_ledger_test.exs` has the equality test plus controls for Swift/Kotlin constant mismatch, constant vs corpus, missing file, zero or two anchored matches, empty corpus and one mutated byte. `mix test` over `parity_ledger_test`, `android_evidence_test` and `test/crosswake/guides`: 283 tests, 0 failures (5 excluded). The ROADMAP SC1 carries the dated D-01 amendment and REQUIREMENTS AND-01 carries the same wording. |
| 2 | Kotlin core JVM tests at least 25 including `BridgeChannel` boundary cases; `androidx.webkit` absent if no source imports it; JSON-stack choice recorded in writing | VERIFIED | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 python3 script/check_kotlin_test_floor.py --run` printed `kotlin-floor: tests=39 source_tests=39 boundary=20 floor=25 verdict=PASS` (fresh Gradle run, XML equals source count). `BridgeChannelBoundaryTest.kt` holds 20 `@Test`. `androidx.webkit:webkit:1.10.0` is still in `build.gradle.kts` and is imported by `BridgeChannel.kt` (`androidx.webkit.WebViewCompat`), so the condition "absent if no source imports it" is correctly not triggered (198-DECISIONS D-02). JSON stack recorded in `198-DECISIONS.md` ("JSON stack (D-09)"): production keeps platform `org.json`; tests use `com.vaadin.external.google:android-json`, confirmed at `build.gradle.kts` line 51 with rejected options recorded. |
| 3 | Fresh foreign Gradle project from `mix crosswake.gen.shell android` output resolves the published Maven coordinate and passes JVM tests on Linux CI as an advisory leg (required only after two clean runs); wrong-coordinate negative control fails | VERIFIED (see caveat) | `script/verify_android_foreign_host.sh` (528 lines) resolves the highest version present on both Hex and Maven Central, runs the published generator into a fresh host with clean HOME and GRADLE_USER_HOME, runs `:app:testDebugUnitTest` with `--refresh-dependencies`, then runs a `-negctl` control that must fail with both `Could not find ...-negctl:V` and `Could not resolve all files ...`. Hermetic selftest `verify_android_foreign_host_test.py` ran 21 tests, OK. CI job `android-foreign-host` exists (workflow line 911), is in `ADVISORY_JOBS` in `check_ci_leaf_manifest.py`, and `phase165_ci_integrity_test.exs` refutes it from leaf, control, compatibility and umbrella lists (it is not required). `gh run view 42144969164` (PR head 9b96b483): job `android-foreign-host` and its "Run published foreign-host proof" step concluded success on ubuntu-latest. Recorded evidence from run 42138656194: version 0.2.11, 2 tests, `control_reason` `could_not_find`, result PASS, both D-18 control lines matched on Gradle 8.7. "Required only after two clean runs" is implemented as a derived, never hand-stamped count (`script/android_foreign_promotion.sh`; selftest `android_foreign_promotion_test.py` 13 tests OK) and promotion is correctly not attempted (D-20 needs a reviewed promotion PR). |
| 4 | No Android claim in the support matrix or capability map exceeds JVM-hermetic evidence | VERIFIED | `test/crosswake/guides/android_claim_ceiling_test.exs` exists and passed in the 283-test run. `guides/capability_map.md` has the typed "Android evidence" column; `guides/parity_ledger.md` reports "JVM hermetic proof" for the shared corpus and "not claimed" for the other corpora. A grep for `Android ... (emulator|device)-(verified|tested|proven|support)` over the three guides matches only the negated non-claim bullet at `guides/support_matrix.md:290` ("that posture is not device-verified"). The ledger states the evidence is CI on the repository head, not a published artifact and not hardware. |

**Score:** 4/4 truths verified (0 present, behavior-unverified).

### Caveat on truth 3 (not a gap)

The foreign-host proof exercises the published Hex generator and the published Maven artifact (0.2.11), not the generator or AAR at this branch's head. This is a documented design choice (the script header, the CI step summary and the evidence field `generator: published` all say so), and it matches the roadmap wording "resolves the published Maven coordinate". It does not prove that this branch's unreleased generator output builds; that remains covered by the existing `android-generated-shell-unit` job. The phrase "on the Linux CI head commit" is met in the way CI always works here: the job ran on the synthetic merge commit (0747b23f for the final run, 232f9d20 for the first green run) and the evidence records the PR head SHA. Both are stated in the evidence and not blurred.

Minor observation: the recorded promotion line `clean_runs=2/2` counts the foreign-host job from run 42137231568 (a workflow run later cancelled after two unrelated docs checks failed, head 50e4d09c) and run 42138656194 (head 01408a04). The counting rule is documented, and a third clean run now exists (42144969164, head 9b96b483), so the real count is at least 3 distinct heads. Not a defect.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `script/verify_android_foreign_host.sh` | VERIFIED | Substantive, wired to CI step and selftest, real control logic |
| `script/android_foreign_promotion.sh` | VERIFIED | Derived counting rules, UNVERIFIED reasons, selftested |
| `script/check_kotlin_test_floor.py` (+ `_test.py`) | VERIFIED | Run live, floor 25, 13 selftests OK |
| `lib/crosswake/parity_ledger.ex`, `guides/parity_ledger.md` | VERIFIED | Declared as a docs.sync output; `--check` clean |
| Generated Kotlin and Swift vector-set constants | VERIFIED | Kotlin constant equals corpus hash; the ledger tests assert the Swift constant too (Swift suite run by executor: 91 tests, 0 failures, recorded in `suite-198.txt`; I did not rerun Swift) |
| `.github/workflows/crosswake-ci.yml` `android-foreign-host` job | VERIFIED | Present, advisory, not in umbrella needs |
| `198-DECISIONS.md`, `198-EVIDENCE/` | VERIFIED | Exist and agree with what I re-measured (floor, selftests) |

### Key Links

| From | To | Status |
|------|----|--------|
| CI `android-foreign-host` | `script/verify_android_foreign_host.sh` | WIRED |
| `script/check_ci_leaf_manifest.py` ADVISORY_JOBS | workflow job | WIRED (self-test passes) |
| `check_kotlin_test_floor.py --run` | `android-package-unit` | WIRED per SUMMARY 03; CI job success in run 42144969164 |
| `mix crosswake.docs.sync` | `guides/parity_ledger.md` | WIRED (`--check` passes; tamper control exists) |
| `bearings-report` | `android_foreign_promotion.sh` | claimed by Plan 10; `bearings_report_test` is in the green full suite |

### Behavioral Spot-Checks and Re-run Gates

| Check | Result | Status |
|-------|--------|--------|
| `JAVA_HOME=/opt/homebrew/opt/openjdk@17 python3 script/check_kotlin_test_floor.py --run` | tests=39 source=39 boundary=20 PASS | PASS |
| `mix crosswake.docs.sync --check` | passed, rc 0 | PASS |
| `python3 script/check_kotlin_test_floor_test.py` | 13 tests OK | PASS |
| `python3 script/verify_android_foreign_host_test.py` | 21 tests OK | PASS |
| `python3 script/android_foreign_promotion_test.py` | 13 tests OK | PASS |
| `python3 script/check_ci_leaf_manifest.py --self-test` | 8 tests OK, "pass" | PASS |
| `node --test test/js/repository_verification.test.mjs` | pass 41, fail 0 | PASS |
| `mix test` parity_ledger, android_evidence, guides | 283 tests, 0 failures | PASS |
| `gh pr view 270` | head 9b96b483, 39 of 39 checks SUCCESS, MERGEABLE, state OPEN | PASS |

Not run by me: the networked `script/verify_android_foreign_host.sh` and `script/android_foreign_promotion.sh` (evidence is the CI artifact and the green CI job), the full core `mix test` suite (executor recorded 3102 run, 0 failures on a05eaa54; CI is green on the PR head), `swift test`, and the privacy scan (executor recorded four clean scans in `privacy-198.txt`; the last one covers HEAD e824659e, and later commits are docs-only). A first, accidental broader `mix test` invocation of mine was killed before completing and changed no files.

### CI on the PR head

Run 42144969164, event `pull_request`, workflow head_sha 9b96b483 (equals `gh pr view 270` headRefOid). All 39 checks succeeded, including `android-foreign-host`, `android-package-unit`, `android-generated-shell-unit`, `phase67-android-jvm-proof`, `e2e-proof` and the `Crosswake CI` umbrella. Per AGENTS.md, CI ran on GitHub's synthetic merge commit 0747b23f (parents origin/main 8d9ac9ac and the head), which is not the head itself. Local HEAD 44fac9e0 is one unpushed docs-only commit ahead (SUMMARY 12, STATE, ROADMAP); the diff 9b96b483..HEAD touches only those three planning files.

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| AND-01 | SATISFIED | Truth 1 and 4; REQUIREMENTS checkbox ticked |
| AND-02 | SATISFIED | Truth 2; REQUIREMENTS checkbox ticked |
| AND-03 | SATISFIED in evidence, NOT YET TICKED | Truth 3. Its text (published coordinate, foreign Gradle project, JVM tests on Linux CI, advisory leg, required only after two clean runs, wrong-coordinate control fails) is met by the recorded runs and the script's control. REQUIREMENTS.md line 63 still reads `- [ ] **AND-03**` and the traceability row (line 117) says `Pending`. STATE.md deliberately left the tick to verification. Tick both when you accept this report; I did not edit REQUIREMENTS.md because the task limited me to writing this file. |

No orphaned requirements: only AND-01..03 map to Phase 198.

### Anti-Patterns

TBD, FIXME and XXX scan over files changed versus origin/main under script, lib, test, packages, .github and guides: no hits. No stubs found in the verified artifacts. No debt-marker blockers.

### Deferred and Debt Items (informational, none block)

- `198-DECISIONS.md` debt rows (a) to (e) are recorded with owner, trigger and receiver (server-command skips in `BridgeChannel`, dead `androidx.webkit` line in the generated template, example-host `org.json` alignment, superseded Phase 196 `tests: 12` pin, SemVer iOS/Android divergence). Receivers are the v29 Android/bridge phase or the next phase touching those files; Phase 199 does not cover them.
- `deferred-items.md` is partly stale: it calls `phase52_operator_truth` pre-existing, which `suite-198.txt` shows was wrong (Plan 07 caused it, fixed in 14942e8f). The Phase 175 partial-run artifact is harmless.

### Items for the user (reported, not changed)

1. **Out-of-scope CI edit, commit 196456d1.** It edits the required `e2e-proof` job's Playwright install step in `.github/workflows/crosswake-ci.yml` (200 second bound per attempt, up to three attempts, 12 minute step limit). The cause was an apt mirror stall that cancelled `e2e-proof` on PR 268 (Phase 197) and on this PR's head 8e841edd. The diff matches that description: only that one step changed. It is a judgment call outside Phase 198's scope, and it is justified by the CI rule "fix forward tied to the observed cause". Decide whether to keep it in PR 270 or split it out.
2. **Four Phase 197 closeout commits carried on the branch** (equivalents 67241beb UAT, 0932e36c phase completion, 6580fd94 validation strategy, f8500948 security verification). They will land on main with PR 270 unless split into a separate docs PR (which needs its own one-use `allow`). 198-DECISIONS.md "Open items for the user" already describes this and the conflict-resolution rule.
3. **Branch and prefix.** Per 198-DECISIONS I-3, plan 01 ran on `test/198-android-foreign-host-proof` and the work later sits on `feat/198-android-foreign-host-proof` (the current branch, PR 270 title `feat(198): ...`). Release-please reads the `feat` prefix, so confirm that is the intended version-bump signal.
4. **AND-03 tick** in REQUIREMENTS.md (line 63 and traceability line 117) as noted above.
5. **Merge** of PR 270 needs a fresh one-use `allow` for the head at that time; I did not request or perform it. Re-read the delete-branch-on-merge setting first (memory notes it was turned off 2026-10-28).

### Human Verification Required

None. Every claim is machine-checked or recorded CI evidence, per the zero-human verification default. Device or emulator behavior is explicitly not claimed, so nothing is deferred to a human.

### Gaps Summary

No gaps. All four success criteria are met within the Android claim ceiling (JVM and Gradle evidence only). The residual items above are bookkeeping and scope decisions for the user.

---

_Verified: 2026-11-06_
_Verifier: Claude (gsd-verifier)_
