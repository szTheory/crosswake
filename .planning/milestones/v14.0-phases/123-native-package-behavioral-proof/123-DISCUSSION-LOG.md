# Phase 123: Native Package Behavioral Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 123-native-package-behavioral-proof
**Areas discussed:** Vector coverage model, Vector delivery, CI topology, Native version source

---

## Vector coverage model

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid | Bridge request→reply behaviors become rich data-driven vectors; activation success/failure + delegate-success paths are code-level tests that load expected version/denial-reason constants from the same JSON. | ✓ |
| Full data-driven | Every one of the six behaviors fully declared as a vector (session_overrides, manifest_overrides, installed-packs, delegate-present flags, expected presentation type). | |

**User's choice:** Hybrid (recommended)
**Notes:** Every behavior stays version-anchored to the file (a bump fails it) without forcing whole manifest/delegate object-graphs into JSON. Requires growing the schema with a `session_override` block (bridge `evaluate()` reads route/capability/pack/origin from the session). Expanding vectors = editing the Phase-121 gen task `vectors_json/4` and regenerating — in-scope; the gen task moduledoc already says the seed is "consumed by Phase 123."

---

## Vector delivery

| Option | Description | Selected |
|--------|-------------|----------|
| gen-emits per-package copies | Extend `mix crosswake.contract.gen` to write DO-NOT-EDIT copies into iOS test resources + Android src/test/resources; GUARD-02 covers them automatically; packages stay self-contained. | ✓ |
| Relative-path / symlink to root file | Tests read the single repo-root file via relative path or symlink; no gen change but fragile across SPM/Maven packaging. | |

**User's choice:** gen-emits per-package copies (recommended)
**Notes:** Requires a `resources:` declaration on the Swift testTarget in Package.swift (currently none). GUARD-02 generate-and-diff covers the new outputs for free; optionally extend GUARD-01's tripwire list for friendlier local failures.

---

## CI topology

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated gate + register script | New `native-behavioral-proof-gate.yml` mirroring Phase 122: Kotlin JVM job → own alls-green aggregator = sole new required check, registered via cloned register-*.sh; Swift macOS advisory job excluded from aggregator. | ✓ |
| Fold into contract-drift-gate.yml | Add Kotlin job as a sibling under the existing contract-drift aggregator; fewer required checks but couples native proof to contract-drift domain. | |

**User's choice:** Dedicated gate + register script (recommended)
**Notes:** Consistent with the one-gate-per-domain idiom. Recognized that the Elixir "bump fails the third suite" *version-field* property is already delivered by Phase 122 GUARD-01 (don't duplicate); Phase 123 adds a new Elixir *behavioral* vector test (anti-vacuous proof) — flagged as a research question to confirm the Elixir single decision seam.

---

## Native version source

| Option | Description | Selected |
|--------|-------------|----------|
| Reject — read version from loaded JSON | Native tests assert against `bridge_protocol_version` loaded from the committed vectors file, not a hardcoded native constant. | ✓ |
| Add native version constants | Follow the research doc: add a version constant per platform for tests to compare against. | |

**User's choice:** Reject — read version from loaded JSON (recommended)
**Notes:** A per-platform version literal is a new drift surface — exactly what v14.0 exists to eliminate. Captured loudly in CONTEXT because `NATIVE-TESTING.md` §9 recommends the opposite and downstream agents will read it.

---

## Claude's Discretion

- Exact test file names/locations and per-language vector iteration style.
- Precise expanded `session_override`/`request_override` field set (must drive every bridge denial).
- Whether GUARD-01's tripwire list gains the two native copies.
- Swift `Package.swift` resource rule (`.copy` vs `.process`); CI cache keys / step ordering.
- The Elixir behavioral-test seam, pending the D-09 research answer.

## Deferred Ideas

- Native `>=` min-version-floor reconciliation + compatibility guide/support-matrix/changelog labels — Phase 124 / COMPAT-*.
- Pre-publish fixture-verification gate — v14.0 publish step (after all four phases green).
- swift-testing / JUnit 5 migration and Linux SwiftPM test support — future hardening only; macOS-only advisory is sufficient.
- Turbine / StateFlow reactive-stream assertions — only if a future behavior needs stream-level proof.
