# Phase 135: CI-Ops Hardening — Release-As Automation (PROOF-03) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-28
**Phase:** 135-ci-ops-hardening-release-as-automation-proof-03
**Areas discussed:** Plan posture, Proof bar, Registration gate

---

## Plan posture (toward already-landed code)

| Option | Description | Selected |
|--------|-------------|----------|
| Audit-then-prove | Read each landed script/workflow, assert against its SC via a proof test, fix only where a SC fails. | ✓ |
| Proof-capture only | Trust landed code; only write proof test + verification doc, never touch scripts. | |
| Re-derive from SC | Ignore landed code; re-plan each SC greenfield, reconcile diffs at the end. | |

**User's choice:** Audit-then-prove
**Notes:** Matches the posture that closed Phases 132/133. Net effect: code mostly unchanged; the deliverable gap is proof artifacts plus any minimal fixes the audit surfaces.

---

## Proof bar (what counts as "proven" given un-hermetic GitHub-side effects)

| Option | Description | Selected |
|--------|-------------|----------|
| Hermetic + structural | Prove deterministic core hermetically (RED→GREEN staleness, strip idempotency); assert GitHub-side wiring structurally (YAML job exists, if:failure() present). Live-fire deferred. | ✓ |
| Live-fire required | No SC closed until exercised against a real release/PR/issue on origin. | |

**User's choice:** Hermetic + structural
**Notes:** Mirrors phase133's doc-presence-assert pattern. Live-fire would stall the phase on the v16.0→origin sync and a real companion release. Per-SC bars recorded in CONTEXT.md D-02.

---

## Registration gate (admin-only branch-protection change, can't run until v16.0 on origin)

| Option | Description | Selected |
|--------|-------------|----------|
| Tooling-proven, registration deferred | Prove registrar (idempotent/green-first) + detector (fail-closed) in-phase; actual registration is an out-of-phase tracked human gate at the sync boundary. | ✓ |
| Registration in-phase | Treat admin registration as a phase task. | |

**User's choice:** Tooling-proven, registration deferred
**Notes:** Preserves "the only intentional human gate is merging the Release PR." Actual `DRY_RUN=0 register_required_checks.sh` deferred to admin after origin sync + lanes green once, per `135-REQUIRED-CHECKS-REGISTRATION.md`.

---

## Claude's Discretion

- Proof-test home: ExUnit `test/crosswake/proof/phase135_*_test.exs` (phase133 pattern) over a standalone CI proof workflow — keeps it in the hermetic suite with one merge-blocking lane.
- Git-tag fixture mechanism for the SC1 RED→GREEN proof (synthetic temp-git-repo vs stubbed tag lookup) — researcher to determine cleanest hermetic approach.
- Optionally schedule the gap detector (`check_required_checks_registered.sh`) with an admin PAT so the declared-but-advisory gap can't silently reopen — planner's call.

## Deferred Ideas

- v16.0 → origin sync (~100-commit catch-up PR, milestone-boundary action).
- Actual required-check registration by an admin after origin sync + lanes green once (the legitimate human gate).
- Live-fire of the real `release-as-cleanup` PR and `release-failure-alert` issue at the next companion release.
- Periodic scheduled run of the gap detector.
