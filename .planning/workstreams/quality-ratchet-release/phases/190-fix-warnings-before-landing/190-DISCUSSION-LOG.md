# Phase 190: Fix warnings before landing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research or execution agents.
> Decisions are captured in 190-CONTEXT.md; this log keeps the alternatives that were considered.

**Date:** 2026-10-19
**Phase:** 190-fix-warnings-before-landing
**Mode:** advisor (minimal_decisive): one recommendation per area, confirmed in one turn
**Areas discussed:** Where the 188 script fixes live; the code-fix defaults

---

## Where the 188 script fixes live (FIX-01, 02, 03)

Finding: `scan-privacy-188.sh`, `selftest-188.sh` and the `g()` helper exist only in the Phase 188 planning folder, not in the candidate. That conflicted with criterion 5 ("all FIX commits are in the candidate").

| Option | Description | Selected |
|--------|-------------|----------|
| Successors in 190 | Leave the 188 originals unchanged; write fixed, self-tested successors in the 190 folder; add a pointer in 188's disposition; reword criterion 5 | ✓ |
| Promote into candidate | Commit the scripts as permanent tooling under `script/` | |
| Edit 188 in place | Patch the 188 scripts directly | |

**User's choice:** Successors in 190 (recommended).

## Code-fix defaults (FIX-04..07, commit layout, deferral)

| Option | Description | Selected |
|--------|-------------|----------|
| Lock them | FIX-04 `:registry_timeout` with the registry kept alive; FIX-05 shared pinned git environment plus top-level check; FIX-07 refusal in the preflight with `PI-PREFLIGHT-CONFIG`; FIX-06 pin raised last from a separate count; one commit per FIX; the 184 FIFO hang deferred | ✓ |
| Change one | Adjust a single default | |

**User's choice:** Lock them (recommended).

## Claude's Discretion

- Successor script names and layout, stub wiring, and how the comparison test runs the Elixir funnel.
- Whether to extract a shared git-env module for FIX-05.
- Wording of the refusal reasons, within the privacy rules.

## Deferred Ideas

- 184 GAP4-WR-01 (the FIFO hang in `probe_source/2`).
- Retained review findings outside v27 scope.
- Promoting the successor scripts into permanent tooling.
