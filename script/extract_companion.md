# Crosswake Companion Extraction Recipe

**Type:** Parameterized checklist (NOT a generator — D-25)
**Purpose:** Mechanical recipe for extracting a Crosswake companion adapter into a
standalone `crosswake_{companion}` Hex package. Run this for each companion extraction.
Proven on rulestead (Phase 130). Apply to rindle (Phase 132).

---

## Prerequisites

Before starting:
- Phase 129 (or equivalent) has frozen the companion contract surface (`@behaviour Crosswake.Companion`)
- The companion adapter source is in `lib/crosswake/companions/{companion}.ex`
- The companion adapter uses `Code.ensure_loaded?({Engine})` inside function bodies (EXTRACT-04-clean)
- The package skeleton `packages/crosswake_{companion}/` exists with `mix.exs` and `mix.lock`
- `EXTRACT-03` and `EXTRACT-04` guards are in place (`CompanionGuard.assert_no_static_refs!/0`)

---

## Step 1: Move source — preserve module names (non-breaking)

```bash
# Create package lib directory
mkdir -p packages/crosswake_{companion}/lib/crosswake/companions/{companion}/

# Move the adapter source (module name PRESERVED = non-breaking for adopters)
# Crosswake.Companions.{Companion} stays Crosswake.Companions.{Companion}
mv lib/crosswake/companions/{companion}.ex \
   packages/crosswake_{companion}/lib/crosswake/companions/{companion}.ex
```

**Required modifications to the moved source:**

1. Add `@compile {:no_warn_undefined, {Engine}}` at the top of the module (D-29).
   `optional: true` alone does NOT silence the undefined-module warning in engine-ABSENT builds.

2. Replace any direct test-module reference (e.g. `alias MockFlagSource`) with
   config-indirection (D-31):
   ```elixir
   defp flag_source do
     Application.get_env(:crosswake, :{companion}_flag_source, nil)
   end
   ```
   Keep `Code.ensure_loaded?({Engine})` calls INSIDE function bodies verbatim (EXTRACT-04-clean).

3. Move test/support modules (e.g. `MockFlagSource`) to `packages/.../test/support/` (next step).

**Verify core lib/ is clean after the move:**
```bash
grep -r "Crosswake.Companions.{Companion}" lib/ && echo "FAIL: references remain" || echo "CLEAN"
```

---

## Step 2: Split tests — SC#1 → companion lane, SC#5 → core lane (D-20)

**DO NOT move all tests wholesale.** The test split is load-bearing:

| Test Type | Lane | Why |
|-----------|------|-----|
| Adapter behavior (gate/kill-switch/report_state with flag source) | Companion package `test/` | Tests the adapter in isolation |
| Engine-present green path (validate_dependency returns :ok) | Companion package, `:engine_present` tag | Advisory lane (D-33) |
| COMPAT-01 fail-closed contract (validate_dependency fails → RouteGate denies) | Core test/ | SC#5 test only works where engine is absent from core deps |
| Doctor dependency_missing (SC#3a/SC#3b) | Core test/ | Doctor test requires engine absent in core context |

**Create companion test structure:**
```bash
mkdir -p packages/crosswake_{companion}/test/crosswake/proof/
mkdir -p packages/crosswake_{companion}/test/support/
mkdir -p packages/crosswake_{companion}/test/engine_present/
```

**Create `test/test_helper.exs` in the companion package:**
```elixir
ExUnit.start(exclude: [:engine_present, :collateral_binaries, :advisory_only])
```

---

## Step 3: Copy minimal test/support stubs (D-23)

Copy ONLY the stubs needed by the moved tests. No shared published test-support package.

```bash
# Move MockFlagSource (or equivalent mock) to companion test/support/
mv lib/crosswake/companions/{companion}/mock_{companion}.ex \
   packages/crosswake_{companion}/test/support/mock_{companion}.ex

# Copy StudySessionLive (or minimal route target LiveView) verbatim
# It is a 3-line stub — no drift seam risk
cp packages/crosswake_rulestead/test/support/study_session_live.ex \
   packages/crosswake_{companion}/test/support/study_session_live.ex
```

---

## Step 4: companion mix.exs — version + marker + deps (D-19/D-22/D-28/D-29)

Required fields in `packages/crosswake_{companion}/mix.exs`:

```elixir
@version "0.1.0"  # x-release-please-version — do NOT add to core release-please group (D-22)

defp deps do
  [
    # D-19: NO runtime: false — core is a RUNTIME dep of the companion
    {:crosswake, path: "../.."},                       # Phase 130: path dep (dress rehearsal)
    # {:crosswake, "~> 0.1"},                          # Phase 131: Hex dep pivot (AFTER publish)
    # D-28: optional: true — adopter installs {engine} themselves
    {:{engine_hex_name}, "~> 0.1", optional: true}
  ]
end

defp package do
  [
    # D-24: test/ EXCLUDED — only ship lib/ source
    files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
  ]
end

# D-33: engine-present advisory lane alias
defp aliases do
  [
    "engine-present.test": [
      "clean",
      "cmd ENGINE_PRESENT_LANE=1 mix test --only engine_present"
    ]
  ]
end

# D-33: conditional elixirc_paths for engine_present stub
defp elixirc_paths(:test) do
  base = ["lib", "test/support"]
  if System.get_env("ENGINE_PRESENT_LANE") == "1" do
    base ++ ["test/engine_present"]
  else
    base
  end
end
defp elixirc_paths(_), do: ["lib"]
```

**Do NOT add `@version` to `.release-please-manifest.json` or `release-please-config.json`
and do NOT join the `linked-versions: "crosswake"` group. That is Phase 131.**

---

## Step 5: Create companion config.exs — wire test flag source (D-31)

```elixir
# packages/crosswake_{companion}/config/config.exs
import Config

if config_env() == :test do
  config :crosswake, :{companion}_flag_source,
    Crosswake.Companions.{Companion}.Mock{Companion}
end
```

---

## Step 6: Create engine_present stub (D-33)

```elixir
# packages/crosswake_{companion}/test/engine_present/{engine}.ex
defmodule {Engine} do
  @moduledoc """
  Fake top-level {Engine} stub for the engine-present advisory lane (D-33).
  Compiled ONLY when ENGINE_PRESENT_LANE=1. NOT a real {Engine} implementation.
  """
end
```

---

## Step 7: Commit mix.lock (D-24)

```bash
cd packages/crosswake_{companion}
mix deps.get
# Review: mix.lock should lock direct non-optional deps only.
# {engine_hex_name} will appear because it's listed as optional: true in mix.exs.
# This is expected — the lock documents the resolved version.
git add mix.lock
git commit -m "chore: commit crosswake_{companion} mix.lock (D-24)"
```

---

## Step 8: Delete MIX_INCLUDE_{COMPANION} from core mix.exs (D-21)

```bash
# Remove the conditional block:
#   {companion} =
#     if System.get_env("MIX_INCLUDE_{COMPANION_UPPER}") == "1" do
#       [{:{engine_hex_name}, "~> 0.1.6"}]
#     else
#       []
#     end
#
# And remove it from the final base ++ ... ++ {companion} expression.
# Core mix.exs deps/0 returns ONLY base. Core names NO companion in any env (EXTRACT-01).
```

---

## Step 9: Wire CI lane + root aliases (D-26)

Add to **core** `mix.exs`:

```elixir
defp aliases do
  [
    "companions.test": ["cmd --cd packages/crosswake_{companion} mix test"],
    verify: [
      "companions.test",
      "test --exclude requires_example_host --exclude advisory_only"
    ]
  ]
end
```

If multiple companions are extracted, extend `companions.test` to chain:
```elixir
"companions.test": [
  "cmd --cd packages/crosswake_rulestead mix test",
  "cmd --cd packages/crosswake_{companion} mix test"
]
```

---

## Step 10: Run verify script (D-24)

```bash
# From repo root:
bash script/verify_companion_package.sh crosswake_{companion}
```

Expected Phase 130/132 dress-rehearsal output:
- Step 1: files: allowlist assertion (test/ absent, lib/ source present)
- Step 2: SKIPPED (path: dep present — Phase 131 pivots to Hex dep)
- Step 3: mix compile --warnings-as-errors → clean

After Phase 131 path: → Hex pivot, re-run to get full Step 1 + Step 2 verification.

---

## Step 11: Run the three guards

```bash
# From repo root — hermetic (no example host required):
mix test test/crosswake/proof/phase130_extraction_guards_test.exs
mix test test/crosswake/proof/phase130_fail_closed_contract_test.exs

# Companion lane:
mix companions.test
```

Expected: all green. EXTRACT-01 (no MIX_INCLUDE_*), EXTRACT-03 (no static refs, still skipped
until next EXTRACT-03 test plan runs assert_no_static_refs!), COMPAT-01 (fail-closed), EXTRACT-04
(ensure_loaded? placement) — all assertions pass.

---

## Step 12: DON'T touch release-please

The following files must NOT be modified in Phase 130/132 (dress rehearsal):
- `.release-please-manifest.json`
- `release-please-config.json`
- `.github/workflows/release-please.yml`

The companion package version (`0.1.0`) is standalone. The `# x-release-please-version`
marker in the companion `mix.exs` is placed for Phase 131 when the component is registered.

---

## Phase 131 lock pivot (deferred)

When Phase 131 promotes the first companion to Hex:

1. Change `{:crosswake, path: "../.."}` → `{:crosswake, "~> 0.1"}` in the companion mix.exs
2. Run `mix deps.get` to re-lock with the Hex dep
3. Run `mix hex.publish --dry-run` (Step 2 of verify script now active)
4. Register the component in `release-please-config.json` and `.release-please-manifest.json`
5. Run `bash script/verify_companion_package.sh crosswake_rulestead` — all 3 steps should pass

---

## Checklist Summary

- [ ] Adapter source moved; module name preserved; `@compile {:no_warn_undefined, Engine}` added (D-29)
- [ ] Config-indirection `flag_source/0` in place; no test-module in lib/ (D-31)
- [ ] MockFlagSource/equivalent moved to companion `test/support/` (verbatim)
- [ ] StudySessionLive stub copied to companion `test/support/` (D-23)
- [ ] Engine-present stub in `test/engine_present/` (D-33)
- [ ] Companion `mix.exs`: version + marker, `{:crosswake, path:}` NO `runtime: false`, `optional: true` engine dep (D-19/D-22/D-28)
- [ ] `config/config.exs` wires test flag_source (D-31)
- [ ] `mix.lock` committed after `mix deps.get` (D-24)
- [ ] `MIX_INCLUDE_{COMPANION}` block deleted from core `mix.exs` (D-21)
- [ ] Root aliases `companions.test` + `verify` wired in core `mix.exs` (D-26)
- [ ] `bash script/verify_companion_package.sh crosswake_{companion}` passes (D-24)
- [ ] Guard tests green: EXTRACT-01, COMPAT-01, companion lane (D-25)
- [ ] release-please config/manifest UNTOUCHED (D-22)

---

*Recipe version: Phase 130 (rulestead extraction proof)*
*Proven on: crosswake_rulestead (Phase 130)*
*Next: crosswake_rindle (Phase 132)*
