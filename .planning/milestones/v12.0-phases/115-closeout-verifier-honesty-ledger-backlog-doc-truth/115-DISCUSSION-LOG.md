# Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 115-closeout-verifier-honesty-ledger-backlog-doc-truth
**Areas discussed:** `expected_phases` fail-closed behavior, v3.6 ledger debt truth, ledger evidence shape, v8.0 doc-truth annotation

---

## `expected_phases` Fail-Closed Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Raise immediately | Delete fallback and raise directly from verifier parsing before a normal report exists. | |
| Blocking check object | Preserve `%Report{}` shape and emit a blocking check, relying on Mix task to raise after rendering. | |
| Hybrid | Strict parser + blocking `closeout.expected_phases` check + existing Mix task raise after report rendering. | ✓ |

**User's choice:** User asked to consider all areas and produce a cohesive recommendation so they would not need to adjudicate.
**Notes:** Advisor research recommended the hybrid. It satisfies fail-closed behavior while preserving stable diagnostic output and no-active-closeout behavior.

---

## v3.6 Ledger Debt Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Honor v3.6 exception only | Keep current `v3.6-CLOSEOUT.md` resolved entry and do not add any new artifact. | |
| Create reconstructed v3.6 ledgers | Create synthetic per-phase `VALIDATION.md` files for phases whose original dirs were never archived. | |
| Update requirements wording | Amend DEBT-01/ROADMAP to distinguish impossible v3.6 ledgers from ordinary missing ledgers. | |
| Accepted exception artifact | Create a single machine-checkable v3.6 exception manifest instead of synthetic per-phase ledgers. | ✓ |

**User's choice:** User delegated the decision.
**Notes:** Selected recommendation is the hybrid: update planning wording and add `.planning/milestones/v3.6-VALIDATION-EXCEPTION.md`. Do not fabricate per-phase ledgers.

---

## Ledger Evidence Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Frontmatter fields only | Add `tested_by`/`evidence` metadata and rely on machine checks. | |
| Body/table evidence only | Accept existing body tables and commands as sufficient. | |
| Both frontmatter and body evidence | Use frontmatter as machine summary and body tables as audit narrative. | ✓ |
| Fully normalized evidence schema | Rich structured schema for commands, test files, CI runs, artifacts, digests. | |

**User's choice:** User delegated the decision.
**Notes:** Selected recommendation uses both: normalized but lightweight frontmatter evidence now, no live GitHub/API artifact validation, and existing body tables retained.

---

## v8.0 Doc-Truth Annotation

| Option | Description | Selected |
|--------|-------------|----------|
| MILESTONES entry + appended audit note | Add precedence rule and v8.0 shipped-state entry to `MILESTONES.md`; annotate audit without rewriting scores. | ✓ |
| Re-audit section with frontmatter metadata | Add a heavier audit re-run structure to the old audit file. | |
| Separate doc-truth ADR | Create a new governance artifact for document precedence. | |
| PROJECT/ROADMAP edits too | Duplicate or reinforce the rule across active planning docs. | |
| Comprehensive guard | Add docs plus a focused test that locks the reconciliation. | ✓ |

**User's choice:** User delegated the decision.
**Notes:** Selected recommendation is minimal but explicit: precedence + v8.0 entry in `MILESTONES.md`, append-only audit note in `v1.0-MILESTONE-AUDIT.md`, and a light planning-doc test.

---

## Claude's Discretion

- Exact parser helper names and report detail shape.
- Exact v3.6 exception artifact wording.
- Exact ledger evidence frontmatter schema details, as long as it is concrete and machine-checkable.
- Exact doc note wording, as long as it preserves historical scores and uses calm truth language.

## Deferred Ideas

- Full YAML parser or broad planning-frontmatter schema library.
- Live verification of GitHub run IDs and artifacts.
- Separate doc-truth ADR.
- Wider closeout CI modernization beyond what Phase 115 needs.
