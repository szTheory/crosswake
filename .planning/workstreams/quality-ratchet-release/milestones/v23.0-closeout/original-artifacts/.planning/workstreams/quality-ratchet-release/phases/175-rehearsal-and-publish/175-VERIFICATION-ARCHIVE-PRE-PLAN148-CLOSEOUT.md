---
phase: 175-rehearsal-and-publish
verified: 2026-09-26T01:14:33Z
status: gaps_found
score: 4/8 success criteria verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - "SC-5: successor 0.2.5 ordinary release was PARTIAL; Maven is absent."
  - "SC-6: exact-public proof was skipped and same-run rollup was not COMPLETE."
  - "SC-7: second held companion publication remains unperformed."
  - "REL-17: future linked release, recovery, and companion publishers remain held until the shared same-candidate evidence contract and cross-path mutation proof close."
historical_gaps:
  - "SC-1: Gate 1 runbook ancestry was violated; this historical condition cannot be repaired retroactively."
security_gate:
  status: accepted_historical_exception
  blocking_threats: 0
  release_hold: REL-17
---

# Phase 175 — Rehearsal and Publish Verification

**Phase goal:** A freshly rehearsed and explicitly authorized successor core candidate and held
second companion are live through the repaired release graph, with exact-public proof executed and
passed and all six core children COMPLETE in that same ordinary run.

**Verified:** 2026-09-26T01:14:33Z  
**Status:** gaps found — 4/8 success criteria verified  
**Security gate:** open — six historical high-severity findings remain blocking (see
[175-SECURITY.md](175-SECURITY.md)).

## Success Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Retire/backfill runbook was in the exact remote publish graph before the first publish. | ✗ NOT SATISFIED | Phase records the Gate 1 ancestry breach: PR #147 base, head, and merge excluded the runbook; the roadmap states this cannot be repaired retroactively. See `175-07-SUMMARY.md`, `175-VALIDATION.md`, and the phase roadmap. |
| 2 | All three publish legs were rehearsed through their last safe reversible step. | ✓ VERIFIED | Exact successor Hex, iOS mirror, and Maven rehearsal evidence is recorded in `175-SUCCESSOR-CANDIDATE.md` and `evidence/175-successor-rehearsals.json`; all report no external mutation. |
| 3 | Multi-registry partial-failure response table existed before publication. | ✓ VERIFIED | `175-PUBLISH-LEG-2.md` records the response table and pre-publication chronology. |
| 4 | First held companion PR #147 was merged and its package confirmed live on Hex. | ✓ VERIFIED | Historical PR #147 publication and registry confirmation are recorded in `175-07-SUMMARY.md` and the release evidence. This does not resolve its Gate 1 ancestry breach. |
| 5 | Fresh successor core published to all three registries in one ordinary run. | ✗ NOT SATISFIED | Successor run `36083361945` is PARTIAL: Hex and iOS are present; Maven POM is absent. See `175-SUCCESSOR-CORE-RUN.md` and `evidence/175-successor-core-registry.json`. |
| 6 | Exact-public proof passed and the same run's six-child rollup was COMPLETE. | ✗ NOT SATISFIED | Android and exact-public proof were skipped in the PARTIAL run; the required same-run proof and COMPLETE rollup do not exist. See `175-SUCCESSOR-CORE-RUN.md`. |
| 7 | Second held companion was separately authorized, published, and confirmed live. | ✗ NOT SATISFIED | No second-companion authorization/publication evidence is present. No such publication is authorized by the consumed Gate 2 token. |
| 8 | Release documentation was corrected and recurring guard wired. | ✓ VERIFIED | Roadmap records DOC-04/DOC-06 completion and the version-literal guard; current integrity and workflow checks pass. |

## Automated Verification Run

| Check | Result |
|-------|--------|
| `HEX_HOME=/tmp/crosswake-hex-home mix test --exclude requires_example_host --max-cases 4` | PASS — 1,975 tests, 0 failures, 74 excluded |
| Focused candidate receipt and workflow tests | PASS — 35 tests, 0 failures |
| `elixir script/check_release_workflow_integrity.exs` | PASS — 79/79 checks |
| `actionlint .github/workflows/ios-mirror-backfill.yml` | PASS |
| `elixir script/inventory_collection_assertions.exs --check` | PASS — 230 classified sites match |
| `git diff --check` | PASS |

The receipt builder now requires the exact eight-file evidence roster, hashes the actual
`ci/cleanroom.json` bytes against the CI receipt claim, and emits a bound `candidate.cleanroom`
proof. The attestation workflow verifies the downloaded file against that proof. A mismatch test
fails closed. These checks close the three current receipt-integrity findings; they do not alter
the four unsatisfied roadmap criteria above.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| REL-10 | NOT SATISFIED | The historical Gate 1 runbook ancestry requirement was breached. |
| REL-11 | SATISFIED | Exact rehearsal evidence for Hex, iOS, and Maven is recorded. |
| REL-12 | PARTIAL | First companion published, but Gate 1 was noncompliant. |
| REL-13 | NOT SATISFIED | Successor core publication was PARTIAL; Maven absent and exact-public proof skipped. |
| REL-14 | PARTIAL | The PARTIAL result is correctly recorded; COMPLETE same-run rollup is absent. |
| REL-15 | NOT SATISFIED | Second companion remains held and unpublished. |
| REL-16 | SATISFIED | Response-table and release-recovery evidence is recorded. |
| REL-17 | OPEN — RELEASE BLOCKER | Fresh same-candidate evidence for the six historical Gate 1 conditions is not yet enforced across all release paths. See `175-KNOWN-RELEASE-BLOCKER.md`. |
| DOC-04 | SATISFIED | Stale fixed-version release claim removed with a recurring version-literal guard. |
| DOC-06 | SATISFIED | `git subtree split` guidance replaces live `splitsh-lite` instructions. |

## Security and Release Boundaries

The maintainer accepted the six high-severity historical evidence limitations only as facts about
the already-published event; the incident remains noncompliant and no historical evidence was
recreated. The security audit therefore has zero blocking threats at its configured high threshold.
Twelve lower-severity findings remain open below that threshold. REL-17 is a separate open release
blocker: no future linked release, recovery, or companion publication may be authorized until a
same-candidate fail-closed gate checks all six conditions and its mutation tests pass. The 0.2.5
Gate 2 authorization is consumed; this verification does not authorize a retry, recovery,
second-companion publication, or any new external mutation.

The phase's roadmap goal remains unachieved because the Gate 1 condition is historically
unsatisfiable and the later successor/second-companion criteria are incomplete. Do not update the
roadmap to mark Phase 175 complete.

## Gap-Closure Scope Amendment — 2026-09-26

After this verification snapshot, the maintainer chose targeted additive planning within Phase 175.
SC-1 remains an explicitly historical, non-closable gap; it must not produce a repair task or be
claimed compliant. The actionable gap set is SC-5, SC-6, SC-7, and the newly formalized REL-17
release hold. Additive gap-closure Plans 175-34..41 were reviewed with zero blockers and one
nonblocking file-scope warning. The 4/8 score above remains the dated pre-amendment snapshot; the
current roadmap has nine criteria and no new verification was performed during this discussion.
This amendment changes planning scope only: no release claim changed, and no external action is
authorized.
