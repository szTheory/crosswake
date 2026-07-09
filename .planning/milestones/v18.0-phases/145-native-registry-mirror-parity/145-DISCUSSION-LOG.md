# Phase 145: Native Registry & Mirror Parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-08
**Phase:** 145-Native Registry & Mirror Parity
**Areas discussed:** Mirror token strictness, iOS v0.2.0 backfill path, Backfill source of truth, Partial native failure reporting

---

## Mirror Token Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Non-empty + `git ls-remote` read preflight | Catches absent secrets and obvious auth failures, but read access can pass with a token that cannot push. | |
| Write-authority dry-run probe | Keeps existing checks and adds non-mutating `git push --dry-run --porcelain` before the real push. Catches the SEED-003 wrong-scope token class earlier. | ✓ |
| Fail at actual push with better copy | The real push is authoritative and simple, but it is not fail-fast and repeats the partial-release pain this phase exists to prevent. | |

**User's choice:** Discuss all; Claude researched and selected the write-authority dry-run probe.
**Notes:** Subagent research favored `Contents:write` on the mirror repo via fine-grained PAT or GitHub App. Routine scratch-ref mutation was rejected as too noisy for normal release, but may be useful in deliberate fire-drills.

---

## iOS v0.2.0 Backfill Path

| Option | Description | Selected |
|--------|-------------|----------|
| Runbook-only manual commands | Fastest, but easy to run from the wrong ref and likely to drift. | |
| Maintained verify-first script | Idempotent, exact-ref, reusable from docs/CI/Phase 146, and can default to verify-only before mutation. | ✓ |
| `workflow_dispatch` wrapper | Good operator UX and secret handling when it delegates to the maintained script. | ✓ |
| Rerun existing release job | Familiar UI, but surprising and unsafe as the primary path because it can re-enter immutable registry work. | |

**User's choice:** Discuss all; Claude selected script-first with a thin dispatch wrapper.
**Notes:** The workflow wrapper should not duplicate logic. Runbook-only commands should remain break-glass appendix material.

---

## Backfill Source Of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Current `main` or checkout | Simple but can tag unreleased or later source as `v0.2.0`. | |
| Release Please component ref | Reproducible and tied to the release commit. Prefer `refs/tags/ios-core-v0.2.0`. | ✓ |
| `.release-please-manifest.json` | Correct version/lockstep truth but not commit/source truth. | ✓ |
| Registry dates or public package state | Useful audit evidence, not write authority for the SwiftPM mirror. | |

**User's choice:** Discuss all; Claude selected Release Please ref as write authority, with manifest and registry checks as invariants.
**Notes:** Local verification showed `hex-v0.2.0`, `ios-core-v0.2.0`, and `android-core-v0.2.0` point to `232a37ddeb32ab526142510fb71d746d2e10dc12`. Local subtree split corroborated expected iOS split SHA `658d60253c58b7e0aedb576f16f40766fa677f23`; planners should confirm through the pinned CI splitter path before writing.

---

## Partial Native Failure Reporting

| Option | Description | Selected |
|--------|-------------|----------|
| Job graph only | Zero code, but poor incident clarity and easy to misread skipped jobs. | |
| Human summary/failure alert | Names per-platform state and next action in the Actions UI. | ✓ |
| Machine-readable status artifact | Gives Phase 146 structured evidence without implementing the full local status command now. | ✓ |
| Block all native completion on one platform failure | Simple all-or-nothing story, but violates MIRR-02 by letting iOS failure suppress Android proof. | |
| Independent proofs + honest aggregate status | Lets unaffected proof finish while reporting `native_core=partial` when one platform fails. | ✓ |

**User's choice:** Discuss all; Claude selected independent proofs plus an always-running rollup summary and narrow JSON artifact.
**Notes:** The aggregate should be honest enough for support truth: Android can be `success` while the native family is `partial` until SwiftPM is repaired.

---

## Claude's Discretion

- Exact script names, JSON field names, and workflow file placement are left to planner/executor discretion.
- Mutation/backfill stays in scripts/workflows; Phase 146 can expose local status via Mix task.
- The planner should keep check IDs stable and actionable, but may choose exact names close to the suggested IDs in CONTEXT.md.

## Deferred Ideas

- Full `mix crosswake.release.status` text/JSON/live-probe completion remains Phase 146.
- Graphical dashboard/operator UI remains DASH-01.
- Broader native registry recovery beyond the iOS `v0.2.0` gap is deferred unless required for MIRR-02 truth.
