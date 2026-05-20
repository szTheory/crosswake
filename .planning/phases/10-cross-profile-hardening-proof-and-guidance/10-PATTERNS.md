# Phase 10: Cross-Profile Hardening, Proof, and Guidance - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 7
**Analogs found:** 6 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `script/verify_saas_profile.sh` | utility | batch | `script/verify_phase5_example_hosts.sh` | exact |
| `script/verify_selective_native.sh` | utility | batch | `script/verify_phase5_example_hosts.sh` | exact |
| `script/verify_local_first.sh` | utility | batch | `script/verify_phase5_example_hosts.sh` | exact |
| `.github/workflows/phase10-proof.yml` | config | batch | `.github/workflows/phase5-proof.yml` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | module | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact (modify self) |
| `lib/crosswake/doctor/doctor.ex` | utility | transform | `lib/crosswake/doctor/doctor.ex` | exact (modify self) |
| `guides/support_matrix.md` | documentation | static | None | N/A (generated) |

## Pattern Assignments

### `script/verify_saas_profile.sh` (utility, batch)

**Analog:** `script/verify_phase5_example_hosts.sh`

**Shell Script Error Handling & Path Setup** (lines 1-7):
```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"
```

**Execution Pattern** (lines 14-18):
```bash
CROSSWAKE_IOS_PROJECT_ROOT="examples/ios_shell_host" \
  bash script/verify_generated_ios_shell.sh

CROSSWAKE_ANDROID_PROJECT_ROOT="examples/android_shell_host" \
  bash script/verify_generated_android_shell.sh
```

---

### `.github/workflows/phase10-proof.yml` (config, batch)

**Analog:** `.github/workflows/phase5-proof.yml`

**Environment Setup Pattern** (lines 13-27):
```yaml
      - name: Setup BEAM
        uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"

      - name: Install Elixir dependencies
        run: mix deps.get
```

**Execution Pattern** (lines 29-35):
```yaml
      - name: Verify checked-in example hosts
        run: bash script/verify_phase5_example_hosts.sh

      - name: Verify generated iOS shell
        run: bash script/verify_generated_ios_shell.sh

      - name: Verify generated Android shell
        run: bash script/verify_generated_android_shell.sh
```

---

### `lib/crosswake/support_matrix/support_matrix.ex` (module, transform)

**Analog:** `lib/crosswake/support_matrix/support_matrix.ex`

**Structure/Validation Pattern** (lines 47-52):
```elixir
  @spec validate(SupportMatrix.t()) :: [map()]
  def validate(%SupportMatrix{} = support_matrix) do
    []
    |> validate_categories_present(support_matrix)
    |> validate_exact_statuses(support_matrix)
    |> validate_narrow_baseline(support_matrix)
  end
```

**Validation Reducer Pattern** (lines 98-112):
```elixir
  defp validate_narrow_baseline(errors, %SupportMatrix{} = support_matrix) do
    counts = %{
      phoenix: 1,
      live_view: 1,
      ios: 1,
      android: 1,
      shells: 2
    }

    Enum.reduce(counts, errors, fn {category, expected_count}, acc ->
      actual_count = support_matrix |> Map.fetch!(category) |> length()

      if actual_count == expected_count do
        acc
      else
        [
          %{
            key: category,
            message: "...",
            hint: "..."
          }
          | acc
        ]
      end
    end)
  end
```

---

### `lib/crosswake/doctor/doctor.ex` (utility, transform)

**Analog:** `lib/crosswake/doctor/doctor.ex`

**Diagnostic Check Generation Pattern** (lines 280-288):
```elixir
        warning_findings =
          Enum.map(warnings, fn warning ->
            check(
              :warning,
              "unmanaged_routes",
              "policy_compile",
              warning.message,
              "decide whether unmanaged routes are intentionally outside Crosswake ownership"
            )
          end)
```

**Finding Creation Pattern** (lines 710-719):
```elixir
  defp check(severity, code, check_name, message, hint, details \\ %{}) do
    %Check{
      severity: severity,
      code: code,
      check: check_name,
      message: message,
      hint: hint,
      details: details
    }
  end
```

---

## Shared Patterns

### Utility Scripts
**Source:** `script/verify_phase5_example_hosts.sh`
**Apply to:** All new `verify_*.sh` scripts (SaaS, Selective Native, Local First).
**Pattern:**
```bash
#!/usr/bin/env bash
set -euo pipefail
```
Each lane should ensure fail-fast strictness and change to the repository root before executing any Mix or generation tasks.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `guides/support_matrix.md` | documentation | static | This will be generated output (markdown dashboard) from the SupportMatrix module rather than a standalone code element. Planners should rely on standard Phoenix guide conventions. |

## Metadata

**Analog search scope:** `script/`, `.github/workflows/`, `lib/crosswake/`
**Files scanned:** 15
**Pattern extraction date:** 2024-05-24
