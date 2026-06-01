# Phase 53: Release Continuity and Closeout Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 53-Release Continuity and Closeout Hardening
**Areas discussed:** Release/changelog truth, Deterministic closeout verification, Next-milestone handoff

---

## Initial Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| All three | Cover release/changelog truth, deterministic closeout verification, and next-milestone handoff in one pass. | ✓ |
| Release truth | Focus only on how Unreleased vs published Hex support claims should be represented. | |
| Closeout gate | Focus only on what the deterministic closeout verifier should fail on and what remains human judgment. | |

**User's choice:** Discuss all areas with subagent-backed research, deep
pros/cons/tradeoffs, ecosystem lessons, prompt-corpus context, and one coherent
recommendation set.

**Notes:** User requested recommendation-first synthesis so routine decisions
would not require additional back-and-forth.

---

## Release/Changelog Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Rich `[Unreleased]` taxonomy | Keep `CHANGELOG.md` as canonical public history with explicit claim categories. | ✓ |
| Separate release support ledger | Add a second guide/ledger for support claims and keep changelog lean. | |
| Doctor-derived generated release truth | Generate or validate release claim truth from support/readiness contracts. | ✓ |
| Minimal changelog only | Keep simple version headings and brief bullets. | |

**User's choice:** Agent recommendation accepted: rich changelog-first public UX
plus doctor/check-derived claim validation.

**Notes:** Advisor research favored an Option A + Option C hybrid: `CHANGELOG.md`
stays canonical, but deterministic checks enforce published-vs-unreleased truth
and known non-claims.

---

## Deterministic Closeout Verification

| Option | Description | Selected |
|--------|-------------|----------|
| ExUnit-only planning tests | Enforce closeout through focused tests under `test/crosswake/planning`. | |
| Mix `closeout.verify` plus tests | Expose maintainer-friendly command backed by the same shared validator tested in ExUnit. | ✓ |
| `gsd-sdk` external script | Enforce through GSD tooling outside the Elixir project surface. | |
| Docs-only checklist | Rely on closeout prose/checklist discipline. | |

**User's choice:** Agent recommendation accepted: shared Elixir validator,
`mix closeout.verify` wrapper, and ExUnit enforcement.

**Notes:** Research emphasized idiomatic Mix/Phoenix DX, Django-style stable
check ids and hints, Terraform-style validation, and avoiding duplicate
validator logic between task and tests.

---

## Next-Milestone Handoff

| Option | Description | Selected |
|--------|-------------|----------|
| Update PROJECT/MILESTONE-ARC/STATE only | Minimal transition without archive/reset boundary. | |
| Archive/reset active milestone to v3.7 Phase 48 | Clear milestone cut line and deterministic next-step routing. | ✓ |
| Thin release-continuity handoff doc | Optional pointer-first artifact for context clears. | ✓ |
| Rely on GSD generated state only | Let tool state carry continuity without explicit release artifacts. | |

**User's choice:** Agent recommendation accepted: archive/reset as the primary
boundary, with a constrained pointer-style handoff only if it improves
continuity.

**Notes:** Research emphasized Ecto migration-ledger discipline, Rails/Django
upgrade/release guidance, Kubernetes/Terraform release choreography, and avoiding
duplicate strategic queues.

---

## the agent's Discretion

- Exact module names and check ids are left to the planner if stable,
  deterministic, and tested.
- Exact changelog subsection headings are planner discretion if they keep Hex
  published truth, unreleased support truth, advisory/verification-required
  posture, and deferred non-claims separate.
- Exact handoff artifact shape is planner discretion; default bias is
  pointer-first and no duplicate source of truth.

## Deferred Ideas

None.
