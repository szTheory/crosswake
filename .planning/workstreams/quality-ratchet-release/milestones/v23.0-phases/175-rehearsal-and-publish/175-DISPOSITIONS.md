# Phase 175 plan status after the 0.2.4 partial release

**Recorded:** 2026-09-24. This is a human-readable disposition record; GSD execution excludes plans only when their own frontmatter has `status: superseded`. Original task bodies, summaries and evidence remain preserved; six previously pending plan files receive superseded metadata only.

| Plans | Status | Reason / successor |
|---|---|---|
| 175-01..07, 175-11..13, 175-18, 175-24..25 | completed | Keep their summaries and proof as recorded. |
| 175-14, 175-19 | halted/partial history | Preserve their original outcomes and evidence. |
| 175-20 | halted_partial history | Authorized 0.2.4 ordinary run published Hex only; its Gate 2 token is consumed. Preserve its summary and evidence. |
| 175-08..10 | superseded, unexecuted | Former 0.2.2 publication/proof path; 175-26..32 are the current successor path. |
| 175-15..17 | superseded, unexecuted | Machine-marked `status: superseded`; former 0.2.3 path replaced by 175-26..32. |
| 175-21..23 | superseded, unexecuted | Machine-marked `status: superseded`; require successful 0.2.4 same-run proof or companion gate that D-39..D-42 rule out; 175-30..32 replace those pending purposes. |
| 175-26..32 | pending | Current executable successor sequence, subject to each plan's preconditions and new one-way publication gates. |

## Addendum — 2026-09-26 REL-17 scope and plan review

The table above is the original 2026-09-24 disposition snapshot. This addendum records the current
sequence without rewriting historical plan outcomes: Plans 175-26/27 and 175-33 are completed
repairs; Plans 175-28/29 preserve the 0.2.5 blocked/PARTIAL history; Plans 175-30..32 are superseded.
The new plans below were checked for this scoped gap-closure pass and remain unexecuted. They grant
no merge, release, registry, recovery, or publication authority.

| Plans | Current disposition | Scope / dependency |
|---|---|---|
| 175-34..35 | planned, `gap_closure: true` | Pure operation-bound validator, package receipt, live evidence adapters and read-only status. |
| 175-36 | planned, `gap_closure: true` | Wire and mutation-prove the same guard across ordinary, recovery, and all five companion paths. |
| 175-37..39 | planned, `gap_closure: true` | After REL-17 closes, establish a fresh candidate, exact Gate 2, one ordinary run, and same-run exact-public plus six-child proof. |
| 175-40 | planned, `gap_closure: true` | After core COMPLETE, use held PR #115 only for its distinct Gate 3 and direct Hex proof; if #115 cannot be made exact, remain BLOCKED with SC-7 open. |
| 175-41 | planned, `gap_closure: true` | Reconcile verified outcomes to the nine-criterion roadmap while keeping SC-1 historically unsatisfied. |

The scoped checker found zero blockers and one nonblocking scope warning: Plan 175-36 declares 11
files across three focused tasks. All eight plans depend on the existing Plan 175-33 chain and are
additive; targeted execution must use `$gsd-execute-phase 175 --gaps-only --ws
quality-ratchet-release` after the discussion and plan checks. Preserve the original Plan 175-33
through 175-41 artifacts and the 0.2.4/0.2.5 records.

Core 0.2.4 is permanently **PARTIAL**: Hex published, iOS tag and Maven coordinate absent at the recorded observation, exact-public skipped. No 0.2.4 recovery is part of the current path. REL-10's first-publish Gate 1 breach remains historical and unsatisfied. This status record grants no release, registry, merge, or publication authority.
