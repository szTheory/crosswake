---
phase: 180-bounded-digital-twin-demonstration
plan: 01
status: complete
mode: candidate_move_rerun
verdict: existing_path_supported
candidate_head: da53c54db06e54be5a80fb4be144a70d3fed36a5
candidate_tree: d1cbbe30ffca9da79c5506004ad2bf8c8da38665
commits: 0
plan_head_before: none (planning files only; no commits by D-27)
plan_head_after: none
requirements_completed: []
---

# Phase 180 Plan 01: Feasibility gate rerun on the Phase 182 candidate head Summary

## Plain-language result

Phase 182 moved the candidate clone from 12f84cd9 to da53c54d (tree d1cbbe30). I reran the whole feasibility check there. Result is the same as before: the gate verdict is `existing_path_supported`. All four gating facts (G1 to G4) were disproved by executed tests, every control passed, and all four safety invariants held.

Nothing was staged or committed in the recovery checkout. All product commands ran in `/private/tmp/crosswake-phase180-impl`. The three Phase180 test files were not edited.

## What was checked before running

- Candidate HEAD and tree match the move record; 12f84cd9 is an ancestor of HEAD.
- 21 uncommitted carried paths present, as recorded.
- The three Phase180 test files' SHA-256 values equal the move record and the previous gate.
- The 33 files changed between 12f84cd9 and da53c54d are exactly the move record's core_diff_paths; none is a Phase180 test file.
- `mix deps.get` in the root and the example host changed neither lockfile.

## Results (each run as its own invocation, control before gate)

| Fact | Control | Gate test | Status |
|---|---|---|---|
| G1 policy declaration | passed | assertion failed (validator accepts the command) | refuted |
| G2 generated activation | passed | assertion failed (activation carries the command) | refuted |
| G3 native session from generated activation | passed | assertion failed (session carries 1.0.0) | refuted |
| G4 offline-island runtime admission | passed | assertion failed (resolve returns offlineIsland) | refuted |
| G6 existing path search (informational) | passed | assertion failed (a route declares a host capability) | refuted |

- G5 (informational): the host template has no WebView container; that stays host-owned work.
- Probe export passed; the exported activation for `offline-study` carries `host.study.audio.play` at 1.0.0.
- Invariants all held: G2_nondeclaring_clean, G2_probe_matches_declaration, G3_no_manufacture, G3_deny_absent.
- `declaration_mechanism` is `route_capabilities_list`; forced_cause is null.

## Deviations from Plan

**Product-diff basis (judgement call, flagged).** The plan defines `product_diff_clean` as an empty `git diff HEAD` over product paths. At 12f84cd9 that was empty. Now ten product files under `lib/` and `examples/phoenix_host/lib/` are dirty, because plans 180-03 and 180-04 already wrote them. They are not changes made by this gate. I checked that each of the ten matches the sha256 in the Phase 182 move record, that no other product path is dirty, and that the full `git diff --binary HEAD` hash equals the move record's value (e208f105...). On that basis I recorded `product_diff_clean: true` and wrote the reasoning into `product_diff_basis` in 180-GATE.json. If you want the stricter literal reading, the verdict would instead read as blocked, so please confirm you accept this basis.

Also: the plan's one-line Task 3 jq verify was not run verbatim; I checked the same conditions individually (head binding, statuses, SHA equality, GATE_CHECK for 180-05).

## What changed (planning files only, uncommitted)

- Preserved byte for byte: `180-CANDIDATE.seam-12f84cd.json`, `180-GATE.seam-12f84cd.json`, `180-01-SUMMARY.seam-12f84cd.md`, `180-DECISION.seam-12f84cd.json`, `180-02-SUMMARY.seam-12f84cd.md`.
- Rewritten: `180-GATE.json` (rerun_kind candidate_move_rerun), `180-CANDIDATE.json` (gate base moved to da53c54d), `180-DECISION.json`, this summary and `180-02-SUMMARY.md`.

## Unknown

No twin runtime check has run, and no TWIN requirement is complete.

## Next action

Run `$gsd-execute-phase 180 --ws quality-ratchet-release` so 180-05 reruns from Task 1.

## Self-Check: PASSED

- All five `*.seam-12f84cd.*` copies exist and match the earlier records.
- Candidate HEAD equals the recorded gate_base_head; test file hashes match.
- The recovery index has no staged files.
