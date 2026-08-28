---
phase: 162-physical-iphone-adoption-proof
verified: 2026-08-27T20:43:17Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 1/5
  gaps_closed:
    - "The retained physical record now pins the corrected pre-ledger code revision exactly, rather than merely an ancestor of later provenance fixes."
    - "The recovery wrapper reads code provenance from the promoted canonical artifact and retains the exact two-file pair without a second physical attempt."
  gaps_remaining: []
  regressions: []
---

# Phase 162: Physical-iPhone Adoption Proof Verification Report

**Phase Goal:** Prove offline answers, offline audio, kill/relaunch persistence, exactly-once replay, conflict recovery, account isolation, and remote disablement on a physical iPhone.
**Verified:** 2026-08-27T20:43:17Z
**Status:** passed
**Re-verification:** Yes — after corrected-provenance recovery.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Verified pronunciation audio plays offline on a physical iPhone. | ✓ VERIFIED | The canonical physical record is schema-valid, reports the complete fixed assertion set, has `physical_iphone` class and passed outcome, and is admitted only as a two-leaf committed artifact. |
| 2 | Selected and free-form answers survive offline use and kill/relaunch, then reconnect and reconcile exactly once until the outbox is empty. | ✓ VERIFIED | Current driver/host authority contracts are covered by focused root and Phoenix tests; the retained full assertion set is bound to the actual corrected code revision. |
| 3 | Reconnect applies accepted events exactly once and exposes rejection/conflict recovery. | ✓ VERIFIED | The Phoenix authority and recovery contracts passed in the focused suite, and the retained closed assertion set is complete and owner-disjoint by the fixed contract. |
| 4 | Account switching, logout, and server disablement fail closed without data loss or cross-scope replay. | ✓ VERIFIED | Focused current-code authority coverage passed; the physical record is provenance-bound to code descending from all three nonce/mutation/cleanup fixes. |
| 5 | The public support claim remains limited to one adopter flow on one iOS runtime line. | ✓ VERIFIED | The renderer/generator parity test passes and the public row expressly preserves the Android, background, generic-sync/storage, multiple-island, simulator, and every-iPhone non-claims. |

**Score:** 5/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `script/retain_physical_iphone_evidence_transaction.sh` | One-shot corrected-provenance transaction | ✓ VERIFIED | Production branch records the pre-ledger code commit, runs the literal canonical command once, requires the promoted record to name that commit, commits exactly two leaves, then performs fresh-process source-bound `Evidence.check/2`. |
| `lib/crosswake/proof_lane/evidence.ex` | Safe, source-bound promotion | ✓ VERIFIED | `Evidence.promote/3` verifies canonical sources before no-replace publication and calls `check(destination, sources)` before returning success. |
| `evidence/physical_iphone/proof-lane-evidence.json` and `.complete` | Canonical redacted retained physical record | ✓ VERIFIED | Exactly two regular leaves; marker is lowercase 64-hex and matches the JSON SHA-256; stage scan passes; schema/closed assertions pass. |
| `examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex` | Host authority and cleanup | ✓ VERIFIED | The host binds the transaction code reference and exposes idempotent cleanup; focused host/authority tests pass. |
| `lib/crosswake/support_matrix/renderer.ex` and `guides/support_matrix.md` | Narrow public support truth | ✓ VERIFIED | Deterministic support-matrix tests pass and the rendered physical-study row is bounded to one flow and one recorded iOS runtime line. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Corrected fixes `b79bce8b`, `c11886b7`, `e46f5136` | Physical code authority | immutable `e649e6ed` | ✓ WIRED | All three fixes are ancestors of `e649e6ed`; the artifact `commit_ref` equals exactly `git-e649e6ed…`, not a later wrapper or evidence commit. |
| `e649e6ed` | Ledger `d59c9182` | sole-parent relation | ✓ WIRED | `d59c9182` has sole parent `e649e6ed` and an empty tree, proving the ledger is not substituted for executed code. |
| Ledger | evidence-only commit `e429a8f9` | bounded Plan 17 recovery chain | ✓ WIRED | The chain contains the wrapper RED `b5a540c1`, GREEN `7c1f34d7`, then `e429a8f9`; the evidence commit changes exactly the two retained leaves. |
| Passed physical output | promoted evidence | wrapper reads artifact `commit_ref` | ✓ WIRED | The wrapper regression forbids reliance on optional run-JSON evidence provenance; current script obtains commit identity from `proof-lane-evidence.json`. |
| Approved same-run source | publication and transaction success | `Evidence.promote/3` then fresh `Evidence.check/2` | ✓ WIRED | Source validation precedes `NativePromotion.publish/2`, and source-bound checking follows publication; the evidence suite exercises this ordering. |
| Retained authority | support/requirements/roadmap/state | deterministic renderer and reconciliation | ✓ WIRED | Current planning and rendered support truth agree on the bounded claim; no stale pre-fix record is used as authority. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Physical record | closed assertion IDs and approved source hash | signed-device/Phoenix producers through the host-owned transaction | Yes — canonical record has the complete contract assertion set and passes stage validation | ✓ FLOWING |
| Evidence promotion | canonical source bytes | private same-run term → source validation → no-replace publication → source-bound recheck | Yes — production ordering is directly tested | ✓ FLOWING |
| Support row | retained evidence admission | renderer and generated guide | Yes — deterministic support-matrix tests prove parity | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Corrected transaction/evidence/physical-task/support contracts | focused root ExUnit selection | 139 tests, 0 failures | ✓ PASS |
| Phoenix proof host and replay authority | focused example-host ExUnit selection | 17 tests, 0 failures | ✓ PASS |
| Root compile and deterministic suite | `mix compile --warnings-as-errors && mix test --max-failures 1` | exit 0; 1,494 tests, 0 failures, 73 excluded | ✓ PASS |
| Retained evidence structure | `Evidence.scan_stage/1`, marker/hash, contract-set checks | all checks passed | ✓ PASS |

The browser command was intentionally not treated as evidence in this re-verification: a direct repository-root invocation resolved the wrong Playwright installation and discovered no test. This is a verifier invocation error, not a failing phase test; the independently passing retained-record, root, and Phoenix checks above are the acceptance evidence.

### Requirements Coverage

| Requirement | Description | Status | Evidence |
| --- | --- | --- | --- |
| DEVICE-01 | Verified pack installation and offline audio | ✓ SATISFIED | Complete retained physical assertion contract plus current pack/host coverage. |
| DEVICE-02 | Offline queue, relaunch, reconnect, exactly-once drain | ✓ SATISFIED | Corrected-code record plus focused current driver/Phoenix tests. |
| DEVICE-03 | Visible recoverable rejection/conflict outcomes | ✓ SATISFIED | Current recovery and Phoenix authority tests passed; record is no longer stale-provenance evidence. |
| DEVICE-04 | No cross-scope replay after logout/account switch | ✓ SATISFIED | Focused authority tests and corrected nonce/mutation/cleanup provenance. |
| DEVICE-05 | Server-side entry/replay disablement retains queued work | ✓ SATISFIED | Focused authority coverage and closed physical assertion contract. |
| DEVICE-06 | Dated redacted artifact | ✓ SATISFIED | Exact two-file commit, marker/hash, canonical schema, privacy stage scan, and source-bound publication path. |
| DEVICE-07 | Narrow one-flow/one-runtime support claim | ✓ SATISFIED | Renderer and guide parity retain explicit non-claims. |

No Phase 162 requirement is orphaned from its plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `STATE.md` / validation/support artifacts | tracked TODO-002 references | ℹ️ Info | Formal deferred adopter-route input, explicitly preserved as a non-claim; not an unowned debt marker. |
| Root suite | existing compiler warnings in unrelated doctor/companion tests | ℹ️ Info | The suite exits successfully; warnings do not concern Phase 162 evidence, replay, or support wiring. |

### Gaps Summary

No blocking gaps remain. The previous stale-provenance failure is closed by the retained recovery topology: the physical record names the immutable corrected pre-ledger code commit exactly; the sole ledger has that commit as its only parent and no tree changes; the later wrapper and evidence commits are explicitly not represented as device-executed code. The current source proves publication occurs only after same-run internal source validation and `Evidence.check/2`, while the wrapper-only repair retains rather than recreates the record.

---

_Verified: 2026-08-27T20:43:17Z_
_Verifier: the agent (gsd-verifier)_
