# Phase 84: Offline Substrate Foundation - Research

**Researched:** 2024-06-10
**Domain:** Elixir Structs, Route Policy, Manifest Generation
**Confidence:** HIGH

## Summary

This phase establishes the structural foundation for Crosswake's Offline Islands by introducing `Crosswake.Offline.ContentPack` and updating the route policy/manifest compilation. The research reviewed how `Crosswake.Policy.Route` currently handles offline metadata (`offline: :unavailable | :cached_read_only | :local_first`) and pack declarations, and determines where `ContentPack` should integrate. 

**Primary recommendation:** Define `Crosswake.Offline.ContentPack` at `lib/crosswake/offline/content_pack.ex` with fields for `id`, `version`, `kind`, `integrity`, `assets`, and `data_payloads`, and expose it through `Crosswake.Manifest.Builder` to link content packs with manifest generation.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OFF-01 | `Crosswake.Offline` provides a documented `ContentPack` standard for bundling assets and data required by an Offline Island. | Identified `lib/crosswake/offline/content_pack.ex` as the home for the struct and mapped its integration points with `Crosswake.Policy.Route` and `Crosswake.Manifest.Builder`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ContentPack struct definition | API / Backend | — | Defines the Elixir data structure for server-side generation of offline asset/data bundles. |
| Route Policy definitions | API / Backend | — | `Crosswake.Policy.Schema` and `Crosswake.Policy.Route` own route-level metadata. |
| Manifest generation | API / Backend | Browser / Client | `Crosswake.Manifest.Builder` compiles the Elixir route metadata into a JSON artifact consumed by the client/shell. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| NimbleOptions | current | Route Policy validation | Used in `Crosswake.Policy.Schema` for all policy validation within Crosswake. |

**Installation:** N/A (Existing dependency in `mix.exs`)

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages.

*No new packages are being installed in this phase. This is purely Elixir data structures and policy definitions.*

## Architecture Patterns

### Recommended Project Structure
```text
lib/crosswake/offline/
├── contracts.ex
├── content_pack.ex         # NEW: Struct for server-side generation of content bundles
├── journal.ex
├── replay.ex
├── runtime.ex
├── status.ex
└── telemetry.ex
```

### Pattern 1: Route Policy Schema Update
**What:** Route packs currently exist as `Schema.pack_requirement()`. The offline route policy updates should ensure `offline: :local_first` routes can specify explicit `ContentPack` bindings.
**When to use:** In `lib/crosswake/policy/schema.ex` and `lib/crosswake/policy/route.ex`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route Validation | Custom maps and conditional logic | `NimbleOptions` | The rest of `Crosswake.Policy.Schema` uses NimbleOptions for robust error messaging and defaults. |
| JSON Serialization | Custom string building | `Jason.Encoder` protocol | Ensure `ContentPack` derives `Jason.Encoder` to integrate smoothly with the manifest builder and JSON endpoints. |

## Code Examples

### ContentPack Definition
```elixir
defmodule Crosswake.Offline.ContentPack do
  @moduledoc """
  Standard for bundling assets and data required by an Offline Island.
  """
  @derive Jason.Encoder
  @enforce_keys [:id, :version, :kind]
  defstruct [:id, :version, :kind, :integrity, assets: [], data_payloads: []]

  @type t :: %__MODULE__{
          id: String.t(),
          version: String.t(),
          kind: atom(),
          integrity: String.t() | nil,
          assets: [String.t()],
          data_payloads: [String.t()]
        }
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ContentPack requires `assets` and `data_payloads` fields | Code Examples | If the required data shape significantly differs, the struct might not serve the demo app correctly. Need feedback during implementation. |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified, pure Elixir module additions).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/offline/content_pack_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OFF-01 | `ContentPack` struct creation and JSON encoding | unit | `mix test test/crosswake/offline/content_pack_test.exs` | ❌ Wave 0 |
| OFF-01 | Manifest Generation includes offline packs properly | unit | `mix test test/crosswake/manifest/builder_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/offline/content_pack_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/offline/content_pack_test.exs` — covers OFF-01 ContentPack struct unit testing

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | Ensure offline assets respect route access policy via `Crosswake.Policy.Validator`. |
| V5 Input Validation | yes | `NimbleOptions` in `Crosswake.Policy.Schema` |
| V6 Cryptography | yes | Integrity hashes (SHA-256) for downloaded packs |

### Known Threat Patterns for Elixir/Crosswake

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampering with offline packs | Tampering | Include `integrity` checksums on the `ContentPack` definition. |
| Malformed route policies | Spoofing | Rely strictly on `Crosswake.Policy.Validator`. |

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/policy/schema.ex` - Checked existing route policy options (`offline: :local_first` and `packs`).
- `lib/crosswake/manifest/builder.ex` - Checked how manifest generation parses routes into the final JSON output.
- `.planning/REQUIREMENTS.md` - Verified OFF-01 requirements for `ContentPack`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Only standard Elixir core libraries are required.
- Architecture: HIGH - Fits clearly in the existing `lib/crosswake/offline/` namespace.
- Pitfalls: HIGH - Adherence to NimbleOptions avoids common schema definition errors.
