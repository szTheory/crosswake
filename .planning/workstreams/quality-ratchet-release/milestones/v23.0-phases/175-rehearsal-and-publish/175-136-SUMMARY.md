---
phase: 175-rehearsal-and-publish
plan: 136
subsystem: release_candidate
tags: [exact-head, same-run-preflight, local-contract]
requires: [175-135]
provides: [synthetic-exact-head-preflight-contract]
affects: [release-candidate-evidence]
tech-stack:
  added: []
  patterns: [versioned-preflight-schema, fake-process-tracer, same-credential-dry-run]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-136-SUMMARY.md
  modified:
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-136-PLAN.md
requirements-completed: []
metrics:
  completed: 2026-10-10
  tasks: 2
  node_tests: 158
  exunit_tests: 55
  commits: 0
status: complete
---

# Phase 175 Plan 136: Exact-Head Preflight Contract

Plan105 now has a separate v3 preflight contract that binds the root manifest version and its exact head/tree/blob provenance to the complete authenticated permission and tag-policy snapshot, then performs one create-only dry-run for the exact mirror ref under the same credential. The v3 scope, receipt, paths, inspector and Mix modes are separate from v1/v2. The synthetic receipt cannot satisfy Plan106's Plan119-pinned precondition and cannot authorize a tag.

The source-grounded gap was that the existing ready-preflight v2 derives the candidate version from the mutable PR title. Plan135 observed the exact-head manifest version and complete policy in a separate metadata-read attempt with zero dry-runs; it did not establish same-run provenance, effective permission rechecks and the exact-ref dry-run together. Plan136 closes that local contract gap while preserving legacy scope and receipt behavior.

Both the Node and Elixir tracers were first observed failing against the unchanged implementation, then passed through the production Elixir-to-Node process seam with fake transport, routes and process results. No external network/provider/credential/helper or hosted-Git access, real attempt/card, live preflight, dry-run, tag, CI, merge, registry or publication operation occurred. The existing local isolated-bare-remote regression remains local-only.

The plan-owned roster completed exactly once: 36 required Node cases and 16 required ExUnit cases. The complete suites passed 158 Node tests and 55 ExUnit tests. Node syntax checks, Elixir formatting, and scoped `git diff --check` passed. The roster verifier was adjusted to recognize this Mix version's `[L#…]` suffix on completed `--trace` rows; after that correction, it found no missing, skipped or duplicate required cases.

Plan135's five sealed raw files still match their execution-start SHA-256 values:

| File | SHA-256 |
|---|---|
| scope.json | `a8da465d3172d87b8c98f0c83acfe2b9d1577e34d67c5252db447856d3417b01` |
| card.md | `9ef1ed2062b594b7d64f338c48882fd80a5c910bdb2258c77f8d2a049b9f3546` |
| authorization.json | `fc400a7644ef8395d9646ed31fc671e254eb39c4cdf6fa4ba5ccff6bcaf1f330` |
| lifecycle.jsonl | `3cba4472d02ffecfcb3294dd0ab0e576a301e1b24384d281bfce09f31de6fcea` |
| result.json (raw file) | `98a07cd7ede5978c4607878a3a0c768dd416def3605ce61973d8873f24122ecd` |

The historical canonical digest inside Plan135's result remains `bfd109757f08e7fda44e106b17b62b963aba3bb3b75b0be9d7810b2aacba463c`.

Plan106 and Plans46-48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE.

Last completed phase remains 174. Phase175 remains IN PROGRESS / INCOMPLETE / RELEASE-BLOCKED with five incomplete held plans. Phase verification and completion remain ineligible. The next eligible work is a separately reviewed fresh preflight plan for preparation, a complete card and one-use plain allow/hold, followed by one bounded read plus dry-run; a tag decision remains a later distinct action. Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`.

No commits were created. No requirement was completed by this local contract result.
