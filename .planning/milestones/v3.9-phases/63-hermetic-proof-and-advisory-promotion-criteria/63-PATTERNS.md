# Phase 63: Hermetic Proof And Advisory Promotion Criteria - Pattern Map

**Mapped:** 2024-06-03
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/crosswake/proof/phase63_hermetic_proof_test.exs` | test | validation | `test/crosswake/proof/phase60_chimeway_registry_test.exs` | role-match |
| `test/crosswake/proof/phase63_advisory_proof_test.exs` | test | validation | `test/crosswake/proof/phase43_rulestead_advisory_test.exs` | exact |
| `lib/crosswake/planning/closeout_verifier.ex` | utility | file-I/O | `lib/crosswake/planning/closeout_verifier.ex` | exact |
| `test/crosswake/planning/closeout_verifier_test.exs` | test | validation | `test/crosswake/planning/closeout_verifier_test.exs` | exact |

## Pattern Assignments

### `test/crosswake/proof/phase63_hermetic_proof_test.exs` (test, validation)

**Analog:** `test/crosswake/proof/phase60_chimeway_registry_test.exs`

**Imports and Setup Pattern** (lines 1-4):
```elixir
defmodule Crosswake.Proof.Phase60ChimewayRegistryTest do
  use ExUnit.Case, async: false

  @moduledoc """
```

**Source-Level Assertion Pattern** (lines 19-24):
```elixir
  test "binding migration does not define raw-token column names" do
    source =
      File.read!(
        "examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs"
      )

    for forbidden_col <- [
```

**DB/Script-based Assertion Pattern** (lines 201-209):
```elixir
  test "metadata sanitizer drops raw-token atom and string keys, and TokenBinding enforces scope rules" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")

    alias CrosswakeExample.Chimeway.MetadataSanitizer
    alias CrosswakeExample.Chimeway.TokenBinding
```
*Note: Uses `System.cmd("mix", ["run", "--no-start", "-e", script], ...)` to validate example-host specifics.*

---

### `test/crosswake/proof/phase63_advisory_proof_test.exs` (test, validation)

**Analog:** `test/crosswake/proof/phase43_rulestead_advisory_test.exs`

**Advisory-Only Tag and Setup Pattern** (lines 20-33):
```elixir
  # async: false — :companions is a shared global Application key; concurrent tests
  # would observe each other's companion registrations.
  use ExUnit.Case, async: false

  @moduletag :advisory_only

  setup do
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
    end)

    :ok
  end
```

---

### `lib/crosswake/planning/closeout_verifier.ex` (utility, file-I/O)

**Analog:** `lib/crosswake/planning/closeout_verifier.ex`

**Check Definition Pattern** (lines 94-110):
```elixir
  defp closeout_frontmatter_check(cwd, opts) do
    path = closeout_path(cwd, opts)
    content = read_file(path)
    frontmatter = parse_frontmatter(content)

    missing =
      if frontmatter == "" do
        @required_closeout_keys
      else
        Enum.reject(
          @required_closeout_keys,
          &Regex.match?(~r/^#{Regex.escape(&1)}:/m, frontmatter)
        )
      end

    check(
      "closeout.ledger.frontmatter",
      "closeout ledger frontmatter",
      rel(cwd, path),
      missing == [],
      "missing keys: #{Enum.join(missing, ", ")}",
      "Preserve the v3.6-CLOSEOUT.md frontmatter contract before closeout.",
      %{missing: missing}
    )
  end
```

---

### `test/crosswake/planning/closeout_verifier_test.exs` (test, validation)

**Analog:** `test/crosswake/planning/closeout_verifier_test.exs`

**Mocking Artifacts Pattern** (lines 24-38):
```elixir
  test "missing closeout frontmatter fails closed with a closeout stable id" do
    tmp = tmp_dir!("missing-frontmatter")
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    File.write!(
      Path.join(tmp, ".planning/milestones/v3.6-CLOSEOUT.md"),
      "# Missing frontmatter\n"
    )

    write_minimal_files!(tmp)

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.ledger.frontmatter")

    assert report.status == :failed
    assert check.blocking
    assert check.observed =~ "milestone"
    assert CloseoutVerifier.render(report) =~ "closeout.ledger.frontmatter"
  end
```

## Shared Patterns

### Test Independence (async)
**Source:** `test/crosswake/proof/*`
**Apply to:** All new `test/crosswake/proof/` files.
```elixir
use ExUnit.Case, async: false
```
*Always set `async: false` for proof tests as they typically mutate global application states (e.g., config changes, starting specific Ecto components).*

### Return Formatting for Verifier
**Source:** `lib/crosswake/planning/closeout_verifier.ex`
**Apply to:** Any new check added for Phase 63.
Ensure `check/7` is properly returned to aggregate under `CloseoutVerifier.Check` struct for output formatting in `CloseoutVerifier.render/1`.

## Metadata

**Analog search scope:** `test/crosswake/proof/`, `lib/crosswake/planning/`
**Files scanned:** ~10 (subset read entirely)
**Pattern extraction date:** 2024-06-03
