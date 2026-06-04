# Phase 69: Docs Contract Parity Gate, Android Promotion, and Closeout - Research

**Researched:** 2026-06-03
**Domain:** Documentation Contract Parity, Release Management, and Milestone Closeout
**Confidence:** HIGH

## Summary

Phase 69 is the final capstone for the milestone, responsible for locking the documentation contract to the runtime-line and support-matrix truth, evaluating Android for promotion from `:verification_required` to `:supported`, and running the deterministic milestone closeout sequence via `mix closeout.verify`. 

This phase does not introduce new capabilities. Instead, it asserts structural parity across all surfaces (manifest ↔ shell fixture ↔ guide ↔ doctor) and ensures the project repository explicitly captures the deferred state of non-claims (e.g., standalone publishable shell packages, device-verified Android, and push-delivery).

**Primary recommendation:** Implement `Phase69DocsContractParityTest` to cross-examine `SupportMatrix.canonical()`, `Doctor.JSONFormatter`, and the markdown content of `guides/` to ensure no documentation drifts from the locked code truth; then, update the Android support status to `:supported` based strictly on the `jvm_hermetic` and `generated_shell` promotion criteria, leaving device-verification deferred.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | A merge-blocking docs-contract test verifies that manifest ↔ shell fixture ↔ guide ↔ doctor agree on runtime-line, rebuild, permission/entitlement, and diagnostics truth. | `Crosswake.SupportMatrix` exposes canonical vocabularies and `.doctor` JSON formatter outputs this truth. We must build a test that parses `guides/*.md` and asserts this truth is documented accurately. |
| PROOF-02 | Public guides document the runtime-line policy, rebuild/compatibility matrix, permission/entitlement templates, diagnostics export, and Android verification posture, parity-locked to live support/doctor truth. | Guides must be updated to align perfectly with the Phase 64-68 runtime-line enhancements. |
| PROOF-03 | Milestone closeout (`mix closeout.verify`, REL-01 gate) verifies all v4.0 requirements are mapped and no surface claims first-party shell packages, device-verified Android without evidence, or first-party crash-reporting/push delivery. | Handled via `Mix.Tasks.Closeout.Verify` which checks `.planning/` frontmatter and `CHANGELOG.md` sections for required deferred exceptions. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Docs Contract Parity | Automated Test | Guides / Docs | Code-level tests must assert that human-readable markdown guides accurately reflect the typed Elixir support matrix truth. |
| Android Support Promotion | `SupportMatrix` | CI / ExUnit | The `SupportMatrix` defines the canonical support level (`:verification_required` or `:supported`). Tests validate if the promotion rules are met. |
| Milestone Closeout | `mix closeout.verify` | Planning Artifacts | The closeout task provides a deterministic gate for the milestone by parsing markdown frontmatter and changelog state. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ExUnit` | Core | Proof framework | Existing proof lanes are purely ExUnit-based hermetic tests. |
| `Regex` / `String` | Core | Markdown parsing | Necessary to assert the presence of specific keywords or tables inside `guides/`. |
| `Mix.Tasks.Closeout.Verify` | Core | Milestone verification | Existing project tool to validate `.planning/` artifacts and `CHANGELOG.md` continuity. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. Run the Package Legitimacy Gate protocol before completing this section.

*No external packages are installed in this phase. Code/config-only changes utilizing standard Elixir library and existing Crosswake components.*

## Architecture Patterns

### Pattern 1: Docs Contract Parity Testing
**What:** Writing ExUnit tests that read from `guides/*.md` and assert against `SupportMatrix.canonical()` structures.
**When to use:** Whenever the documentation claims authoritative truth about support versions, rebuild policies, or promotion posture.
**Example:**
```elixir
test "guides document canonical runtime line policy" do
  content = File.read!("guides/compatibility.md")
  canonical = SupportMatrix.canonical()
  
  for row <- SupportMatrix.rebuild_matrix(canonical) do
    assert String.contains?(content, row.runtime_line),
      "Docs must document runtime line #{row.runtime_line}"
  end
end
```

### Anti-Patterns to Avoid
- **Hardcoded Documentation Truth:** Updating the `.md` guides but failing to enforce the synchronization with an ExUnit test. Docs will drift immediately in the next phase.
- **Evidence Laundering:** Claiming `:device_verified` for Android when only `:jvm_hermetic` evidence exists. The docs must explicitly state that Android promotion relies on CI and emulator UAT, not device fleets.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Closeout verification | Custom bash script | `mix closeout.verify` | The project already has a robust, deterministic closeout logic mapped to `.planning/` architecture. |

## Runtime State Inventory

> Include this section for rename/refactor/migration phases only. Omit entirely for greenfield phases.

Step 2.5: SKIPPED (This phase adds tests and documentation; no string/rename migrations occur here).

## Common Pitfalls

### Pitfall 1: Android Promotion Evidence Laundering
**What goes wrong:** The `SupportMatrix` promotes Android to `:supported`, but the tests or docs imply this includes Firebase Test Lab (device) validation.
**Why it happens:** Misinterpreting the `jvm_hermetic` and Phase 68 UAT checklist as real device proof.
**How to avoid:** Explicitly keep the device-verified evidence deferred (DPROOF-01) in `v3.9-CLOSEOUT.md` and explicitly document in `native_shell.md` that Android support is `:jvm_hermetic` (CI) driven.

### Pitfall 2: Failing `mix closeout.verify`
**What goes wrong:** The closeout task fails because `CHANGELOG.md` claims "standalone native shell packages are shipped" or `.planning/v3.9-CLOSEOUT.md` lacks proper `deferred_with_reason` shapes.
**Why it happens:** The strict verifier enforces against premature or false claims (e.g., first-party push delivery).
**How to avoid:** Run `mix closeout.verify` locally during development and ensure the `CHANGELOG.md` and closeout `.planning/` frontmatter are formatted exactly to the requirements.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unverified Guides | Docs Contract Parity | Phase 69 | Prevents documentation drift from the runtime reality. |
| Verification Required | `:supported` (JVM Hermetic) | Phase 69 | Unblocks Android adoption with explicit CI-level caveats. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Android JVM hermetic tests pass successfully, qualifying for `:supported` flip in `SupportMatrix` | Summary | We might flip the status when CI is actually failing, causing a false promotion. |

## Open Questions (RESOLVED)

1. **Android Promotion**
   - What we know: Phase 64 explicitly gated the `:supported` flip until Phase 69.
   - What's unclear: Does the planner want us to actually execute the flip to `:supported` in `SupportMatrix`?
   - Recommendation: Execute the flip to `:supported` on `android` and `android_shell` entries, but keep the `evidence_tier` as `:jvm_hermetic`.
   - **Resolution:** Yes, execute the flip to `:supported` in `SupportMatrix` now that the promotion criteria have passed.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase69_docs_contract_parity_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 | Docs-contract parity | unit | `mix test test/crosswake/proof/phase69_docs_contract_parity_test.exs` | ❌ Wave 0 |
| PROOF-03 | Milestone closeout | unit | `mix closeout.verify` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase69_docs_contract_parity_test.exs` — covers PROOF-01
- [ ] `.planning/milestones/v3.9-CLOSEOUT.md` — required for `mix closeout.verify` execution

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core ExUnit and existing task logic is locked.
- Architecture: HIGH - Contract parity via ExUnit is standard for Crosswake proof lanes.
- Pitfalls: HIGH - The `CloseoutVerifier` explicitly prevents false claims.

**Research date:** 2026-06-03
**Valid until:** 30 days
