# Known Release Blocker — REL-17

**Status:** OPEN — blocks every future linked release, release recovery, and companion publication.
**Recorded:** 2026-09-26
**Historical scope:** Phase 175 Gate 1 findings T-175-35 through T-175-40b.

## Historical disposition

The Gate 1 evidence for PR #147 is incomplete or noncompliant and cannot be recreated. The
maintainer accepted that limitation only as a fact about a past release. The incident remains
recorded as noncompliant; this is not retroactive proof or a claim that the gate passed.

## Release hold

Do not authorize a new linked release, recovery, or companion publication until REL-17 is
implemented and its evidence gate passes for the exact candidate. A new candidate, approval token,
or later successful release does not waive this hold.

The candidate-bound gate must fail closed unless it verifies all six conditions together:

1. A leg-specific Hex run ID is bound to the exact candidate.
2. Base, head, merge, CI, and required-check policy are rechecked immediately before authorization.
3. The raw registry response is retained and its nonempty parse is checked.
4. The exact merge used the normal protected path and did not use administrative bypass.
5. The matching Hex response-table row is retained and bound to the leg run.
6. The incident runbook commit is an ancestor of the exact base, approved head, and merge.

The current ancestry helper covers condition 6 for future linked releases. Conditions 1–5 still
need explicit candidate-bound enforcement; historical evidence remains accepted only for the
already-published event.

## Closure evidence

REL-17 closes only when:

- every release, recovery, and companion publication path consumes the same exact-candidate gate;
- absence, mismatch, stale run identity, omitted response fields, and bypass attempts fail closed;
- CI runs positive and mutation cases proving the gate is wired to each path;
- the release workflow integrity checker requires the contract; and
- a fresh candidate has a complete evidence bundle before any one-way authorization is requested.

Until then, the release hold is the operative decision. This record grants no merge, publish, or
recovery authority.
