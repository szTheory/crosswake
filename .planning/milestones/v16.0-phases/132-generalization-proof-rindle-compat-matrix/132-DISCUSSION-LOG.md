# Phase 132: Generalization Proof (rindle) + Compat Matrix - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-26
**Phase:** 132-generalization-proof-rindle-compat-matrix
**Areas discussed:** rindle owned contracts + test coupling, compat matrix content/shape, drift-test design/locus, rindle clean-room engine handling

---

## Gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| rindle's owned contracts + phase72 test coupling | Public-surface vs companion-private; core test coupling | ✓ |
| Compat matrix content & shape (COMPAT-02) | guides/companion_compatibility.md columns/format/prose | ✓ |
| Drift-test design & locus (COMPAT-03) | Locus, env-conditional-resolver parsing, strictness | ✓ |
| rindle clean-room engine handling | Happy-path vs both-states; engine version cap | ✓ |

**User's choice:** All four — with an explicit mandate: research each with subagents (pros/cons/
tradeoffs, idiomatic Elixir/Plug/Ecto/Phoenix patterns, ecosystem lessons incl. other languages,
DX/UX, brand-book alignment preferring the newer brandbook over `prompts/` references), then
one-shot a single coherent, opinionated recommendation set "so I don't have to think."

**Method:** Four parallel `gsd-advisor-researcher` subagents (Sonnet), each grounded in the live
code + the 130/131 locked recipe + `prompts/` DNA + `brandbook/BRAND-SPEC.md`. Findings re-verified
against the repo before locking (the test coupling turned out to be 6 files, not the 1 first noted;
the rindle engine investigation confirmed `0.3.0 ∉ ~> 0.1` with `0.1.10` as the compliant pin).

---

## ① rindle owned contracts + test coupling

| Option | Description | Selected |
|--------|-------------|----------|
| Contracts/Reconciliation → companion-private, move with rindle | Ecosystem-unanimous; core owns behaviour envelope, companion owns domain model | ✓ |
| Promote any rindle type to the frozen public surface | Widens the frozen 5; breaks SEAM; couples core to companion domain | |
| phase72 → move wholesale to companion lane | Domain proof, D-20 SC#1-class | ✓ |
| phase72 → rewrite in core against the seam | Loses valuable domain assertions; proof vacuity | |
| Core guides test (companions_test.exs) → rewrite to seam, stay in core | Direct alias would trip EXTRACT-03 | ✓ |

**Notes:** Six core-lane files couple to rindle internals (phase72, three phase45_*, phase47 arc,
guides companions_test); split by the D-20 rule. phase47_companion_arc flagged for per-assertion
investigation (cross-companion). Unit tests move verbatim. Largest mechanical reality of the phase.

## ② Compat matrix content & shape

| Option | Description | Selected |
|--------|-------------|----------|
| 6-column single table, one row/companion, verbatim `~> 0.1` | Minimal-but-sufficient for adopter deps JTBD; machine-keyable | ✓ |
| Resolved range instead of verbatim requirement | Adds a transform = drift seam | |
| Add status/maturity + config-snippet columns | Noise at N=2; can't keep accurate | |

**Notes:** Columns: Hex Package | Companion ID | Current Version | Requires crosswake | Engine
Dependency | hexdocs. Five prose sections; honest engine-friction note (live engines exceed `~> 0.1`).
Match `guides/support_matrix.md` style; keep distinct from existing `guides/compatibility.md`.

## ③ Drift-test design & locus

| Option | Description | Selected |
|--------|-------------|----------|
| Core proof lane owns it; AST-parse crosswake_dep/0; bidirectional exact-match | Repo idiom (130-D-12); doc lives in core; async-safe | ✓ |
| Evaluate deps/0 with CROSSWAKE_RELEASE=1 | Non-hermetic, not async-safe, pollutes Mix.Project | |
| Per-companion or both | Can't bidirectionally check; two-source-of-truth smell | |
| Substring / semver-equivalence match | False-passes / hides drift | |

**Notes:** Env-conditional resolver means a naive read returns the path dep — AST is mandatory.
Pin a doc column-contract comment; non-vacuity ≥2; `[crosswake]` stable-id failure messages.

## ④ rindle clean-room engine

| Option | Description | Selected |
|--------|-------------|----------|
| Happy-path; pin engine `{:rindle, "~> 0.1"}` → 0.1.10; cap stays `~> 0.1` | Inherits 131-D-19; fail-closed proven in core; script already parameterized | ✓ |
| Both-states in the clean-room | Redundant with core merge-blocking lane; 131-D-20 fallback only | |
| Widen cap to `~> 0.3` + install 0.3.0 | 0.3 API unvalidated against the probe; deliberate future decision | |

**Notes:** hex.pm confirmed rindle exists (szTheory), 0.1.4–0.1.10 then 0.3.0; `0.3.0 ∉ ~> 0.1`.
Add one Contracts canary (`media_state_vocabulary/0`) to the inline smoke test. clean-room script
needs no new param; `verify_companion_package.sh` rulestead hardcode (lines 53/54/81) must be parameterized.

---

## Claude's Discretion

- ExUnit module/file names, stable-id slug strings, drift-test helper API.
- New `phase132-proof.yml` vs folding into the `phase130-proof.yml` companion-lane pattern (recommend
  one workflow file per companion lane).
- Brand-voice microcopy finalization for failure strings + matrix prose.
- Engine-present stub via tag+conditional `elixirc_paths` vs separate alias (inherit rulestead's choice).
- Copy vs relative-path for the four media helpers when phase72 moves (recommend copy).

## Deferred Ideas

- Widening the rindle engine cap to `~> 0.3` (future, once 0.3 API validated).
- sigra/chimeway/threadline extraction (EXTRACT-FUT, later milestone).
- `Crosswake.Telemetry` (Phase 133); shell lifecycle + native UAT (Phase 134).
- Richer adopter-facing companion clean-room (later hardening).
- Generating the matrix doc from code (only if the family grows large).
