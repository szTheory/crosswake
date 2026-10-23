---
phase: 175-rehearsal-and-publish
plan: 92
subsystem: release-evidence
tags: [elixir, node, evidence, fail-closed]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan91 attempt-bound operation accounting and historical Plan88 evidence
provides:
  - Attempt-derived Plan92 path-set reservation and offline pending inspection
  - Terminal TRIGGER_UNVERIFIED zero-request HOLD for attempt 73fbfd33f8d969cc9f8bc303fa9cb50d
affects: [phase-175, REL-13, REL-17]
actuals:
  tokens: 20609
  tasks: 3
  commits: 10
  plan_head_before: f86b278202eb141d9fe64a228a30ce9eaa01e965
  plan_head_after: baf39af5ba18e72dfcfb892f8ee2d58f930547ba
tech-stack:
  added: []
  patterns:
    - Attempt-specific sealed path set with exact derived basenames
    - Ordered terminal lifecycle evidence for a no-request HOLD
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan92-73fbfd33f8d969cc9f8bc303fa9cb50d-path-set.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan92-73fbfd33f8d969cc9f8bc303fa9cb50d-read-scope.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan92-73fbfd33f8d969cc9f8bc303fa9cb50d-hold.json
  modified:
    - lib/crosswake/release_candidate/plan87_mirror_tag.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/plan87_mirror_ref.mjs
    - test/crosswake/release_candidate/plan87_mirror_tag_test.exs
    - script/release_candidate/plan87_mirror_ref.test.mjs
requirements-completed: []
coverage: []
status: halted
---

# Phase 175 Plan 92: Attempt-bound path flow and zero-request D-107 hold

Plan92 created one attempt-specific sealed path set and PENDING scope, inspected it offline,
then ended the attempt as `TRIGGER_UNVERIFIED` without request intent or a remote read. Task1's
continuation now threads selected paths through fake preflight and terminal inspection. It also
rejects internally consistent but unauthenticated bundle metadata. The release remains blocked
and held.

## Results

- Task 1 added attempt-derived path-set preparation, local path-set/scope validation, offline
  pending/held inspection, terminal hold writing, and Node-side path-bound scope validation.
  The continuation threaded that same path set through preflight recheck, collector dispatch,
  journal reservation, pair validation, and terminal inspection; the fake Node transport binds it
  before its first GET.
- The local bundle consistency verifier binds the pinned version/base/head/tree, run ID/attempt,
  exact receipt digests, artifact bytes, and full unique all-success check roster, including
  `Crosswake CI` and `ios-mirror-parity-proof`. A matching custom JSON bundle still cannot prove
  GitHub origin offline, so the public gate deliberately returns `UNVERIFIED / PROVENANCE_UNVERIFIED`
  and never reaches the read adapter without an independently verifiable provenance format.
- Task 2 reserved attempt `73fbfd33f8d969cc9f8bc303fa9cb50d`. Its path-set digest is
  `0d97e764587005fd4a6d769a0ec11adc39174c061b43adb86cb271675d15a26a`; its scope digest is
  `a1c2dcab8a43e0641e7529d753706dd636128dd6b51bc7050c9312fd1091c007`; the Plan91 read-contract
  digest is `ecc3ddfc8bb5da278c26bebf30c9abd2420921fb631fb3c1acde73530d7116e2`.
- Task 3 used an empty local trigger-bundle path because no retained bundle met D-107. The local
  check returned `UNVERIFIED / NO_RETAINED_INDEPENDENT_BUNDLE`; it then sealed and independently
  inspected a `TRIGGER_UNVERIFIED` HOLD. The hold has zero requests, zero read intent, and zero
  invocations. No ALLOW/HOLD read decision was offered.
- The dated local signal and check-run observations were not accepted: the run was historical and
  both required checks failed. No artifact fetch, credential lookup, provider request, remote Git,
  CI, tag, Gate2, merge, recovery, registry, publication, or release-state change occurred.
- Historical Plan88 scope/lifecycle remained byte-identical: SHA-256 values are
  `91d56151862317adb23bd2c91490e93753928bce8919c7bc7e9891334e31a47f` and
  `45426eaf68b3f60d6ec6a8f3288e9f06a0c334e60131c374d0bb4b3f449e02b6`.

## Verification

- Initial RED/GREEN: focused ExUnit began with 19 tests and 2 intended failures, then passed 19
  after path-set/hold implementation.
- Continuation RED/GREEN: path-bound preflight and D-107 checks first produced 2 intended ExUnit
  failures; after implementation, focused ExUnit passed 23 tests, zero failures.
- Provenance RED/GREEN: 23 ExUnit tests produced 2 intended failures when a self-asserted bundle
  was required to stay unverified and blocked before collector invocation; the fail-closed gate
  then passed all 23 tests.
- Node TAP passed 19 tests, zero failures or skips. Named Elixir format, Node syntax, and scoped
  `git diff --check` passed.
- Offline held inspection passed with attempt `73fbfd33f8d969cc9f8bc303fa9cb50d`: request count,
  read intent, and invocations are all zero. Both Plan88 historical hashes matched their captured
  values.

## Deviations and remaining implementation limits

- The terminal D-107 branch and Plan92 selected-path flow are complete. No Plan92 read was attempted.
- The verifier checks local cross-file consistency and bytes, but its current custom `artifact.json`,
  `run.json`, and `checks.json` records are self-asserted. There is no retained cryptographic
  attestation, trust anchor, or other offline-authenticated origin proof in this checkout. It
  therefore refuses to emit a verified D-107 signal even when those fields and hashes match. A
  new independently authenticated provenance format is the exact remaining gate; do not pass a
  self-asserted bundle or reuse Plan88 ALLOW to reopen the read path.
- The initial prepare command's stdout included non-JSON Mix output, so the shell JSON parse failed
  after the single attempt had been created. The exact newly created attempt was identified from
  its unique Plan92 path-set filename and then inspected successfully; no second attempt was
  created.

No requirement is marked complete. REL-13/14/15/17 remain OPEN, candidate readiness BLOCKED,
merge policy UNKNOWN, release hold ACTIVE, Plans45–48 HELD, and Phase175 INCOMPLETE.

## Commits

- `a6f21f1b` — RED tests for sealed path set and zero-request hold
- `86e3f2cb` — attempt-specific path sets and no-request hold implementation
- `95cd8eea` — one fresh zero-request path-set reservation
- `89055719` — terminal zero-request D-107 hold
- `43e3f227` — record the terminal D-107 safe stop
- `f6da09c8` — correct measured plan head in the summary
- `4654f32b` — RED tests for D-107 bundle and selected-path preflight
- `3ba246c7` — thread selected paths through preflight and offline validation
- `59e1606d` — RED tests reject unauthenticated local provenance
- `baf39af5` — fail closed on unauthenticated provenance

The measured plan commit count and `plan_head_after` are captured immediately before the final
summary metadata commit.

## TDD Gate Compliance

The initial RED commit `a6f21f1b` precedes `86e3f2cb`; the selected-path RED commit `4654f32b`
precedes `3ba246c7`; and provenance RED commit `59e1606d` precedes `baf39af5`. Each intended
failure was observed before its corresponding green change, and the final focused suites passed.
The workspace did not produce a separate machine-classifier report for ExUnit output.

## Self-Check: PASSED

- Plan92 path-set, scope, HOLD artifact, and lifecycle exist and passed offline inspection.
- All task commits are ancestors of the current plan head.
- Plan88 scope and lifecycle digests match their captured pre-task values.
- No requirement is marked complete; the verifier keeps unauthenticated local bundle metadata
  from reaching the fake read adapter.
