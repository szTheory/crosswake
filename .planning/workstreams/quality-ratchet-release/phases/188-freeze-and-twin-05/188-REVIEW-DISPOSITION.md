---
phase: 188-freeze-and-twin-05
review: 188-REVIEW.md
critical: 0
warning: 8
info: 3
recorded: 2026-10-16
---

# Phase 188 review disposition

The standard-depth review covered the nine new Phase 188 scripts, using the byte-equal copies in `scripts/`. The unchanged `prepare-record.sh` was not in scope. It found no critical issue. It confirmed that the `set -C` sentinel is atomic, the gate record is written with noclobber, `verify_twin` runs exactly once with the same argument vector as the preflight, and any `not_run` or `fail` label is a no-go. The review ran after twin-05 had already run once and passed, and no finding invalidates that run. For each finding that could have affected it, the note below says what the actual run did. Phase 188 changes no product code, and these scripts are single-use run tooling. Fixes therefore belong to whatever later twin-touching change reuses them (twin-06 or later). No finding blocks completion.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| WR-01 | warning | open (not triggered) | An empty directory, or one holding only symlinks, scans as `files 0, hits 0` with exit 0 instead of a scope error. Every real scan in this phase had a non-empty scope: 1 file before the copy, 24 files in the run-root scan, 18 files in the early scan and 26 files in the blocking scan. Fix in the next reuse: count the expanded regular files and exit 2 on zero. Successor: Phase 190 scripts/scan-privacy-190.sh (FIX-01), self-tested by selftest-scan-190.sh. |
| WR-02 | warning | accepted (by design, D-17 ruling W1) | The credential class is case-sensitive and narrow. D-17 ruling W1 locked these exact classes and "never grep -i", so the scan matches what was decided. A wider credential class is a policy change for the next privacy-scan revision. |
| WR-03 | warning | accepted with note | `assert-twin-05.sh` checks shape and the receipt digest, not the commit. The twin-05 receipt and result carry no head or tree. The binding to the freeze comes from the run lineage instead: gate record `go-no-go-05.1.json` (`head_equals_freeze`, `head_equals_record` and `tree_equals_record` all passed), the sentinel, `twin-run-path-05`, the `source` identity join that `verify_twin` checks against `twin-05-candidate.json`, and run id `twin-037ff19e6d010e32` appearing in both receipt and result. 188-TWIN-RECORD.md states the head and tree from those records. A later change could add the head to the receipt schema. |
| WR-04 | warning | accepted (owner bound covered it) | The script's 2700-second deadline is checked only after the checks finish. The plan's outer owner bound (3300 seconds, stopping the process group and writing `gate-stalled-05`) is the guard against a hang, and 188-05 held it. In the actual run the gate reached the sentinel at 21:20:12Z, well inside both bounds. |
| WR-05 | warning | open (not triggered) | Port, simulator and root state are not re-read immediately before the sentinel (a window between check and use). The orchestrator checked separately before the launch: port 4790 free, 0 leftover Simulators. The run passed and the candidate stayed unchanged after it. Fix in the next reuse. |
| WR-06 | warning | open (not triggered) | On a colliding attempt number, `: > "$LOG"` could truncate an earlier gate log before noclobber refuses. Only attempt 1 ran, with no earlier records. |
| WR-07 | warning | open (not triggered) | `l_port` reads a missing or erroring `lsof` as "no listener". `lsof` is present on this host, and the orchestrator's own check found no listener on 4790. |
| WR-08 | warning | open | Selftest controls never make some gate labels fail (`port_4790_free`, `no_leftover_simulator`, `simulator_runtime_available`, `run_env_unsets_build_and_db`, `head_equals_record`, `tree_equals_record`, the 87-count check). "31 of 31" therefore asserts less than the 30-label gate implies. Add negative controls for each label in the next reuse. Successor: Phase 190 scripts/selftest-190.sh (FIX-02), coverage derived from the gate source. |
| IN-01 | info | open | `refresh-handoffs-188.sh` updates the two records non-atomically. It ran once successfully, and its pre-188 copies and the refreshed records verified. |
| IN-02 | info | open | The freeze script does not re-check cleanliness after `mix run`, and `make-identity-188.sh` takes no freeze SHA and loses one error message. The candidate porcelain was 0 bytes after every step. |
| IN-03 | info | open | Uses macOS-only `stat -f`, and the history manifest and handoff `candidate_path` carry absolute paths. The paths are under the run directory in `/private/tmp` and outside the D-17 home and temp classes, and every planning-bound scan found 0 hits. |

Integration item (the gate's g() was not pinned like the Elixir funnel): successor Phase 190 scripts/git-pinned-190.sh (FIX-03), checked against the funnel by gitpin-compare-190.sh.

Out of scope, no successor: scripts/freeze-check-188.sh keeps its unpinned g(); it is a one-time twin-05 record that no candidate, CI or release path runs, and at most the Phase 188 records self-test runs it against fixture roots; any future rerun must use scripts/git-pinned-190.sh from Phase 190.

Out of scope, no successor: scripts/make-identity-188.sh keeps its unpinned g(); it is a one-time twin-05 record that no candidate, CI or release path runs, and at most the Phase 188 records self-test runs it against fixture roots; any future rerun must use scripts/git-pinned-190.sh from Phase 190.

Out of scope, no successor: scripts/prepare-record.sh keeps its unpinned g(); it is a one-time twin-05 record that no candidate, CI or release path runs, and at most the Phase 188 records self-test runs it against fixture roots; any future rerun must use scripts/git-pinned-190.sh from Phase 190.

Out of scope, no successor: scripts/refresh-handoffs-188.sh keeps its unpinned g(); it is a one-time twin-05 record that no candidate, CI or release path runs, and at most the Phase 188 records self-test runs it against fixture roots; any future rerun must use scripts/git-pinned-190.sh from Phase 190.

