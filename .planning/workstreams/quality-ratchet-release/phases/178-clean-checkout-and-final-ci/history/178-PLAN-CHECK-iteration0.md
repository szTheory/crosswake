## ISSUES FOUND

**Phase:** clean-checkout-and-final-ci (178)  
**Plans checked:** 5  
**Issues:** 5 blocker(s), 2 warning(s), 1 info

### Coverage Summary

| Requirement | Plans | Status |
|---|---|---|
| MAINT-07 — complete existing verifier from exact clean source with before/after state | 178-01, 178-02, 178-05 | Covered, subject to findings below |
| MAINT-08 — green hosted CI bound to the same runner-tested source | 178-03, 178-04, 178-05 | Covered, subject to findings below |

The plans claim all D-01 through D-25 and preserve the six Phase177 source outputs, the 119 captured rows, private recovery material, and unresolved historical reader comparisons. All five `verify plan-structure` results were valid. The supplied path probe reports `not_applicable` for all 17 commands, which does not establish target existence; the supplied failing-direction probe reports 17 `ok`, zero blockers/warnings, and no read error. I checked the newly produced command paths against their producing tasks and the attested source's facade, manifest, and policy. I did not run source, build, Git, or remote operations.

### Blockers — these properties must hold

**1. [task_completeness] Every plan carries its execution-facing artifact producer/consumer contract.**

- Plans: 178-01, 178-02, 178-03, 178-04, 178-05
- Evidence: The producer/consumer table appears only in `178-PLANNING.md`. None of the five PLAN.md files contains the required “Artifacts this phase produces” section, so an executor consuming an individual plan lacks that contract in the executable artifact.
- Example fix (non-binding): Include each plan's relevant produced symbols/files, flags, and consuming task/plan in that PLAN.md.

**2. [verification_derivation] The local proof parser is tested against actual `--all` facade behavior.**

- Plan: 178-02
- Task: 1
- Evidence: The test behavior says it spawns the actual facade with `--self-test`; the attested facade's `--self-test` emits `PASS repository-preflight self-test`, while the nine ordered stage lines and retained log behavior come from `--all`. The plan does not require a fixture that exercises the actual facade's full-run behavior, leaving the nine-line parser contract liable to be validated only against invented output.
- Example fix (non-binding): Exercise the real facade's full-run path with controlled temporary stage commands/manifest and capture its actual subprocess output and retained files, or provide an equivalent source-grounded fixture.

**3. [key_links_planned] Hosted required-check policy evidence covers every applicable policy source.**

- Plan: 178-03
- Evidence: The collector's fixed policy routes name base-branch `required_status_checks` reads, but do not name repository ruleset reads or a check proving no applicable ruleset exists. The phase decision requires current required-check policy, including context/app identity, and inaccessible required policy must block; the planned contract can therefore miss requirements enforced through rulesets.
- Example fix (non-binding): Account for all applicable required-check policy sources, including rulesets where present, and fail closed if any required source cannot be read.

**4. [verification_derivation] Supplemental before/after Git snapshots preserve the index while measuring it.**

- Plans: 178-02, 178-05
- Tasks: 178-02 T1/T2; 178-05 T2
- Evidence: Both plans require independent `git status` and index-hash snapshots, but do not require `GIT_OPTIONAL_LOCKS=0` for those supplemental commands. The attested facade sets this variable for its own snapshots; that does not cover the separately planned collector snapshots. A status read may refresh the index and undermine the claimed unchanged-index comparison.
- Example fix (non-binding): Apply the facade's `GIT_OPTIONAL_LOCKS=0` capture discipline to every supplemental status/index snapshot.

**5. [research_resolution] Research open questions are resolved before planning proceeds.**

- Plan: null (phase-level)
- Evidence: `178-RESEARCH.md` retains `## Open Questions` without a `(RESOLVED)` marker. Both questions remain open: the exact hosted synthetic merge commit and whether current policy/credentials expose all required evidence. Plans provide execution procedures and fail-closed outcomes, but the research artifact does not resolve or formally disposition these questions as resolved execution-time unknowns.
- Example fix (non-binding): Mark the questions resolved with the selected execution-time observation and fail-closed decision rules, or otherwise resolve them before planning handoff.

### Warnings — these properties should hold

**1. [scope_sanity] A plan stays within the expected file budget.**

- Plan: 178-01
- Evidence: `files_modified` lists 10 files, at the warning threshold; its estimate is 21,000 tokens with low confidence because the calibration sample count is zero. The other four estimates are within the 100,000-token budget (21,000/24,000/26,000/20,000/30,000; all confidence low).
- Example fix (non-binding): Reduce the per-plan file load or split a separable work unit while preserving the source-candidate dependency.

**2. [verification_derivation] Fallback assumptions are traceable from the audit into executable plans.**

- Plans: 178-01 through 178-05
- Evidence: `178-PLANNING.md` says the fallback probe left MAINT-07 `unclassified` and MAINT-08 `boundary`/`precision` unresolved assumptions. The PLAN.md files contain related checks, but do not identify those assumptions or map each to a specific task acceptance condition, so the executor cannot verify that the probe flags were deliberately addressed.
- Example fix (non-binding): Carry the unresolved assumptions and their task-level acceptance/disposition into the plans that own the relevant checks.

### Advisories (info)

**1. [dependency_correctness] Ordering between same-wave plans is declared, not implied.**

- Plans: 178-02 and 178-03
- Evidence: Both are Wave 2 and declare only dependency on 178-01. The aggregate artifact table says Plan02 hands its private run pointer to Plan04 and Plan03 hands its private policy/log pointer to Plan04; both therefore write the shared owner-private handoff state without an ordering edge. This is non-local private-state coupling even though their public files are disjoint.
- Example fix (non-binding): Declare the shared-state handoff as justified or order the writers.

### Structured Issues

```yaml
issues:
  - plan: null
    plans: ["178-01", "178-02", "178-03", "178-04", "178-05"]
    dimension: task_completeness
    severity: blocker
    required_property: "Each plan carries its execution-facing artifact producer/consumer contract"
    description: "The producer/consumer table exists only in 178-PLANNING.md; none of the five executable PLAN.md files contains the required Artifacts this phase produces section."
    fix_hint: "Include each plan's relevant produced symbols/files and consumers in that PLAN.md."
  - plan: "178-02"
    dimension: verification_derivation
    severity: blocker
    required_property: "The local proof parser is validated against actual complete --all facade behavior"
    description: "Task 1 tests the actual facade --self-test path, which emits only a self-test PASS line; it does not require exercising the nine-stage --all output/log behavior that the parser accepts."
    task: 1
    fix_hint: "Use a source-grounded full-run fixture with real facade subprocess behavior."
  - plan: "178-03"
    dimension: key_links_planned
    severity: blocker
    required_property: "The hosted CI contract accounts for every applicable current required-check policy source"
    description: "The fixed policy route list includes base-branch required_status_checks but no ruleset read or evidence that no applicable ruleset exists."
    fix_hint: "Account for applicable rulesets as well as branch protection, failing closed on inaccessible policy."
  - plan: "178-02"
    plans: ["178-02", "178-05"]
    dimension: verification_derivation
    severity: blocker
    required_property: "Supplemental status and index snapshots cannot mutate the index being measured"
    description: "The plans' independent Git snapshot commands omit GIT_OPTIONAL_LOCKS=0; only the facade's internal snapshots are explicitly protected from optional index refresh."
    fix_hint: "Use GIT_OPTIONAL_LOCKS=0 for every supplemental status/index snapshot."
  - plan: null
    dimension: research_resolution
    severity: blocker
    required_property: "RESEARCH.md has no unresolved open questions before planning handoff"
    description: "178-RESEARCH.md has an unmarked Open Questions section with two unanswered execution-state questions about the actual synthetic merge commit and required policy/credential access."
    fix_hint: "Resolve and mark the questions, including explicit execution-time observation and fail-closed dispositions."
  - plan: "178-01"
    dimension: scope_sanity
    severity: warning
    required_property: "Each plan stays within the expected per-plan file budget"
    description: "Plan 178-01 lists 10 modified files, at the warning threshold; its token estimate is low-confidence with zero calibrated samples."
    fix_hint: "Reduce or split a separable unit while preserving the source-candidate dependency."
  - plan: null
    plans: ["178-01", "178-02", "178-03", "178-04", "178-05"]
    dimension: verification_derivation
    severity: warning
    required_property: "Every fallback assumption is mapped to a task-level acceptance condition or explicit disposition"
    description: "The aggregate planning audit retains unresolved probe items (MAINT-07 unclassified; MAINT-08 boundary and precision), but the plans do not identify and map those flags to task acceptance/disposition."
    fix_hint: "Carry each fallback assumption and its owning task-level acceptance/disposition into the executable plans."
  - plan: "178-02"
    plans: ["178-02", "178-03"]
    dimension: dependency_correctness
    severity: info
    required_property: "Ordering between same-wave plans is declared, not implied"
    description: "Plans 178-02 and 178-03 both write the owner-private state later consumed by Plan04, while running in Wave 2 with no ordering edge."
    fix_hint: "Declare the shared-state coupling as justified or order the writers."
```

### Recommendation

5 blockers and 2 warnings require revision. Returning to planner with feedback.

<!-- PLAN_CHECK_RESULT: ISSUES_FOUND -->
