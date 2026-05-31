# Phase 45: Pattern Map

**Created:** 2026-05-31

## Core Companion

| New/Changed File | Role | Closest Analog | Pattern To Reuse |
|------------------|------|----------------|------------------|
| `lib/crosswake/companions/rindle.ex` | Concrete companion implementation | `lib/crosswake/companions/rulestead.ex` | `@behaviour Crosswake.Companion`, six callbacks, `Code.ensure_loaded?(Rindle)`, `Companion.State` report |
| `mix.exs` | Optional dependency gate | existing `MIX_INCLUDE_RULESTEAD` block | Add a parallel `MIX_INCLUDE_RINDLE` conditional list and return `base ++ rulestead ++ rindle` |
| `test/crosswake/proof/phase45_rindle_companion_test.exs` | Hermetic fail-closed proof | `test/crosswake/proof/phase42_rulestead_companion_test.exs` | Application env setup, doctor fixture files, `companion.dependency_missing` assertion |
| `test/crosswake/proof/phase45_rindle_advisory_test.exs` | Advisory dep-present proof | `test/crosswake/proof/phase43_rulestead_advisory_test.exs` | `@moduletag :advisory_only`, explicit dependency-present assertion |

## Example-Host Media Lane

| New/Changed File | Role | Closest Analog | Pattern To Reuse |
|------------------|------|----------------|------------------|
| `examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex` | Pure-Elixir media evidence emitter | `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` | Deterministic fake provider values and injectable timestamps |
| `examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex` | Stable event/subject keys | `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` | Canonical stable fields plus trace-only correlation metadata |
| `examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex` | Evidence ingestion wrapper | `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` | Replay detection from stable event key and trace metadata |
| `examples/phoenix_host/lib/crosswake_example/media/media_projection.ex` | Backend-owned projection | `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` | Reject unverified reconciliation, derive display state from authoritative projection |
| `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex` | Proof route UI | `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` | Direct callback tests, explicit state-specific render text |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | Route declaration | `/commerce/paywall` and `/gating/beta-feature` scopes | `crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard` |

## Proof Workflow

| New/Changed File | Role | Closest Analog | Pattern To Reuse |
|------------------|------|----------------|------------------|
| `.github/workflows/phase45-proof.yml` | Hermetic + advisory CI | `.github/workflows/phase43-proof.yml` | merge-blocking hermetic job, scheduled/manual advisory job, step-level env |
| `test/crosswake/proof/phase45_rindle_mock_media_test.exs` | MEDIA-03 invariant proof | `test/crosswake/proof/phase34_mock_storefront_test.exs` | `Code.require_file/2` pure example modules, stable identity, replay, no provider SDK tokens |
| `test/crosswake/proof/phase45_rindle_live_test.exs` | LiveView display proof if needed | `test/crosswake/proof/phase35_paywall_live_test.exs` | Runtime module resolution and `Phoenix.LiveViewTest.rendered_to_string/1` |

## Planning Constraints

- Core must not add transport/provider/storage SDK code.
- Example-host modules may orchestrate the lane, but availability must flow
  through `Contracts.verified_media_object/2`.
- Proof should assert source fences for provider-specific token leakage when
  practical.
- CI hermetic job must not contain `MIX_INCLUDE_RINDLE`.
