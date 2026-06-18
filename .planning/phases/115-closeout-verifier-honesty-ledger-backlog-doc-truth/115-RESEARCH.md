# Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth - Research

**Researched:** 2026-06-18
**Domain:** Internal GSD closeout verifier, validation-ledger artifacts, and planning-doc truth
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### GATE-02: `expected_phases` fail-closed behavior
- **D-01 (Hybrid fail-closed contract):** Replace the hardcoded `@v40_phases` fallback with a strict parser that returns `{:ok, phases}` or `{:error, reason}`. Missing, malformed, empty, or junk `expected_phases:` is a closeout-contract failure. Do not silently guess a phase set.
- **D-02 (Report first, then Mix raises):** Add a stable blocking check, recommended id `closeout.expected_phases`, to the `CloseoutVerifier` report. `mix closeout.verify` should continue to print the full rendered report, then raise through the existing `Mix.raise("closeout verification found blocking issues")` path. This preserves operator-grade diagnostics while still failing CI.
- **D-03 (No-active-closeout stays non-blocking):** Include `closeout.expected_phases` in the inactive-closeout relaxation list. Ordinary mid-milestone planning edits must not fail merely because `.planning/milestones/v12.0-CLOSEOUT.md` does not exist yet.
- **D-04 (No cascading fake checks):** Phase-dependent checks must not fabricate results after `expected_phases` parsing fails. They should either skip with an explicit invalid-contract observation or reuse the parsed phase list from one shared parse result. Prior-closeout debt scanning must also avoid falling back to a guessed phase set for malformed prior closeouts.
- **D-05 (Parser scope):** Accept the existing frontmatter style: a non-empty inline array such as `expected_phases: ["112", "113"]`, whether top-level or indented under `phase_verification_coverage`. Reject block-list syntax unless the planner deliberately broadens the parser and adds tests. Do not add a YAML dependency unless the planner finds one already established in the project.

### DEBT-01: v3.6 exception and real ledger evidence
- **D-06 (Do not create synthetic v3.6 per-phase ledgers):** v3.6 is historically exceptional. `.planning/milestones/v3.6-CLOSEOUT.md` states the v3.6 phase directories were never archived and phase numbers 48/49/52/53 were reused. Creating `.planning/milestones/v3.6-phases/48-*/*-VALIDATION.md` now would imply source phase artifacts existed when they did not and risks conflating v3.6 Phase 48 with v3.7 Phase 48.
- **D-07 (Make the v3.6 exception first-class):** Add a single accepted-exception artifact, recommended path `.planning/milestones/v3.6-VALIDATION-EXCEPTION.md`, rather than reconstructed phase ledgers. It should be machine-checkable and human-readable:
  - `status: accepted_exception`
  - `scope: validation-ledger-finalization`
  - `affected_phases: ["48", "49", "52", "53"]`
  - `not_reconstructable: true`
  - `reason:` explaining missing archives + reused numbers
  - `evidence:` citing `.planning/milestones/v3.6-CLOSEOUT.md`, `.planning/milestones/v3.6-ROADMAP.md`, `.planning/milestones/v3.6-REQUIREMENTS.md`, and the relevant operator-truth proof file(s)
  - `resolved_at:` and maintainer ownership metadata
- **D-08 (Update planning wording to match truth):** Amend DEBT-01/ROADMAP wording so v3.8 54-58 and v3.9 62/63 require concrete ledger evidence fields, while v3.6 48/49/52/53 is satisfied by the accepted exception artifact. This is a correction to scope truth, not a reduction in rigor.
- **D-09 (Evidence frontmatter is now required for real ledgers):** For every real target `*-VALIDATION.md`, require `nyquist_compliant: true` plus concrete machine-readable evidence in frontmatter. Use both:
  ```yaml
  tested_by:
    - "mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs"
  evidence:
    - type: test_file
      ref: test/crosswake/proof/phase63_notification_seam_proof_test.exs
    - type: command
      ref: "mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs"
  ```
  Existing body tables stay as the human audit narrative; frontmatter is the machine contract.
- **D-10 (Evidence validation strictness for this phase):** `CloseoutVerifier` should validate that at least one evidence item is concrete. `type: test_file` refs must exist. `type: command` refs must name an executable local verification command such as `mix test`, `mix compile`, or `mix closeout.verify`. `type: ci_run` or `type: artifact` may be allowed only when the ref is a non-empty concrete identifier. Do not call the GitHub API or require live artifact verification in this phase.
- **D-11 (Keep active deferrals narrow):** An active `deferred_with_reason` entry for `validation-ledger-finalization` can still explain an intentionally open current-milestone ledger, but stale unsatisfied prior debt must block. Existing protection that `resolved_gaps` does not reopen the escape hatch must remain.

### DOC-01: v8.0 document-truth reconciliation
- **D-12 (Precedence location):** Put the document-precedence rule in `.planning/MILESTONES.md` near the top, because that file is the curated post-archival shipped-state ledger. Recommended text: `MILESTONES.md` > `PROJECT.md` Requirements marks > `v*-MILESTONE-AUDIT.md`.
- **D-13 (Add v8.0 shipped-state entry):** Add a proper v8.0 entry to `.planning/MILESTONES.md` consistent with `.planning/PROJECT.md` and `.planning/milestones/v8.0-ROADMAP.md`: phases 99-101 shipped on 2026-06-11, with real network toggling, advisory runtime storage budgets, consolidated offline UI, and known accepted verification debt later addressed by v12.0.
- **D-14 (Audit is annotated, not rewritten):** Add an append-only note to `.planning/v1.0-MILESTONE-AUDIT.md` explaining that the `0/10` score is a point-in-time 2026-06-11 snapshot of missing/gapped verification artifacts, not the current shipped-state truth. Do not change the original `status: gaps_found`, scores, or gap rows.
- **D-15 (No separate ADR):** Do not create a new doc-truth ADR for this phase. It adds discovery overhead for little benefit. If doc-precedence rules become broader project governance later, that can become its own phase.
- **D-16 (Test the doc contract lightly):** Add a focused planning-doc test or extend an existing one to assert the precedence rule exists, v8.0 has a MILESTONES entry, the v1.0 audit has an append-only annotation, and the original `requirements: 0/10` snapshot remains intact.

### the agent's Discretion

### Claude's Discretion
- Exact helper names and internal data shapes for parsed closeout contracts.
- Whether ledger evidence validation lives inside `validation_ledger_check/2` or a small helper such as `validation_ledger_evidence?/2`.
- Exact wording of the v3.6 exception artifact and v8.0 audit note, as long as the text is calm, explicit, append-only, and does not imply the old snapshot was wrong.
- Parity-test scope is resolved: do not update `test/crosswake/planning/closeout_ci_parity_test.exs` unless the GATE-02 implementation changes closeout CI parity behavior; run the existing parity test in the final focused suite.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Full YAML/frontmatter schema parsing with a dependency such as a YAML parser or NimbleOptions-backed struct can be a later cleanup if regex parsing becomes too brittle. Phase 115 only needs strict validation of the current closeout contract.
- Live verification of historical GitHub run IDs/artifacts is deferred. For this phase, concrete local test files and commands are enough.
- A general planning-governance ADR for document precedence is deferred. `MILESTONES.md` is the canonical location for this phase.
- Broader closeout CI modernization is deferred unless planner finds the parity test is actively misleading.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route and avoid generic WebView wrapper or LiveView-driven native-rendering designs. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency. [VERIFIED: AGENTS.md]
- Keep offline claims honest by distinguishing cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries in `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-02 | `CloseoutVerifier` fails closed on absent/malformed `expected_phases`, zero-ledger phases with no active deferral, and stale unsatisfied prior debt. | The current helper falls back to `@v40_phases`, phase-dependent checks call it independently, and the Mix task already prints the report before raising, so implementation should add `closeout.expected_phases` and reuse one parsed contract. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; lib/mix/tasks/closeout.verify.ex] |
| DEBT-01 | v3.8 phases 54-58 and v3.9 phases 62-63 need real ledger evidence, while v3.6 phases 48/49/52/53 need an accepted exception rather than synthetic ledgers. | Existing v3.8/v3.9 target `*-VALIDATION.md` files exist and contain body evidence but no `tested_by:` or structured `evidence:` frontmatter; no `v3.6-phases` archive or `v3.6-VALIDATION-EXCEPTION.md` exists. [VERIFIED: `.planning/milestones/v3.8-phases/*/*-VALIDATION.md`; `.planning/milestones/v3.9-phases/*/*-VALIDATION.md`; `find .planning/milestones -path '*v3.6-phases*'`] |
| DOC-01 | Record document precedence, add a v8.0 shipped-state entry to `MILESTONES.md`, and annotate the v1.0 milestone audit without changing its original score. | `PROJECT.md` and `v8.0-ROADMAP.md` mark v8.0 shipped, `MILESTONES.md` lacks v8.0, and `v1.0-MILESTONE-AUDIT.md` preserves `requirements: 0/10`. [VERIFIED: `.planning/PROJECT.md`; `.planning/MILESTONES.md`; `.planning/v1.0-MILESTONE-AUDIT.md`; `.planning/milestones/v8.0-ROADMAP.md`] |
</phase_requirements>

## Summary

Phase 115 is a closeout-truth phase, not product-runtime work: it should modify the Elixir closeout verifier, historical planning artifacts, and focused planning tests only. [VERIFIED: `.planning/phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-CONTEXT.md`; `.planning/ROADMAP.md`]

The primary implementation move is to replace `expected_phases/1` with a strict `{:ok, phases} | {:error, reason}` parser and add a stable `closeout.expected_phases` check while preserving the existing report-first/Mix-raises flow. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; lib/mix/tasks/closeout.verify.ex; 115-CONTEXT.md]

The ledger cleanup should normalize real v3.8/v3.9 ledgers with machine-readable evidence, create a first-class v3.6 accepted-exception artifact, and update DEBT wording so the project does not invent historical phase ledgers that never existed. [VERIFIED: 115-CONTEXT.md; `.planning/milestones/v3.6-CLOSEOUT.md`; `.planning/milestones/v3.8-phases`; `.planning/milestones/v3.9-phases`]

**Primary recommendation:** Implement in three ordered slices: GATE-02 verifier hardening first, DEBT-01 ledger/exception normalization second, DOC-01 doc-truth reconciliation and tests third. [VERIFIED: `.planning/ROADMAP.md`; 115-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Closeout contract parsing and report status | Mix task / Elixir library | CI workflow | `CloseoutVerifier` owns deterministic checks and `mix closeout.verify` owns CLI failure; workflows only execute the command. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; lib/mix/tasks/closeout.verify.ex; `.github/workflows/phase75-closeout-gate.yml`] |
| Historical validation-ledger evidence | Planning artifacts | Elixir verifier | `*-VALIDATION.md` and the v3.6 exception carry evidence; the verifier enforces shape and concrete references. [VERIFIED: `.planning/milestones/v3.8-phases`; `.planning/milestones/v3.9-phases`; 115-CONTEXT.md] |
| v8.0 document truth | Planning docs | Planning tests | `MILESTONES.md` should become curated shipped-state truth, with a test locking precedence and audit immutability. [VERIFIED: `.planning/MILESTONES.md`; `.planning/v1.0-MILESTONE-AUDIT.md`; 115-CONTEXT.md] |

## Standard Stack

### Core

| Tool / Library | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix / ExUnit | Elixir 1.19.5, Mix 1.19.5 available locally | Implement verifier logic and focused regression tests. | Existing project stack and focused tests are already green. [VERIFIED: `elixir --version`; `mix --version`; `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_ci_parity_test.exs`] |
| `NimbleOptions` | 1.1.1 in `mix.lock` | Existing runtime option-schema precedent. | Do not introduce it for frontmatter parsing in this phase unless planner deliberately broadens scope; context locks a strict current-shape parser instead. [VERIFIED: mix.exs; mix.lock; 115-CONTEXT.md] |

### Installation

No new package installation is recommended for this phase. [VERIFIED: 115-CONTEXT.md; mix.exs]

## Package Legitimacy Audit

No external packages are recommended or required, so the package legitimacy gate is not applicable. [VERIFIED: mix.exs; 115-CONTEXT.md]

## Current State

### CloseoutVerifier Behavior

- `CloseoutVerifier.run/1` builds ten standard checks when not in security-only mode: closeout frontmatter, deferred shape, release continuity, requirements state, roadmap state, phase verification, summary frontmatter, validation ledger, prior validation debt, and thread/seed disposition. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex]
- `@closeout_artifact_check_ids` is the inactive-closeout relaxation list; when the current milestone has no `CLOSEOUT.md`, those checks are rewritten to non-blocking pass results while release continuity and prior-debt still evaluate. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; `mix closeout.verify`]
- `@v40_phases` is currently `~w(64 65 66 67 68 69)`, and `expected_phases/1` silently returns that hardcoded list when no inline array is found or when parsing yields an empty list. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex]
- `phase_verification_check/2`, `summary_frontmatter_check/2`, `validation_ledger_check/2`, and `prior_validation_debt_check/2` each call `expected_phases/1` independently, so a malformed closeout can cascade into misleading phase scans. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex]
- `validation_ledger_check/2` marks a phase problematic unless at least one matching `*-VALIDATION.md` exists and every matching file contains `nyquist_compliant: true`; an active `deferred_with_reason` entry with `scope: validation-ledger-finalization` and status other than `resolved` or `closed` lets problematic phases pass. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex]
- `prior_validation_debt_check/2` scans prior `v*-CLOSEOUT.md` files, considers only active `validation-ledger-finalization` entries whose status is not `resolved` or `closed`, and annotates unsatisfied entries as `(stale)` when the `revisit_phase` appears in an archived milestone path. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; test/crosswake/planning/closeout_verifier_test.exs]
- `Mix.Tasks.Closeout.Verify` parses CLI options, calls `CloseoutVerifier.run/1`, prints `CloseoutVerifier.render(report)`, and raises `Mix.Error` only after printing when `report.status == :failed`. [VERIFIED: lib/mix/tasks/closeout.verify.ex; test/mix/tasks/closeout_verify_test.exs]

### Existing Test Coverage

- Existing closeout tests cover stable check ids, inactive-closeout relaxation, missing frontmatter, malformed `deferred_with_reason`, prior-debt blocking, prior-debt satisfaction by compliant ledgers or `status: resolved`, stale annotation, missing ledger blocking, and `resolved_gaps` not reopening the validation-ledger escape hatch. [VERIFIED: test/crosswake/planning/closeout_verifier_test.exs]
- Existing Mix task tests cover pass output, blocking output plus `Mix.Error`, invalid options, and security-only closeout behavior. [VERIFIED: test/mix/tasks/closeout_verify_test.exs]
- `test/crosswake/planning/closeout_ci_parity_test.exs` still checks `.github/workflows/phase69-proof.yml`, while `.github/workflows/phase75-closeout-gate.yml` is the standing closeout gate that runs `mix closeout.verify`. [VERIFIED: test/crosswake/planning/closeout_ci_parity_test.exs; `.github/workflows/phase75-closeout-gate.yml`; `.github/workflows/phase69-proof.yml`]
- Focused local verification is currently green: closeout verifier/task/parity tests passed `19 tests, 0 failures`, and milestone planning tests passed `12 tests, 0 failures`. [VERIFIED: `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_ci_parity_test.exs`; `mix test test/crosswake/planning/milestone_transition_reset_test.exs test/crosswake/planning/milestone_arc_closeout_parity_test.exs`]

### Ledger Artifacts

- v3.8 target ledgers for phases 54-58 exist under `.planning/milestones/v3.8-phases/*/*-VALIDATION.md` and all currently have `nyquist_compliant: true`. [VERIFIED: `rg -n "nyquist_compliant" .planning/milestones/v3.8-phases/*/*-VALIDATION.md`]
- v3.9 target ledgers for phases 62-63 exist under `.planning/milestones/v3.9-phases/*/*-VALIDATION.md` and both currently have `nyquist_compliant: true`. [VERIFIED: `rg -n "nyquist_compliant" .planning/milestones/v3.9-phases/{62,63}-*/*-VALIDATION.md`]
- The target v3.8/v3.9 ledgers already contain body-level commands, audit rerun notes, test counts, and sign-off narrative, but they do not contain `tested_by:` or structured `evidence:` frontmatter. [VERIFIED: `.planning/milestones/v3.8-phases/*/*-VALIDATION.md`; `.planning/milestones/v3.9-phases/*/*-VALIDATION.md`]
- There is no `.planning/milestones/v3.6-phases` archive and no `.planning/milestones/v3.6-VALIDATION-EXCEPTION.md` artifact today. [VERIFIED: `find .planning/milestones -path '*v3.6-phases*'`; `find .planning/milestones -name 'v3.6-VALIDATION-EXCEPTION.md'`]
- `.planning/milestones/v3.6-CLOSEOUT.md` currently records the `validation-ledger-finalization` entry as `status: resolved` with evidence text explaining missing archives and reused numbers. [VERIFIED: `.planning/milestones/v3.6-CLOSEOUT.md`]

### Doc Truth

- `.planning/PROJECT.md` says v8.0 shipped on 2026-06-11 and marks SYNC-01, SYNC-02, SYNC-03, OFFC-01/02, BDGT-01/02/03, and BRND-01/02 as satisfied. [VERIFIED: `.planning/PROJECT.md`]
- `.planning/milestones/v8.0-ROADMAP.md` marks v8.0 shipped on 2026-06-11, lists phases 99-101, and explicitly carries accepted verification debt. [VERIFIED: `.planning/milestones/v8.0-ROADMAP.md`]
- `.planning/MILESTONES.md` currently jumps from v9.0 to v6.0 and has no v8.0 shipped-state entry. [VERIFIED: `.planning/MILESTONES.md`; `rg -n "v8.0" .planning/MILESTONES.md`]
- `.planning/v1.0-MILESTONE-AUDIT.md` has frontmatter `status: gaps_found` and `scores.requirements: 0/10`, and its body says 0/10 requirements were fully satisfied. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`]

## Recommended Approach

### GATE-02 Implementation

1. Add `closeout.expected_phases` as a stable check id and include it in `@closeout_artifact_check_ids` so inactive closeout remains non-blocking. [VERIFIED: 115-CONTEXT.md; lib/crosswake/planning/closeout_verifier.ex]
2. Replace `expected_phases/1` with a strict parser, for example `parse_expected_phases(frontmatter)`, returning `{:ok, phases}` for a non-empty inline array and `{:error, reason}` for missing, empty, junk, or block-list syntax. [VERIFIED: 115-CONTEXT.md; lib/crosswake/planning/closeout_verifier.ex]
3. Parse the current closeout contract once per run or once per check group and feed the result into phase-dependent checks; if parsing fails, emit only the blocking `closeout.expected_phases` result and make dependent checks observe `skipped: invalid expected_phases contract` instead of scanning `@v40_phases`. [VERIFIED: 115-CONTEXT.md; lib/crosswake/planning/closeout_verifier.ex]
4. Keep `Mix.Tasks.Closeout.Verify` behavior unchanged except for expected output: print the full report, then raise the existing `closeout verification found blocking issues` message when the report fails. [VERIFIED: lib/mix/tasks/closeout.verify.ex; test/mix/tasks/closeout_verify_test.exs]
5. Extend ledger validation to require concrete evidence frontmatter for real ledgers: `nyquist_compliant: true`, non-empty `tested_by:`, and at least one structured `evidence:` item whose `type/ref` pair is locally checkable under the D-10 rules. [VERIFIED: 115-CONTEXT.md; `.planning/milestones/v3.8-phases/*/*-VALIDATION.md`; `.planning/milestones/v3.9-phases/*/*-VALIDATION.md`]

### Ledger Normalization Shape

Use this frontmatter shape for real v3.8/v3.9 ledgers; preserve existing body tables and audit narrative below the frontmatter. [VERIFIED: 115-CONTEXT.md; existing validation files]

```yaml
---
phase: 63
slug: hermetic-proof-and-advisory-promotion-criteria
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
tested_by:
  - "mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs"
evidence:
  - type: test_file
    ref: test/crosswake/proof/phase63_notification_seam_proof_test.exs
  - type: command
    ref: "mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs"
---
```

Recommended per-phase evidence refs:

| Phase | Minimum `tested_by` / `evidence` refs |
|-------|----------------------------------------|
| 54 | `test/crosswake/proof/phase54_sigra_session_authority_test.exs`; optionally supporting `contracts_test`, `schema_test`, and `route_gate_test`. [VERIFIED: 54-VALIDATION.md] |
| 55 | `test/crosswake/companions/sigra/handoff_test.exs` and `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`. [VERIFIED: 55-VALIDATION.md] |
| 56 | `test/crosswake/companions/sigra/step_up_test.exs` and `test/crosswake/proof/phase56_step_up_ceremony_test.exs`. [VERIFIED: 56-VALIDATION.md] |
| 57 | `test/crosswake/proof/phase57_auth_return_boundaries_test.exs`. [VERIFIED: 57-VALIDATION.md] |
| 58 | `mix closeout.verify --security-only --security-closeout .planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md` plus `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs`. [VERIFIED: 58-VALIDATION.md; `.planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md`] |
| 62 | `test/crosswake/doctor/doctor_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`, `test/crosswake/support_matrix_test.exs`, `test/crosswake/companions/chimeway/telemetry_test.exs`, `test/crosswake/operator_inspection/operator_inspection_test.exs`, and `test/crosswake/support_matrix/renderer_test.exs`. [VERIFIED: 62-VALIDATION.md] |
| 63 | `test/crosswake/proof/phase63_notification_seam_proof_test.exs`, `test/crosswake/proof/phase63_advisory_proof_test.exs --include advisory_only`, and `test/crosswake/planning/closeout_verifier_test.exs`. [VERIFIED: 63-VALIDATION.md] |

### v3.6 Exception Shape

Create `.planning/milestones/v3.6-VALIDATION-EXCEPTION.md` instead of synthetic v3.6 phase ledgers. [VERIFIED: 115-CONTEXT.md; `.planning/milestones/v3.6-CLOSEOUT.md`; `find .planning/milestones -path '*v3.6-phases*'`]

```yaml
---
status: accepted_exception
scope: validation-ledger-finalization
affected_phases: ["48", "49", "52", "53"]
not_reconstructable: true
owner: maintainer
resolved_at: 2026-06-18
evidence:
  - type: planning_artifact
    ref: .planning/milestones/v3.6-CLOSEOUT.md
  - type: planning_artifact
    ref: .planning/milestones/v3.6-ROADMAP.md
  - type: planning_artifact
    ref: .planning/milestones/v3.6-REQUIREMENTS.md
  - type: test_file
    ref: test/crosswake/proof/phase52_operator_truth_test.exs
reason: "v3.6 phase directories were not archived before phase numbers 48/49/52/53 were reused; reconstructing per-phase ledgers would imply artifacts that did not exist."
---
```

### DOC-01 Implementation

1. Add a short precedence rule near the top of `.planning/MILESTONES.md`: `MILESTONES.md` curated shipped-state truth > `PROJECT.md` active-project requirements marks > `v*-MILESTONE-AUDIT.md` point-in-time snapshots. [VERIFIED: 115-CONTEXT.md; `.planning/MILESTONES.md`]
2. Add a v8.0 entry to `.planning/MILESTONES.md` between v9.0 and v6.0, matching the existing descending milestone order and stating phases 99-101 shipped on 2026-06-11 with real network toggling, advisory storage budgets, consolidated offline UI, and accepted verification debt later addressed by v12.0. [VERIFIED: `.planning/MILESTONES.md`; `.planning/milestones/v8.0-ROADMAP.md`; `.planning/PROJECT.md`]
3. Append a note to `.planning/v1.0-MILESTONE-AUDIT.md` without changing frontmatter or the original `0/10` text; the note should say the audit is a 2026-06-11 point-in-time snapshot of verification gaps and not the current shipped-state ledger. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`; 115-CONTEXT.md]
4. Add `test/crosswake/planning/doc_truth_test.exs` or equivalent focused coverage asserting the precedence rule, v8.0 entry, audit annotation, and preservation of `requirements: 0/10`. [VERIFIED: existing planning test layout in `test/crosswake/planning`]

## File/Code Map

| File | Current Role | Phase 115 Action |
|------|--------------|------------------|
| `lib/crosswake/planning/closeout_verifier.ex` | Main verifier and report API. [VERIFIED: file inspection] | Add `closeout.expected_phases`, strict parser, shared parsed contract, evidence validation helpers, and tests for zero-ledger/evidence cases. |
| `lib/mix/tasks/closeout.verify.ex` | CLI wrapper that prints report then raises on failed reports. [VERIFIED: file inspection] | Preserve behavior; only update tests/output assertions for new check id. |
| `test/crosswake/planning/closeout_verifier_test.exs` | Primary verifier fixture suite. [VERIFIED: file inspection] | Add strict expected-phases parser tests and ledger evidence acceptance/rejection tests. |
| `test/mix/tasks/closeout_verify_test.exs` | Mix task behavior tests. [VERIFIED: file inspection] | Add malformed/missing `expected_phases` case asserting rendered report plus `Mix.Error`. |
| `test/crosswake/planning/closeout_ci_parity_test.exs` | Older workflow parity check for phase69 closeout lane. [VERIFIED: file inspection] | Do not touch unless GATE-02 changes closeout CI parity behavior; keep it in the final focused suite. |
| `.github/workflows/phase75-closeout-gate.yml` | Standing closeout gate runs `mix closeout.verify`. [VERIFIED: file inspection] | Likely no restructure; update only if new planning test must be part of this gate. |
| `.planning/milestones/v3.8-phases/54-58/*-VALIDATION.md` | Real historical validation ledgers. [VERIFIED: file inspection] | Add `tested_by:` and `evidence:` frontmatter without rewriting body evidence. |
| `.planning/milestones/v3.9-phases/62-63/*-VALIDATION.md` | Real historical validation ledgers. [VERIFIED: file inspection] | Add `tested_by:` and `evidence:` frontmatter without rewriting body evidence. |
| `.planning/milestones/v3.6-VALIDATION-EXCEPTION.md` | Missing accepted-exception artifact. [VERIFIED: `find` command] | Create with machine-checkable exception frontmatter. |
| `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` | Current v12 requirement/scope wording. [VERIFIED: file inspection] | Reconcile DEBT-01 wording with v3.6 accepted exception. |
| `.planning/MILESTONES.md` | Curated shipped-state ledger. [VERIFIED: file inspection] | Add precedence rule and v8.0 entry. |
| `.planning/v1.0-MILESTONE-AUDIT.md` | Point-in-time v8.0 audit snapshot with 0/10 score. [VERIFIED: file inspection] | Append annotation; do not rewrite original frontmatter or scores. |

## Architecture Patterns

### Data Flow

```text
CLOSEOUT.md frontmatter
  -> parse current closeout contract
  -> closeout.expected_phases check
  -> phase artifact checks reuse parsed phase list
  -> validation ledgers read frontmatter evidence
  -> report rendered with stable ids
  -> mix closeout.verify prints report
  -> Mix.raise when any check blocks

Historical ledger cleanup
  -> real v3.8/v3.9 VALIDATION frontmatter evidence
  -> v3.6 accepted-exception artifact
  -> prior debt check sees no stale unsatisfied debt

Doc truth
  -> MILESTONES precedence rule
  -> v8.0 shipped-state entry
  -> v1.0 audit append-only annotation
  -> planning-doc test locks contract
```

### Pattern: Report-First Fail-Closed Checks

**What:** Fail through a stable `Check` entry rather than an early exception, then let the Mix task raise after rendering. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; lib/mix/tasks/closeout.verify.ex]

**When to use:** Use for `closeout.expected_phases`, malformed ledger evidence, and doc-contract failures that should be visible in operator output. [VERIFIED: 115-CONTEXT.md]

### Pattern: Append-Only Historical Truth

**What:** Add annotations or new accepted-exception artifacts instead of rewriting historical audit scores or creating fake historical ledgers. [VERIFIED: 115-CONTEXT.md; `.planning/v1.0-MILESTONE-AUDIT.md`; `.planning/milestones/v3.6-CLOSEOUT.md`]

**When to use:** Use for v3.6 ledger exception and v8.0 audit note. [VERIFIED: 115-CONTEXT.md]

### Anti-Patterns to Avoid

- **Hardcoded phase fallback:** Substituting `@v40_phases` for invalid closeout frontmatter verifies the wrong milestone. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; `.planning/research/PITFALLS.md`]
- **Bare compliance attestation:** A ledger with only `nyquist_compliant: true` can satisfy the current string check without concrete evidence. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; `.planning/research/PITFALLS.md`]
- **Synthetic v3.6 ledgers:** Creating phase 48/49/52/53 v3.6 ledgers would collide with reused phase numbers and imply non-existent archived phase directories. [VERIFIED: 115-CONTEXT.md; `.planning/milestones/v3.6-CLOSEOUT.md`; `find .planning/milestones -path '*v3.7-phases/48-*'`]
- **Audit score rewrite:** Changing `requirements: 0/10` in `.planning/v1.0-MILESTONE-AUDIT.md` would erase the point-in-time evidence DOC-01 is supposed to preserve. [VERIFIED: 115-CONTEXT.md; `.planning/v1.0-MILESTONE-AUDIT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| General YAML parsing | A partial YAML parser for every frontmatter shape | A strict parser for the locked inline `expected_phases: [...]` and the specific evidence shape | Phase scope explicitly rejects new YAML dependency and only needs current frontmatter contracts. [VERIFIED: 115-CONTEXT.md; mix.exs] |
| Live artifact verification | GitHub API artifact/run validation | Local `type/ref` checks for files and commands | Live GitHub verification is deferred; local evidence is enough. [VERIFIED: 115-CONTEXT.md] |
| Historical reconstruction | Fake v3.6 phase ledgers | One accepted-exception artifact | v3.6 archives are absent and phase numbers were reused. [VERIFIED: 115-CONTEXT.md; `.planning/milestones/v3.6-CLOSEOUT.md`] |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix. [VERIFIED: mix.exs; `mix --version`] |
| Config file | `mix.exs`. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/doc_truth_test.exs` [VERIFIED: existing test layout; recommended new file] |
| Full focused command | `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_ci_parity_test.exs test/crosswake/planning/milestone_transition_reset_test.exs test/crosswake/planning/milestone_arc_closeout_parity_test.exs test/crosswake/planning/doc_truth_test.exs` [VERIFIED: existing test layout; recommended new file] |
| Closeout command | `mix closeout.verify` [VERIFIED: local command passed with no active closeout] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| GATE-02 | Missing/malformed/empty/junk `expected_phases` yields blocking `closeout.expected_phases`, dependent checks do not scan `@v40_phases`, and inactive closeout remains non-blocking. | unit/CLI | `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs` | Existing files need new tests. [VERIFIED: test files] |
| GATE-02 | Zero ledger files with no active deferral blocks, and bare `nyquist_compliant: true` without concrete evidence blocks. | unit | `mix test test/crosswake/planning/closeout_verifier_test.exs` | Existing file needs new tests. [VERIFIED: test/crosswake/planning/closeout_verifier_test.exs] |
| DEBT-01 | v3.8/v3.9 target ledgers have `tested_by:` and structured `evidence:` frontmatter with concrete local refs. | source contract | `mix test test/crosswake/planning/closeout_verifier_test.exs` plus source grep in test helper if desired | Ledgers exist; evidence fields missing. [VERIFIED: target validation files] |
| DEBT-01 | v3.6 is satisfied by accepted exception artifact, not reconstructed per-phase ledgers. | source contract | `mix test test/crosswake/planning/closeout_verifier_test.exs` or new planning test | Exception file missing. [VERIFIED: `find` command] |
| DOC-01 | MILESTONES precedence rule, v8.0 entry, audit annotation, and preserved `requirements: 0/10`. | source contract | `mix test test/crosswake/planning/doc_truth_test.exs` | New file needed. [VERIFIED: existing planning test directory] |

### Sampling Rate

- Per task commit: run the quick command for touched verifier/doc surfaces. [VERIFIED: existing project test pattern in validation files]
- Per wave merge: run full focused command plus `mix closeout.verify`. [VERIFIED: `.github/workflows/phase75-closeout-gate.yml`; local `mix closeout.verify`]
- Phase gate: run `mix closeout.verify` and the focused planning test set before `$gsd-verify-work`. [VERIFIED: `.planning/ROADMAP.md`; local command results]

### Wave 0 Gaps

- [ ] `test/crosswake/planning/doc_truth_test.exs` — covers DOC-01 precedence, v8.0 entry, audit annotation, and immutable `0/10` score. [VERIFIED: no existing doc-truth test found by `rg`]
- [ ] `closeout.expected_phases` tests in `test/crosswake/planning/closeout_verifier_test.exs`. [VERIFIED: current test file]
- [ ] Mix task rendered-output test for malformed expected phases in `test/mix/tasks/closeout_verify_test.exs`. [VERIFIED: current test file]
- [ ] Ledger evidence acceptance/rejection fixture tests in `test/crosswake/planning/closeout_verifier_test.exs`. [VERIFIED: current test file]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication/session behavior is modified. [VERIFIED: phase scope in 115-CONTEXT.md] |
| V3 Session Management | no | No runtime session behavior is modified. [VERIFIED: phase scope in 115-CONTEXT.md] |
| V4 Access Control | no | No route/runtime access-control behavior is modified. [VERIFIED: phase scope in 115-CONTEXT.md] |
| V5 Input Validation | yes | Strictly validate closeout frontmatter and ledger evidence shape; reject malformed input instead of defaulting. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; 115-CONTEXT.md] |
| V6 Cryptography | no | No cryptographic behavior is modified. [VERIFIED: phase scope in 115-CONTEXT.md] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed `CLOSEOUT.md` causing verifier to inspect the wrong phase set | Tampering | Fail closed with `closeout.expected_phases`; do not use fallback phase lists. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; 115-CONTEXT.md] |
| Bare `nyquist_compliant: true` without evidence | Repudiation | Require concrete `tested_by:`/`evidence:` refs and local existence/command-shape checks. [VERIFIED: `.planning/research/PITFALLS.md`; 115-CONTEXT.md] |
| Rewriting historical audit scores | Repudiation | Append annotation; preserve original audit frontmatter and scores. [VERIFIED: 115-CONTEXT.md; `.planning/v1.0-MILESTONE-AUDIT.md`] |

## Risks and Pitfalls

- **Parser drift:** Broadening into general YAML parsing invites edge cases; keep parser scope to inline `expected_phases` and explicit evidence shape. [VERIFIED: 115-CONTEXT.md; mix.exs]
- **Cascading misleading checks:** If dependent checks still call `expected_phases/1`, an invalid closeout can produce wrong missing-ledger lists for phases 64-69. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex]
- **Inactive closeout regression:** Adding `closeout.expected_phases` without adding it to the relaxation list would make normal mid-milestone planning fail while v12.0 lacks a closeout file. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; `mix closeout.verify`]
- **Over-strict evidence parser:** If evidence validation tries to prove GitHub artifacts live, it will exceed D-10 and create network brittleness. [VERIFIED: 115-CONTEXT.md]
- **v3.6 truth regression:** Synthetic v3.6 ledgers would be worse than the current gap because they imply source artifacts existed and risk conflating v3.6/v3.7 phase 48. [VERIFIED: 115-CONTEXT.md; `.planning/milestones/v3.6-CLOSEOUT.md`; `.planning/milestones/v3.7-phases/48-commerce-provider-adapter-context`]
- **Doc-truth overwrite:** Replacing the audit score instead of annotating it would destroy the point-in-time signal DOC-01 depends on. [VERIFIED: `.planning/v1.0-MILESTONE-AUDIT.md`; 115-CONTEXT.md]

## Planning Recommendations

1. Plan `115-01` for GATE-02 only: strict expected-phase parser, new check id, no-active-closeout relaxation, dependent-check skip/reuse behavior, evidence validation helper, and focused verifier/Mix tests. [VERIFIED: `.planning/ROADMAP.md`; 115-CONTEXT.md]
2. Plan `115-02` for DEBT-01 only: add frontmatter evidence to v3.8 54-58 and v3.9 62-63 ledgers, create the v3.6 exception artifact, and reconcile DEBT wording in `.planning/REQUIREMENTS.md`/`.planning/ROADMAP.md`. [VERIFIED: target validation files; 115-CONTEXT.md]
3. Plan `115-03` for DOC-01 only: update `MILESTONES.md`, append the audit annotation, add the doc-truth test, and run the focused planning test set. [VERIFIED: `.planning/MILESTONES.md`; `.planning/v1.0-MILESTONE-AUDIT.md`; existing planning test directory]
4. Leave broad closeout CI modernization out. Do not update `closeout_ci_parity_test.exs` unless GATE-02 changes closeout CI parity behavior; `phase75-closeout-gate.yml` already runs `mix closeout.verify`, and the existing parity test remains part of the final focused suite. [VERIFIED: `.github/workflows/phase75-closeout-gate.yml`; test/crosswake/planning/closeout_ci_parity_test.exs; 115-CONTEXT.md; 115-VALIDATION.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Verifier implementation and tests | yes | 1.19.5 | none needed. [VERIFIED: `elixir --version`] |
| Mix | Tests and `closeout.verify` task | yes | 1.19.5 | none needed. [VERIFIED: `mix --version`] |
| GSD tools seam | `init.phase-op`, research cache/classify, commit helper | no | installed script errors with missing `../../../package.json` | Direct repo inspection and local commands used. [VERIFIED: `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query init.phase-op 115`; `node /Users/jon/.agents/gsd-core/bin/gsd-tools.cjs query init.phase-op 115`] |
| Project graph | Graph context | no | `.planning/graphs/graph.json` absent | Direct `rg`/file inspection used. [VERIFIED: `if [ -f .planning/graphs/graph.json ]`] |

**Missing dependencies with no fallback:** none for implementation. [VERIFIED: local Elixir/Mix checks]

**Missing dependencies with fallback:** GSD tools seam unavailable; local codebase research was sufficient for this codebase-only phase. [VERIFIED: gsd-tools command failures]

## Assumptions Log

No `[ASSUMED]` claims are required for implementation planning; recommendations are based on local project artifacts and the locked phase context. [VERIFIED: source inspection listed below]

## Resolved Questions

1. **Should `closeout_ci_parity_test.exs` be updated now?**  
   Resolution: do not update `test/crosswake/planning/closeout_ci_parity_test.exs` in Phase 115 unless the GATE-02 implementation changes closeout CI parity behavior. The existing parity test still belongs in the final focused suite from `115-VALIDATION.md`, so Phase 115 proves it remains green without broad closeout CI modernization. [VERIFIED: 115-CONTEXT.md; 115-VALIDATION.md; test/crosswake/planning/closeout_ci_parity_test.exs]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-CONTEXT.md` - locked decisions and scope. [VERIFIED: local file]
- `lib/crosswake/planning/closeout_verifier.ex` - verifier behavior, check ids, fallback, ledger/prior-debt logic. [VERIFIED: local file]
- `lib/mix/tasks/closeout.verify.ex` - CLI print-then-raise behavior. [VERIFIED: local file]
- `test/crosswake/planning/closeout_verifier_test.exs`, `test/mix/tasks/closeout_verify_test.exs`, `test/crosswake/planning/closeout_ci_parity_test.exs` - existing coverage. [VERIFIED: local files]
- `.planning/milestones/v3.6-CLOSEOUT.md`, `.planning/milestones/v3.6-ROADMAP.md`, `.planning/milestones/v3.6-REQUIREMENTS.md` - v3.6 exception basis. [VERIFIED: local files]
- `.planning/milestones/v3.8-phases/*/*-VALIDATION.md` and `.planning/milestones/v3.9-phases/*/*-VALIDATION.md` - ledger normalization targets. [VERIFIED: local files]
- `.planning/MILESTONES.md`, `.planning/v1.0-MILESTONE-AUDIT.md`, `.planning/milestones/v8.0-ROADMAP.md`, `.planning/PROJECT.md` - doc truth inputs. [VERIFIED: local files]
- Local commands: `mix closeout.verify`, focused closeout tests, focused planning tests, `elixir --version`, and `mix --version`. [VERIFIED: command output]

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md` and `.planning/research/PITFALLS.md` - v12 proof-honesty synthesis and known pitfalls. [VERIFIED: local files]
- `.planning/MILESTONE-ARC.md` and project prompts - house style and proof-truth posture. [VERIFIED: local files]

### External

- No external web sources were needed; this phase is implementation-focused and all decisive evidence is in the repository. [VERIFIED: research scope and local evidence]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing Elixir/Mix stack verified locally and no new packages needed. [VERIFIED: mix.exs; command output]
- Architecture: HIGH - all implementation surfaces and target artifacts were inspected locally. [VERIFIED: listed sources]
- Pitfalls: HIGH - pitfalls match current code paths and prior research artifacts. [VERIFIED: lib/crosswake/planning/closeout_verifier.ex; `.planning/research/PITFALLS.md`]

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 for local code/artifact findings unless Phase 115 implementation changes these files first.
