---
phase: "198"
slug: "android-foreign-host-proof"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-05"
---

# Phase 198 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `198-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir), JUnit 4.13.2 via Gradle (Kotlin), XCTest (Swift), Python `unittest` (scripts) |
| **Config file** | `packages/crosswake-shell-core-android/build.gradle.kts`; `Package.swift`; none for Python |
| **Quick run command** | `mix test test/crosswake/parity_ledger_test.exs test/crosswake/guides/android_claim_ceiling_test.exs` (Elixir); `cd packages/crosswake-shell-core-android && JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew --no-daemon cleanTestDebugUnitTest testDebugUnitTest` (Kotlin, ~20 s) |
| **Full suite command** | `mix test` plus `swift test` in `packages/crosswake-shell-core-ios` plus the Gradle command above |
| **Estimated runtime** | ~20 s quick (Kotlin), full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the area touched (Kotlin, Elixir or scripts)
- **After every plan wave:** All three quick runs plus `mix crosswake.docs.sync --check`
- **Before `/gsd-verify-work`:** Full `mix test`, `swift test`, Gradle run, floor checker, and a measured advisory-job run (`script/ci_cost_report.sh`) must be green
- **Max feedback latency:** 60 seconds for task-level checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 198-01-T1 | 01 | 1 | AND-02 | T-198-01, T-198-04 | branch from origin/main with only Phase 198 commits; JSON-stack swap; envelope rejects non-string required fields | unit (JVM) + git | Gradle forced run + XML count >= 14; `git merge-base --is-ancestor origin/main HEAD` and no Phase 197 closeout commit on the branch | ❌ W0 | ⬜ pending |
| 198-01-T2 | 01 | 1 | AND-02 | T-198-02, T-198-03 | parseBody/listenerAllows extracted; SemVer digit-only | unit (JVM) | Gradle forced run + XML count >= 21 | ❌ W0 | ⬜ pending |
| 198-01-T3 | 01 | 1 | AND-02 | — | JSON-stack choice, SemVer iOS divergence, D-13 override, Phase 197 open item and debt rows in writing | artifact | heading and content greps on 198-DECISIONS.md | ❌ W0 | ⬜ pending |
| 198-02-T1 | 02 | 2 | AND-02 | T-198-05, T-198-07 | compatibility, route, origin, deny-shape boundaries | unit (JVM) | Gradle forced run + XML count >= 26 | ❌ W0 | ⬜ pending |
| 198-02-T2 | 02 | 2 | AND-02 | T-198-06, T-198-08 | command, capability, pack, side-effect, precedence | unit (JVM) | Gradle forced run + XML count >= 32 | ❌ W0 | ⬜ pending |
| 198-02-T3 | 02 | 2 | AND-02 | T-198-09 | transfer, files.pick, permissions, command parity, D-14 characterization | unit (JVM) | Gradle forced run + XML count >= 37 | ❌ W0 | ⬜ pending |
| 198-03-T1 | 03 | 3 | AND-02 | T-198-10 | Kotlin tests >= 25, 0 failed/skipped, derived equality, boundary >= 10, named tests | script | `python3 script/check_kotlin_test_floor.py --run` | ❌ W0 | ⬜ pending |
| 198-03-T2 | 03 | 3 | AND-02 | T-198-10, T-198-11 | every floor-checker reason (all 11, gradle_failed via fake gradlew) red on its own fixture | script | `python3 script/check_kotlin_test_floor_test.py` (Ran >= 13) + per-reason grep | ❌ W0 | ⬜ pending |
| 198-03-T3 | 03 | 3 | AND-02 | T-198-12 | floor runs in merge-blocking android-package-unit | structural | `python3 script/check_ci_leaf_manifest.py --self-test` + phase165/134 gate | ✅ extend | ⬜ pending |
| 198-04-T1 | 04 | 4 | AND-01 | T-198-13, T-198-14 | Kotlin constant equals raw-bytes sha256; flipped byte fails | unit | `mix crosswake.contract.gen` no-op + Gradle + floor checker | ❌ W0 | ⬜ pending |
| 198-04-T2 | 04 | 4 | AND-01 | T-198-13 | every Kotlin corpus load verified | unit (JVM) | reader scan + `check_kotlin_test_floor.py --run` | ✅ extend | ⬜ pending |
| 198-04-T3 | 04 | 4 | AND-01 | T-198-15 | LF pins; Kotlin constant declared output | structural | `git check-attr` + policy sort check + phase166 gate + node suite | ✅ extend | ⬜ pending |
| 198-05-T1 | 05 | 5 | AND-01 | T-198-16, T-198-17 | Swift constant equals Kotlin constant and corpus hash; mismatch fails | unit | generator + `swift test` (>= 91 executed) | ❌ W0 | ⬜ pending |
| 198-05-T2 | 05 | 5 | AND-01 | T-198-16 | all five Swift loaders verified | unit | reader scan + `swift test` | ✅ extend | ⬜ pending |
| 198-05-T3 | 05 | 5 | AND-01 | T-198-16 | Swift constant declared; one-time byte flip turns both suites red | structural + one-time evidence | policy check + phase166 gate; SUMMARY byte-flip section | ✅ extend | ⬜ pending |
| 198-06-T1 | 06 | 6 | AND-01 (SC4) | T-198-18, T-198-20 | typed Android ceiling; Android evidence column; no level above ceiling | unit | `mix crosswake.docs.sync --check` + `mix run` API assertions + capability/support gate | ✅ extend | ⬜ pending |
| 198-06-T2 | 06 | 6 | AND-01 (SC4) | T-198-19 | single-sourced boundary sentence; hand-written native_shell.md copy exempted and pinned | unit | documentation-contracts gate + lib literal-count check + guides copy check | ✅ extend | ⬜ pending |
| 198-06-T3 | 06 | 6 | AND-01 (SC4) | T-198-18 | API raise controls, typed vs rendered count, native_shell.md pin | unit | `mix test test/crosswake/support_matrix/android_evidence_test.exs` (>= 9); directory gate >= 110 | ❌ W0 | ⬜ pending |
| 198-07-T1 | 07 | 7 | AND-01 | T-198-21, T-198-22 | ledger generated through docs.sync; hash equal on all sides | integration | `mix crosswake.docs.sync --check` + ledger/docs.sync/hex_page gate (>= 20) | ❌ W0 | ⬜ pending |
| 198-07-T2 | 07 | 7 | AND-01 | T-198-21, T-198-23, T-198-24 | registry two-sided; every D-06 control red | unit | `mix test test/crosswake/parity_ledger_test.exs` (>= 20) | ❌ W0 | ⬜ pending |
| 198-07-T3 | 07 | 7 | AND-01 | T-198-22 | ledger declared output; tampered ledger fails --check | integration | phase166 + docs.sync gate (>= 22) + node suite | ✅ extend | ⬜ pending |
| 198-08-T1 | 08 | 8 | AND-01 (SC4) | T-198-25 | no Android column cell above `JVM hermetic proof`; floor; controls | unit | `mix test test/crosswake/guides/android_claim_ceiling_test.exs` (>= 8) | ❌ W0 | ⬜ pending |
| 198-08-T2 | 08 | 8 | AND-01 (SC4) | T-198-26 | measured prose backstop over capability map and ledger | unit | documentation-contracts gate (>= 256) | ✅ extend | ⬜ pending |
| 198-08-T3 | 08 | 8 | AND-01 | T-198-27 | ledger qualifier mandatory; roadmap/requirements amended | unit + artifact | documentation-contracts + hex_page gate; ROADMAP awk checks | ✅ extend | ⬜ pending |
| 198-09-T1 | 09 | 9 | AND-03 | T-198-28..32 | real foreign-host run PASS; control fails `could_not_find` | networked script | `bash script/verify_android_foreign_host.sh --evidence ...` | ❌ W0 | ⬜ pending |
| 198-09-T2 | 09 | 9 | AND-03 | T-198-28..31 | every foreign-host reason (all 15) red hermetically | script | `python3 script/verify_android_foreign_host_test.py` (Ran >= 21) + per-reason grep | ❌ W0 | ⬜ pending |
| 198-10-T1 | 10 | 10 | AND-03 | T-198-33 | derived clean-run line from CI history | script | `bash script/android_foreign_promotion.sh` | ❌ W0 | ⬜ pending |
| 198-10-T2 | 10 | 10 | AND-03 | T-198-33..35 | every counting rule and all six UNVERIFIED paths | script | `python3 script/android_foreign_promotion_test.py` (Ran >= 13) + per-reason grep | ❌ W0 | ⬜ pending |
| 198-10-T3 | 10 | 10 | AND-03 | T-198-33 | bearings report android_foreign line with UNVERIFIED control | unit | `mix test test/crosswake/bearings_report_test.exs` (>= 74) | ✅ extend | ⬜ pending |
| 198-11-T1 | 11 | 11 | AND-03 | T-198-37..39 | advisory job wired, outside required authority | structural | `python3 script/check_ci_leaf_manifest.py --self-test` + job-shape check | ✅ extend | ⬜ pending |
| 198-11-T2 | 11 | 11 | AND-03 | T-198-38 | advisory controls for the new job; sibling integrity test | structural | manifest self-test + phase165/134 gate (>= 48) | ✅ extend | ⬜ pending |
| 198-12-T1 | 12 | 12 | AND-01..03 | T-198-41, T-198-42 | full local gates, privacy clean, PR open | full suite | `script/mix_test_gate.sh --min 3102 --min-total 3178` + swift + floor + selftests | ✅ | ⬜ pending |
| 198-12-T2 | 12 | 12 | AND-03 | T-198-43 | first CI run recorded with exactly one foreign-host outcome (A success with control wording, or B external-outage advisory failure, which keeps AND-03 open); derived promotion line | CI evidence | ci-198.txt outcome greps | ❌ W0 | ⬜ pending |
| 198-12-T3 | 12 | 12 | AND-01..03 | — | validation signed off; STATE handoff (old one in history); ROADMAP 198 row; one final push; CI green on final pushed head | artifact + CI | frontmatter, STATE, ROADMAP greps + final privacy rc + `gh pr view` statusCheckRollup on the pushed head | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Task IDs are filled in once plans exist.*

---

## Wave 0 Requirements

- [ ] `test/crosswake/parity_ledger_test.exs` — AND-01
- [ ] `test/crosswake/guides/android_claim_ceiling_test.exs` — SC4
- [ ] `script/check_kotlin_test_floor_test.py` and `script/verify_android_foreign_host_test.py` — AND-02, AND-03
- [ ] `BridgeChannelBoundaryTest.kt`, `SemVerBoundaryTest.kt`, `BridgeFixtures.kt`, `VectorCorpus.kt`, `VectorCorpus.swift` — AND-01, AND-02

Every new check records a non-empty floor and the mutation that turns it red (BEARINGS tripwire).

---

## Manual-Only Verifications

All phase behaviors have automated verification. The one-time native-loader mutation check (flip one byte per resource copy) is agent-run phase evidence, not CI.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
