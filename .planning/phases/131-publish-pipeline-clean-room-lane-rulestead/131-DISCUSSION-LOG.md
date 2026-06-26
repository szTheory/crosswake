# Phase 131: Publish Pipeline & Clean-Room Lane (rulestead) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 131-Publish Pipeline & Clean-Room Lane (rulestead)
**Areas discussed:** release-please wiring, publish job gating, clean-room test+doctor semantics, clean-room placement

---

## Gray-area selection

The phase WHAT is locked by ROADMAP §"Phase 131" SC#1–4 and Phase 130's decisions; the four
areas below are the open HOW forks. User selected ALL FOUR and directed: research each via
parallel subagents (pros/cons/tradeoffs, Elixir/Hex ecosystem idiom, lessons from other libs &
ecosystems, DX/least-surprise, project DNA in `prompts/` + `brandbook/BRAND-SPEC.md`), then
return ONE coherent opinionated recommendation set "so I don't have to think."

| Option (multiSelect) | Description | Selected |
|--------|-------------|----------|
| release-please wiring | Independent component config: key, release-type, separate vs aggregate PR, tag format, manifest baseline, commit attribution | ✓ |
| publish job gating | Per-component output vs aggregate `releases_created`; in-band vs separate workflow; checkout ref; path→Hex pivot timing | ✓ |
| clean-room test+doctor | "Runs its tests" when test/ is excluded from the tarball; engine-present-vs-absent for a green `mix crosswake.doctor` | ✓ |
| clean-room placement | `script/verify_companion_cleanroom.sh` + CI lane; pre/post-publish split; propagation polling; rindle reuse | ✓ |

**Method:** four parallel `gsd-advisor-researcher` subagents (Sonnet), one per area, each grounded
in the live repo + DNA docs + ecosystem research. Orchestrator (Opus) reconciled cross-area
conflicts and synthesized a single coherent recommendation.

---

## ① release-please wiring

| Option | Description | Selected |
|--------|-------------|----------|
| Separate component, `separate-pull-requests: true`, manifest `0.1.0` | Own Release PR; per-component publish gate; generalizes to rindle | ✓ |
| Shared aggregate PR, gate on `releases_created` | Fatally broken — fires on any release; violates independence | |
| Shared PR, gate on path-prefixed output | Correct gating but conflates core+companion review | |

**User's choice:** Separate component with its own Release PR (D-01..05).
**Notes:** `extra-files` → companion `mix.exs` is mandatory (else the elixir releaser bumps core).
Component name `crosswake_rulestead` (not bare `rulestead`) to disambiguate from the engine.
First-release bootstrap (`release-as: 0.1.0` vs. cut 0.1.1) flagged as a planner-investigation item.

---

## ② Publish job gating

| Option | Description | Selected |
|--------|-------------|----------|
| In-band job in release-please.yml, gate on per-component output | Shared run/outputs; cleaner at N=2–4 companions | ✓ |
| Dedicated workflow (workflow_run / release-published) | Better at 5+ companions; indirect output access | |

**User's choice:** In-band, gated on `rulestead_release_created` (D-06..10).
**Notes:** Must alias slash-path outputs in the `outputs:` block (GitHub Actions `if:` can't index
slash keys). NEVER gate on the aggregate `releases_created` (documented v4 footgun). Test step =
engine-absent hermetic lane.

---

## ③ The path: → Hex dep pivot

| Option | Description | Selected |
|--------|-------------|----------|
| Env-conditional resolver (path locally, Hex on `CROSSWAKE_RELEASE=1`) | Preserves Phase-130 local-core fidelity AND publishes honest Hex dep | ✓ |
| Permanent `{:crosswake, "~> 0.1"}` pivot | Simpler, but in-tree lane then tests published core (loses local fidelity) | |
| Ephemeral CI sed-rewrite before publish | "Opaque shell soup" (DNA-rejected); risks silent path-drop | |

**User's choice:** Env-conditional resolver (D-11..14). User explicitly LOCKED this over the
simpler permanent pivot after the tradeoff (in-monorepo lane fidelity) was surfaced.
**Notes:** hex.publish SILENTLY drops path deps — add a `hex.build --unpack` dep-presence grep belt
(`--dry-run` alone won't catch it). This activates Step 2 of `verify_companion_package.sh`.

---

## ④ Clean-room test + doctor + placement

| Option | Description | Selected |
|--------|-------------|----------|
| Post-publish resolvability proof; install real engine → doctor exit 0 (happy path) | "All green" = exit 0; fail-closed stays proven in core | ✓ |
| Register-only, assert fail-closed finding as "green" | doctor exits non-zero on :error → reds the lane; dishonest to call green | |
| Prove BOTH states (engine-absent fail-closed + engine-present green) | Strongest proof; more complex | (fallback per D-20) |

**User's choice:** Post-publish clean-room, happy-path-green with the real `rulestead` engine
(D-15..20). Thin `script/verify_companion_cleanroom.sh` + thin CI; throwaway app is a minimal
Phoenix host (doctor needs `--router`); "its tests" = inline smoke test (tarball ships no test/).
**Notes:** Engine on Hex at 1.0.0 ∉ `~> 0.1` — pin clean-room engine to 0.1.x or widen the cap
(planner-investigation D-20). Fallback to prove-both-states if the engine can't be cleanly resolved.

---

## Lock-in

User selected **"Lock all four as-is"** — wrote CONTEXT.md with ①–④ exactly as recommended plus
the four planner-investigation flags (D-04 first-release bootstrap, D-14 unpack-grep wording,
D-20 engine version/module).

## Claude's Discretion

- Exact CI job/step names, propagation poll constants, the `verify_companion_cleanroom.sh`
  parameter signature beyond package+version, and the inline-smoke-test mechanism (single-file
  ExUnit vs `mix run` vs generated `test/`).
- Env var name beyond `CROSSWAKE_RELEASE` (that one is fixed — referenced across ② and ③).
- New-failure-message microcopy (lead `[crosswake]`, brand voice).
- The minimal Phoenix host shape the doctor smoke needs.

## Deferred Ideas

- rindle extraction + publish via the identical recipe + cross-package compat matrix — Phase 132.
- Dedicated companion-publish workflow file — only at ~5+ companions.
- Widening the companion's `~> 0.1` optional engine cap to admit engine 1.x — only if D-20 forces it.
- Richer adopter-facing companion clean-room — later hardening.
- `Crosswake.Telemetry` public API — Phase 133.
