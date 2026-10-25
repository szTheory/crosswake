---
phase: 175-rehearsal-and-publish
plan: 135
subsystem: release_candidate
tags: [metadata-read, exact-head, one-use]
requires: [175-134]
provides: [audited-exact-head-version-observation]
affects: [release-candidate-evidence]
tech-stack:
  added: []
  patterns: [same-attempt-one-use-read, independent-offline-terminal-audit]
key-files:
  created:
    - evidence/175-plan134-0bb956299110958d644df7ff4e53ca9f-metadata-read-authorization.json
    - evidence/175-plan134-0bb956299110958d644df7ff4e53ca9f-metadata-read-result.json
    - 175-135-SUMMARY.md
  modified:
    - evidence/175-plan134-0bb956299110958d644df7ff4e53ca9f-metadata-read-lifecycle.jsonl
requirements-completed: []
metrics:
  completed: 2026-10-10
  tasks: 3
  commits: 0
status: complete
---

# Phase 175 Plan 135: Exact-Head Metadata Observation

The one approved v3 read completed ALLOW / OBSERVED / FACTS_CAPTURED at `2026-10-10T18:54:25.205331Z`. PR219's verified immutable head establishes core candidate version **0.2.7** through the root release manifest. Both prescribed independent terminal audits passed. This is an observed metadata and policy snapshot; it does not establish a ready preflight or authorize a write.

## Tasks

1. Task1 was already complete. The retained reservation and complete displayed card were resumed without preparing a new attempt. All five reviewed source fingerprints stayed unchanged. The current production PENDING inspector and independent scope/card/reservation audit passed immediately before decision recording.
2. The user's plain `allow` was bound internally to this displayed attempt and its inspector-derived scope, raw card and collector digests. One local decision command created the exclusive same-attempt authorization.
3. The production metadata-read mode ran exactly once, sealed the result, and was followed by the prescribed Elixir and Node audits plus an independent Python digest/lifecycle/history check. There was no repeated decision, acquisition, preparation or broad test rerun.

## Sealed bindings

- Attempt: `0bb956299110958d644df7ff4e53ca9f`.
- Scope SHA-256: `cc98cd9457fb26a3dd1597a672bf565420fb87834e4046995f10cbd1eae9575b`.
- Raw-card SHA-256: `9ef1ed2062b594b7d64f338c48882fd80a5c910bdb2258c77f8d2a049b9f3546`.
- Collector SHA-256: `965a115d6c0914844d057248b3f2acac0c89ec863e85d2d77973b6851d9b8ff5`.
- Authorization SHA-256: `31eea9408111a3b08fc146e762e27c9ddbde66b219deac8283a45173795bcc44`.
- Result SHA-256: `bfd109757f08e7fda44e106b17b62b963aba3bb3b75b0be9d7810b2aacba463c`.

## Audited facts

PR219 is OPEN, draft=false, merged=false. Its base is `e51698528dc667ef89beb951e4eb1ec91da74981`, head is `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, and verified head tree is `5279cae1daa1fbff3437b673df8ca231fb07c91f`. Version `0.2.7` has typed `github_contents_exact_head` provenance: head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, tree `5279cae1daa1fbff3437b673df8ca231fb07c91f`, manifest blob `31da6202a8408ddda013edea104c9d5b1f787438`. The fixed manifest read was anonymous and preceded authenticated identity, permission and policy acquisition under the reviewed collector contract.

Source tag and commit are `998742856a37a97ae7247f6c532f9c154ea20885`. The source package split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` equals mirror main and prior v0.2.5; package and split trees both equal `b80f3bf00ef61708120b062bc88738fed88294a9`. Destination v0.2.6 is ABSENT; source and mirror refs were stable during this observation and the cloned origin matched.

Authenticated access projects permission_role=ADMIN, permission=TRUE, identity_match=TRUE, helper_available=TRUE. The observed policy is complete=true and tag_policy=CREATE_ONLY_ALLOWED, with policy SHA-256 `8c6309834aaedddf8f21cbad4cf3728b4aa4085a73c652a82c083ee23760a035`. These observations do not satisfy Plan106's separately pinned Plan119 PREFLIGHT_READY, immediate effective permission/policy recheck, exact one-ref dry-run or distinct tag decision. Effective write permission stays UNKNOWN and tag authority stays NONE in the release posture.

## Counts and verification

| Operation | Actual | Scope maximum |
|---|---:|---:|
| GitHub GET requests | 8 | 26 |
| Git operations | 16 | 16 |
| Helper checks | 1 | 1 |
| Permission checks | 2 | 2 |
| Dry-run attempts | 0 | 0 |
| Tag attempts | 0 | 0 |
| CI requests | 0 | 0 |

Canonical SHA-256 for scope, authorization, result and all four events passed in both Elixir and independent Python checks. The prescribed Node audit passed exact v3 schemas/key sets, same-attempt and path references, raw-card/collector equality, reservation/read-decision/read-intent/read-result order, one intent, bounded exact counts, structured privacy and typed version provenance. Event states are PENDING / ALLOW / INTENT / OBSERVED. The result has no failure diagnostic. All 610 task-start phase files outside this attempt's lifecycle remained byte-identical before parent tracking updates, and all five reviewed source/test files remain unchanged. Earlier attempts and approvals remain spent.

Plan134's recorded 122 Node and 39 focused ExUnit passing cases remain applicable because the reviewed source is unchanged. They were not rerun; the current evidence gates above provide this plan's verification. No new recurring CI check or human UAT was created. Wave-post schema and UI gates reported block=false; the codebase-drift advisory skipped because STRUCTURE.md is absent, with no action required.

## Release posture and handoff

Plan106 HELD; Plans46-48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE.

The observed version and complete policy snapshot materially change the earlier unknown questions and support a separately reviewed follow-up. Exact next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research`, limited to reconciling these audited facts with the unmet pinned preflight and other held release prerequisites. This attempt and ALLOW are consumed. Do not replay Wave38, reserve another read, run held Plan106, or infer tag/release authority from this summary. Any later external observation or write requires its separately reviewed scope and applicable fresh choice.

Last completed phase remains 174. Phase175 remains IN PROGRESS / INCOMPLETE / RELEASE-BLOCKED with five incomplete held plans. Phase verification and completion are ineligible. The parked adopter workstream and capability/support truth remain unchanged.

## Task commits

None. Phase overrides prohibit staging, commits, branch switching and worktrees; all three tasks followed that posture.

## Deviations

None in execution. Parent-owned tracking is reconciled separately after the terminal audits; historical evidence and completed summaries are preserved.

## Self-Check: PASSED

The actual authorization/result/lifecycle exist and independent terminal gates passed. The complete held release posture is retained. No dry-run, tag, CI, merge, registry, publication, support promotion or phase completion followed the approved read.
