# Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-03
**Phase:** 64-Runtime-Line Policy Contract & Support-Truth Taxonomy
**Mode:** advisor (minimal_decisive calibration — research-backed, decisive single recommendation per area)
**Areas discussed:** Rebuild-policy derivation, Evidence taxonomy shape, Rebuild matrix projection, Android promotion criteria

---

## Area selection

User selected ALL FOUR surfaced gray areas and issued a standing directive: research each via parallel subagents (pros/cons/tradeoffs with a concrete example per approach; Elixir/Plug/Ecto/Phoenix idioms; lessons — including wins and footguns — from comparable libs/apps in this and other ecosystems; emphasis on DX and least-surprise; consult the `prompts/` research corpus), then one-shot a single COHERENT recommendation set so the user doesn't have to decide piecemeal.

Four parallel Sonnet advisor researchers ran (one per area), cross-referencing each other. Results synthesized into one coherent set; two cross-seam overlaps reconciled (the evidence enum the matrix displays; where the verification-method field attaches).

---

## Rebuild-policy derivation

| Option | Description | Selected |
|--------|-------------|----------|
| Static declarative table | New module owns an exhaustive change_class → verdict table, independent of manifest data | |
| Hybrid (derive from manifest data + locked static for system-level) | Capability-axis changes derive from existing `Capability.rebuild`; system-level classes from a locked `@system_rebuild_classes` attr | ✓ |

**User's choice:** Hybrid (researcher recommendation, accepted via "Lock all four").
**Notes:** Decisive factor — static table duplicates the existing `rebuild` field (drift hazard, against house style). Hybrid keeps one source of truth and makes the native_runtime_version-derivation invariant provable via parity against `action_classes()`. Footgun explicitly avoided: classify by runtime context, not change-class label (the Expo/CodePush silent-OTA-break failure).

---

## Evidence taxonomy shape

| Option | Description | Selected |
|--------|-------------|----------|
| Orthogonal axis (`verification_method`) | Add a new provenance axis alongside `proof_class`; keep proof_class as the merge-gate axis | ✓ |
| Refine/replace `proof_class` | Collapse merge-gate + provenance into one richer enum | |

**User's choice:** Orthogonal axis.
**Notes:** Refinement overloads one atom with two orthogonal meanings → badge-inflation / evidence-laundering footgun (SLSA, notarization, test-pyramid all separate these), and breaks existing `proof_class` pattern-matches on a shipped lib. Tier enum locked: `:none | :provider_advisory | :jvm_hermetic | :emulator_advisory | :device_verified`. CI-only-never-device guaranteed structurally (construction/validation + render invariants).

---

## Rebuild matrix projection

| Option | Description | Selected |
|--------|-------------|----------|
| Typed row list `[RuntimeLineRow.t()]` | New struct, one row per major runtime-line band, projected via `SupportMatrix.rebuild_matrix/1`, rendered in doctor human+JSON | ✓ |
| Version-keyed map | `%{native_runtime_version => %{...}}` lookup map | |

**User's choice:** Typed row list.
**Notes:** Fits the uniform list-of-typed-structs convention in `SupportMatrix`; human/JSON parity is structural (shared traversal). Map shape breaks the convention and creates two drift-prone serialization paths. Reconciliation locked: the row's `evidence_tier` reuses the SAME `verification_method` enum (no separate 3-value enum); `rebuild_required` comes from RebuildPolicy. The matrix displays the other two seams, never re-decides them.

---

## Android promotion criteria

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `promotion_rules()` with two data rows | jvm_hermetic row (promotable now) + device_verified row (gated to Phases 67/68), criteria-as-code | ✓ |
| Dedicated Android promotion contract module | New module/type/indirection | |

**User's choice:** Extend `promotion_rules()`.
**Notes:** Criteria-as-data is the established idiom; existing struct already handles multi-entry platform-specific rules. Dedicated module fragments support truth without adding expressiveness. Values locked honest to the CI-only-JVM reality: `minimum_consecutive_passes: 3`, `freshness_window: "within 30 CI runs"`, `failure_budget: "zero consecutive; single failure resets"`. Scope guardrail: Phase 64 authors criteria as data only — Android stays `:verification_required`; the merge-blocking JVM lane is Phase 67, the actual `:supported` flip is Phase 69.

---

## Claude's Discretion
- Exact module/struct/function/field names and atom spellings (preserve locked semantics).
- `@system_rebuild_classes` representation; `PromotionRuleEntry` field population, `check_ids`, telemetry/check identifiers, `demotion_trigger` prose.
- Proof-test placement/naming; whether `verification_method` validation lives in a constructor guard vs `SupportMatrix.validate/1`.

## Deferred Ideas
- Generator templates / `ADOPT:` markers / Xcode 26 CI — Phase 66.
- Native shell implementation, Android toolchain floor bumps, merge-blocking JVM-hermetic CI lane — Phase 67.
- Advisory emulator lane + device-UAT (where `:emulator_advisory`/`:device_verified` evidence arrives) — Phase 68.
- Docs-contract parity gate, guides parity-lock, actual Android `:supported` promotion, `mix closeout.verify` — Phase 69.
- Diagnostic export seam (redaction allowlist + typed envelope) — Phase 65.
- Nyquist validation-ledger cleanup for Phases 59/60/62/63 (deferred tech debt) — alongside v4.0 validation.
