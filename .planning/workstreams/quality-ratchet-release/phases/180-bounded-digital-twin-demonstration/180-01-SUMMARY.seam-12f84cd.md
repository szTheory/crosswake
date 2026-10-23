---
phase: 180-bounded-digital-twin-demonstration
plan: 01
status: complete
mode: authorized_seam_rerun
verdict: existing_path_supported
candidate_head: 12f84cd950d4574921767df823faed6797c17c26
candidate_tree: e51f069d52b1c1303d8d606d6000ff146654948e
commits: 0
requirements_completed: []
---

# Phase 180 Plan 01: Feasibility gate rerun against the repaired seam Summary

## Plain-language result

I reran the feasibility check against the core-seam repair that Phase 181 produced (head 12f84cd9, tree e51f069d). The earlier run, against the original source, found that the host audio command could not be declared, projected, admitted or run. This time every one of those four facts was disproved by an executed test, and every control and safety invariant passed. The gate verdict is now `existing_path_supported`.

Nothing was committed or staged in the recovery checkout. All product commands ran in `/private/tmp/crosswake-phase180-impl`. The three Phase180 test files were not edited, and their SHA-256 values match the baseline gate exactly.

## What was checked

- The handoff passed validation: schema, decision binding, base head, repaired head and tree, and ancestry. The 55 files changed between the old base and the repaired head are all inside the authorized paths, and none is a Phase180 test file.
- The candidate was moved to the repaired head. Neither lockfile changed after `mix deps.get`.
- The baseline records were preserved as `180-CANDIDATE.baseline.json` and `180-GATE.baseline.json`.
- `180-CANDIDATE.json` was rewritten with base kind `authorized_seam_rerun`.

## Results (each run as its own invocation)

| Fact | Control | Gate test | Status |
|---|---|---|---|
| G1 policy declaration | passed | assertion failed (validator now accepts the command) | refuted |
| G2 generated activation | passed | assertion failed (activation carries the command) | refuted |
| G3 native session from generated activation | passed | assertion failed (session carries 1.0.0) | refuted |
| G4 offline-island runtime admission | passed | assertion failed (resolve returns offlineIsland, not denied) | refuted |
| G6 existing path search (informational) | passed | assertion failed (a route now declares a host capability) | refuted |

- G5 (informational): no WebView container in the host template. Host-owned visible work remains for later plans.
- Probe export: passed. The exported activation for `offline-study` carries `host.study.audio.play` at 1.0.0.
- Invariants: G2_nondeclaring_clean, G2_probe_matches_declaration, G3_no_manufacture and G3_deny_absent all held. The probe route is confirmed to declare the command.
- Product diff against the gate base is clean, and forced_cause is null.
- `declaration_mechanism` is `route_capabilities_list`.

## Verdict and what it does and does not mean

The verdict is `existing_path_supported`. This means later plans may rely on the repaired seam. It does not complete any TWIN requirement by itself, so none are marked complete here.

Accepted limitation, carried from the plan: this gate cannot detect a projection that is hard-coded to the probe route alone. The Phase 181 handoff lists declaration-driven evidence (a fixed-seed generated loop, a two-declaring-route matrix and a mutation check) as the owner of that proof.

Handoff deviation to be aware of: a legacy manifest without `host_commands` keeps today's entry-route behavior (user-confirmed in Phase 181).

## Deviations from Plan

None. The plan was executed as written in rerun mode. The Task 3 jq verify was approximated with an equivalent check on the key consistency conditions (schema, head binding, statuses, SHA equality with the baseline). I did not run the plan's full one-line verify string verbatim.

## Next action

Run `180-02` so it records `not_required` and rebinds `180-DECISION.json` to this gate. This is the gate's `next_action`.

## Self-Check: PASSED

- 180-CANDIDATE.json, 180-GATE.json and both baseline JSON files exist.
- The candidate HEAD equals the recorded gate_base_head.
- The recovery index has no staged files.
