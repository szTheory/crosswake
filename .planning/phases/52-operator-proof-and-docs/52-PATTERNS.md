# Phase 52: operator-proof-and-docs - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/crosswake/proof/phase52_operator_truth_test.exs` | test | request-response | `test/crosswake/proof/phase47_companion_arc_test.exs` | exact |
| `test/support/proof_assertions.ex` | utility | transform | `test/support/router_fixtures.ex` | role-match |
| `.github/workflows/phase52-proof.yml` | config | batch | `.github/workflows/phase45-proof.yml` | exact |
| `mix.exs` (optional alias wiring) | config | batch | `mix.exs` | exact |

## Pattern Assignments

### `test/crosswake/proof/phase52_operator_truth_test.exs` (test, request-response)

**Analog:** `test/crosswake/proof/phase47_companion_arc_test.exs`

**Imports/aliases pattern** (`test/crosswake/proof/phase47_companion_arc_test.exs:1`-`13`):
```elixir
defmodule Crosswake.Proof.Phase47CompanionArcTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Rindle
  alias Crosswake.Companions.Rulestead
  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Doctor
  alias Crosswake.Manifest
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix
```

**Core proof pattern (live canonical truth assertions)** (`test/crosswake/proof/phase47_companion_arc_test.exs:150`-`160`):
```elixir
assert [%{} = row] = SupportMatrix.auth_contract_truth()
assert row.route_predicates == [:auth_min_level, :requires_recent_auth]
assert row.denial_vocabulary == :step_up_required
assert row.fallback == :step_up_required
```

**Hermetic lane guard pattern** (`test/crosswake/proof/phase47_companion_arc_test.exs:193`-`202`):
```elixir
source = File.read!(__ENV__.file)
refute Regex.match?(~r/^\s*@moduletag\s+:advisory_only\b/m, source)
refute String.contains?(source, "Crosswake" <> "Example."),
       "phase 47 proof must not depend on example host modules"
```

**Docs parity pattern (generated file exact lock)** (`test/crosswake/support_matrix/renderer_test.exs:250`-`252`):
```elixir
assert File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())
```

**Mix task JSON contract pattern** (`test/mix/tasks/crosswake_inspect_test.exs:26`-`45`):
```elixir
decoded = Jason.decode!(output)
assert decoded["schema_version"] == "1.0.0"
assert decoded["routes"]["dashboard"]["path"] == "/dashboard"
```

**Error-handling/assert-raise pattern for CLI contracts** (`test/mix/tasks/crosswake_inspect_test.exs:47`-`74`):
```elixir
assert_raise Mix.Error, ~r/pass --router/, fn ->
  Mix.Task.reenable(@task)
  Mix.Task.run(@task, [])
end
```

### `test/support/proof_assertions.ex` (utility, transform)

**Analog:** `test/support/router_fixtures.ex`

**Support module structure pattern** (`test/support/router_fixtures.ex:48`-`50`):
```elixir
defmodule Crosswake.TestSupport.RouterFixtures do
  defmodule ManagedRouter do
    use Crosswake.Router
```

Apply this style for namespaced `Crosswake.TestSupport.ProofAssertions` helper functions used by the phase test, with deterministic string/map normalization and rich failure messages.

### `.github/workflows/phase52-proof.yml` (config, batch)

**Analog:** `.github/workflows/phase45-proof.yml`

**Layered required/advisory workflow shape** (`.github/workflows/phase45-proof.yml:32`-`39`, `42`-`47`, `67`-`73`):
```yaml
on:
  pull_request:
  push:
    branches:
      - main
  workflow_dispatch:
  schedule:
    - cron: "0 6 * * 1"
...
if: ${{ github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
...
if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}
continue-on-error: true
```

**Hermetic merge-blocking run command pattern** (`.github/workflows/phase45-proof.yml:64`-`66`):
```yaml
- name: Run hermetic Phase 45 rindle proof (fail-closed)
  run: mix test --exclude requires_example_host --exclude advisory_only
```

**Advisory status notice pattern** (`.github/workflows/phase45-proof.yml:99`-`105`):
```yaml
- name: Advisory lane status summary
  run: |
    echo "::notice title=Advisory lane::This lane is advisory only and"
    echo "::notice::cannot gate merge."
```

### `mix.exs` (config, batch; optional)

**Analog:** `mix.exs`

**Project conventions to preserve** (`mix.exs:30`-`36`):
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

If adding an alias for Phase 52, keep it simple and deterministic (focused `mix test` target), aligned with existing dependency/env isolation patterns.

## Shared Patterns

### Hermetic vs advisory boundaries
**Sources:** `.github/workflows/phase43-proof.yml:57`-`77`, `.github/workflows/phase45-proof.yml:67`-`73`  
**Apply to:** `phase52-proof.yml`, `phase52_operator_truth_test.exs`

Use explicit event gating for required jobs and `continue-on-error: true` for advisory jobs; keep merge-blocking lane free of optional provider/device env assumptions.

### Canonical docs-contract lock
**Source:** `test/crosswake/support_matrix/renderer_test.exs:250`-`274`  
**Apply to:** `phase52_operator_truth_test.exs`

Use exact byte parity for generated docs (`support_matrix.md`) plus semantic assertions for authored guidance claims/non-claims.

### Stable operator JSON checks
**Sources:** `test/mix/tasks/crosswake_inspect_test.exs:26`-`45`, `test/mix/tasks/crosswake_doctor_test.exs:163`-`200`  
**Apply to:** `phase52_operator_truth_test.exs`

Run task output through `Jason.decode!/1` and assert stable schema/status/check fields; normalize volatile fields before golden comparisons.

### Actionable assertion failures
**Sources:** `test/crosswake/support_matrix/renderer_test.exs:220`-`224`, `test/crosswake/proof/phase47_companion_arc_test.exs:197`-`202`  
**Apply to:** `test/support/proof_assertions.ex`, `phase52_operator_truth_test.exs`

Include explicit remediation text in assertion messages to identify drift source and fix path.

## No Analog Found

None. All likely Phase 52 targets have close analogs in current code.

## Metadata

**Analog search scope:** `test/crosswake/proof`, `test/crosswake/support_matrix`, `test/mix/tasks`, `test/support`, `.github/workflows`, `mix.exs`  
**Files scanned:** 9  
**Pattern extraction date:** 2026-06-01
