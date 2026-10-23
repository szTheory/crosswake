# Phase 169: Diagnostic Legibility - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-15
**Phase:** 169-diagnostic-legibility
**Areas discussed:** "Never ran" emission model, Foreign-failure blast radius, Rename + uniqueness sequencing, Exit-code vocabulary (FID-02)

**Mode:** advisor (USER-PROFILE.md present), calibration tier `minimal_decisive`,
`NON_TECHNICAL_OWNER = false` (overridden by `technical_background: true`).
Four `gsd-advisor-researcher` subagents ran in parallel, one per area, at the maintainer's explicit
request for research-backed pros/cons/tradeoffs, ecosystem precedent, and a single coherent
one-shot recommendation set.

---

## Empirical Check That Reframed Three Of The Four Areas

Two subagent reports disagreed about what happens on a failing scanner run, so the orchestrator
verified it directly rather than adjudicating on authority.

```
# clean main
elixir script/check_release_workflow_integrity.exs
→ 68 [crosswake] lines, 68 OK, 0 FAIL, exit 0

# PR #164 drift condition
RELEASE_PLEASE_MANIFEST_PATH=<manifest with "." = "0.2.2"> elixir script/check_release_workflow_integrity.exs
→ 68 [crosswake] lines, 67 OK, 1 FAIL, exit 1

# required-ID drift
comm -23 <27 required IDs> <68 emitted IDs> → empty
```

`SUMMARY.md` divergence #2's causal chain ("scanner exits non-zero → later checks never emit →
`missing != []` fires first") is false at both links. Recorded in CONTEXT.md under
`<verified_ground_truth>`, which supersedes it. Consequence: MSG-01 is confirmed live, MSG-03 is
latent-not-live, and MSG-02's success-criterion phrasing describes an unreachable state.

---

## "Never ran" emission model

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Stream each check as computed + up-front ROSTER | Break the eager list literal into sequential evaluation so a crash leaves a truthful partial tail | |
| (B+) Keep eager evaluation; add static ROSTER line + terminal DONE sentinel + roster-exactness self-check | Additive stdout verbs; consumer splits into three labeled buckets | ✓ |

**User's choice:** (B+), via "Lock all four".
**Notes:** (A) was rejected because it changes the scanner's failure semantics — today a crash
asserts nothing; streaming manufactures a partial run in which ~40 already-printed `OK:` lines are
greens from an aborted process, which a maintainer skimming red CI reads as a clean run. That is the
project's own "right failure, wrong explanation" pitfall, manufactured by the phase meant to end it.
It also costs ~62 mechanical edit sites in a phase chartered as fully reversible. TAP's `1..N` plan
line adopted as the ROSTER precedent; its footgun (silently tolerating plan/emission mismatch)
neutralized by making mismatch a hard `FAIL: release.scanner.roster_exact`. Rejected outright:
switching to `--format=json`, which breaks the regex contract and 7 `phase142` assertions for no
diagnostic gain. MSG-02's microcopy restated to "0 of 68 roster checks ran", which is satisfiable.

---

## Foreign-failure blast radius

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Literal fan-out | All 5 scoped `scanner_check/7` call sites surface any global failure's detail | |
| (B′) Designated owner + cascade pointer | One new `release.workflow_integrity` check owns the full parsed set and carries the verbatim detail; scoped checks report their own results | ✓ |
| (C) Primary + deduped secondary | First call site in deterministic order carries full detail, others back-reference | |

**User's choice:** (B′), via "Lock all four".
**Notes:** Subagent corrected the call-site count from ~8 to 5 (`release_status.ex:382, 394, 414,
423, 432`). (C) was dominated by (B′) — "first in deterministic order" is arbitrary and moves when
call sites are reordered, whereas the owner check is stable by construction.

The orchestrator's empirical run further simplified (B′) beyond what the subagent proposed: because
all checks DO emit, the five scoped checks can evaluate their own IDs correctly, so under a complete
run where only a foreign check fails they report **OK**, not a cascade pointer. The subagent's
illustrative BEFORE output (five ERRORs reading "missing scanner IDs") does not occur; the real
BEFORE is five ERRORs reading "failing scanner IDs: <bare id>". The cascade pointer survives only
for the crash case. Recorded as D-07, explicitly flagged as a deliberate narrowing of SUMMARY.md's
locked rule 1 rather than drift.

Subagent's fail-closed warning adopted in full: do NOT introduce a new status atom without wiring
it into both `aggregate_status/1` and `exit_code/1`, because `exit_code(_status), do: 0` at `:875`
is a catch-all that maps any unrecognized status to SUCCESS.

Precedent mined: Mix aborting after a dependency compile error rather than emitting N downstream
errors; rustc root error + `note:` chaining; TypeScript cascading-error suppression; pytest
collection ERROR reported once. Their shared footgun — presenting cascade count as problem count —
is what (A) walks into. Their own footgun — suppressing a cascade until the dependent looks clean —
avoided by keeping crash-case dependents loudly non-passing.

---

## Rename + uniqueness sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| A. Phase 169 does all of it atomically in one PR | 5 renames + global uniqueness assertion + de-duplicate the one real collision | ✓ |
| B. Defer renames to Phase 171, 169 lands assertion + convention only | Groups renames with the `if:`-clause edits in the same file | |

**User's choice:** A, via "Lock all four".
**Notes:** The subagent found **two upstream premises factually wrong**, verified against the live
GitHub API and the repo:

1. `main` requires exactly ONE status context — `Crosswake CI` (app_id 15368, strict) — confirmed
   via `gh api repos/szTheory/crosswake/branches/main/protection/required_status_checks`, mirrored
   in `script/required_check_policy.json`, hard-asserted in `script/list_merge_blocking_checks.py`.
   `release-please.yml:13-17` is `push`/`workflow_dispatch` only, so its job names can never be PR
   check contexts. **SEED-007's rename footgun does not apply; the renames are free.**
2. There is **1** duplicate display name, not 3 — `advisory provider sandbox/device proof (storekit
   + play billing)`, shared by `phase48-proof.yml` and `phase70-proof.yml`, both advisory.

Inverse hazard surfaced: today's duplicate detection is vacuous by construction
(`list_merge_blocking_checks.py` dedupes only names containing `"merge-blocking"`, which post-v22.0
matches nothing live; `check_required_checks_registered.sh` iterates only registered contexts, i.e.
one string). Widening the scan therefore DOES trip the one real collision — hence the assertion and
its fix must land in one atomic commit, mirroring Phase 171's atomicity rule. `--admin` merge is
refused in this repo, so a red `main` has no escape hatch.

Roadmap wording correction noted (3 duplicates → 1) but no roadmap edit opened; the maintainer chose
"Lock all four" over the variant that would have flagged it to the roadmap.

---

## Exit-code vocabulary (FID-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A. `3` = could not verify; `1` = ran and found a defect; `:warning` stays 0; no 4th code | Ratifies two existing tested in-repo precedents; renumbers nothing | ✓ |
| B. `2` = could not verify (grep/shellcheck convention) | Most widely recognized outside the repo | |

**User's choice:** A, via "Lock all four".
**Notes:** The brief's stated precedent (`physical_iphone`'s `System.halt(2)`) was corrected: this
repo already ships a four-value vocabulary and puts could-not-run at **3**, not 2. Exit `2` is
already triple-booked — *ran and found a defect* (`verify_generated_ios_shell.sh`,
`physical_iphone.ex:50,57,61`), *usage error* (two shell scripts), and *shells behind* (the
adopter-facing `shell.status.ex:121`). Exit `3` already means could-not-run in two independent,
already-tested places (`check_required_checks_registered.sh:51-52`, locked by
`phase135_ci_ops_proof_test.exs:526-533`; `verify_generated_ios_shell.sh:44`). Choosing (B) would
make the same integer mean opposite things in sibling verifiers and could silently reclassify a
BLOCKED ios-shell defect as "could not run".

Danger scan came back clean: no workflow branches on a specific numeric code; every
`continue-on-error: true` is an advisory proof workflow; every `|| true` is cleanup/kill/rev-parse;
`if: failure()` fires on any nonzero so 3 still trips it; `mix crosswake.release.status` is invoked
by no workflow at all.

Mechanism decided as `exit({:shutdown, 3})` over `System.halt/1` — halt skips `at_exit` and
truncates buffered stdout when piped, and the repo already documents the idiom at
`crosswake.demo.ex:25`. Scanner moves to `System.stop(code); Process.sleep(:infinity)` because CI
pipes its stdout.

Ecosystem norm recorded: Mix has no convention above 1; the `0/1/2`-style split is UNIX-side
(grep, diff, shellcheck, ESLint, golangci-lint). pytest's exit 5 ("no tests collected") noted as the
one extra code that earns its keep because it is precisely an anti-vacuity signal. Rejected:
pytest's five codes and curl's ninety as over-design.

---

## Claude's Discretion

- Module/function decomposition inside `lib/crosswake/release_status.ex`, and whether the owner
  check is a new private builder or an extension of `scanner_check/7`.
- Whether emission order is retained as an ordered list or an `:order` key per check map.
- Indentation/wrapping of the multi-line `detail` block in `render/1`.
- Whether to take the optional `check_release_version_truth.exs` 2→3 sweep, if it stays separable.

## Deferred Ideas

- Streaming scanner emission — rejected now, ROSTER/DONE kept forward-compatible with it.
- Widening the status vocabulary beyond `:unverifiable` (`:blocked`, `:partial` as check statuses) —
  needs its own fail-closed audit of every catch-all.
- ROADMAP.md SC #2/#3 and MSG-06 wording corrections — recorded in CONTEXT.md, no edit opened.
- `check_release_version_truth.exs` BLOCKED 2→3 consistency sweep — optional, separable.
- Consolidating the legacy and matrix clean-room paths — forbidden in v23.0 by SUMMARY.md
  divergence #1; seeded for the milestone after v23.0.
