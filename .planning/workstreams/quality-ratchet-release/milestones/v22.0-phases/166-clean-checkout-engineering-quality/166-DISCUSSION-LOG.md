# Phase 166: Clean-Checkout Engineering Quality - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-09
**Phase:** 166-clean-checkout-engineering-quality
**Areas discussed:** Clean-checkout entry point, Code-cleanup boundary, Artifact and residue policy,
Failure and legacy-label experience

---

## Clean-checkout entry point

| Option | Description | Selected |
|--------|-------------|----------|
| Expand `mix verify` | Make the existing Mix alias own every repository surface. Familiar, but it changes the alias's established meaning and makes Mix an unnatural owner of browser, Swift, Gradle, and repository-policy work. | |
| Named stages only | Keep each proof independently runnable. Focused and explicit, but easy to omit and unable to provide a trustworthy complete verdict. | |
| Repository facade plus fixed stages | Add one complete purpose-named command over independently runnable stages while preserving existing commands and CI leaf authority. | ✓ |
| Container-only verification | Make one image the verification environment. Repeatable for Linux work, but unable to own Xcode honestly and costly to maintain. | |

**User's choice:** Asked for delegated research, one coherent recommendation, and no manual
arbitration; approved the facade-plus-fixed-stages recommendation as part of the complete set.
**Notes:** Preserve `mix verify`; validate exact prerequisites; allow only lock-governed project
dependency fetches; never silently skip Apple proof; protect local/CI command parity.

---

## Code-cleanup boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Milestone diff only | Review only lines/files changed during v22. Small, but may strand an adjacent owner of the same invariant. | |
| Bounded ownership cone | Begin with the v22 diff and expand only through a recorded direct ownership edge supported by executable evidence. | ✓ |
| Broad repository cleanup | Search and refactor the whole repository. May expose old debt, but creates unbounded scope and compatibility risk. | |

**User's choice:** Approved the bounded, evidence-triggered ownership cone.
**Notes:** Record `candidate -> evidence -> owner -> disposition`; use strict evidence for deadness,
duplication, and fallback removal; retain uncertain candidates as unproven; do not expand Android,
adopter, documentation, release, or product scope.

---

## Artifact and residue policy

| Option | Description | Selected |
|--------|-------------|----------|
| `.gitignore`/denylist only | Familiar and cheap, but ignored does not establish legitimate ownership and broad patterns can conceal mistakes. | |
| Repository-wide allowlist | Explicitly inventory every artifact. Strong in theory, but brittle across tool versions and enormous ignored dependency/build trees. | |
| Explicit policy plus Git snapshots | Classify stable transient, tracked-generated, and forbidden families; combine that policy with clean before/after Git state and generator drift proof. | ✓ |
| Isolated checkout only | Protect the caller and make cleanliness literal, but does not define artifact intent by itself. | |

**User's choice:** Approved the combined explicit-policy and clean-snapshot recommendation, using an
isolated exact-commit checkout for canonical evidence.
**Notes:** Never stage to detect drift, trust local excludes as policy, print suspect contents, use
`git clean -xfd`, or delete global/shared temporary state. Cleanup owns exact invocation paths only.

---

## Failure and legacy-label experience

| Option | Description | Selected |
|--------|-------------|----------|
| Pure fail-fast | Stop at the first failure. Fast, but hides independent defects and requires repeated full runs. | |
| Continue everything | Collect every result. Broad, but creates cascading noise and wastes expensive work after prerequisite failures. | |
| Dependency-aware hybrid | Fail fast on invalid prerequisites, preserve dependent order, continue independent families, and always run cleanup/residue checks. | ✓ |
| Machine-first event schema | Emit structured events with renderers. Powerful, but adds taxonomy and a public schema without a demonstrated consumer. | |

**User's choice:** Approved dependency-aware hybrid execution and compatibility-preserving naming.
**Notes:** Use purpose-led new names and literal `PASS`/`FAIL`/`BLOCKED`; preserve existing machine
contracts and provenance names; give each failure one safe exact correction; terminal output remains
portable authority and GitHub rendering stays additive.

## the agent's Discretion

- The user explicitly delegated option evaluation and recommendation after requesting parallel
  specialist research across ecosystem practice, architecture, security, DevOps/SRE, reviewability,
  adversarial failure modes, JTBD, developer ergonomics, and accessible maintainer-facing output.
- Exact filenames, flags, internal stage-inventory representation, tool-preflight order, policy
  schema, negative fixtures, and output wrapping remain implementation discretion within the locked
  contracts.

## Deferred Ideas

None. The research rejected a new dashboard, machine-event taxonomy, container-only environment,
broad repository cleanup, Android breadth, adopter activation, documentation reconciliation, and
release work as outside Phase 166.
