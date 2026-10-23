# Roadmap: Quality Ratchet & Release

## Milestones

- **v25.0 iOS Host Setup & Digital Twin Proof** — phases 179–183; planning closeout complete 2026-10-15; 20/20 requirements, 32 plans, 78 tasks; re-audit `tech_debt` with no blocker. Product code stays in the `/private/tmp` candidate pending a separately authorized delivery. [Archive](milestones/v25.0-ROADMAP.md).
- **v24.0 Repository Cleanup & Maintenance** — phases 176–178; planning closeout complete 2026-10-12; 8/8 requirements, 15 plans, 28 tasks; six retained debt records. [Archive](milestones/v24.0-ROADMAP.md).
- **v23.0 Release Pipeline Repair & Proof-Lane Truth** — phases 169–175, archived with exceptions 2026-10-11; 42/43 requirements; REL-10 breached. [Archive](milestones/v23.0-ROADMAP.md).
- **v22.0 Quality Ratchet & Release Readiness** — phases 164–168, archived with overrides 2026-09-15. [Archive](milestones/v22.0-ROADMAP.md).

## Phases

<details>
<summary>v25.0 iOS Host Setup & Digital Twin Proof (Phases 179–183) — planning closeout 2026-10-15</summary>

- [x] Phase 179: iOS Host Setup Without Hand Patches (4/4 plans) — completed 2026-10-13
- [x] Phase 180: Bounded Digital Twin Demonstration (7/7 plans) — completed 2026-10-15
- [x] Phase 181: Core Host-Command Seam (10/10 plans) — completed 2026-10-14
- [x] Phase 182: Loopback Origin for Local iOS Host (6/6 plans) — completed 2026-10-14
- [x] Phase 183: Close gap: twin source binding fails closed on uncommitted code (5/5 plans) — completed 2026-10-15

</details>

## Exact Next Action

`$gsd-new-milestone --ws quality-ratchet-release`

Last completed phase: **183**, complete at 5/5 plans and 6/6 verification. No active phase remains; v25.0 planning closeout is complete. Choose fresh scope through the next-milestone workflow; numbering continues after 183. Do not repeat the completed phases, audit or closeout.

The [closeout record](milestones/v25.0-closeout/CLOSEOUT.md) and [debt disposition](milestones/v25.0-closeout/debt-disposition.md) carry the open items forward. Two can degrade silently on the next twin run (183 WR-01 index flags, WR-02 filemode); fix them in the next twin-touching change before run root twin-05. Delivering the candidate commits needs separate authorization. Recovery-checkout staging, commits, tags and branch/worktree changes remain prohibited. Adopter work stays parked on its recorded external gate.
