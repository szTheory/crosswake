---
phase: 175-rehearsal-and-publish
plan: 104
subsystem: release-evidence
tags: [ios-mirror, read-scope, release-hold, rehearsal]
requires:
  - phase: 175-103
    provides: "Safe route and transport diagnostic for the bounded Plan97 read"
provides:
  - "One terminal, bounded current source/mirror/PR observation"
  - "A sanitized report that keeps tag authority and the release hold unchanged"
affects: [REL-13, REL-17, Phase175 release hold]
requirements: [REL-13, REL-17]
requirements-completed: []
coverage:
  - id: D1
    description: "A fresh, exact-approval Plan104 observation is terminal and independently inspected."
    requirement: REL-13
    verification:
      - kind: other
        ref: "plan97-inspect --expect terminal --json (exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The result preserves the active release hold and grants no tag-write authority."
    requirement: REL-17
    verification:
      - kind: other
        ref: "terminal inspector: REL-13/14/15/17 OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; release hold ACTIVE"
        status: pass
    human_judgment: false
duration: not separately measured
completed: 2026-10-08
status: complete
---

# Phase 175 Plan104 Summary

**One approved read now confirms that the source package matches the iOS mirror and PR #219, while the target mirror tag is absent. The release remains blocked.**

## Accomplishments

- Revalidated the fresh Plan104 PENDING reservation, attempt, path-set/scope/contract digests, collector hash, and empty operation journals before making the read.
- Treated the user's exact Wave13 execute command as approval for this displayed Plan104 read. Wrote a one-use authorization tied to attempt `a7da00381a01c8c2f425a0d023ae2f0a` and its three evidence digests.
- Ran the bounded preflight once. The terminal inspector returned `READ_READY` / `MATCHING_PAIR`; the target tag `refs/tags/v0.2.6` is absent. Source and mirror objects are present, and the local split matches the mirror's current main and prior tag.
- The current observation matches the historical candidate comparison: PR #219 is open, not draft, and not merged; its base, head, and tree match the October 6 planning pin. That older pin is a comparison only; current facts come from this Plan104 observation.
- The inspector recorded 13 API fetch invocations and 9 Git spawn attempts, within the exact scope's 32-request and 9-spawn limits. Delivery remains `UNKNOWN`; the operation counts and upper bound are exact.
- Preserved the release stop: REL-13/14/15/17 OPEN; write permission UNKNOWN; tag authority NONE; readiness BLOCKED; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD; Phase175 INCOMPLETE.

## Current facts

- Source tag `ios-core-v0.2.6` resolves to commit `998742856a37a97ae7247f6c532f9c154ea20885`.
- The iOS package split is `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, matching mirror `main` and prior tag `v0.2.5`. The package tree is `b80f3bf00ef61708120b062bc88738fed88294a9`.
- Mirror target tag `v0.2.6` is absent. This observation does not authorize creating it.
- PR #219 is open, not draft, and not merged. Its base/head/tree are `e51698528dc667ef89beb951e4eb1ec91da74981`, `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, and `5279cae1daa1fbff3437b673df8ca231fb07c91f`.

## Evidence

- Attempt: `a7da00381a01c8c2f425a0d023ae2f0a`
- Path-set SHA-256: `f8a3f22d73af657b25fb6171c5cdecb4868947c77737b6ebff04a8a4e954607d`
- Scope SHA-256: `f4b225e25ef05bcf7d120cdab7b8786a1286d730d103bb003ed97ca92d5afade`
- Contract SHA-256: `ecc3ddfc8bb5da278c26bebf30c9abd2420921fb631fb3c1acde73530d7116e2`
- Isolated collector SHA-256: `4aca512493bc0e3f9b9865aa12f3fd73758fe9032f7b0a4509217424c029ad24`
- Sealed authorization digest: `f6da6994a586d09b6f06f9b08a02ddac4d6bc3b6fad09cbda76d2925c1ad6a71`
- Sealed terminal preflight digest: `fe6735fe066814866d88b1e7a8f19ac2605e6ec5f7f67599c302bc64854ea1ab`
- Parent journal SHA-256: `04f1cc987b1ff0c23877315a5ae2a48c23964449794f78fa1128bee6281e6bbf`
- Child journal SHA-256: `8eed4b6d08c06f83a19be8ef206998cb09886c912a32f8518d03140b81c387bf`

The terminal result contains no transport diagnostic because the read completed. Plan101's consumed attempt and evidence were not changed. No CI, tag write, merge, registry, recovery, or publication operation occurred. Phase 175 remains incomplete.

## Next gate

The next step is to plan a separate, exact tag-write decision from these observed facts. That plan must preserve the independent REL-17 release hold; this successful read did not remove it. No write or publication is authorized by Plan104.

## Self-Check: PASSED

- The PENDING inspector passed before authorization; the attempt and displayed digests matched the approval card, and both operation journals were empty.
- The terminal inspector passed after the single preflight. It reports 13 API fetches and 9 Git spawns, `READ_READY`, `MATCHING_PAIR`, target `ABSENT`, and the required release posture.
- The Plan104 task verification and GSD summary verification passed. No tests were added or run.
- Plan101's authorization, preflight, and parent/child journal hashes still match the recorded Plan101 summary; its consumed attempt was not modified.
- Roadmap progress is 85 summaries out of 89 plans. Phase175 remains in progress; the outstanding plans retain their recorded prerequisite links.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-08*
