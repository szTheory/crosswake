# Phase 183: Close gap: twin source binding fails closed on uncommitted code - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-15
**Phase:** 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
**Areas discussed:** Source binding rule, Scope

Advisor mode was active (minimal_decisive tier). This is a code-local question, so the orchestrator checked the facts directly in the candidate instead of starting advisor research subagents. It checked:
- the ignored-path coverage;
- that twin-03 left no stray files;
- the freeze/observe code.

Then it asked one combined question with a single recommendation.

---

## Source binding rule

| Option | Description | Selected |
|--------|-------------|----------|
| Fail closed | A dirty or untracked tree blocks at freeze and again at observe (`source_dirty`). Phase 180 is committed in the candidate, a new prepared record is written, and twin-04 runs once. | ✓ |
| Bind working-tree digest | Allow dirty runs and bind a temp-index `write-tree` id. HEAD no longer names what ran, and a pass is possible on code that is never committed. | |

**User's choice:** Fail closed (Recommended)

## Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Defer it | Keep Phase 183 to the source-binding gap and the rerun. Record the identity-projection join as debt. | ✓ |
| Fold it in | Also join the twin against the Phase 179 identity/settings projections. | |

**User's choice:** Defer it (Recommended)

## Claude's Discretion

- Helper shape and cause atom spelling, plus whether the prepared-record writer also refuses a dirty tree.
- Commit grouping in the candidate.

## Deferred Ideas

- Twin join against the Phase 179 identity/settings projections (hardcoded bundle id).

---

## Research fan-out (2026-10-15, at the user's request)

Four read-only Sonnet research agents covered:
- (1) clean-tree git mechanics and prior art: Go `-buildvcs`, goreleaser, cargo `--allow-dirty`, setuptools-scm, Nix flakes, SLSA/in-toto, Bazel stamping, `mix hex.publish`;
- (2) mid-run integrity, cause flow and message DX;
- (3) commit, prepared record and history provenance;
- (4) negative-control test design.

The synthesized recommendations are D-02..D-20 in CONTEXT.md.

Adversarial pass, with corrections the orchestrator verified:
- **Agent 4's suggested isolation was insufficient.** It proposed `GIT_CONFIG_GLOBAL=/dev/null` to neutralise global excludes. On git 2.41.0 that does NOT show a file hidden by the XDG `~/.config/git/ignore`; `-c core.excludesFile=/dev/null` does. That is why D-03 requires the `-c` form.
- **Agent 3's claimed field does not exist.** It said `180-TWIN-RESULT.json` shows `candidate_head: null`. The file has no head field at all (keys: exit_status, fidelity_limits, groups, identity_joins, overall_status, receipt_sha256, residual_external_gates, run_id, schema). The proposed "null head is a blocker" rule was dropped.
- **Agent 2's write-tree comparator was rejected.** It proposed a temp-index `write-tree` comparator in addition to porcelain. It was rejected as redundant: it writes blobs into the candidate's object store, and it would read like the working-tree digest the user turned down. Its edit-then-revert residual was kept as a stated fidelity limit (D-12), and the snapshot clone was deferred.
- **Agent 4 found a fixture bug, adopted as D-15.** The existing test fixtures put the identity file and the run root inside the temp repo, so the guard would break every clean test.
- **Agent 1's suggestions were adopted.** It recommended treating `.git/info/exclude` entries as dirty (D-03); the candidate has 0 entries. It also recommended rescuing a missing git binary (D-04).
