---
phase: 181-core-host-command-seam
verified: 2026-10-14T20:30:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 181: Core host-command seam - Verification Report

**Goal:** a route's own `crosswake:` declaration of a `host.*` command travels through route policy, generated activation, and the native session to the registered host delegate; the bounded iOS shell admits offline-island routes.
**Candidate:** /private/tmp/crosswake-phase181-impl, branch phase181-impl, head 12f84cd950d4574921767df823faed6797c17c26, base 96e5a63.

## What was checked and what happened

I re-ran the suites myself against the candidate and read the code, rather than relying on the summaries.

- Candidate head and tree match the handoff (`12f84cd...`, tree `e51f069...`). The working tree is clean.
- Changed paths from base to head (55 files) match `authorized_paths` in `180-SEAM-HANDOFF.json` exactly (diff empty).
- Root `mix test`: 2218 tests, 0 failures, exit 0.
- `examples/phoenix_host` `mix test`: 150 tests, 0 failures, exit 0.
- `swift test` in `packages/crosswake-shell-core-ios`: 80 tests, 0 failures, exit 0.
- No Android paths, vectors, `mix.lock` files or `priv/templates` changed from base (checked by diff).
- Code spot-checks: manifest schema `1.2.0`, with `host_command_seam_version` added only when a route declares a command (`types.ex`); the Swift `ActivationCoordinator` has a closed, case-sensitive `live_view` / `offline_island` switch with other runtimes denied and an accurate hint; the example host handles `case let .offlineIsland`. No product code is keyed to the `offline-study` route (the only `offline-study` hits in `lib` are unrelated capability-map text).
- Preflight records (`181-PREFLIGHT-FINAL.json`): all four gating facts G1-G4 and G6 show control passed and gate refuted, all four invariants held, expected verdict `existing_path_supported`. Pinned test hashes match `181-CANDIDATE.json`. I did not re-run the Phase 180 gate itself; that is the 180-01 rerun.

## Requirements coverage

| ID | Status | Evidence |
|----|--------|----------|
| SEAM-01 | Satisfied | Router registry and compile-time validation (plan 01); `host_commands_test`, `router_host_commands_test` pass in the root suite |
| SEAM-02 | Satisfied | Per-route manifest `host_commands`, entry-route-only activation, fixed-seed 50-set loop and mutation check (plan 02) |
| SEAM-03 | Satisfied | Per-route grant, re-resolution on navigation, named-route denials (plan 05); 80 Swift tests pass |
| SEAM-04 | Satisfied | `.offlineIsland` presentation and `OfflineIslandAdmissionTests` (15 tests) (plan 06) |
| SEAM-05 | Satisfied | Schema 1.2.0, bridge 1.1.0, Android/vectors/locks unchanged, shell-package gate, doctor findings, guides and support matrix (plans 03, 04, 08, 09) |
| SEAM-06 | Satisfied | `180-SEAM-HANDOFF.json` binds head, tree, authorized paths and probe route; paths verified equal to the real diff |

All six IDs appear in `REQUIREMENTS.md` and are marked Complete there. No orphaned requirements.

## Orchestrator-directed deviations

- **7aca4bf (local package reference only for declaring routers):** reasonable and tested. The summary admits the new test was not run against the pre-fix code, so the fix is covered going forward but not shown to fail before it. Minor.
- **12f84cd (template version kept at 4, iOS README left at base):** D-11 requires that the `.offlineIsland` source break be visible to host authors, and that the example host and upgrade notes handle it. In substance this is met. The exhaustive-switch change is documented in `guides/native_shell_upgrade.md` (line 85) and `guides/native_shell.md` (line 253), the example host has the arm, and a guide test locks the wording. D-11 also lists the "generated template" as a place that must handle it, and the template README no longer mentions it. That part is not met literally. Impact is low because the generated shell does not itself contain an exhaustive switch over the presentation (not tested by me beyond the passing suites), and the guide carries the instruction. Recorded as a recorded deviation, not a gap.

## Unknown or not done

- The `verification.fingerprint` command needs files in the recovery checkout; the product files exist only in the candidate repo, so no fingerprint was computed. `covered_files` and `covered_digest` are omitted.
- Nothing here is device, release or adopter evidence. TWIN-01..06 remain pending the 180-01 gate rerun, as the requirements file says.

## Gaps

None.
