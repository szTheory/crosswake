---
phase: 159-host-reusable-proof-lane
verified: 2026-08-02T01:58:33Z
status: gaps_found
score: 21/23 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Generator filesystem operations execute only a helper built from repository-owned source and cannot execute a shared-temp-file winner."
    status: failed
    reason: "GeneratorFS reuses a predictable executable under the shared system temp directory using File.regular?/1, then executes it through System.cmd/3 and Port.open/2 without provenance, owner, type, or symlink-safe validation."
    artifacts:
      - path: "lib/crosswake/proof_lane/generator_fs.ex"
        issue: "build/1 trusts and executes System.tmp_dir!/crosswake-proof-lane-fs-<public source digest>."
    missing:
      - "Build and execute the helper in a process-private, restrictive directory, or validate a private cache with descriptor/ownership/type guarantees before reuse."
      - "Add a regression that pre-creates the predictable cache pathname and proves it is rejected rather than executed."
  - truth: "Every retained-evidence reader validates and consumes the same digest-bound canonical artifact bytes."
    status: failed
    reason: "Evidence.check/1 and check/2 verify bytes in scan_stage/1, then reopen proof-lane-evidence.json in read_evidence/1. A replacement between those reads can be decoded and accepted without matching .complete."
    artifacts:
      - path: "lib/crosswake/proof_lane/evidence.ex"
        issue: "scan_stage/1 returns :ok instead of verified bytes/evidence; both check variants perform a second path read."
    missing:
      - "Carry the bytes verified against .complete through scanning, decoding, and source-hash verification, or use a descriptor/identity-preserving equivalent."
      - "Add a deterministic replacement-between-scan-and-read regression for both check arities."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding.
**Verified:** 2026-08-02T01:58:33Z
**Status:** gaps_found
**Re-verification:** No — the earlier report contained no `gaps:` section and used a non-canonical `complete` status, so this is an independent initial goal-backward verification.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generator creates a configurable, missing-only host-owned scaffold and provides read-only check/diff. | ✓ VERIFIED | `Config` has exactly nine validated keys; `Generator` renders ten host-owned files and uses `GeneratorFS` for read/write. The focused generator/config suite passed. |
| 2 | Existing browser tests/fixtures remain the primary web/island proof and generated proof is additive. | ✓ VERIFIED | `bash script/verify_phoenix_host_proof_lane.sh` passed: the generated spec typechecked and ran through the existing Phoenix Playwright `webServer`, with one passing browser test. The generated support has `finally` online restoration. |
| 3 | Native scaffold is bounded to shell/auth/relaunch/offline-island prerequisites and does not claim device success without adapters. | ✓ VERIFIED | iOS templates and verifier tests implement closed `passed`/`blocked`/`unavailable` results; the generated accessibility runtime remains advisory, and roadmap/state retain Phase 162 physical-device ownership. |
| 4 | Evidence generation rejects sensitive data and retained evidence is safe, complete, and digest-bound. | ✗ FAILED | The allowlist and sensitive-term controls exist, but the digest guarantee is hollow: `Evidence.check/1` and `check/2` reopen the artifact after `scan_stage/1` verified different bytes. |
| 5 | Generator operations remain safe for a host running generate, check, or diff. | ✗ FAILED | `GeneratorFS.build/1` trusts a predictable executable in `System.tmp_dir!/` and executes it. A same-host temp-directory writer can win that pathname. |

**Score:** 21/23 truths verified (the earlier 23 grouped plan truths are preserved as the score denominator; two security/integrity truths fail).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/crosswake.gen.proof_lane.ex` | iOS generator entry and action selection | ✓ VERIFIED | Normalizes configuration before `generate`, `check`, or `diff`. |
| `lib/crosswake/proof_lane/config.ex` | closed nine-key configuration | ✓ VERIFIED | Exact-key/type/path validation; rejects quote and backslash endpoint values. |
| `lib/crosswake/proof_lane/generator.ex` | missing-only desired-state renderer | ✓ VERIFIED | Ten templates, versioned manifest, `GeneratorFS` read/write wiring. |
| `lib/crosswake/proof_lane/generator_fs.ex` | confined safe filesystem helper boundary | ✗ FAILED | Substantive and wired, but its helper-executable cache is unsafe (CR-01). |
| `lib/crosswake/proof_lane/evidence.ex` | typed, safe, digest-bound evidence reader/publisher | ✗ FAILED | Substantive and wired, but its reader has a digest-validation TOCTOU (CR-02). |
| `priv/native/crosswake_evidence_promote.c` | exclusive incomplete reservation and marker publication | ✓ VERIFIED | Warning-clean compile passed; its no-automatic-cleanup behavior is intentional and locked. |
| `script/verify_phoenix_host_proof_lane.sh` | runnable isolated generated Phoenix proof | ✓ VERIFIED | Passed in the declared full focused gate. |
| generated Playwright and iOS templates | host-owned browser/native scaffold | ✓ VERIFIED | Generated browser spec uses typed adapter; iOS templates encode closed outcomes and UI contract checks. |

`verify.artifacts` reported every declared artifact as present/substantive. That probe only checks levels 1–2; the two failed artifacts above fail the adversarial semantic/integrity check and cannot be accepted merely because they exist.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Mix task | `Config.normalize/1` | all action paths | ✓ WIRED | `lib/mix/tasks/crosswake.gen.proof_lane.ex:19-28,69`. |
| `Generator` | `GeneratorFS` | missing-only reads/writes | ✗ FAILED | Wiring exists, but it reaches an executable selected from untrusted shared temp state (CR-01). |
| `Evidence.promote/3` | native evidence helper | bounded byte/digest frame | ✓ WIRED | `evidence.ex:136` delegates to `NativePromotion.publish`; declared tests passed. |
| `Evidence.check/1,2` | `.complete` marker and decoded artifact | digest validation | ✗ FAILED | `evidence.ex:90-103` calls `scan_stage`, then a separate `read_evidence`; `scan_stage` verifies the marker only against its first read at lines 113-118. |
| Phoenix proof command | existing Playwright configuration and host lifecycle | isolated generated spec | ✓ WIRED | Current command passed one generated test through the existing test server lifecycle. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated Playwright proof | mutation ID/outbox/backend assertions | real Phoenix test host and IndexedDB browser flow | Yes | ✓ FLOWING |
| Evidence check | canonical JSON bytes | retained artifact pathname | No — second unchecked pathname read | ✗ HOLLOW integrity flow |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused proof-lane contracts | declared 51-test `mix test` command | 51 tests, 0 failures | ✓ PASS |
| Generated Phoenix browser proof | `bash script/verify_phoenix_host_proof_lane.sh` | 1 generated Playwright test passed | ✓ PASS |
| TypeScript generated proof surface | `npm --prefix examples/phoenix_host run typecheck:offline-route-proof` | exit 0 | ✓ PASS |
| Native helper compilation | two `cc -Wall -Wextra -Werror` commands | exit 0 | ✓ PASS |
| Full syntax/format gate | declared `bash -n` and `mix format --check-formatted` commands | exit 0 | ✓ PASS |

The passing tests are insufficient evidence for the two failed truths: no test pre-creates the predictable helper cache, and no test replaces the evidence artifact between marker verification and the subsequent decode.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 01, 02, 03, 05, 06, 08, 09, 12-24 | Configurable host-owned scaffold without overwriting host files | ✗ BLOCKED | Missing-only behavior passes, but the generator can execute a same-host attacker’s predictable temp-cache executable (CR-01), so the host-owned generator safety contract is not achieved. |
| PROOF-02 | 01, 02, 05, 08, 10, 12, 14, 16-24 | route/storage/mutation/endpoint/router/shell configuration | ✓ SATISFIED | Exact nine-key normalizer and focused tests pass, including endpoint rejection before write authority. |
| PROOF-03 | 01, 03, 06, 09, 10, 12, 14, 15, 17-21, 24 | Primary browser/unit/fixture corpus remains authoritative | ✓ SATISFIED | Current isolated generated Playwright proof passed in the existing Phoenix lifecycle; generated support remains additive. |
| PROOF-04 | 01, 04, 07, 10-12, 14, 17, 20-22, 24 | Sensitive evidence is rejected | ✗ BLOCKED | The reader can accept a replacement artifact not bound to `.complete` (CR-02), defeating the required retained-evidence integrity boundary. |

All four requirement IDs declared by every Phase 159 plan are accounted for. The checked-off entries in `REQUIREMENTS.md` are contradicted by the current source evidence for PROOF-01 and PROOF-04; this report does not alter planning state.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/proof_lane/generator_fs.ex` | 160-163 | predictable shared-temp executable trusted by `File.regular?` | 🛑 BLOCKER | Arbitrary code execution by a local writer before generate/check/diff. |
| `lib/crosswake/proof_lane/evidence.ex` | 90-103, 113-118, 379-386 | digest-verified bytes discarded, then artifact path reopened | 🛑 BLOCKER | Replaced bytes can be accepted without marker digest proof. |

No unresolved `TBD`, `FIXME`, or `XXX` debt marker was found in the phase code.

### Review Reassessment

- **CR-01: confirmed.** The reviewed vulnerable code is still live. The later summary calls this a content-addressed cache, but its digest covers only the expected source name; it does not authenticate the file selected at that predictable shared path.
- **CR-02: confirmed.** The marker is correctly shaped and checked against the first artifact read, but `check/1` and `check/2` do not consume those verified bytes. A passing post-promotion mutation test does not cover a replacement between the two reads.
- **WR-01: not a gap.** The review’s proposed cleanup conflicts with the locked Plan 159-22 truth: an interrupted/replaced advertised reservation must remain visibly incomplete and Crosswake must not automatically remove, move, restore, quarantine, or repurpose that final directory. The current C helper’s lack of advertised-destination cleanup therefore preserves host ownership; no fix is requested for WR-01.

### Gaps Summary

The phase has runnable scaffolding and a passing focused gate, but its two most security-sensitive integrity boundaries are not achieved. The cache flaw is a direct executable-trust violation for a host-owned generator. The evidence flaw disconnects the accepted JSON from the completion digest precisely across the replacement race the phase claims to close. These are not deferred Phase 160–162 capabilities: they are immediate Phase 159 blockers and no later roadmap phase specifically schedules them.

---

_Verified: 2026-08-02T01:58:33Z_
_Verifier: the agent (gsd-verifier)_
