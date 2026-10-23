---
phase: 175-rehearsal-and-publish
plan: 134
subsystem: release_candidate
tags: [metadata-read, plan105, local-contract]
requires: [175-133]
provides: [plan105-exact-head-metadata-read]
affects: [release-candidate-evidence]
tech-stack:
  added: []
  patterns: [exact-head-fixed-route, fake-transport-tracer]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan134-local-contract.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-134-SUMMARY.md
  modified:
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
decisions:
  - Use PR219's verified head and root manifest for the v3 metadata-read scope.
  - Keep metadata acquisition separate from release readiness and tag authority.
metrics:
  completed: 2026-10-10
  actuals:
    tokens: 10955
    tasks: 2
    commits: 0
status: complete
---

# Phase 175 Plan 134: Exact-Head Metadata Read Summary

Plan105 now supports a separate v3 metadata-read scope that reads the root release manifest at PR219's verified head and carries only the validated root version with typed head/tree/blob provenance. The fixed contents request is anonymous and runs before credential acquisition; the existing authenticated identity, permission, policy, and Git-read sequence remains intact afterward.

The new scope has eight GET shapes and a 26-request limit. Its card identifies the anonymous fixed-head route and zero write/CI authority. It has its own Plan134 paths, authorization schema, lifecycle schema, and result schema. Mix exposes prepare, inspect, decision, and run modes; the decision mode accepts plain-language `allow` and `hold`. Manifest parsing rejects invalid file identity, encoding, size, blob hash, duplicate root keys, and noncanonical versions. The old v1/v2 scope shapes retain their seven routes and 25-request limit.

The Node tracer was first run against the unchanged implementation and failed because the metadata validator was absent. The ExUnit tracer likewise failed because `prepare_metadata_read/2` did not exist. Both passed after implementation. The ExUnit test crosses the real Elixir coordinator and Node collector process using injected fake HTTP and Git callbacks; it verifies that the fixed contents GET precedes authenticated policy routes. No provider network, real credentials, helper, remote Git, tag, CI, merge, registry, or publication action ran.

Validation passed: 122 Node tests, including the 117 existing cases; 38 focused ExUnit tests, including the 37 existing cases; Node syntax checks; named Elixir format check; and scoped whitespace check. The new tests cover exact-head routing, wrapped base64, title/version separation, hostile manifests, schema and route tampering, operation/schema swaps, 26-request boundary, credential placement, HOLD, and one-use decision handling. Historical Phase175 plans, summaries, and evidence remained unchanged: 421 of 421 matched the task-start fingerprint.

The local synthetic result does not establish a live candidate version or release permission. A future external read needs its own reviewed plan and a fresh displayed card bound to the updated collector, followed by its own one-use plain-language allow/hold.

Plan106 HELD; Plans46-48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; candidate version UNKNOWN.

No commits were created because the phase override disables commit documentation. Phase 175 remains incomplete and its tracking files remain parent-owned.
