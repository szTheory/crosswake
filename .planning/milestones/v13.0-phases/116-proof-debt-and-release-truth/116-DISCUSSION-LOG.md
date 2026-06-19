# Phase 116: Proof Debt And Release Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18T18:49:46Z
**Phase:** 116-Proof Debt And Release Truth
**Areas discussed:** TODO-001 disposition, Release-truth wording, Drift guard shape, Phase 116 boundary vs Phase 118

---

## TODO-001 Disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Fix both example-host debts | Fix Flashcards schema/test drift and Chimeway nondeterminism so public proof does not depend on known failing/flaky tests. | ✓ |
| Fix Flashcards and exclude Chimeway | Clean the core adoption/offline exemplar but narrowly exclude notification-open flake if repair expands outside Phase 116. | Fallback only |
| Exclude both from public proof | Fastest public-proof cleanup but leaves the example host broken and weakens adopter confidence. | |
| Build broader DB test harness | Durable long-term test infrastructure but wider than Phase 116 unless needed for TODO-001. | |

**User's choice:** Asked to consider all and make the best coherent recommendation.
**Notes:** Subagent research and targeted local test run both support fixing both by default. The parent run confirmed 10 tests, 5 failures in the targeted example-host files.

---

## Release-Truth Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid exact facts plus derived prose plus labeled fixtures | Use exact `0.1.2` facts where trust depends on current truth; use package-version wording in reusable prose; label old fixtures explicitly. | ✓ |
| Exact `0.1.2` everywhere | Very clear today, but will stale on every release and may erase historical fixture meaning. | |
| Preserve `0.1.0` manifests and label only around them | Lower churn but weak adopter confidence because public examples still look stale. | |
| Release-please-managed docs/manifests | Useful for narrow machine-owned fields, risky for narrative docs and historical fixtures. | |

**User's choice:** Asked to consider all and make the best coherent recommendation.
**Notes:** The hybrid policy aligns release truth, future maintenance, and fixture honesty.

---

## Drift Guard Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone scanner script | Fast and language-agnostic, but easier to become regex soup and less idiomatic locally. | |
| ExUnit docs-contract test | Idiomatic, runs in normal `mix test`, can derive package version, and matches existing Crosswake docs-contract style. | ✓ |
| Publish-readiness integration | Good diagnostic surface, but heavier and less likely to catch every doc edit early. | Follow-on |
| ExDoc build checks | Good package/docs smoke, but stale prose can build cleanly. | Complement only |

**User's choice:** Asked to consider all and make the best coherent recommendation.
**Notes:** The selected guard should be semantic and narrow: stale current-version claims, `0.1.2 pending`, unlabelled `0.1.0` current-baseline prose, and deferred-standalone-shell contradiction.

---

## Phase 116 Boundary Vs Phase 118

| Option | Description | Selected |
|--------|-------------|----------|
| Only remove known-bad proof commands | Preserves roadmap purity, but leaves public docs able to route users into broken instructions. | |
| Add minimal front-door safety edits | Stops public readers from hitting known-bad commands or fictional offline API while preserving Phase 118 ownership of the full rewrite. | ✓ |
| Temporarily depublish or redirect stale pages | Honest, but creates a dead-end first-read experience. | |
| Pull full Phase 118 rewrite into Phase 116 | Ends drift immediately, but violates ordering and risks premature native/support claims. | |

**User's choice:** Asked to consider all and make the best coherent recommendation.
**Notes:** Phase 116 should stop harm now; Phase 118 should make the first-run path excellent after Phase 117 vocabulary and Phase 119 classification are settled.

---

## Claude's Discretion

- Downstream agents may choose the exact ExUnit helper/test organization.
- Downstream agents may choose the exact minimal safety-copy wording as long as it preserves the proof labels and Phase 118 boundary.
- Downstream agents may decide whether old `0.1.0` artifacts are relabeled or regenerated based on how public-facing each artifact is.

## Deferred Ideas

- Full quick-start/adoption rewrite remains Phase 118.
- Native evidence classification remains Phase 119.
- Full collateral/artifact proof package remains Phase 120.
- Broad example-host DB harness remains deferred unless needed to fix TODO-001 durably.
