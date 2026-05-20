# Phase 14: Proof, Doctor, And Support Truth - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/doctor/formatter.ex` | utility | transform | `lib/crosswake/support_matrix/renderer.ex` | exact |
| `lib/crosswake/doctor/doctor.ex` | service | evaluation | `lib/crosswake/doctor/doctor.ex` | exact |
| `guides/capabilities.md` / `guides/commerce.md` | docs | static | `guides/capabilities.md` | role-match |
| `guides/compatibility.md` | docs | static | `guides/compatibility.md` | exact |

## Pattern Assignments

### `lib/crosswake/doctor/formatter.ex` (utility, transform)

**Analog:** `lib/crosswake/support_matrix/renderer.ex`

**Table formatting pattern** (lines 80-92 in `renderer.ex`):
```elixir
  defp package_surface_section(entries) do
    [
      "## Packaging Ledger",
      "",
      "`crosswake` remains the one primary public package. Companions are first-party-scoped typed boundaries, not plugin-market surfaces.",
      "",
      "| Surface | Class | Why | Release Burden | Public Guide |",
      "|---------|-------|-----|----------------|--------------|",
      Enum.map_join(entries, "\n", &package_surface_row/1)
    ]
    |> Enum.join("\n")
  end
```

**Doctor existing string output pattern** (lines 50-65 in `formatter.ex`):
```elixir
  defp format_release_policy(%{
         crosswake_version: crosswake_version,
         manifest_schema_version: manifest_schema_version,
         bridge_protocol_version: bridge_protocol_version,
         native_runtime_version: native_runtime_version,
         package_version_truth: package_version_truth,
         companion_requirement: companion_requirement
       }) do
    [
      "release policy:",
      "  crosswake_version=#{crosswake_version}",
      "  manifest_schema_version=#{manifest_schema_version}",
      "  bridge_protocol_version=#{bridge_protocol_version}",
      "  native_runtime_version=#{native_runtime_version}",
      "  #{package_version_truth}",
      "  #{companion_requirement}"
    ]
    |> Enum.join("\n")
  end
```

---

### `lib/crosswake/doctor/doctor.ex` (service, evaluation)

**Analog:** `lib/crosswake/doctor/doctor.ex`

**Advisory vs Error mapping pattern** (lines 284-300 in `doctor.ex`):
```elixir
    findings = [
      check(
        if(coherent?, do: :advisory, else: :error),
        if(coherent?, do: "offline_posture_ready", else: "offline_posture_incomplete"),
        "offline_posture",
        "offline posture exposes route-local cached, saved locally, queued for replay, replay failed, and conflict requires attention vocabulary",
        if(coherent?,
          do:
            "doctor and JSON output now describe explicit cached-route and study-session island posture from typed contract truth",
          else: "restore explicit cache and island contract truth for every offline route"
        ),
        %{
          status: Atom.to_string(offline.status),
          states: status_vocabulary,
          telemetry_keys: telemetry_keys,
          terminal_outcomes: terminal_outcomes,
          routes: offline.routes
        }
      )
    ]
```

**Snapshot extraction pattern** (lines 405-419 in `doctor.ex`):
```elixir
  defp release_policy_snapshot(manifest) do
    compatibility = manifest.compatibility
    support_matrix = manifest.support_matrix

    %{
      crosswake_version: manifest.crosswake_version,
      manifest_schema_version: compatibility.manifest_schema_version,
      bridge_protocol_version: compatibility.bridge_protocol_version,
      native_runtime_version: compatibility.native_runtime_version,
      package_version_truth:
        "Package versions alone do not determine support truth.",
      companion_requirement:
        "Future companions must declare minimum compatible ranges for core, manifest_schema_version, bridge_protocol_version, native_runtime_version, and exposed capability-family majors.",
      package_surfaces: Enum.map(support_matrix.package_surfaces, & &1.surface),
      change_classes: Enum.map(support_matrix.change_classes, & &1.change_class)
    }
  end
```

---

### `guides/capabilities.md` (docs, static)

**Analog:** `guides/capabilities.md`

**Documentation boundary structure for capabilities** (lines 142-166):
```markdown
### Route owner

`paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence` remain Phoenix/backend-owned seams. A docs-only classification does not authorize the device to own entitlement truth.

### Why not core/companion

These surfaces are meaningful vocabulary now, but provider/storefront churn, reviewer guidance, and backend reconciliation burden are still too high to market as first-class runtime support.

### Host-owned responsibilities

The host owns storefront/provider selection, backend reconciliation, receipt or event ingestion, and explicit native-screen decisions when policy-sensitive purchase UI cannot stay Phoenix-owned.

### Prerequisites

Backend entitlement authority, provider-specific adapter design, storefront guidance, and explicit support-matrix classification must exist before promotion.

### Denial behavior

If the seam is undeclared or unsupported, Crosswake fails closed with explicit unavailable posture instead of pretending the bridge or shell can complete a purchase flow safely.

### Fallback behavior

Fallback remains Phoenix-owned guidance or a deliberate native-screen requirement. Crosswake does not imply a runnable supported host recipe from docs-only examples.
```

## Shared Patterns

### Diagnostic Checking & Findings Accumulation
**Source:** `lib/crosswake/doctor/doctor.ex`
**Apply to:** Validation logic in `doctor.ex`
```elixir
      check(
        severity,
        code,
        check_name,
        message,
        hint,
        details
      )
```

## No Analog Found

Files with no close match in the codebase: None. (All formatters and guides have clear existing analogues).

## Metadata

**Analog search scope:** `lib/crosswake/doctor/*.ex`, `lib/crosswake/support_matrix/*.ex`, `guides/*.md`
**Files scanned:** 6
**Pattern extraction date:** 2024-05-24
