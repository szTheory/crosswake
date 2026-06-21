# Phase 121: Canonical Contract Source - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 121-canonical-contract-source
**Areas discussed:** Version value resolution, Per-axis values, Canonical module shape, Gen artifact boundary

---

## Gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Version value: 1.1.0 | Snap stale 1.0.0 surfaces up to 1.1.0 (true current value) | ✓ |
| Per-axis values | Decide which of the three axes move | ✓ |
| Canonical module shape | Where the single constant lives | ✓ |
| Gen artifact boundary | Compile-time Elixir vs gen-emitted surfaces | ✓ |

**User's choice:** All four areas selected (multiSelect).
**Notes:** Each area carried an embedded research-backed recommendation; user opted to discuss all four together as a coupled set.

---

## Version value resolution + per-axis values

Synthesized recommendation presented (not multiple-choice): bridge protocol → `1.1.0` everywhere; manifest schema + native runtime stay `1.0.0`; only the axis with a real additive change (Threadline `thread_id`, commit `4ccc646`) moves. Backward-safe because aligning the manifest to `1.1.0` makes native exact-match pass (resolving a live latent denial) without depending on Phase 124's `>=` change.

**User's choice:** Accepted (no override; "Design needs changes" not selected).
**Notes:** Grounded in commit `4ccc646` which labeled the 1.1.0 bump "additive-minor, no breaking change."

## Canonical module shape

Recommendation: no new module; `Bridge.Contract` stays the bridge-protocol authority, `Manifest.Types` references `Contract.version()` at compile time, manifest-schema and native-runtime axes keep their own named constants in `Manifest.Types`.

**User's choice:** Accepted.
**Notes:** Three named constants, three homes, zero duplicates.

## Gen artifact boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Emit vectors now | `mix crosswake.contract.gen` produces `bridge_contract_vectors.json` in Phase 121; Phase 123 wires it into native suites | ✓ |
| Defer vectors to 123 | 121 emits only fixtures/templates/docs; vectors created fresh in 123 | |
| Design needs changes | Adjust version/axis/module/gen design | |

**User's choice:** Emit vectors now.
**Notes:** Keeps the canonical artifact list complete from the start; Elixir surfaces derive at compile time, only non-Elixir surfaces go through gen with DO-NOT-EDIT headers.

---

## Claude's Discretion

- Internal helper name/location for reading the canonical constant in the gen task.
- On-disk path/name of any intermediate canonical artifact (e.g. a `priv/` JSON) and whether gen reads Elixir constants directly vs an intermediate JSON.
- Exact DO-NOT-EDIT header wording on generated files.

## Deferred Ideas

- Native `>=` floor reconciliation → Phase 124 (COMPAT-01).
- Drift guards (single-reader test, generate-and-diff CI, `contract_version_parity` doctor, aggregator/branch-protection) → Phase 122.
- Wiring vectors into Swift/Kotlin/Elixir suites + six native behaviors → Phase 123.
- Public docs / compatibility guide / support matrix / changelog upgrade-impact labels → Phase 124.
