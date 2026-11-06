# Phase 198: Android foreign-host proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-05
**Phase:** 198-android-foreign-host-proof
**Areas discussed:** Parity ledger and vector-set hash; Kotlin test floor and JSON stack; Foreign Gradle host proof; Android claim ceiling

**Mode:** Fan-out, per the user's standing boilerplate prompts. Four research subagents ran in parallel, each from several role lenses plus an adversarial pass. Their recommendations were synthesized without a question-by-question interview.

---

## Parity ledger and vector-set hash

| Option | Description | Selected |
|--------|-------------|----------|
| A | Generated public guide via docs.sync, raw-byte SHA-256, generated native constants, ExUnit cross-check | ✓ |
| B | Same guide, hash in sidecar resource files | |
| C | Canonical-JSON (RFC 8785) hash | |
| D | Non-public contract.gen artifact, hash checked only in ExUnit | |

**Choice:** A. **Notes:** found that `priv/contract_vectors/` holds only the Elixir-only topology file; the shared corpus is `test/fixtures/bridge_contract_vectors.json`. The ledger globs both and the corpus is not moved.

## Kotlin test floor and JSON stack

| Option | Description | Selected |
|--------|-------------|----------|
| A | Keep platform org.json, keep Crockford test artifact | |
| B | Keep platform org.json, swap test artifact to AOSP-derived android-json | ✓ |
| C | kotlinx.serialization in production | |
| D | Vendor AOSP org.json source | |

**Choice:** B. **Notes:** `androidx.webkit` is imported so it stays; dead kotlinx-serialization removed; about 30 new tests; derived count-floor checker with negative controls. Android-only ungated `server.*` commands documented and deferred, not changed.

## Foreign Gradle host proof

| Option | Description | Selected |
|--------|-------------|----------|
| A | New script reusing release-host generator, advisory CI job, published-version intersection | ✓ |
| B | Generate from checkout then sed version | |
| C | Extend verify_android_public_build.sh | |
| D | Rely on post-publish release job | |

**Choice:** A. **Notes:** three anti-vacuous guards (probe test, AAR byte check, settings check); strict wrong-coordinate control; promotion derived from CI history. Gradle message and cost are unverified until the first CI run.

## Android claim ceiling

| Option | Description | Selected |
|--------|-------------|----------|
| A | Prose lint only | |
| B | Typed ceiling, ledger cell computed, capability map unchanged | |
| C | Typed ceiling plus typed android_evidence field on every capability row, shared boundary constant, prose backstop | ✓ |
| D | New ledger-only taxonomy | |

**Choice:** C. **Notes:** fallback to B if the 11-column capability map is unacceptable; backstop scanner measured before it becomes blocking.

---

## Claude's Discretion

Module and file names beyond those listed, plan and wave split, whether to extract `parseBody`/`listenerAllows`, choice of probe class.

## Deferred Ideas

Gating `server.*` bridge commands, dead template webkit line, example-host org.json alignment, checkout-seded foreign-host leg, required promotion, canonical-JSON/kotlinx/vendoring alternatives.
