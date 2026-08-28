# Phase 159: Host-Reusable Proof Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-31
**Phase:** 159-host-reusable-proof-lane
**Areas discussed:** Host integration footprint, Configuration contract, Device scaffold readiness, Evidence and drift gates

---

## Host Integration Footprint

| Option | Description | Selected |
|--------|-------------|----------|
| Integrate into existing suites | Write helpers/specs directly into the adopter's established test layout and modify its wiring. Familiar locally, but risks collisions and rewrites. | |
| Isolated additive proof namespace | Add small host-owned Crosswake directories beside existing ExUnit, Playwright, and iOS proof without reorganizing the host corpus. | ✓ |
| Separate proof application | Generate a dedicated Phoenix/native proof host. Strong isolation, but duplicates setup and stops proving the adopter's real host. | |

**User's choice:** Consider all alternatives, research them with subagents, and choose one coherent recommendation without further decision-by-decision interviewing.
**Notes:** Selected the isolated additive namespace because it preserves existing browser tests and fixtures, proves the real host, and keeps generation reversible within the three-day extraction.

---

## Configuration Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Required CLI flags | Pass every route/storage/endpoint value on every invocation. Small implementation, but repetitive, hard to review, and prone to shell-history drift. | |
| Phoenix application config | Keep a closed durable `config :crosswake, :proof_lane` contract; reserve CLI switches for target/config/action selection. | ✓ |
| Standalone JSON or YAML | Language-neutral config for every tool. Adds a second schema/parser/migration surface without current user value. | |

**User's choice:** Delegated after ecosystem and DX research.
**Notes:** Phoenix application configuration follows the principle of least surprise for this adopter audience. A normalized versioned manifest feeds all generated languages; errors never echo rejected values.

---

## Device Scaffold Readiness

| Option | Description | Selected |
|--------|-------------|----------|
| Complete concrete device flows now | Fully implement replay and pack behavior in Phase 159. Executable, but steals Phase 160/161 ownership and exceeds the time-box. | |
| Executable driver with later capability injection | Generate compiling XCTest/XCUITest and real lifecycle wiring; missing later behavior reports closed blocked/unavailable prerequisites. | ✓ |
| Marked skeletons | Copy placeholder files and README instructions only. Cheapest, but defers Xcode/process-lifecycle risk and can launder scaffolding into readiness. | |

**User's choice:** Delegated after iOS/mobile-harness research.
**Notes:** XCTest validates contracts; XCUITest owns launch/terminate/relaunch and accessibility-driven behavior. Later phases plug assertions into the stable harness without no-op success or hidden test authority.

---

## Evidence and Drift Gates

| Option | Description | Selected |
|--------|-------------|----------|
| Closed allowlist only | Emit a very small schema. Strong construction boundary, but cannot catch unsafe final files or later hand edits alone. | |
| Denylist scanner | Scan flexible evidence for known bad patterns. Useful defense in depth, but incomplete and vulnerable to false confidence. | |
| Typed allowlist plus final scan | Validate before serialization, scan the staged final artifact set, then publish atomically with non-echoing failures. | ✓ |

**User's choice:** Delegated after security, SRE, DevOps, and DX research.
**Notes:** Retained evidence is low-cardinality and closed. Raw `.xcresult`, screenshots, traces, media, logs, payloads, and stable identifiers are never retained. `--check` gates safe completeness; `--diff` is advisory and never rewrites host-owned files.

---

## the agent's Discretion

- The user explicitly requested deep one-shot recommendations across all four areas, informed by
  subagent research, Elixir/Phoenix ecosystem practice, successful cross-framework patterns,
  project prompt research, architecture/security/DevOps/SRE lenses, JTBD, usability, accessibility,
  and the current brand authority.
- Exact internal names, file layout details, encoding, exit-code values, and non-destructive Xcode
  wiring mechanics remain for research/planning within the locked outcomes.

## Deferred Ideas

- Scoped replay/auth behavior remains Phase 160.
- Real pack installation/offline audio remains Phase 161.
- Physical-iPhone execution and dated support evidence remains Phase 162.
- Generic orchestration, dashboards, Android, background sync, and raw native result retention stay
  outside the milestone.
