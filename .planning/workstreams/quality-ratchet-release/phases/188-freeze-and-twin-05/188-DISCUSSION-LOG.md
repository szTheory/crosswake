# Phase 188 discussion log

**Date:** 2026-10-16
**Mode:** advisor (minimal-decisive tier), four parallel research agents
**For human reference only.** Downstream agents read `188-CONTEXT.md`.

## Areas researched

All four areas were researched without a selection prompt. With the command, the owner gave a fan-out brief: consider every relevant lens (release engineering and SRE, security and fail-closed design, test-of-record, privacy, Elixir idiom, an adversarial pass), prefer primary sources, prefer copying code to adding a dependency, then synthesize one coherent set of recommendations and follow it without per-area questions.

| Area | Question |
|------|----------|
| Pre-freeze fix scope | Fix 186 WR-01/WR-02, 187 WR-02 and the others before the freeze, or disclose them as limits? |
| Freeze shape and refresh | What is "one frozen candidate commit"? Where does the handoff refresh live? |
| Go/no-go and the single run | What are the prepared record, the gate checks, the exactly-once mechanism and the way the root is created? |
| Result capture and failure | Where do the fidelity limits go? How is the result copied, what is the privacy rule, how are counts asserted, and what is the failure policy? |

## Recommendations adopted

| Area | Options weighed | Adopted |
|------|-----------------|---------|
| Fix scope | (A) freeze as is, disclose and defer; (B) fix 186 WR-01/02 and 187 WR-02; (C) fix everything | A. No open item that fails open lies on the Simulator twin path; scripted preconditions replace the fixes (D-04, D-07). |
| Freeze commit | HEAD `a53fbef` cumulative tree / new fix(188) commit / squash | HEAD `a53fbef` (D-01) |
| Refresh location | run-dir script / phase-dir script / candidate script or mix task | run-dir script, byte-copied into the phase dir (D-08, D-09) |
| Go/no-go shape | one gate+run script / separate scripts / candidate mix task | one `run-once-05.sh` in the run dir (D-12) |
| Exactly-once | noclobber `.started` sentinel / receipt refusal only | sentinel, with the receipt refusal as a backstop (D-12, D-14) |
| Root creation | separate `mkdir -m 0700` step / created by the script | separate step (D-13) |
| Limits home | planning sidecar / edit `@fidelity_limits` | sidecar `188-TWIN-RECORD.md` (D-19) |
| What to copy | result JSON only / plus logs | result JSON only, plus a privacy scan (D-17) |

## Adversarial reconciliation by the orchestrator

- Two agents put the scripts in different places: the run dir and the phase dir. Resolved to the run dir, because `run-once-04.sh` and `prepare-record.sh` live there next to the twin roots, with byte-copies into the phase dir as evidence.
- One agent asked for the open off-path warnings to be listed as twin limits. They go in a separate "not exercised by twin-05" list so the twin limits stay precise (D-19).
- One agent reported no description of DEF-SNAP. FEATURES.md and CHALLENGE M7 show that DEF-SNAP is the edit-and-revert limit, which is already receipt limit 5.
- The orchestrator verified the agents' factual claims directly: the candidate HEAD is `a53fbef` and its status is clean; `twin-05` does not exist; the history manifest has 87 lines and includes `183-TWIN-RESULT.json`; the precedent scripts are present.

## Claude's discretion

Script and label names, the plan split, and the `jq` and privacy-regex details are left to the planner (see CONTEXT).

## Deferred

See `188-CONTEXT.md` `<deferred>`.
