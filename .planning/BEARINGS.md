# Bearings (read first; max 60 lines; edited only at milestone close; prune at least as many as added)

## Posture invariants (statement | how checked)
1. Land before leap: main green; nothing valuable only in /tmp, a stash or an unpushed branch. | script/bearings-report
2. Fail-closed explicit denials; offline claims honest (cached read-only is not mutation; one island is not sync). | docs-contract + vector tests
3. Privacy: opaque scope refs, scope-partitioned outboxes, no raw payloads, tokens or device ids in telemetry, doctor, logs or proof. | privacy scan before every push
4. Irreversible steps follow the AGENTS.md approval gate (one-use allow, never standing). | AGENTS.md
5. Android posture: see ADR amendment A1. | .planning/ADR-FIRST-B2C-ADOPTER.md#a1
6. Every milestone serves an AGENTS.md priority or names the repair it blocks. After 2 inward milestones the next is outward unless the scope doc records a user override.
7. Never name, infer, search for or link the real first adopter. Synthetic profiles stay generic.
8. Publish DAG is core-first, then companions; irreversible Maven/Hex publishes only after a clean-room run against published coordinates. | clean-room command (Phase 195)
9. Backend authority is explicit: device and client signals are evidence until backend contracts promote them.
10. Hermetic and advisory proof lanes stay separate; merge-blocking proof is deterministic.
11. Docs-contract parity is mechanically checked against live code.

## Tripwires: check at plan time
- A check with no negative control passes by asserting nothing. Require a non-empty floor and a mutation that turns it red.
- A check can pin the FALSE value (stale versions, a literal SHA). Assert shape or derive from source.
- Piped gate commands report the tail's status. One command per gate; never `| tail && echo OK`.
- Status written before the event, or stamped by automation, goes stale on arrival. Derive from git, CI or an artifact path.
- A deferral without a receiver that can act is a drop. Debt rows carry owner, trigger, receiver.
- A recurring gate living only in a phase folder is not a gate. Promote only recurring contracts; measure findings on main before merge-blocking.
- Simulator-green is not device-green. Twin results never promote a claim.
- Line-number citations and line-keyed allowlists rot; key by file plus normalized text.
- Path-dependency rehearsals never catch published-core resolution.
- Hand-maintained version/date tables drift; generate them.

## Do not re-open (reopen only by ADR amendment citing a measured artifact; max one stop-list item per milestone)
- Generic/background sync, generic native storage, capture packs, commerce productionization, native menu breadth, dashboard.
- Candidate-in-/tmp "freeze" regimes; merge queue below ~3 PRs/day; per-persona host apps/twins; new label taxonomy.
- Rotating MIRROR_PUSH_TOKEN as a SEED-003 fix; deleting archived milestone records.
- Making the twin a per-PR lane; consuming a used twin run root; retrying a failed twin to green.

## Open traps (delete when fixed; max 5)
- twin-05 attests a53fbef, not main; no CI lane (v30).
