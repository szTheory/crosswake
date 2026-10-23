---
phase: 186-host-seam-and-harness-honesty
verified: 2026-10-16T18:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-05-SUMMARY.md
covered_digest: "v3:sha256:d3ccaa956890428b74da48755b1bf0c8c12da2e85a27e06a7399f45640d9f5bf"
behavior_unverified: 0
advisory:
  - finding: "WR-01: the physical-iPhone preflight passes when the host's Info.plist is unreadable and no other local-loopback signal exists (follows decision D-17 as written)."
    category: other
    reason: "Not a gap for LOOP-07 as worded (see reasoning below). Residual hole: a local-mode host whose plist was made unreadable after generation and whose route_activation.json is also unreadable or lacks a local declaration. Fix candidate: treat an unreadable plist as a refusal in the preflight only, with a test."
    evidence_status: "read IOSHostOriginMode and the preflight code; not reproduced with an unreadable-plist fixture"
  - finding: "WR-02/WR-03 (review): the preflight rescue labels any observation crash as local loopback; the harness skips its evidence precheck for an explicit empty --evidence value, and a bare --evidence dies before the trap."
    category: other
    reason: "Both fail closed or are operator-error edges on a manually run harness. WR-03 should be fixed before Phase 188 uses the harness for the real Simulator run."
    evidence_status: "from 186-REVIEW-DISPOSITION.md; code read, not run"
---

# Phase 186: Host seam and harness honesty Verification Report

**Phase Goal:** The host-command seam denies rather than silently grants, doctor reports instead of passing when it cannot read its inputs, no output leaks a home path, and the loopback harness cannot report a pass after its own failure.
**Verified:** 2026-10-16
**Status:** passed
**Re-verification:** No, initial verification (candidate commit `bd29400722e14bed74c987bf5a9903f486dc6fc2` on `25614cf6`)

## What was checked and what happened

I confirmed the candidate is at `bd294007` with an empty `git status`, and that it stayed empty after I finished. I did not trust the summaries: I read the committed diffs for the Swift coordinator, the doctor, the shell-package redaction helper, the generation gate, the physical-iPhone preflight and mix task, and the loopback harness script. I then ran eight focused test files on the candidate with a separate build path: 93 tests, 0 failures. I did not run the twin, a Simulator, xcodebuild or twin-05, and I created no files in either checkout apart from this report.

From the run records: the Swift suite executed 89 tests with 1 failure, and its failing set is identical to the recorded baseline (the pre-existing G4 test); the mutation script exited 0 with a 28-line log (control 0, control 1, and controls 2 to 26, all failing as expected); the pre-mutation hash manifest verified.

## Observable truths

| # | Requirement | Truth | Status | Evidence |
|---|-------------|-------|--------|----------|
| 1 | SEAM-07 | A route with no `host_commands` key grants nothing; each host command is denied with `not_registered` or `version_unsupported`; doctor reports the legacy manifest with a repair hint; guide explains it; schema and public API unchanged | VERIFIED | `grantHostCommands` in `ActivationCoordinator.swift` now returns `([:], denials)` on the legacy path: route-declared `host.*` names get `not_registered`, and on the entry route the request's `host.*` keys get `not_registered` or `version_unsupported` by `supportsCommandVersion`. The old grant loop is gone. Doctor emits `host_commands_legacy_manifest` (error when the router declares commands on that route, warning otherwise) with the hint `Run mix crosswake.gen.shell ios`. `guides/native_shell_upgrade.md` and `CHANGELOG.md` say "A pre-1.2.0 manifest grants nothing". Diff boundaries show no manifest, BridgeChannel or `public` Swift change. Swift suite is baseline-equal; controls 17 and 18 (revert the coordinator, swap the denial reason) fail named tests. |
| 2 | SEAM-08 | `host_commands_stale` is an error when the fixture is unreadable or malformed, and when a declaring router route is missing from the manifest; an absent fixture is skipped | VERIFIED | `stale_host_command_findings/3` has explicit branches: `{:error, :enoent}` returns `[]` when nothing declares commands and the advisory `host_commands_stale_skipped` otherwise; other read errors return an error finding with reason `unreadable`; undecodable or shape-invalid JSON (including a non-map `host_commands`) returns reason `malformed`; `:error when commands != []` returns reason `route_missing`. The old `else -> []` fall-through is gone. Controls 2 to 8 each fail a named test when one branch is reverted. |
| 3 | SEAM-09 | Doctor findings, gate messages and raised errors about package paths show only project-relative paths, with no absolute home path or username; the guide's version wording matches the code's floor semantics | VERIFIED | `ShellPackage.display_location/2` has no clause returning a raw absolute path: it yields a project-relative path, `<home>/...`, or `<outside project>`, with component-wise containment and a 32-hop symlink bound. It is applied in `shell_unsupported_finding` (finding text and `package_location` metadata), in `IOSHostGeneration.shell_gate`, and `gen.shell` passes `project_root`. `path_redaction_test.exs` uses a sentinel directory and covers doctor output, the gate error and the raised gen.shell error text. `guides/compatibility.md` now says the route still activates and each command is denied with `seam_unsupported` only when the shell's compiled version is below the manifest's, which matches the `seam_unsupported` denial at `ActivationCoordinator.swift:296`. Controls 9 to 16 fail named tests. |
| 4 | LOOP-06 | The loopback harness fails when its hash check misses the swapped file, when writing evidence fails, and when uninstall or device restore fails; proved with broken-state shims; documented as manual evidence | VERIFIED | The harness now hashes the whole generated tree before the swap and after build and at exit (`compare_tree_hashes`), requires the swap target to equal the probe bytes and to differ from its pre-swap hash, and adds `LOOP-IOS-OWNED-HASH`. Evidence is prechecked and written via temp file and `mv`, and a failed write turns a pass into `blocked` with `LOOP-IOS-EVIDENCE`. A passed run with `APP_UNINSTALLED` or `DEVICE_LEFT_AS_FOUND` not true becomes `blocked` with `LOOP-IOS-CLEANUP`. `loopback_origin_harness_test.exs` (403 lines, shim-based, no live Simulator) is in the 93-test run. `guides/native_shell.md` states "manually run phase evidence, not a CI lane" and the 0/2/3 exit codes. Controls 19 to 25 fail named tests. |
| 5 | LOOP-07 | A regression test proves physical-iPhone proof preparation cannot reach a host generated in local loopback mode; preflight code only if the test shows the generator refusal did not already cover it | VERIFIED | The 186-04 test run was red, so preflight code was justified and added: `PhysicalIphonePreflight.config/1` blocks with `PI-PREFLIGHT-CONFIG` whenever `IOSHostOriginMode.observe/2` returns anything but `:none`, and the mix task reports the generator's own refusal text as the cause. The tests cover a local `ios_host` declaration, and real `gen.shell` local-mode output (Info.plist and `route_activation.json` present on disk) under a production declaration, each across preflight-only, readiness and run, with `refute_received :device_report_called`. A control test shows production output still passes. Control 26 (the local-signal branch returns nil) fails the named tests. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

## Judgment on LOOP-07 and WR-01

The requirement says proof preparation must not reach "a host generated in local loopback mode". A host generated that way writes a readable Info.plist containing the `CrosswakeOriginMode` marker, and records the local declaration in `route_activation.json`. The test uses exactly that real generator output and shows all three modes blocked before any device report is produced, so the stated condition is met. WR-01 is a different case: a plist that cannot be read, with no other signal. That is a tampered or damaged host, not a host "generated in local loopback mode" whose generated files are intact, and D-17 chose to refuse only on an observed signal. I count it as an advisory gap in the decision, not a failure of this requirement. I recommend closing it cheaply (unreadable plist refuses in the preflight, with a test) in the next change that touches the preflight, because the fail-closed ethos of the milestone argues for it, and the code comment currently overstates the guarantee.

## Accepted deviations judged

1. **Two stale iOS fixtures gained `"routes":{}`** (`doctor_test.exs` and `crosswake_doctor_test.exs`, one line each). The fixtures were missing the `routes` map, which the new doctor correctly calls malformed. The change touches only test fixtures, not product behavior, and is on the commit allowlist. Does not undermine SEAM-08; it confirms the new strictness.
2. **Swift "at least 90 tests" was a miscount.** I confirmed 89 executed, 1 failure, and the failure list equals the baseline file (the G4 test, deferred to Phase 188). Accepted.
3. **Controls 25 and 26 corrected.** Control 25 now restores the three-stage piped `grep -F | grep -q` form that the product code removed (a real hazard under pipefail), and control 26 now disables the local-signal branch in `origin_refusal_for/2`, the code that actually causes the block. Both target real guards, and no product code changed because of the corrections. Accepted.

## Requirements coverage

| Requirement | Source plans | Status |
|-------------|--------------|--------|
| SEAM-07 | 186-01, 186-02, 186-05 | SATISFIED |
| SEAM-08 | 186-01, 186-05 | SATISFIED |
| SEAM-09 | 186-01, 186-02, 186-05 | SATISFIED |
| LOOP-06 | 186-03, 186-05 | SATISFIED |
| LOOP-07 | 186-04, 186-05 | SATISFIED (with WR-01 advisory) |

All five IDs appear in plan frontmatter and in REQUIREMENTS.md (Phase 186). No orphaned requirement. REQUIREMENTS.md still shows these as Pending; the orchestrator must tick them.

## Anti-patterns and deferred debt

No debt markers or stubs found in the changed product paths. Known open debt, all advisory and recorded in the summaries: the harness build-addition allow-list (confirm in the Phase 188 Simulator run), WR-03 empty `--evidence` (fix before Phase 188), the pre-existing Swift G4 failure, absence-checker pin 249 vs 251 files (Phase 188 freeze), other absolute paths in doctor output outside package paths, and Linux execution of the harness suite unverified.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
