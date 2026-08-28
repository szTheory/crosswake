# Phase 164: Dependency Security and Gate Authority - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-28
**Phase:** 164-dependency-security-and-gate-authority
**Areas discussed:** dependency remediation, required-context authority, test ownership and
isolation, aggregator semantics

---

## Dependency Remediation

| Option | Description | Selected |
|--------|-------------|----------|
| Conservative fixed line | Use the newest fixed patch on the current minor when possible; widen only with proof | ✓ |
| Latest allowed | Resolve every dependency to the newest version admitted by current broad constraints | |
| Advisory exception | Retain vulnerable locks and document a temporary exception | |

**User's choice:** Follow the agent's recommendation automatically.
**Notes:** Both supported lockfiles must be audited; no credentials are needed for the audit.

---

## Required-Context Authority

| Option | Description | Selected |
|--------|-------------|----------|
| Extend current detector | Reuse local inventory, registration audit, and green-first registrar | ✓ |
| New gate registry | Create a second required-context declaration source | |
| GitHub-only inspection | Depend on live branch-protection state without a repository-local uniqueness guard | |

**User's choice:** Follow the agent's recommendation automatically.
**Notes:** External administration authority is a specific handoff only if the current session lacks
it; repository proof remains automated.

---

## Test Ownership and Isolation

| Option | Description | Selected |
|--------|-------------|----------|
| Repair and prove | Map every test file to a required lane, restore mutated state, then remove serial crutches when proven | ✓ |
| Keep serial | Preserve `--max-cases 1` indefinitely as the isolation strategy | |
| Exclude unstable files | Remove stateful tests from merge-blocking execution | |

**User's choice:** Follow the agent's recommendation automatically.
**Notes:** Verification must exercise isolation and complete-suite behavior; retries are not proof.

---

## Aggregator Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Closed vocabulary | Only success passes; explicit irrelevance is neutral; every other/missing state fails | ✓ |
| Treat skips as neutral | Allow skipped leaves to avoid blocking the rollup | |
| Workflow-specific logic | Let every aggregator implement different result rules | |

**User's choice:** Follow the agent's recommendation automatically.
**Notes:** Extend the existing negative control and sibling parity contract.

## the agent's Discretion

- Helper/module names, fixture shape, focused test organization, and bounded seed count.
- Concise failure and step-summary wording.

## Deferred Ideas

- Phase 165 owns CI efficiency and orchestration consolidation.
- Phases 166-168 own clean-checkout quality, docs/PR reconciliation, and the release candidate.
