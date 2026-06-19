# Phase 119: Native Evidence Classification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-19T19:28:04Z
**Phase:** 119-Native Evidence Classification
**Areas discussed:** Checked-In Host Strategy, Evidence Label Contract, Native Docs Reconciliation, Drift Guard Scope

---

## Checked-In Host Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Published-coordinate checked-in hosts | Checked-in iOS/Android hosts use published SwiftPM/Maven coordinates by default; `--local` remains explicit maintainer path. | yes |
| Local-dev checked-in hosts with explicit labels | Keep checked-in hosts local-development proof and label them everywhere as local/advisory. | |
| Hybrid two-host proof | Add separate public-coordinate and maintainer-local host paths. | |
| Generated-only public proof | Treat generated non-local output as the public proof and demote checked-in hosts. | |

**User's choice:** User selected all areas for research-backed recommendation and delegated final choice to Claude.
**Notes:** Subagent research recommended published-coordinate checked-in hosts because Phase 119 requirements name this as preferred, generator templates already support public defaults, and public proof artifacts should match adopter install truth. Tradeoff: maintainer iteration must use explicit `--local`; docs and guards must prevent simulator/device overclaim.

---

## Evidence Label Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Strict dimensional taxonomy plus DRIFT-03 guard | Closed set of labels separating proof class, coordinate mode, and execution environment. | yes |
| Existing Phase 117 labels plus stricter prose | Keep current labels and rely mostly on clearer prose. | |
| Artifact-manifest-first taxonomy | Pull Phase 120 artifact manifest thinking into Phase 119 taxonomy. | |
| Light prose guidance only | Add explanatory prose without a strict testable contract. | |

**User's choice:** User selected all areas for research-backed recommendation and delegated final choice to Claude.
**Notes:** Subagent research recommended strict labels: merge-blocking proof, advisory evidence, local-dev proof, generated public-coordinate proof, checked-in public-coordinate proof, JVM hermetic proof, simulator evidence, emulator evidence, device evidence, verification-required, and rebuild-required. The taxonomy forbids vague "native support" style claims unless immediately qualified.

---

## Native Docs Reconciliation

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid evidence spine plus inline proof chips | Support matrix remains canonical; short labels repeat beside commands, paths, UAT rows, generated READMEs, and future captions. | yes |
| Canonical guide only | Put definitions in one place and link there. | |
| Inline labels everywhere, no canonical spine | Repeat labels everywhere without a canonical generated source. | |
| Split public-coordinate quick start from local-dev maintainer path | Add separate public proof and maintainer-local information architecture. | |

**User's choice:** User selected all areas for research-backed recommendation and delegated final choice to Claude.
**Notes:** Subagent research recommended the hybrid because readers misinterpret evidence at the point of command execution or screenshot viewing. Keep support matrix canonical, but place proof chips near each native command/path/caption. Use careful maintainer voice from `brandbook/BRAND-SPEC.md`.

---

## Drift Guard Scope

| Option | Description | Selected |
|--------|-------------|----------|
| ExUnit docs/source scanner | Scan checked-in native hosts and public docs in `mix test`, with synthetic regressions. | yes |
| Publish-readiness extension | Add a narrow machine-readable doctor summary. | maybe |
| Generator tests only | Rely on existing generator coordinate tests. | |
| Script-only | Add shell scanner outside Mix. | |
| CI job aggregation | Aggregate existing/new tests under a required check. | |

**User's choice:** User selected all areas for research-backed recommendation and delegated final choice to Claude.
**Notes:** Subagent research recommended an ExUnit scanner because existing generator parity does not cover checked-in hosts or public docs. Existing generator tests and `PublishReadiness` remain supporting coverage. Optional publish-readiness extension is acceptable only if narrow and non-duplicative.

---

## Claude's Discretion

- Exact scanner file/module/helper names.
- Exact support matrix source changes and renderer structure.
- Exact inline proof-chip wording, as long as proof class, coordinate mode, execution environment, and limitation remain visible.
- Whether to add a narrow `doctor --check-publish` native-evidence summary after the ExUnit scanner exists.

## Deferred Ideas

- Phase 120 collateral capture, screenshots, recordings, manifests, artifact upload, and caption application.
- Full troubleshooting/rough-edge guide expansion.
- Physical-device, app-store, provider-authority, camera/media-upload, and required simulator/emulator proof promotion.
