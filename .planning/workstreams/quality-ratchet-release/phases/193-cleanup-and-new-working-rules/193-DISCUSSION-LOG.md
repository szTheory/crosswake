# Phase 193 Discussion Log

**Date:** 2026-10-23
**Mode:** delegated recommendations (user asked for a fan-out research pass and one coherent set of recommendations to follow; no question-by-question interview)

This log is for human reference only. Downstream agents read 193-CONTEXT.md.

## Already decided before this discussion
- What gets removed: 189-DECISIONS-ANSWERS.md (all 14 groups, "the backup is the keep").
- Merge commit only, allow gate bound to the displayed head, privacy scan bound to the push head: 191 D-03/D-22, 192 D-04/D-07.

## Areas researched (one research agent each)

| Area | Options weighed | Chosen | Why |
|---|---|---|---|
| Working rules (CLEAN-04) | land all except the authorization / condense durable rules / drop all recovery text; merge-commit vs squash; doc test vs none | Condense durable rules; drop the Phase 175 authorization; merge commit only; no new test | Rules stay true after v27; merge policy already proven in 192; branch protection enforces the real contract |
| Records and PRs | one PR / two PRs / three PRs; merge green Dependabot or record only; fix 192 residue or seed it | Two PRs; record dispositions only; SEED-025 | PR 1 gets the 192 records off the old checkout before retirement; cleanup phase stays code-free |
| Checkout retirement (CLEAN-01) | clone and swap by rename / convert in place / new path | Clone, copy forward from backups, swap by rename, end session, delete last after one gate | Keeps the path-keyed Claude memory and a two-rename rollback; no destructive git command on the only source copy |
| Removal order (CLEAN-02/03) | rely on main / small post-189 bundle / bundle whole clone; per-ref deletes vs retire whole checkout | Small post-189 bundle; per-item fail-closed gate; retire whole checkout last | Found `carry-trial` and `carry-trial-2` not on main and not in any 189 bundle |

## Notable finding
- `carry-trial` (`28a48db7`) and `carry-trial-2` (`dd3bdf5f`) in the integration clone are on no backup and not on `main`. D-07 adds one bundle before removal.

## Deferred
See 193-CONTEXT.md `<deferred>`.

## Process note
The discussion's commit step was skipped. Until the swap in Phase 193, the recovery checkout gets no git write (ROADMAP ordering rules; D-03). These files land through PR 1.
