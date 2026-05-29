---
phase: 36-hermetic-proof-lane
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - test/crosswake/proof/phase34_paywall_corridor_proof_test.exs
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 36: Code Review Report

**Reviewed:** 2026-05-29T00:00:00Z
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed the sole Phase 36 deliverable: a hermetic, merge-blocking ExUnit proof of
the mock paywall corridor. The review traced every assertion against the SHIPPED code
it exercises (`lib/crosswake/commerce/{reconciliation,contracts}.ex` and
`examples/phoenix_host/lib/crosswake_example/commerce/{entitlement_projection,mock_backend,reconciliation_inbox,reconciliation_keys}.ex`).

Overall the proof is well-constructed and the core behavioral assertions are
**non-vacuous** — they would fail on a real corridor regression. The four `Code.require_file`
lines are the intentional hermetic idiom and are out of scope. No security issues, no
hermeticity leaks (no process start, no network, no PubSub, no runtime-path require_file),
and the `:granted` path correctly routes through the real shipped pipeline rather than a
hand-built snapshot.

The findings below are all about **assertion strength and self-scan-guard robustness** —
the things that determine whether this proof actually catches regressions or can silently
rot into a green-but-meaningless lane. None are blockers; all are quality/robustness
improvements appropriate for a merge-blocking guardian test.

## Warnings

### WR-01: Self-scan token guard scans only the proof file, giving false hermeticity confidence

**File:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs:176-191`
**Issue:** The "no process-start or server tokens" guard reads `File.read!(__ENV__.file)` —
i.e. only the proof's own source text. It cannot detect hermeticity violations introduced
through the modules the proof `require_file`s or transitively calls. For example,
`MockBackend.verify_and_broadcast/2` (in the required `mock_backend.ex`) calls
`Phoenix.PubSub.broadcast/3`; the proof correctly avoids that function today, but nothing
in this guard would prevent a future edit from calling `verify_and_broadcast/2` instead of
`build_verified_snapshot/2`, which would touch PubSub and break hermeticity while every
self-scan test still passes (because `phoenix.pubsub` never appears in the proof's own text).

The guard's scope is intentional, but its assertion message ("hermetic lane must not start
processes or use Phoenix server infrastructure") overstates what it actually verifies.
**Fix:** Add an explicit negative assertion that the proof never calls the PubSub-touching
entry point, e.g. scan for `verify_and_broadcast` and `phoenix.pubsub` (already covered) and
add `"verify_and_broadcast"` to the forbidden-token list (built via concatenation so the guard
does not match its own line):
```elixir
forbidden_tokens = [
  "start" <> "_supervised",
  "phoenix" <> ".pubsub",
  "genserver" <> ".start",
  "liveview" <> "test",
  "verify_and" <> "_broadcast"  # PubSub-touching entry point; proof must use build_verified_snapshot/2 only
]
```
Alternatively, tighten the assertion message to state the guard only covers the proof file's
own source, so a future reader does not over-trust it.

### WR-02: `:denied` assertion is over-determined — passes even if grant logic partially regresses

**File:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs:56-62`
**Issue:** The base snapshot from `phase34_snapshot/0` sets BOTH `authority: :none` (not in
`@grantable_authority_states`) AND `access: :denied` (not `:granted`). `granted_snapshot?/1`
requires all four conditions, so two independent conditions fail simultaneously. The test
therefore still returns `:denied` even if a regression made `granted_snapshot?` ignore the
`access.decision == :granted` check — the `authority: :none` failure alone keeps it `:denied`.

The stated intent (per the comment) is to prove that "verified reconciliation + access :denied"
falls through to `:denied`. To prove *that specific* fence, the only failing condition should
be the access decision; everything else should be a granting value.
**Fix:** Make `access` the sole non-granting field so the assertion isolates the intended fence:
```elixir
snap =
  phase34_snapshot(%{
    authority: phase34_authority_lane(:active),
    access: phase34_access_lane(:denied),
    reconciliation: phase34_reconciliation_lane(:projection_refreshed),
    freshness: phase34_freshness_lane(:fresh)
  })
assert EntitlementProjection.derived_state(snap) == :denied,
       "fresh + verified + grantable authority but access :denied must fall through to :denied"
```

### WR-03: SC#1/SC#2 `:granted` and `:pending` cases are duplicated, and the `:granted` path never asserts non-vacuity of state ordering

**File:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs:64-68, 82-92`
**Issue:** Two pairs of tests assert the same thing through the same code path:
- SC#1 `:granted` (lines 64-68) and SC#2 `verified -> project -> :granted` (lines 87-92) are
  behaviorally identical — same `MockBackend.build_verified_snapshot/2` → `project_snapshot(nil, _)`
  → `derived_state == :granted` chain.
- SC#1 `:pending` (lines 51-54) and SC#2 `:pending origin` (lines 82-85) are identical.

Duplication is not itself a bug, but it means SC#2 does not actually prove a *transition*
(`:pending -> :granted`) as a single connected sequence — it proves the two endpoints
independently. A regression that broke the linkage between the ingested evidence and the
verified snapshot (e.g. `build_verified_snapshot` ignoring the evidence's group/reference)
would not be caught, because the `:granted` assertion only checks the terminal atom, never
that the granted snapshot's `group_id`/reference derive from the ingested evidence.
**Fix:** In the SC#2 transition test, thread the same evidence through both steps and assert
the linkage, not just the endpoints:
```elixir
evidence = phase34_mock_evidence()
{:ok, ingested} = ReconciliationInbox.ingest_evidence(evidence)
assert ingested.status == :awaiting_verification          # :pending origin

verified = MockBackend.build_verified_snapshot(evidence, @group_id)
assert verified.group_id == @group_id                      # evidence -> snapshot linkage
{:ok, projected} = EntitlementProjection.project_snapshot(nil, verified)
assert EntitlementProjection.derived_state(projected) == :granted
```

## Info

### IN-01: `forbidden_runtime_substrings` will not catch a `.exs`/`.eex`/`.heex` runtime path

**File:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs:166`
**Issue:** The substring blocklist (`_live`, `endpoint`, `application`, `router`, `repo`, `_web`)
is name-based and could miss a runtime-path require that does not contain one of those tokens
(e.g. a future `paywall_entry.ex` LiveComponent, or `socket.ex`). The exact-allowlist check on
lines 160-163 already constrains requires to the four named pure modules, so this blocklist is
belt-and-suspenders — but its enumerated tokens give a false sense of completeness.
**Fix:** Optionally drop the redundant blocklist in favor of the allowlist, or document that the
allowlist (not the blocklist) is the authoritative gate.

### IN-02: `ingest_evidence/2` test ignores the second arg and asserts only `status`

**File:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs:76-80`
**Issue:** The test asserts `result.status == :awaiting_verification` but does not assert the
other fields the shipped `ingest_evidence/2` returns (`source`, `event_key`, `subject_key`,
`replay?`, `trace_metadata`). A regression that corrupted `subject_key` or flipped `replay?`
would pass. For a merge-blocking proof this is acceptable scope (status is the PROOF-relevant
field), but a single additional assertion on `result.replay? == false` and
`result.source == :storefront` would harden the evidence-only contract.
**Fix:** Add `assert result.replay? == false` and `assert result.source == :storefront`.

### IN-03: Self-scan `length(require_call_lines) == 4` is brittle to formatting/whitespace

**File:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs:145, 156-157`
**Issue:** The regex `~r/^\s*code\.require_file\s*\(/` requires the call to begin a line. A
benign reformat that placed a `Code.require_file` after a comment token or used a multi-line
form would silently fail the count assertion (count != 4) and break the merge lane on a
non-substantive change. This is a low-impact maintainability snag, not a correctness bug.
**Fix:** No change required; note in a comment that all four requires must remain at line start
in the canonical one-per-line form so future editors do not reformat them.

---

_Reviewed: 2026-05-29T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
