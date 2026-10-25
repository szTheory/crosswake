---
updated: 2026-10-24
active_milestone: v28.0
priority_order_ref: AGENTS.md#Current-Priority
---
# Rolling Roadmap

Crosswake is infrastructure for the First B2C Adopter; synthetic adopter profiles are the proving
ground while that lane is parked. Arc: land truth, then prove Android and the host seams, then the
newcomer path. Horizon is confidence, not dates. Effort is S/M/L; adr is none, amends or reopens;
the promotion trigger is the entry condition. Plan and phase counts are approximate (`~`).

## NOW

| ID | Outcome | Horizon | Effort | adr | Promotion trigger |
|---|---|---|---|---|---|
| v28.0 Truth and Release Train | Main and PR queue clean; release PR green without hand edits and released (one `allow` per publish); public docs true; sensitive-module specs hardened; Android unfrozen (proof and parity of existing contracts) with one foreign-host proof. Appetite: 6 phases (194-199), ~20 plans. Exit: bearings-report green, release published, docs.verify clean. | now | L | amends (A1 Android, A2 synthetic-profile gate) | promoted 2026-10-24 by v28.0 scope approval |

## NEXT

| ID | Outcome | Horizon | Effort | adr | Promotion trigger |
|---|---|---|---|---|---|
| v29.0 Android Proof | Toolchain bump with templates in one PR; ktlint advisory; emulator advisory lane; P1 offline-study journey on emulator; manifest host-command seam read (additive, versioned); weekly hygiene workflow. ~5 phases. | next | L | amends (Android disposition in Upgrade Impact) | v28 closed; Android JVM proof green; user says yes. Outward: moves matrix cells for P7. |
| v30.0 Twin and Host Trust | Twin identity debt closed; receipt binds head and tree; twin run on main; host-run webview conformance; first Hostile Host rows; iOS brownfield leg of the clean-room run. ~5 phases. | next | L | none | v29 closed; user approves the twin run (macOS time). Outward: device-class blind spots. |
| v31.0 Newcomer Path | README top third for evaluators; one-page first-route guide; doctor-to-troubleshooting bijection; DSL tiering doc; maintainer tasks hidden; clean-room as a CI lane after two clean runs. ~4 phases. | next | M-L | none | v30 clean-room green twice; newcomer measures recorded. Outward: raises P1 grade. |

## LATER

| ID | Outcome | Horizon | Effort | adr | Promotion trigger |
|---|---|---|---|---|---|
| Property tests | Cross-shell differential corpus and a test-only generator dependency decision | later | M | none | Muex pilot survivors show boundary gaps, or a seeded loop proves inadequate |
| Weekly advisory Muex run | Then PR-scoped runs; Kotlin and Swift mutation pilots | later | M | none | Muex pilot adopted and a 4-week stable baseline |
| L2 split | Move proof_lane, release_candidate, planning, support_matrix out of the Hex tarball; tarball allowlist | later | L | none | v31 done; layer-direction test exists; core-first DAG rehearsal planned |
| Module splits and renames | Doctor/ActivationCoordinator split; phase_N renames; provenance-comment strip, per file | later | M | none | Touching the file for another reason |
| Scenario catalog | Generated capability matrix with a platform axis; rename-by-capability aliases | later | M | none | A second profile row set is needed (Hostile Host rows exist) |
| Doc system | Generated companion matrix, doctests on pure modules, claims cite proof, guide audience split | later | M-L | none | docs.verify stable for one cycle |
| Commerce extraction | Move commerce to a companion (not productionization) | later | M | amends | A profile shows a core-names-companion defect, or the L2 split starts |
| PROJECT.md split (E4) and capability taxonomy move | Split the long project file; move the capability taxonomy out of MILESTONE-ARC | later | M | none | bearings-report reports PROJECT.md over 250 lines |
| Seed frontmatter normalization and fires_when backfill (E7) | Uniform seed frontmatter with evaluable triggers | later | S | none | A seed trigger is missed at a milestone start |
| Closeout debt-row template with owner/trigger/receiver (E6) | Every deferral names an owner, a trigger and a receiver that can act | later | S | none | The next milestone closeout |
| Notification re-entry corridor | Re-entry via push, only if a synthetic journey needs it | later | M | reopens | ADR A2 gate passed with a cited artifact |

## PARKED

| ID | Outcome | Horizon | Effort | adr | Promotion trigger |
|---|---|---|---|---|---|
| First B2C Adopter readiness (v21) | Real sanitized route rows and the physical-iPhone path | parked | L | none | Adopter public-v1 mobile path active; resume with `--ws first-b2c-adopter-readiness` |
| Android physical-device proof | Device evidence for Android | parked | L | none | An adopter commits Android scope; new milestone after the v29 emulator ceiling |
| Physical-iPhone exit test | One real iPhone run | parked | M | none | External gate above plus device availability; existing driver, new run |

## DROPPED

| ID | Outcome | Horizon | Effort | adr | Promotion trigger |
|---|---|---|---|---|---|
| Capture packs, generic or background sync, generic native storage, dashboard | No persona evidence | dropped | L | none | Reopen only via an amendment citing a measured gap |
| In-repo AST mutation harness; Credo/dialyzer as merge gates | Wait for a Muex pilot failure; noise at this size | dropped | M | none | Muex pilot fails, or finding counts measured low |
| Per-persona host apps and twins; merge queue | ADR forbids host apps; PR volume too low | dropped | M | none | PR volume reaches ~3 per day |
| LiveView-driven native rendering, on-device BEAM, write-once | Against the thesis | dropped | L | none | Thesis change by ADR |
| Superseded root JTBD ordering (commerce, notification, operator, auth and native families) — not executed | Replaced by PERSONAS.md and this file | dropped | M | none | ADR A2 gate per family |
| Milestone-start byte-snapshot ritual (history/vNN-before-vMM-start + sha256) | Planning lives on main; git is the snapshot | dropped | S | none | planning leaves main |

## Loop rules

- Promote only in the new-milestone loop; an item that ships partially is re-pitched or dropped, never auto-carried.
- A row unchanged for 3 milestones is demoted. Seeds are minted only for ideas; review residue becomes debt rows.
- Milestone start: no byte-copy snapshot of planning files; planning lives on main and git is the snapshot.
- Android unfrozen applies to proof and parity of existing contracts only (ADR A1, on main since PR #247).
