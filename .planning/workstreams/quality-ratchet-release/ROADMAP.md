# Roadmap: Quality Ratchet & Release Readiness

## Milestones

- ✅ **v22.0 Quality Ratchet & Release Readiness** — Phases 164-168 (shipped 2026-09-16)

## Phases

<details>
<summary>✅ v22.0 Quality Ratchet & Release Readiness (Phases 164-168) — SHIPPED 2026-09-16</summary>

- [x] Phase 164: Dependency Security and Gate Authority (5/5 plans) — completed 2026-08-28
- [x] Phase 165: Efficient and Maintainable CI (13/13 plans) — completed 2026-09-09
- [x] Phase 166: Clean-Checkout Engineering Quality (8/8 plans) — completed 2026-09-10
- [x] Phase 167: Documentation and Pull-Request Reconciliation (9/9 plans) — completed 2026-09-12
- [x] Phase 168: 0.2.1 Release Candidate Readiness (13/13 plans) — completed 2026-09-16, 1 item deferred

Full detail: [`milestones/v22.0-ROADMAP.md`](milestones/v22.0-ROADMAP.md)

**Closeout type:** `override_closeout`. Phases 167 and 168 carried `stale` verification at close
(covered files changed after their verification ran), and 9 seeds were deliberately left
unacknowledged. See `MILESTONES.md` for the recorded overrides.

</details>

## Carried into v23.0

Phase 168 met its goal — `crosswake 0.2.1` is live on Hex, SwiftPM and Maven — but closing it
surfaced that the **post-publication proof lane has never executed at any release**. That is one
body of work, not three tickets:

| Item | What it establishes |
|---|---|
| `TODO-009` / `SEED-017` | The release graph is welded to `0.2.1`; any other version tags and then publishes nothing. An interim CI tripwire is on `main`. |
| `TODO-011` | The companion clean-room lane has failed at every release inspected — three releases, three distinct causes. |
| `TODO-012` | The exact-public proof is structurally unsatisfiable: it requires one candidate ref for all six packages, while D-15/D-16 require companions to be versioned independently. |

`SEED-017` is marked **BLOCKING before any release of a version other than 0.2.1** and was
deliberately left unacknowledged at milestone close so it surfaces at v23.0 scoping.

**PR #164 (`chore: release main`, proposing 0.2.2) must not be merged until SEED-017 lands.**
