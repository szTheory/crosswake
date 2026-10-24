# Phase 193 — PR 1 standing merge authorization

Recorded 2026-10-24 by the execute-phase orchestrator from the user's own words in the session:
"if ci green u can squash merge", followed by the user's explicit choice of **merge commit**
(keeping D-02) when asked whether to squash.

Scope (one use):

- Applies only to PR 1 of Phase 193 (branch `docs/192-post-sync-records`), merged once with a
  merge commit through `land-gate-193.sh merge` (`gh pr merge --merge --match-head-commit`).
- Bound to the head commit plan 05 pushes and proposes. If the head changes before the merge,
  this authorization no longer applies and the user is asked again.
- Conditions: the required Crosswake CI check passed on that head, the privacy scan is clean at
  that head, and every land-gate check passes. Any failure, refusal or uncertain delivery stops
  the plan; never retry a merge whose delivery is uncertain.
- Does not cover squash, rebase, admin bypass, force push, the Gate B removal `allow`/`hold`
  (plan 08), the PR 2 merge (plan 10), or anything else.

The plan 05 `answer` step records `answer allow` against this displayed proposal; the plain-language
proposal is still written and shown to the user in the report.
