# Requirements: Crosswake — v14.0 Runtime Contract Confidence

**Defined:** 2026-06-20
**Core Value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.

**Milestone goal:** Make the bridge/runtime contract boringly canonical and hard to drift — one source of truth across Elixir, manifest compatibility, generated shells, reusable native packages, examples, proof lanes, and docs — then prove it directly in the native packages. Coherence work, not feature breadth. Research synthesis: `.planning/research/SUMMARY.md`.

**Phase ordering is non-negotiable** (registry immutability + lockstep release): canonical source → drift guards → native behavioral proof → compatibility semantics & docs truth → any publish last.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Canonical Contract Source (CANON)

- [ ] **CANON-01**: A single canonical Elixir source declares the bridge protocol version; `Crosswake.Bridge.Contract`, `Crosswake.Manifest.Types`, and shell fixtures all derive from it instead of carrying independent literals.
- [ ] **CANON-02**: Each of the three version axes (manifest schema, bridge protocol, native runtime) has exactly one named authoritative source, with no second hand-maintained copy.
- [ ] **CANON-03**: A `mix crosswake.contract.gen` task renders the canonical contract into every derived non-Elixir surface (JSON fixtures, generated shell templates, native conformance vectors, and a docs snippet).
- [ ] **CANON-04**: The `1.1.0` vs `1.0.0` protocol-version divergence is resolved to one correct current value without silently breaking the published `crosswake 0.1.x` adopter contract.
- [ ] **CANON-05**: The silent Kotlin `?: "1.0.0"` native-runtime fallback (`ActivationCoordinator.kt:594`) is removed so native always reads the version and never assumes a default.

### Drift Guards (GUARD)

- [ ] **GUARD-01**: A deterministic, browser-free, merge-blocking ExUnit drift test fails when any derived surface's contract version diverges from the canonical source, and its failure message names the one file to edit plus the exact regenerate command.
- [ ] **GUARD-02**: A generate-and-diff CI check (`mix crosswake.contract.gen` followed by `git diff --exit-code`) fails when generated contract artifacts are hand-edited or stale.
- [ ] **GUARD-03**: A `contract_version_parity` doctor check reports contract drift to operators, as a sibling to the existing `generator_coordinate_parity` check.
- [ ] **GUARD-04**: The contract drift checks are registered in the merge-blocking aggregator and branch protection, while native-toolchain-dependent checks remain advisory (required-vs-advisory split).

### Native Package Behavioral Proof (NTEST)

- [ ] **NTEST-01**: A single committed `bridge_contract_vectors.json` of canonical request → expected-outcome cases is loaded by the Elixir, Swift, and Kotlin test suites so one version bump fails all three.
- [ ] **NTEST-02**: The iOS `crosswake-shell-core-ios` package has XCTest behavioral tests (no simulator) covering activation success/failure, bridge denial, capability allowlist, active-route check, pack-version check, and delegate/escape-hatch behavior.
- [ ] **NTEST-03**: The Android `crosswake-shell-core-android` package has JVM JUnit behavioral tests (no emulator) covering the same six behaviors.
- [ ] **NTEST-04**: Native package test lanes run in CI (deterministic JVM lane merge-blocking where feasible; macOS native lane advisory) without claiming simulator or device support.

### Compatibility Semantics & Adopter Truth (COMPAT)

- [ ] **COMPAT-01**: The bridge-protocol compatibility check is reconciled to a single `>=` min-version-floor semantics across Elixir and native (the native exact-equality check is changed to negotiate by floor, matching `compatible_version?/2`), so additive protocol bumps no longer cause silent denials.
- [ ] **COMPAT-02**: Each version axis is mapped to a rebuild class (core-only / compat-bump only / native-rebuild-required) with documented additive-vs-breaking rules.
- [ ] **COMPAT-03**: The support matrix and a compatibility guide communicate the rebuild classes to adopters, leading with a decision table before explanatory prose.
- [ ] **COMPAT-04**: Doctor findings for a version/rebuild mismatch name the change class, the full action sequence (regenerate → rebuild → resubmit App Store/Play Store → coordinated deploy), the denial reason seen in logs, and a docs link.
- [ ] **COMPAT-05**: A changelog upgrade-impact label communicates the rebuild requirement for each release that touches the contract.

## v2 Requirements

Deferred behind runtime-contract confidence (tracked, not in this roadmap).

### Native Runtime & Generated-Shell Lifecycle

- **LIFE-01**: Repeatable simulator/emulator/device native UAT where support labels can remain honest.
- **LIFE-02**: A stronger upgrade/patch runbook for host-owned generated shells.

### Day-2 Surfaces

- **DASH-01**: Surface offline adoption / operator metrics (carried from v8.0).
- **NTV-01**: Extend storage budgets to native physical disk space (carried from v8.0).
- **SYNCP-01**: Offline-sync productization — better `mix crosswake.gen.sync` scaffolding and reusable idempotent replay helpers, without claiming a generic sync engine.

## Out of Scope

Explicitly excluded for v14.0 to prevent scope creep. This milestone is coherence work only.

| Feature | Reason |
|---------|--------|
| New bridge commands or capability families | Coherence milestone; widening the command vocabulary belongs to a later capability wedge |
| IDL/protobuf redesign of the contract | Disproportionate for three version strings + a small command vocabulary; a committed canonical file + diff-check suffices |
| Bridge envelope restructuring | Out of scope; would risk the published 0.1.x adopter contract |
| Breaking the published `crosswake 0.1.x` contract | Existing adopters must keep working; canonical resolution must stay backward-safe |
| Promoting simulator/device native evidence to merge-blocking support truth | Native environment proof stays advisory; only deterministic checks block merges |
| A full codegen/IDL pipeline | Over-engineering relative to the problem; a small canonical file + generate-and-diff is the disciplined choice |

## Traceability

Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CANON-01 | Phase 121 | Pending |
| CANON-02 | Phase 121 | Pending |
| CANON-03 | Phase 121 | Pending |
| CANON-04 | Phase 121 | Pending |
| CANON-05 | Phase 121 | Pending |
| GUARD-01 | Phase 122 | Pending |
| GUARD-02 | Phase 122 | Pending |
| GUARD-03 | Phase 122 | Pending |
| GUARD-04 | Phase 122 | Pending |
| NTEST-01 | Phase 123 | Pending |
| NTEST-02 | Phase 123 | Pending |
| NTEST-03 | Phase 123 | Pending |
| NTEST-04 | Phase 123 | Pending |
| COMPAT-01 | Phase 124 | Pending |
| COMPAT-02 | Phase 124 | Pending |
| COMPAT-03 | Phase 124 | Pending |
| COMPAT-04 | Phase 124 | Pending |
| COMPAT-05 | Phase 124 | Pending |

**Coverage:**
- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-20*
*Last updated: 2026-06-20 after roadmap creation (traceability populated)*
