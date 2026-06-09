# Phase 94: Audit Ledger Contract + Generator - Discussion Log

**Date:** 2026-06-09

## Discussion Areas

### Migration Idempotency
- **Options Presented:** Generate with timestamp vs check for existing migration by name.
- **Selection:** Check for existing by name suffix.
- **Notes:** User requested deep research. The recommendation to scan `priv/repo/migrations/*_create_crosswake_audit_ledger.exs` and skip if found was accepted to prevent duplicate migration footguns, aligning with `gen.sync`'s superior DX.

### HMAC Secret Source
- **Options Presented:** Application config vs runtime argument.
- **Selection:** Dual-mode fallback (Opts -> Config).
- **Notes:** Accepted recommendation to use a fallback model: checking explicit `opts` keyword list first, then falling back to `Application.get_env(:crosswake, :audit_hmac_secret)`. This provides "it just works" ergonomics with necessary flexibility.

### Customizable Schema Name
- **Options Presented:** Hardcoded vs CLI Arguments.
- **Selection:** Convention over Configuration.
- **Notes:** Accepted recommendation to statically target `MyApp.Audit.Ledger` and table `crosswake_audit_ledger` (derived from host app's base namespace). This eliminates wiring boilerplate for day-2 ops tools.

### Metadata Serialization
- **Options Presented:** Simple `:map` vs JSONB equivalent column.
- **Selection:** Native Ecto `:map` (JSONB).
- **Notes:** Accepted recommendation to use native Ecto `:map` because it seamlessly translates to JSONB in Postgres, allowing the `reject_pii_in_metadata/1` guard to trivially iterate over keys without extra serialization dependencies.

## Deferred Ideas
- None — discussion stayed within phase scope.

## Notes
- User requested one-shot cohesive architectural recommendations across all four areas, emphasizing developer ergonomics, idiomatic Elixir patterns, and principle of least surprise. Recommendations were provided and accepted in full.
