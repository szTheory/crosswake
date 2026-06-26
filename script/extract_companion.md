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

## Step 4: companion mix.exs — version + marker + deps (D-19/D-22/D-28/D-29/D-11/D-13)

Required fields in `packages/crosswake_{companion}/mix.exs`:

```elixir
@version "0.1.0"  # x-release-please-version — do NOT add to core release-please group (D-22)

defp deps do
  [
    # D-19: NO runtime: false — core is a RUNTIME dep of the companion
    # D-11/D-13: env-conditional crosswake_dep/0 — see below
    crosswake_dep(),
    # D-28: optional: true — adopter installs {engine} themselves
    {:{engine_hex_name}, "~> 0.1", optional: true}
  ]
end

# D-11/D-13: Env-conditional crosswake dep resolver — the publish seam.
# Phase 130 dress rehearsal: CROSSWAKE_RELEASE unset → path dep (local fidelity).
# Phase 131+ publish: CROSSWAKE_RELEASE=1 → Hex dep (honest tarball requirement).
# NOTE: "path:" still appears in this function body after the pivot (Pitfall 4) —
# this is expected and does NOT represent an active bare path dep in deps/0.
defp crosswake_dep do
  if System.get_env("CROSSWAKE_RELEASE") == "1",
    do: {:crosswake, "~> 0.1"},
    else: {:crosswake, path: "../.."}
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
# From repo root (Phase 131+: CROSSWAKE_RELEASE=1 required — activates Hex dep in tarball):
CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_{companion}
```

Expected Phase 131+ output (env-conditional dep pivot in place):
- Step 1: hex.build --unpack tarball inspection (test/ absent, lib/ source present)
- Step 2: dep-presence gate (crosswake present in hex_metadata.config)
- Step 3: mix compile --warnings-as-errors → clean

Phase 130 dress-rehearsal (crosswake_dep/0 not yet in place):
- The verify script will error if run without CROSSWAKE_RELEASE=1 (path: dep causes hex.build to fail).
- For Phase 130 only, use the Step 4 companion mix.exs with `{:crosswake, path: "../.."}` directly.
- Once crosswake_dep/0 is in place (Phase 131), always run with CROSSWAKE_RELEASE=1.

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

## Step 12: Register the release-please component (Phase 131+)

**Phase 130 (dress rehearsal):** Do NOT touch the following files — leave them as-is:
- `.release-please-manifest.json`
- `release-please-config.json`
- `.github/workflows/release-please.yml`

The companion package version (`0.1.0`) is standalone. The `# x-release-please-version`
marker in the companion `mix.exs` is placed in Step 4 above for Phase 131 when the component
is registered here.

**Phase 131+ (first Hex publish for this companion):**

Perform these mechanical steps to wire the companion into the release pipeline.
Apply by substituting `{companion}` = your companion name (e.g. `rulestead`, `rindle`):

### 12a. Add component entry to `release-please-config.json`

Add under `"packages"` (do NOT add `"crosswake_{companion}"` to `linked-versions` components):

```json
"packages/crosswake_{companion}": {
  "component": "crosswake_{companion}",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_{companion}/mix.exs"],
  "changelog-sections": [
    { "type": "feat",     "section": "Features" },
    { "type": "fix",      "section": "Bug Fixes" },
    { "type": "perf",     "section": "Performance Improvements" },
    { "type": "deps",     "section": "Dependencies" },
    { "type": "chore",    "section": "Miscellaneous",          "hidden": true },
    { "type": "docs",     "section": "Documentation",          "hidden": true },
    { "type": "test",     "section": "Tests",                  "hidden": true },
    { "type": "ci",       "section": "Continuous Integration", "hidden": true },
    { "type": "refactor", "section": "Refactoring",            "hidden": true },
    { "type": "build",    "section": "Build System",           "hidden": true }
  ]
}
```

### 12b. Add manifest baseline to `.release-please-manifest.json`

```json
"packages/crosswake_{companion}": "0.1.0"
```

### 12c. Add output aliases to `.github/workflows/release-please.yml` `outputs:` block

```yaml
# Companion: crosswake_{companion}
# release-please-action v4 path outputs use <path>--<name> (double-dash) format.
# GitHub Actions if: cannot index slash-containing keys; alias here for dot-notation downstream (D-08).
{companion}_release_created: ${{ steps.release.outputs['packages/crosswake_{companion}--release_created'] }}
{companion}_tag_name: ${{ steps.release.outputs['packages/crosswake_{companion}--tag_name'] }}
{companion}_version: ${{ steps.release.outputs['packages/crosswake_{companion}--version'] }}
```

### 12d. Add `publish-hex-{companion}` job to `release-please.yml`

Mirror the `publish-hex` core job shape (steps: checkout at tag → setup-beam → cache → hex+rebar →
deps.get → compile → version grep → mix test → dry-run → publish → poll Hex).
Key differences from core:
- `if: needs.release-please.outputs.{companion}_release_created == 'true'`
- `ref: needs.release-please.outputs.{companion}_tag_name`
- `working-directory: packages/crosswake_{companion}` on all mix steps
- `VERSION: needs.release-please.outputs.{companion}_version`
- Version grep target: `packages/crosswake_{companion}/mix.exs`
- Test step: `mix test` (no `--exclude requires_example_host` — that is a core-only tag)
- `CROSSWAKE_RELEASE: "1"` env on all mix steps (activates Hex dep in tarball)
- Poll URL: `hex.pm/api/packages/crosswake_{companion}/releases/$VERSION`

### 12e. Add `clean-room-proof-{companion}` job to `release-please.yml`

`needs: [release-please, publish-hex-{companion}]`
Run `bash script/verify_companion_cleanroom.sh crosswake_{companion} $VERSION` (Plan 02/03 for rulestead).
Pattern mirrors existing `clean-room-proof-ios`/`-android` jobs.

### 12f. `release-as` removal — automated (PROOF-03), no manual step

The one-shot `release-as: "0.1.0"` bootstrap pin MUST be removed once the companion's first
release tag exists, or every subsequent run re-targets `0.1.0` forever (Pitfall 6). **As of
Phase 135 this is CI-automated — no manual edit and no per-companion human runbook:**

- **Auto-cleanup PR** — the `release-as-cleanup` job in `release-please.yml` fires when
  `{companion}_release_created == 'true'`, runs `script/strip_release_as.py crosswake_{companion}`
  (surgical, minimal-diff, idempotent), and opens a one-line cleanup PR. A human only merges it.
- **Fail-closed guard** — `.github/workflows/release-as-staleness-gate.yml` (the
  `merge-blocking-release-as-staleness` check) runs `script/check_release_as_staleness.sh` and goes
  RED if any `release-as` pin equals an already-released version (`{component}-v{X}` tag). It stays
  RED until the cleanup PR merges, so the fix cannot be silently skipped.

Both are parametric over every `crosswake_*` package, so new companions inherit this for free —
no new wiring needed in Step 12 beyond the standard `release-as: "0.1.0"` bootstrap pin in 12a.
The only intentional human gate in the release chain is merging the Release PR (the irreversible
`hex.publish` go/no-go).

---

## crosswake_dep/0 pivot recap (D-11/D-13)

The env-conditional resolver in Step 4 above handles the path: → Hex dep pivot automatically.
No manual dep-string editing needed when promoting from dress rehearsal to publish:

- Dress rehearsal (Phase 130): `CROSSWAKE_RELEASE` unset → `crosswake_dep()` returns path dep
- Publish (Phase 131+): `CROSSWAKE_RELEASE=1` set in CI job env → returns Hex dep `{:crosswake, "~> 0.1"}`
- The committed `mix.lock` retains the path dep entry (still valid for local dev)
- `mix deps.get` in the publish job resolves the Hex dep fresh

---

## Checklist Summary

**Extraction (Steps 1–11 — Phase 130 dress rehearsal):**
- [ ] Adapter source moved; module name preserved; `@compile {:no_warn_undefined, Engine}` added (D-29)
- [ ] Config-indirection `flag_source/0` in place; no test-module in lib/ (D-31)
- [ ] MockFlagSource/equivalent moved to companion `test/support/` (verbatim)
- [ ] StudySessionLive stub copied to companion `test/support/` (D-23)
- [ ] Engine-present stub in `test/engine_present/` (D-33)
- [ ] Companion `mix.exs`: version + marker, `crosswake_dep()` call, `optional: true` engine dep (D-19/D-22/D-28/D-11)
- [ ] `crosswake_dep/0` private function with env-conditional (CROSSWAKE_RELEASE=1 → Hex, else path:) (D-11/D-13)
- [ ] `config/config.exs` wires test flag_source (D-31)
- [ ] `mix.lock` committed after `mix deps.get` (D-24)
- [ ] `MIX_INCLUDE_{COMPANION}` block deleted from core `mix.exs` (D-21)
- [ ] Root aliases `companions.test` + `verify` wired in core `mix.exs` (D-26)
- [ ] `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_{companion}` passes (D-24)
- [ ] Guard tests green: EXTRACT-01, COMPAT-01, companion lane (D-25)

**Release-please registration (Step 12 — Phase 131+ only):**
- [ ] `release-please-config.json`: `packages/crosswake_{companion}` entry with `release-as: "0.1.0"`, NOT in `linked-versions` (D-01/D-04)
- [ ] `.release-please-manifest.json`: `"packages/crosswake_{companion}": "0.1.0"` added (D-03)
- [ ] `release-please.yml` `outputs:` block: three `{companion}_*` aliases with double-dash format (D-08)
- [ ] `publish-hex-{companion}` job added with `CROSSWAKE_RELEASE=1` env on all mix steps (D-06/D-07)
- [ ] `clean-room-proof-{companion}` job added, needs publish job (PROOF-01/PROOF-02)
- [x] `release-as` removal is CI-automated (PROOF-03): `release-as-cleanup` job auto-opens the
  cleanup PR + `merge-blocking-release-as-staleness` guard enforces it — parametric, no manual step (Pitfall 6)

---

*Recipe version: Phase 135 (release-as removal CI-automated — PROOF-03)*
*Base: Phase 131 (rulestead publish pipeline + crosswake_dep/0 pivot)*
*Proven on: crosswake_rulestead (Phase 130 extraction + Phase 131 publish wiring), crosswake_rindle (Phase 132)*
*Next: sigra / chimeway / threadline (fast follow-on — inherit 0-human release ops)*
