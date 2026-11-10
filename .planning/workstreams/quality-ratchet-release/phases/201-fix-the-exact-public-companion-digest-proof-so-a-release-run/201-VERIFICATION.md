---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
verified: 2026-11-09T23:59:00Z
status: passed
score: 8/8 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-07-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-08-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-RESEARCH.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-REVIEW-DISPOSITION.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-REVIEW.md
  - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-VALIDATION.md
covered_digest: "v4:sha256:1b72d4953164270962473ddf823d840bd1355a27f1bcaa563d0f08565694d7a4"
behavior_unverified: 0
overrides_applied: 0
advisory:
  - finding: "record-ledger job in exact-public-proof.yml reports success while discarding its ledger line when a ledger PR is already open (TODO-013); the 0.2.14 line reached main by script in PR 289"
    category: other
    reason: "Separate job from the digest proof, untouched by this phase; not part of the phase goal. Tracked in TODO-013. A later release with an open ledger PR would lose its line the same way until fixed."
    evidence_status: "reproduced live in run 42713010358; workflow text at origin/main line 342 still has the skip path"
coincidental_reliance_items: []
---

# Phase 201: Fix the exact-public companion digest proof so a release run can complete - Verification Report

**Phase Goal:** A release run can reach COMPLETE: the exact-public artifact proof stops failing every published companion with `digest_mismatch`, without loosening what it proves about the core or about a companion's contents.
**Verified:** 2026-11-09T23:59:00Z
**Status:** passed
**Re-verification:** No - initial verification

Code pin: the implementation (`lib/crosswake/release_candidate/artifact.ex`, `test/crosswake/release_candidate/artifact_real_tarball_test.exs`, `test/fixtures/hex_tarballs/`) was verified at origin/main commit af1dd94e (merge of PR 289; the fix is PR 287). The main checkout is on the docs branch and cannot hold those files, so they are pinned by that commit id instead of by `covered_digest`, which covers this phase's planning files only.

Method: the implementation lives on origin/main (PR 287, main head af1dd94e), not in the checked-out docs branch. I read the code with `git show origin/main:<path>`, ran the tests in a scratch worktree at af1dd94e (removed afterwards), re-read the live GitHub release run, and checked Hex. SUMMARY claims were not used as evidence.

## Goal Achievement

### Observable Truths

The ROADMAP entry for Phase 201 has a Goal and a Scope list but no numbered Success Criteria, so the truths below are derived from the Goal, the four Scope items and the PLAN must_haves (Option C plus 2b).

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The exact-public proof no longer fails companions with `digest_mismatch`: a real public companion tarball and its Hex 2.6+ rebuild give equal metadata and payload digests | VERIFIED | `lib/crosswake/release_candidate/artifact.ex` at origin/main has `@build_env_excluded_packages` (five companions) and `drop_build_env/2` applied before `normalize_term`. Ran `mix test test/crosswake/release_candidate/artifact_real_tarball_test.exs` at af1dd94e: 22 tests, 0 failures, including "equality: public tarball and Hex 2.6+ rebuild of the same tag give equal digests". Fixtures are real tarballs (`test/fixtures/hex_tarballs/`, `SHA256SUMS`), not invented. |
| 2 | The core's proof is not loosened: `crosswake` keeps `build_env` in its digest, so a changed or removed core `build_env` still changes its metadata digest | VERIFIED | `drop_build_env(metadata, _package)` returns the metadata unchanged for any package not in the literal list. Tests "core build_env: changing it ... changes the core metadata digest only" and "removing it changes the core metadata digest" pass. Live run log: `artifact-provenance: package=crosswake version=0.2.14 build_env_hex=2.7.0 build_env_digested=yes`. Measurement M3 (`201-EVIDENCE/measure-201.json`): flipping the core's `build_env` gives 5/6 metadata equal, verdict DIFFER on `crosswake` only. |
| 3 | A companion's contents are not loosened: description, requirement, link and payload-byte changes still change the digest; unknown metadata keys still raise; `build_env` shape is validated fail-closed for every package before any exclusion | VERIFIED | `build_env!/1` (nil, or exactly `[{"hex", semver}]`, else `invalid!()`) runs before `drop_build_env/2`; `@metadata_keys` and `@required_metadata_keys` unchanged in the fix commits. Passing tests: five "shape:" tests, "control description/requirement/links/payload byte", "unknown key". Six mutations recorded red then restored in `201-EVIDENCE/real-tarball-mutation-201.txt` (plan 201-03). |
| 4 | Scope 1: the differing metadata field was found with evidence | VERIFIED | The differing field is `build_env` (Hex 2.6+ toolchain stamp). The 0.2.13 pre-fix rule reproduces the defect on real tarballs (M1 in `measure-201.json`: metadata equal 1/6, payload equal 6/6, rc 1), and `test/fixtures/hex_tarballs/README.md` records the real tarballs and their provenance. |
| 5 | Scope 2: expectation vs candidate build decided with a recommendation, fixed forward with a regression test on real tarballs | VERIFIED | README `## Decision: companions only` (user decision of 2026-11-09, PD-01). The regression test file has 22 tests on real tarballs; its pre-fix red state is captured in `201-EVIDENCE/real-tarball-red-201.txt`. |
| 6 | Scope 3: the proof's findings were measured before it stays merge- or release-blocking | VERIFIED | `201-EVIDENCE/measure-201.json` and `measure-201.txt`: M1 (defect reproduces under old rule), M2/M1b (6/6 equal under the fix), M3 (core strict), M4 (history of earlier runs). Includes self, flip and short-manifest controls (rc 0, 1, 2). Companions measured toolchain-invariant under Hex 2.5.1 and 2.7.0. |
| 7 | Scope 4 / goal: a release run reached COMPLETE with exact-public proven for all six packages | VERIFIED | Re-read with `gh run view 42713010358`: status completed, conclusion success, head dc6a8ed3 (contains fix commit 5b7e572c). Jobs "exact-public artifact proof body" success, "linked release rollup" success, "iOS swift build" success, "ios mirror tag check" success. Run log: result `{"state":"COMPLETE","source_mode":"exact-public",...,"package_count":6,...}` and six `artifact-provenance:` lines (core `digested=yes`, five companions `digested=no`). Hex lists 0.2.14, 0.2.13, 0.2.12 for `crosswake`. The 0.2.14 ledger line is on origin/main (`docs/release-ledger/RELEASE-LEDGER.jsonl`, run_id 42713010358, outcome success). |
| 8 | Prohibitions held: no change to `cleanroom.ex`, ref comparison, release scripts or workflows; no `feat:` commit; Maven fire drill used its own one-use allow | VERIFIED | `git diff --stat` across the four fix commits (55cead25 to be335acc) touches only `artifact.ex`, the real-tarball test, `test/fixtures/hex_tarballs/*` and `.gitattributes`. Commit types are `fix:` and `test:`. `gates-201.txt` records the `core-maven-drill` allow (decision at 22:00:03Z) bound to head 407398160bb5, and the standing-rules precheck before merge. |

**Score:** 8/8 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/release_candidate/artifact.ex` | `build_env!/1`, literal five-companion exclusion list, `drop_build_env/2`, `provenance_line/1`, `inspect_single!/2` | VERIFIED | All present at origin/main (lines 21, 99, 123, 202-220, 346-360); substantive; wired through `inspect_cli!/1` -> `inspect_family!/1` -> `inspect_artifact!/2` -> `inspect_metadata!/3` |
| `test/crosswake/release_candidate/artifact_real_tarball_test.exs` | Regression on real tarballs | VERIFIED | 22 tests, 0 failures when run |
| `test/fixtures/hex_tarballs/` | Real public/rebuild tarballs, SHA256SUMS, README with decision | VERIFIED | Three tarballs plus checksums and README present |
| `201-EVIDENCE/` | Red/green/mutation/measure/run/ledger evidence | VERIFIED | Files present and consistent with live reads (run, mirror tag, ledger line) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Artifact.inspect_metadata!/3` | candidate manifest and public observation | one normalizer, `drop_build_env(package)` | WIRED | One code path serves both sides; live run showed equal digests for all six |
| `Artifact.inspect_cli!/1` | CI logs of candidate build and exact-public proof | `IO.puts(:stderr, provenance_line/1)` | WIRED | Six provenance lines found in the live run log |

### Data-Flow Trace (Level 4)

Not applicable beyond the above: the digest is computed from real tarball metadata on both sides, and the live run consumed real Hex tarballs (not fixtures).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Real-tarball regression | `mix test test/crosswake/release_candidate/artifact_real_tarball_test.exs` (scratch worktree at af1dd94e) | 22 tests, 0 failures | PASS |
| Whole release_candidate directory | `mix test test/crosswake/release_candidate/` | 205 tests, 0 failures | PASS |
| Live release run | `gh run view 42713010358 --json status,conclusion,jobs` | completed / success; exact-public and rollup jobs success | PASS |
| Hex publication | Hex API for `crosswake` | 0.2.14 listed | PASS |

The full hermetic suite (3201 ran, 0 failures on origin/main) was established earlier today and not re-run here.

### Probe Execution

SKIPPED: no probe-based verification is declared by this phase's plans.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| REL-08 | 201-04, 201-06, 201-07, 201-08 | Default iOS generation writes and builds every referenced file; pre-release build gate | SATISFIED | REQUIREMENTS.md marks it Complete with the closeout annotation. This phase's contribution: the 0.2.14 release run passed the iOS clean-room (`iOS swift build` success) and the mirror tag check PASS (`mirror-tag-0.2.14-201.txt`, mirror tag v0.2.14); the original 200-01/200-02 deliveries are cited, not re-verified here |
| REL-09 | 201-01 to 201-08 | Release run ends COMPLETE including iOS clean-room and exact-public proofs, ledger line on main, with the amended 0.2.14 wording | SATISFIED | Truth 7 above. Ledger line on main verified. Standing approvals and Maven drill allow recorded in `gates-201.txt` |

All IDs declared in the eight PLAN files (`REL-09` in 201-01/02/03/05, `REL-08, REL-09` in 201-04/06/07/08) appear in REQUIREMENTS.md. No orphaned requirements. REL-07 stays Pending by design and is not counted. One cosmetic note: the traceability table at REQUIREMENTS.md lines 105-106 maps REL-08 and REL-09 to Phase 200, not Phase 201; the status is Complete either way.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/crosswake/release_candidate/artifact.ex` | n/a | No TBD/FIXME/XXX debt markers in the changed region | none | none |
| `.github/workflows/exact-public-proof.yml` (record-ledger job, not changed by this phase) | 342 | Skip path logs "not opening a duplicate" and exits 0 | Warning (tracked, TODO-013) | Silent loss of a release's ledger line when a ledger PR is open; see below |

Code review (`201-REVIEW.md`): 0 critical, 3 warnings (WR-01 exclusion list verified for one of five companions in tests, WR-02 provenance line re-derives the exclusion decision, WR-03 AGENTS.md contract test is positive-only), 5 info. All dispositioned `deferred` to TODO-014 in `201-REVIEW-DISPOSITION.md`. I agree none blocks the goal: the live run proved all five companions, and WR-01 is test coverage of an already-correct literal list.

### Is the record-ledger defect a gap against the phase goal?

Judgment: no, it is a tracked follow-up (TODO-013), recorded here as an advisory warning rather than a gap.

Why it is not a gap:
- The phase goal is that the exact-public digest proof stops failing companions so a release run can complete. Run 42713010358 completed and succeeded with six of six packages proven. The defective job is a different job (`record-ledger`) that runs after the proof's verdict and does not influence whether the proof passes.
- The defect predates the phase and sits in code the phase did not touch; the phase's prohibitions forbade workflow edits.
- No verdict is lost: the 0.2.14 success line is on origin/main (`RELEASE-LEDGER.jsonl`, run_id 42713010358), appended by `script/append_release_ledger.sh` in PR 289, and sits next to the 0.2.13 failure line. REL-09's ledger clause (as amended) is therefore met.
- It was observed, escalated, and written up as TODO-013 instead of being hidden.

Why it still deserves a warning: the job reports success while discarding the line, which is the "degrade silently" pattern AGENTS.md says to flag. It will recur on any release made while a ledger PR is open, so the next release should confirm its ledger line on main by hand until TODO-013 lands. Note that TODO-013 and TODO-014 are present on the local docs branch (`.planning/todos/`) but not on origin/main as of af1dd94e; they land with the docs branch.

### Human Verification Required

None. Every must-have was checked by code reads, test runs or live GitHub/Hex reads. No behavior-dependent truth was left without a behavioral test.

### Gaps Summary

No gaps. The companion `build_env` toolchain stamp was identified as the differing field, excluded from the digest for the five companions only after strict shape validation, covered by real-tarball tests that pass, and proven in a live release run that ended COMPLETE with exact-public six of six. The core keeps `build_env` in its digest, and the live log shows it digested. The only carried item is the unrelated record-ledger defect (TODO-013), with the review warnings in TODO-014.

---

_Verified: 2026-11-09T23:59:00Z_
_Verifier: Claude (gsd-verifier)_
