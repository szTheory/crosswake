# Phase 24: Reconciliation Traceability Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 24-reconciliation-traceability-hardening
**Areas discussed:** Normalization scope, REQUIREMENTS.md sync, Re-audit evidence shape, Regression prevention

---

## Normalization Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow: Phase 21 only | Update only `21-01-SUMMARY.md` and `21-02-SUMMARY.md` frontmatter `requirements:` → `requirements-completed:`. Mirrors exactly what the v3.2 milestone audit flagged. | ✓ |
| Sweep: every phase summary | Audit every `*-SUMMARY.md` across all phases; any summary listing requirements gets the canonical key. | |
| Narrow now + canonical key in template | Fix Phase 21 only AND lock the canonical key in any summary template/skeleton so future phases don't drift. | |

**User's choice:** Narrow: Phase 21 only
**Notes:** Smallest possible diff, lowest risk of touching unrelated phase artifacts. Future-drift concern is handled by the deterministic parity test selected in the Regression Prevention area below — that mechanism makes a template-level lockdown redundant.

---

## REQUIREMENTS.md Sync

| Option | Description | Selected |
|--------|-------------|----------|
| A1: Flip bullets + table, leave in current section | Toggle `[ ]` → `[x]` and `Pending` → `Complete` where the lines currently live. No section moves. | ✓ |
| A2: Flip + move RECN bullets to a `### Validated` subsection | Same flips plus move the three RECN bullets to a `### Validated` subsection, mirroring PROJECT.md convention. | |
| A3: Flip + move + Phase 24 traceability note | Same as A2 plus narrative note explaining the validation happened in Phase 21 but the metadata flip is dated Phase 24. | |

**User's choice:** A1 (flip in place) — per research recommendation
**Notes:** REQUIREMENTS.md's native shape is `milestone-section + traceability table at the bottom`; it does not have a `### Validated` subsection. A2/A3 would graft PROJECT.md's structure onto a document that does not use it, creating internal divergence with every other milestone subsection. The Phase-21-validated / Phase-24-normalized distinction is captured in the traceability table cell as `Phase 21 (validated); Phase 24 (traceability normalized)` rather than as narrative prose.

---

## Re-Audit Evidence Shape

| Option | Description | Selected |
|--------|-------------|----------|
| B1: Overwrite `v3.2-MILESTONE-AUDIT.md` | Regenerate the audit doc showing all RECN requirements `satisfied`; replace the original `gaps_found` snapshot. | |
| B2: Capture re-audit only inside `24-VERIFICATION.md` | Leave the milestone audit doc as a historical snapshot; put new evidence only in VERIFICATION.md. | |
| B3: Both — append-only audit doc + cite from VERIFICATION.md | Append `## Re-Audit (Phase 24)` to the audit doc with new `reaudits:` frontmatter; cite that section from `24-VERIFICATION.md`. | ✓ |

**User's choice:** B3 (append-only)
**Notes:** B1 destroys the historical `gaps_found` snapshot that motivated Phases 23 and 24 existing, breaking the audit chain. B2 leaves the audit doc permanently stating `gaps_found` — the next audit-tool or milestone-archival run will re-flag the closed gap with no record that it was addressed. B3 matches Phase 21 D-04's append-only normalized-evidence thesis and Phase 23 D-11's proof-lane evidence preservation posture. The top-level `status:` field is verdict-at-time and must remain unchanged; current state lives in `reaudits[].current_status`.

---

## Regression Prevention

| Option | Description | Selected |
|--------|-------------|----------|
| C1: Fix-and-move-on (no test) | Just fix the frontmatter; optionally add an AGENTS.md or CONTRIBUTING note documenting the canonical key. | |
| C2: Deterministic merge-blocking parity test | Ship `test/crosswake/planning/summary_frontmatter_test.exs` asserting the canonical key shape and requirement-ID existence across all phase summaries. | ✓ |

**User's choice:** C2 (parity test)
**Notes:** Phase 23 D-10 already established deterministic parity tests as the canonical drift-prevention mechanism in this project. The Phase 21 frontmatter drift is exactly the failure mode that C1 cannot prevent — discipline / human review / AGENTS notes are not mechanically enforced and were not enough to prevent this bug. The new test lives at `test/crosswake/planning/summary_frontmatter_test.exs`, creating a `planning/` subsystem directory consistent with existing `guides/`, `support_matrix/`, `doctor/`, `proof/` parity-test layout. It is scoped narrowly to frontmatter key shape and requirement-ID existence — verification status, commit SHAs, completion dates, and plan-number consistency are deferred.

---

## Coherence Posture

All four decisions form one posture: **planning artifacts are product evidence and must be proven mechanically, not by discipline.** Narrow normalization keeps the canonical source (REQUIREMENTS.md) in its native shape so the parity test has a stable schema to validate against. A1 mirrors that same "respect the doc's existing shape" instinct. B3 keeps audit evidence append-only because the project's reconciliation thesis (Phase 21) and drift-prevention thesis (Phase 23 D-10) both reject overwriting evidence and reject advisory-only enforcement. C2 puts the new test in the merge-blocking lane (Phase 23 D-12), matching the existing `test/crosswake/guides/` and `test/crosswake/support_matrix/` parity tests that already protect the same class of "rendered artifact stays in sync with canonical truth" claim. This is the maintainer's OSS DNA — proof lanes as product surface, install/audit truth as honest as the happy path — extended to `.planning/` itself.

## Claude's Discretion

- Exact ExUnit module name, test description strings, and helper decomposition for `summary_frontmatter_test.exs`.
- Exact YAML key naming under `reaudits:` entries (e.g., `evidence_links` vs `commits` vs `references`).
- Exact wording of the `## Re-Audit (Phase 24)` body section beyond requiring the three-source cross-check table and before/after diff cells.
- Whether the parity test reads `REQUIREMENTS.md` via regex or a small helper module.

## Deferred Ideas

- Sweep all phase summaries to enforce canonical key retroactively beyond Phase 21 (handled by the new parity test at commit-time per D-11 with backfill or floor-allowlist if the survey reveals widespread drift).
- Expand the parity test to assert verification status, commit SHAs, completion dates, plan-number consistency — each is a separate parity concern.
- AGENTS.md / CONTRIBUTING note documenting the canonical key — the parity test is mechanical enforcement; a human-facing note would be redundant disclosure that rots.
- Phase 20 VERIFICATION.md contradictions flagged in audit `tech_debt` — different phase, doc-debt rather than traceability-shape.
- Cross-phase reconciliation drift checks between core and example reconciliation paths — contract drift concern, not traceability artifact-shape concern.
