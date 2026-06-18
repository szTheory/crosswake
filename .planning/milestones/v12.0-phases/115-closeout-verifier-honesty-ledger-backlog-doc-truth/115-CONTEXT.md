# Phase 115: Closeout-Verifier Honesty + Ledger Backlog + Doc Truth - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the GSD closeout surface tell the truth in three places:

1. `CloseoutVerifier` must fail closed when `CLOSEOUT.md` lacks a valid `expected_phases:` contract, instead of silently substituting a hardcoded phase set.
2. The validation-ledger backlog must be resolved honestly: real archived ledgers get concrete evidence metadata; historically impossible v3.6 ledgers are handled as an explicit accepted exception, not synthetic phase evidence.
3. The v8.0 planning docs must converge on a durable precedence rule: `MILESTONES.md` is shipped-state truth, `PROJECT.md` is active-project truth, and `v*-MILESTONE-AUDIT.md` files are point-in-time snapshots.

This is internal closeout/proof/documentation hardening. No Phoenix runtime, native shell, bridge, offline app behavior, or user-facing UI changes belong in this phase.

**Maps to requirements:** GATE-02, DEBT-01, DOC-01.

**Ordering constraint:** GATE-02 before DEBT-01. The verifier must know what “missing/malformed expected phases” and “concrete ledger evidence” mean before backlog cleanup can be trusted.

</domain>

<decisions>
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

### Claude's Discretion
- Exact helper names and internal data shapes for parsed closeout contracts.
- Whether ledger evidence validation lives inside `validation_ledger_check/2` or a small helper such as `validation_ledger_evidence?/2`.
- Exact wording of the v3.6 exception artifact and v8.0 audit note, as long as the text is calm, explicit, append-only, and does not imply the old snapshot was wrong.
- Whether to update `test/crosswake/planning/closeout_ci_parity_test.exs` in this phase. It currently points at the older phase69 closeout lane while `.github/workflows/phase75-closeout-gate.yml` also exists; include only if needed to keep closeout-gate parity honest.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and roadmap
- `.planning/REQUIREMENTS.md` — GATE-02, DEBT-01, DOC-01; DEBT-01 wording must be reconciled with the v3.6 exception decision above.
- `.planning/ROADMAP.md` — Phase 115 goal, success criteria, ordering constraint that GATE-02 precedes DEBT-01.
- `.planning/STATE.md` — current v12.0 status, prior decisions, and deferred validation-ledger debt context.
- `.planning/research/SUMMARY.md` — v12.0 proof-honesty synthesis; explicitly calls out the `expected_phases` hardcoded fallback and closeout ledger/doc-truth cleanup.
- `.planning/research/PITFALLS.md` — pitfalls for stale validation debt and doc-truth precedence.
- `.planning/MILESTONE-ARC.md` — contracts-first/proof-always posture; artifact parity and closeout ledger truth.

### Project prompt guidance
- `prompts/crosswake-elixir-oss-dna.md` — install truth, public contract honesty, proof lanes, release truth, and planning artifacts as long-term memory.
- `prompts/crosswake-research-synthesis.md` — explicit runtime/support boundaries and anti-patterns; useful as project thesis guardrail even though this phase is non-runtime.
- `prompts/crosswake-gsd-project-brief.md` — Crosswake scope, house style, and delivery/quality expectations.
- `prompts/crosswake-brand-book.md` — only relevant for doc microcopy tone: calm, explicit, no hype. No visual UI work in this phase.

### Closeout verifier code and tests
- `lib/crosswake/planning/closeout_verifier.ex` — main implementation surface; current `@v40_phases` and `expected_phases/1` fallback live here.
- `lib/mix/tasks/closeout.verify.ex` — Mix task wrapper; should continue printing the verifier report and raising on failed reports.
- `test/crosswake/planning/closeout_verifier_test.exs` — primary fixture tests for check ids, prior debt, stale deferrals, and missing ledger behavior.
- `test/mix/tasks/closeout_verify_test.exs` — Mix task behavior; add malformed/missing `expected_phases` output + `Mix.Error` coverage here.
- `test/crosswake/planning/closeout_ci_parity_test.exs` — closeout workflow parity; currently references `.github/workflows/phase69-proof.yml`.
- `.github/workflows/phase75-closeout-gate.yml` — standing closeout gate workflow to inspect if parity coverage is updated.

### Existing ledger and closeout artifacts
- `.planning/quick/260603-nzr-tighten-validation-ledger-closeout-gate/260603-nzr-SUMMARY.md` — prior quick task that tightened missing-ledger detection but left the `expected_phases` fallback and backlog cleanup.
- `.planning/milestones/v3.6-CLOSEOUT.md` — authoritative v3.6 exception basis; states phase dirs were never archived and numbers were reused.
- `.planning/milestones/v3.6-ROADMAP.md` and `.planning/milestones/v3.6-REQUIREMENTS.md` — v3.6 supporting evidence for the exception artifact.
- `.planning/milestones/v3.8-phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-VALIDATION.md`
- `.planning/milestones/v3.8-phases/55-session-handoff-tickets-and-authority-projection/55-VALIDATION.md`
- `.planning/milestones/v3.8-phases/56-step-up-intent-and-plug-liveview-ceremony/56-VALIDATION.md`
- `.planning/milestones/v3.8-phases/57-oauth-passkey-and-native-return-boundaries/57-VALIDATION.md`
- `.planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-VALIDATION.md`
- `.planning/milestones/v3.9-phases/62-diagnostics-support-truth-and-docs/62-VALIDATION.md`
- `.planning/milestones/v3.9-phases/63-hermetic-proof-and-advisory-promotion-criteria/63-VALIDATION.md`
- `.planning/milestones/v3.8-MILESTONE-AUDIT.md` and `.planning/milestones/v3.9-CLOSEOUT.md` — existing audit/closeout precedent for resolved ledger debt and append-only truth.

### v8.0 doc-truth artifacts
- `.planning/MILESTONES.md` — add document-precedence rule and v8.0 entry here.
- `.planning/v1.0-MILESTONE-AUDIT.md` — annotate append-only; preserve original status and scores.
- `.planning/milestones/v8.0-ROADMAP.md` — v8.0 shipped details and accepted tech debt.
- `.planning/PROJECT.md` — current v8.0 shipped summary and validated SYNC/OFFC/BDGT/BRND requirement marks.

### External research references
- `https://hexdocs.pm/mix/Mix.html` — Mix task/reporting behavior; `Mix.raise/1` is the expected CLI failure path after rendering useful output.
- `https://hexdocs.pm/nimble_options/` — Elixir ecosystem precedent for explicit schemas and required option validation.
- `https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions` — CI behavior and `continue-on-error` semantics.
- `https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches` — required status checks as merge gates.
- `https://keepachangelog.com/en/1.1.0/` — changelog/milestone history as curated human-readable truth.
- `https://github.com/architecture-decision-record/architecture-decision-record` — immutable/append-only decision record guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Planning.CloseoutVerifier.Check` already gives every finding a stable id, subject, source, observed text, hint, posture, and details map. Reuse it for `closeout.expected_phases`; do not replace the report API with raw exceptions.
- `relax_inactive_closeout/2` is the existing mechanism that keeps current-closeout artifact checks present but non-blocking while no active closeout exists.
- `phase_paths/4` already searches both archived and live phase directories. Keep this behavior, but feed it only validated phase lists.
- Existing v3.8/v3.9 `*-VALIDATION.md` files already contain rich body evidence and commands. Phase 115 should add normalized frontmatter evidence without rewriting the body narrative.
- `Mix.Tasks.Closeout.Verify` already raises only after rendering the report; this is the right CLI shape to preserve.

### Established Patterns
- Planning frontmatter is treated as a machine contract. Missing required fields should be explicit failures, not defaulted guesses.
- Historical audits are append-only. When truth changes, add notes/re-audits instead of overwriting the original snapshot.
- Public proof and support claims must be backed by deterministic local evidence when possible. Live provider/API checks are not required for historical ledger cleanup.
- Active deferrals require shaped `owner/scope/reason/revisit_phase/evidence/status` entries. Resolved or closed entries must not continue to act as escape hatches.

### Integration Points
- `validation_ledger_check/2` should become stricter for real ledgers: `nyquist_compliant: true` plus concrete evidence metadata.
- `prior_validation_debt_check/2` should understand that a resolved v3.6 exception artifact is a legitimate terminal state, but unresolved/stale prior debt remains blocking.
- Planner should decide whether to add a new focused planning-doc test or extend an existing planning test to cover DOC-01.
- If closeout workflow parity is touched, keep the scope narrow: prove the standing closeout gate runs `mix closeout.verify` and relevant tests; do not restructure CI unless required.

</code_context>

<specifics>
## Specific Ideas

- User explicitly requested all four areas be researched with subagents and wanted one coherent recommendation set. Four advisor research passes converged on the decisions above.
- The through-line across every recommendation is “do not make proof artifacts lie”: no hardcoded fallback, no synthetic v3.6 phase evidence, no body-only attestation hidden behind `nyquist_compliant: true`, and no rewriting an old audit score to make history cleaner.
- Documentation microcopy should use calm truth language: “point-in-time snapshot,” “accepted exception,” “not reconstructable,” “subsequently reconciled.” Avoid dramatic or apologetic phrasing.

</specifics>

<deferred>
## Deferred Ideas

- Full YAML/frontmatter schema parsing with a dependency such as a YAML parser or NimbleOptions-backed struct can be a later cleanup if regex parsing becomes too brittle. Phase 115 only needs strict validation of the current closeout contract.
- Live verification of historical GitHub run IDs/artifacts is deferred. For this phase, concrete local test files and commands are enough.
- A general planning-governance ADR for document precedence is deferred. `MILESTONES.md` is the canonical location for this phase.
- Broader closeout CI modernization is deferred unless planner finds the parity test is actively misleading.

</deferred>

---

*Phase: 115-closeout-verifier-honesty-ledger-backlog-doc-truth*
*Context gathered: 2026-06-18*
