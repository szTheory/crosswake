# Roadmap: Quality Ratchet & Release

## Milestones

- ✅ **v27.0 Land and Clean Up** — phases 189–193; shipped 2026-10-24; 18/18 requirements, 55 plans, 127 tasks; audit `tech_debt` with no blocker. The v25 and v26 work is on GitHub `main` with CI green (PR #242, merge `d12aed75`), the recovery checkout was retired for a clean `main` checkout, and changes now land through PRs branched from `main`. [Archive](milestones/v27.0-ROADMAP.md).
- **v26.0 Harden Before Trust** — phases 184–188; planning closeout complete 2026-10-16; 18/18 requirements, 37 plans, 96 tasks; audit `tech_debt` with no blocker; twin-05 passed against the frozen candidate `a53fbef`. The product code was delivered to `main` in v27.0. [Archive](milestones/v26.0-ROADMAP.md).
- **v25.0 iOS Host Setup & Digital Twin Proof** — phases 179–183; planning closeout complete 2026-10-15; 20/20 requirements, 32 plans, 78 tasks; re-audit `tech_debt` with no blocker. The product code was delivered to `main` in v27.0. [Archive](milestones/v25.0-ROADMAP.md).
- **v24.0 Repository Cleanup & Maintenance** — phases 176–178; planning closeout complete 2026-10-12; 8/8 requirements, 15 plans, 28 tasks; six retained debt records. [Archive](milestones/v24.0-ROADMAP.md).
- **v23.0 Release Pipeline Repair & Proof-Lane Truth** — phases 169–175, archived with exceptions 2026-10-11; 42/43 requirements; REL-10 breached. [Archive](milestones/v23.0-ROADMAP.md).
- **v22.0 Quality Ratchet & Release Readiness** — phases 164–168, archived with overrides 2026-09-15. [Archive](milestones/v22.0-ROADMAP.md).

## Phases

<details>
<summary>✅ v27.0 Land and Clean Up (Phases 189–193) — SHIPPED 2026-10-24</summary>

- [x] Phase 189: Inventory and backup (13/13 plans) — completed 2026-10-18
- [x] Phase 190: Fix warnings before landing (10/10 plans) — completed 2026-10-19
- [x] Phase 191: Integration branch and local suite (12/12 plans) — completed 2026-10-23
- [x] Phase 192: PR, CI and merge (10/10 plans) — completed 2026-10-23
- [x] Phase 193: Cleanup and new working rules (10/10 plans) — completed 2026-10-24

</details>

<details>
<summary>v26.0 Harden Before Trust (Phases 184–188) — planning closeout 2026-10-16</summary>

- [x] Phase 184: Twin probe and safe preflight (15/15 plans) — completed 2026-10-16
- [x] Phase 185: Checks that cannot pass empty (5/5 plans) — completed 2026-10-16
- [x] Phase 186: Host seam and harness honesty (5/5 plans) — completed 2026-10-16
- [x] Phase 187: Doctor and proof fidelity (7/7 plans) — completed 2026-10-16
- [x] Phase 188: Freeze and twin-05 (5/5 plans) — completed 2026-10-16

</details>

<details>
<summary>v25.0 iOS Host Setup & Digital Twin Proof (Phases 179–183) — planning closeout 2026-10-15</summary>

- [x] Phase 179: iOS Host Setup Without Hand Patches (4/4 plans) — completed 2026-10-13
- [x] Phase 180: Bounded Digital Twin Demonstration (7/7 plans) — completed 2026-10-15
- [x] Phase 181: Core Host-Command Seam (10/10 plans) — completed 2026-10-14
- [x] Phase 182: Loopback Origin for Local iOS Host (6/6 plans) — completed 2026-10-14
- [x] Phase 183: Close gap: twin source binding fails closed on uncommitted code (5/5 plans) — completed 2026-10-15

</details>

## Exact Next Action

Next: `$gsd-new-milestone --ws quality-ratchet-release`. v27.0 is archived and no scope is selected yet. Carried debt is in the [v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md). The adopter lane stays parked on its external gate.
