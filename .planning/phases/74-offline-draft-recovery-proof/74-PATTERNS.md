# Phase 74: Offline/Draft Recovery Proof - Pattern Map

**Mapped:** 2025-06-05
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs` | test | verification | `test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` | role-match |
| `.github/workflows/phase74-proof.yml` | config | script execution | `.github/workflows/phase73-proof.yml` | exact |

## Pattern Assignments

### `test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs` (test, verification)

**Analog:** `test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` and `test/crosswake/offline/proof_lane_test.exs`

**Imports and Context Pattern** (`test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` lines 1-13):
```elixir
defmodule Crosswake.Proof.Phase74OfflineDraftRecoveryProofTest do
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types.Compatibility
  alias Crosswake.Manifest.Types.Host
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Manifest.Types.CacheContract
  alias Crosswake.Manifest.Types.IslandContract
```

**Hermetic Route Evaluation Pattern** (`test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` lines 61-76):
```elixir
  describe "offline posture and RouteGate limits" do
    test "enforces local_first bounds and rejects generic sync" do
      # Set up local route entries with :local_first and :cached_read_only
      route = %RouteEntry{
        id: "offline-draft-route",
        path: "/draft",
        runtime: :live_view,
        offline: :local_first,
        island_contract: %IslandContract{...}
      }
      
      decision = RouteGate.evaluate(manifest(%{"offline-draft-route" => route}), "offline-draft-route", target())
      # assert fail-closed transitions or expected offline limits
    end
  end
```

**Manifest Route Verification Pattern** (`test/crosswake/offline/proof_lane_test.exs` lines 7-11):
```elixir
  test "repo-local proof lane asserts the narrow cached and study-session offline posture" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(Crosswake.TestSupport.RouterFixtures.ManagedRouter)

    assert manifest.routes["library"].cache_contract.hydration == :sqlite_snapshot
    assert manifest.routes["study-session"].island_contract.sync_seam == "study_reviews"
    assert manifest.routes["study-session"].island_contract.authoritative_source == :phoenix
  end
```

---

### `.github/workflows/phase74-proof.yml` (config, script execution)

**Analog:** `.github/workflows/phase73-proof.yml`

**Workflow Definition Pattern** (`.github/workflows/phase73-proof.yml` lines 1-38):
```yaml
name: Phase 74 Proof

permissions:
  contents: read

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  merge-blocking-offline-draft-recovery-proof:
    name: merge-blocking offline/draft recovery proof (hermetic)
    runs-on: macos-15
    timeout-minutes: 20

    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6

      - name: Setup BEAM
        uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"

      - name: Install Elixir dependencies
        run: mix deps.get

      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Run hermetic Phase 74 offline draft recovery proof
        run: mix test test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs
```

## Shared Patterns

### Test Target Manifest Setup
**Source:** `test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` (lines 352-386)
**Apply to:** Hermetic testing inside `phase74_offline_draft_recovery_proof_test.exs`
```elixir
  defp manifest(routes \\ %{}) do
    %Root{
      manifest_schema_version: "2.0.0",
      crosswake_version: "0.1.0",
      generated_at: @fixed_now,
      host: %Host{
        phoenix_version: "1.7.0",
        live_view_version: "0.20.0",
        origin: "https://example.test",
        manifest_sources: [:bundled]
      },
      compatibility: %Compatibility{
        manifest_schema_version: "2.0.0",
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        supported_manifest_sources: [:bundled],
        remote_updates: []
      },
      routes: routes
    }
  end

  defp target do
    %Target{
      manifest_schema_version: "2.0.0",
      bridge_protocol_version: "1.0.0",
      native_runtime_version: "1.0.0",
      origin: "https://example.test",
      manifest_source: :bundled
    }
  end
```

## Metadata

**Analog search scope:** `test/crosswake/proof/`, `test/crosswake/offline/`, `.github/workflows/`
**Files scanned:** 3
**Pattern extraction date:** 2025-06-05
