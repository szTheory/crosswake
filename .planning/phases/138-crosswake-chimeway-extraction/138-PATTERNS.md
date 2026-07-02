# Phase 138: crosswake_chimeway Extraction - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 22 new/modified files
**Analogs found:** 22 / 22

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `packages/crosswake_chimeway/mix.exs` | config | request-response | `packages/crosswake_sigra/mix.exs` | exact |
| `packages/crosswake_chimeway/mix.lock` | config | — | `packages/crosswake_sigra/mix.lock` | exact |
| `packages/crosswake_chimeway/config/config.exs` | config | — | `packages/crosswake_sigra/config/config.exs` | exact |
| `packages/crosswake_chimeway/README.md` | doc | — | `packages/crosswake_sigra/README.md` | exact |
| `packages/crosswake_chimeway/CHANGELOG.md` | doc | — | `packages/crosswake_sigra/CHANGELOG.md` | exact |
| `packages/crosswake_chimeway/LICENSE` | doc | — | `packages/crosswake_sigra/LICENSE` | exact |
| `packages/crosswake_chimeway/lib/crosswake/companions/chimeway.ex` | provider | request-response | `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex` | exact |
| `packages/crosswake_chimeway/lib/crosswake/companions/chimeway/*.ex` (6 files) | service | request-response | `packages/crosswake_sigra/lib/crosswake/companions/sigra/*.ex` | role-match |
| `packages/crosswake_chimeway/test/test_helper.exs` | config | — | `packages/crosswake_sigra/test/test_helper.exs` | exact |
| `packages/crosswake_chimeway/test/support/study_session_live.ex` | utility | — | `packages/crosswake_sigra/test/support/study_session_live.ex` | exact |
| `packages/crosswake_chimeway/test/crosswake/companions/chimeway_test.exs` | test | request-response | `packages/crosswake_sigra/test/crosswake/companions/sigra_test.exs` (in-core move) | exact |
| `packages/crosswake_chimeway/test/crosswake/companions/chimeway/*.exs` (5 files) | test | request-response | Moved from `test/crosswake/companions/chimeway/` | exact |
| `packages/crosswake_chimeway/test/crosswake/proof/phase59_chimeway_contract_test.exs` | test | request-response | Split from `test/crosswake/proof/phase59_chimeway_contract_test.exs` | exact (split) |
| `packages/crosswake_chimeway/test/crosswake/proof/phase71_notification_workflow_proof_test.exs` | test | event-driven | Moved from `packages/crosswake_sigra/test/crosswake/proof/phase71_notification_workflow_proof_test.exs` | exact (move) |
| `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` | test | event-driven | `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs` | role-match |
| `test/crosswake/proof/phase59_chimeway_support_truth_test.exs` | test | request-response | `test/crosswake/proof/phase54_sigra_support_truth_test.exs` | exact |
| `test/support/stub_companion.ex` (add StubChimewayAbsentCompanion) | utility | request-response | `test/support/stub_companion.ex` lines 89-141 (StubSigraAbsentCompanion) | exact |
| `release-please-config.json` | config | — | Lines 93-112 (sigra block) | exact |
| `.release-please-manifest.json` | config | — | Line 7 (`"packages/crosswake_sigra": "0.1.0"`) | exact |
| `.github/workflows/release-please.yml` (outputs) | config | — | Lines 59-61 (sigra outputs) | exact |
| `.github/workflows/release-please.yml` (publish-hex-chimeway job) | config | — | Lines 335-425 (publish-hex-sigra) | exact |
| `.github/workflows/release-please.yml` (clean-room-proof-chimeway job) | config | — | Lines 892-924 (clean-room-proof-sigra) | exact |
| `.github/workflows/release-please.yml` (release-as-cleanup + release-failure-alert patches) | config | — | Lines 926-1021 | exact |
| `script/verify_companion_cleanroom.sh` (chimeway canary patch) | utility | — | Lines 307-320 (rindle canary pattern) | role-match |
| `examples/phoenix_host/mix.exs` (add chimeway path dep) | config | — | Lines 48-49 (rindle/sigra path deps) | exact |
| `guides/companion_compatibility.md` (add chimeway row) | doc | — | Line 24 (sigra row) | exact |
| `mix.exs` (remove Chimeway from application env) | config | — | Lines 28-31 (Phase-138 extraction comment) | exact |

## Pattern Assignments

### `packages/crosswake_chimeway/mix.exs` (config)

**Analog:** `packages/crosswake_sigra/mix.exs` (lines 1-72)

**Full pattern** (`packages/crosswake_sigra/mix.exs` lines 1-72):
```elixir
defmodule CrosswakeSigra.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — D-22: separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_sigra,
      version: @version,
      name: "crosswake_sigra",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # NOTE: No ENGINE_PRESENT_LANE branch — sigra has no optional engine library.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [crosswake_dep()]
    # NOTE: No optional engine dep
  end

  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  defp description do
    "Sigra auth companion adapter for the Crosswake route-policy system."
  end

  defp package do
    [
      name: "crosswake_sigra",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_sigra",
        "GitHub" => @source_url
      },
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
```

**Chimeway substitutions:** Replace every `sigra` → `chimeway`, `Sigra` → `Chimeway`. Change description to `"Chimeway notification companion adapter for the Crosswake route-policy system."`.

**Critical difference from sigra:** No changes to the no-engine branch structure — chimeway also has no engine dep. The `defp deps` block is identical (single `crosswake_dep()` call).

---

### `packages/crosswake_chimeway/test/test_helper.exs` (config)

**Analog:** `packages/crosswake_sigra/test/test_helper.exs` (line 1)

```elixir
ExUnit.start(exclude: [:requires_example_host, :advisory_only])
```

Copy verbatim.

---

### `packages/crosswake_chimeway/test/support/study_session_live.ex` (utility)

**Analog:** `packages/crosswake_sigra/test/support/study_session_live.ex` (lines 1-7)

```elixir
defmodule Crosswake.TestSupport.StudySessionLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>study session</div>"
  end
end
```

Copy verbatim — needed for phase71 notification workflow proof test.

---

### `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` (test, event-driven)

**Analog:** `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs` (lines 1-45)

**Sigra cleanroom pattern** (lines 1-45):
```elixir
defmodule Crosswake.Proof.Phase137SigraCleanroomTest do
  use ExUnit.Case, async: false

  # ... aliases ...

  setup do
    original = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])
    on_exit(fn -> Application.put_env(:crosswake, :companions, original) end)
    :ok
  end

  test "clean-room non-vacuity: sigra registered → :step_up_required not :dependency_missing" do
    # ... RouteGate.evaluate assertion proving dispatch ran non-vacuously ...
  end
end
```

**Chimeway diverges significantly** — chimeway is NOT an auth companion, so the non-vacuity proof uses telemetry aggregation instead of RouteGate auth dispatch. Use the full pattern from RESEARCH.md Pattern 6:

```elixir
defmodule Crosswake.Proof.Phase138ChimewayCleanroomTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Chimeway
  alias Crosswake.Companions.Chimeway.Telemetry, as: ChimewayTelemetry

  setup do
    original = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Chimeway])
    on_exit(fn -> Application.put_env(:crosswake, :companions, original) end)
    :ok
  end

  test "clean-room non-vacuity: chimeway registered → telemetry_events/0 contributes to core catalog" do
    all_events = Crosswake.Telemetry.events()
    chimeway_event_names = ChimewayTelemetry.event_names()
    chimeway_events_in_catalog = Enum.filter(all_events, fn event -> event.event in chimeway_event_names end)
    assert chimeway_events_in_catalog != [],
           "chimeway events must appear in Crosswake.Telemetry.events/0 when registered"
  end

  test "clean-room non-vacuity: chimeway registered → forbidden_metadata_keys aggregated" do
    aggregated = Crosswake.Telemetry.forbidden_metadata_keys()
    chimeway_keys = ChimewayTelemetry.forbidden_metadata_keys()
    for key <- chimeway_keys do
      assert key in aggregated, "chimeway forbidden key :#{key} must be in aggregated forbidden_metadata_keys"
    end
  end

  test "chimeway is NOT an auth authority (CHIME-02: no sigra dep)" do
    refute function_exported?(Chimeway, :auth_authority?, 0),
           "Chimeway must not export auth_authority?/0 — it is a notification companion, not auth"
  end

  test "clean-room: crosswake_sigra is NOT in deps (vacuity guard)" do
    deps = Mix.Project.config()[:deps]
    dep_names = Enum.map(deps, fn {name, _} -> name; {name, _, _} -> name end)
    refute :crosswake_sigra in dep_names, "crosswake_chimeway must NOT depend on crosswake_sigra (CHIME-02)"
  end
end
```

**Planner note (Assumption A2):** Verify `Crosswake.Telemetry.forbidden_metadata_keys/0` is a public function before wiring the second assertion. If absent, use `Crosswake.Telemetry.events()` filtering only.

---

### `test/support/stub_companion.ex` (add StubChimewayAbsentCompanion)

**Analog:** `test/support/stub_companion.ex` lines 89-141 (StubSigraAbsentCompanion)

**StubSigraAbsentCompanion pattern** (lines 89-141):
```elixir
defmodule Crosswake.TestSupport.StubSigraAbsentCompanion do
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :sigra

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [Crosswake.Companions.Sigra]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :sigra, %{})
    %Crosswake.Companion.State{
      companion_id: :sigra,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [Crosswake.Companions.Sigra]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end

  @impl true
  def auth_authority?, do: false   # ← sigra has this; chimeway MUST NOT
end
```

**Chimeway substitutions:** Replace `:sigra` → `:chimeway`, `Sigra` → `Chimeway`. **CRITICAL OMISSION:** Do NOT add `auth_authority?/0` — chimeway is NOT an auth companion. The `enabled?/1` default in the stub uses `false` (same as sigra stub), which is correct for the absent-companion stub modeling.

---

### `release-please-config.json` (add chimeway block)

**Analog:** `release-please-config.json` lines 93-112 (sigra block)

```json
"packages/crosswake_sigra": {
  "component": "crosswake_sigra",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "_TODO_release_as": "ONE-SHOT override ...",
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_sigra/mix.exs"],
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

Add an identical block keyed `"packages/crosswake_chimeway"` with `s/sigra/chimeway/g` applied. The `_TODO_release_as` comment must reference `Phase 138 / recipe Step 12f / Pitfall 6`.

---

### `.release-please-manifest.json` (add chimeway entry)

**Analog:** `.release-please-manifest.json` line 7

```json
"packages/crosswake_sigra": "0.1.0"
```

Add after the sigra line:
```json
"packages/crosswake_chimeway": "0.1.0"
```

---

### `.github/workflows/release-please.yml` — outputs block (lines 59-61)

**Analog:** Lines 59-61 (sigra outputs):
```yaml
sigra_release_created: ${{ steps.release.outputs['packages/crosswake_sigra--release_created'] }}
sigra_tag_name: ${{ steps.release.outputs['packages/crosswake_sigra--tag_name'] }}
sigra_version: ${{ steps.release.outputs['packages/crosswake_sigra--version'] }}
```

Add after sigra outputs (apply `s/sigra/chimeway/g`):
```yaml
# Companion: crosswake_chimeway (Phase 138 — independently versioned, NOT in lockstep)
chimeway_release_created: ${{ steps.release.outputs['packages/crosswake_chimeway--release_created'] }}
chimeway_tag_name: ${{ steps.release.outputs['packages/crosswake_chimeway--tag_name'] }}
chimeway_version: ${{ steps.release.outputs['packages/crosswake_chimeway--version'] }}
```

---

### `.github/workflows/release-please.yml` — `publish-hex-chimeway` job

**Analog:** Lines 335-425 (`publish-hex-sigra` job)

Full job structure (apply `s/sigra/chimeway/g` throughout):
- `needs: release-please`
- `if: ${{ needs.release-please.outputs.chimeway_release_created == 'true' }}`
- `env: CROSSWAKE_RELEASE: "1"`
- Checkout at `chimeway_tag_name`
- Cache path: `packages/crosswake_chimeway/deps` + `_build`, key `runner.os-chimeway-hashFiles(mix.lock)`
- Steps: `mix deps.get` → `mix compile --warnings-as-errors` → verify version → `mix test` → `mix hex.publish --dry-run --yes` → `mix hex.publish --yes` → Hex propagation poll (36 attempts × 10s = 6 min timeout)

**Key comment to preserve** (from publish-hex-sigra lines 338-341):
```yaml
# D-8 / D-07: Gate on the PER-COMPONENT output, never the aggregate `releases_created`.
# `releases_created` is true if ANY package released — gating on it would publish the
# companion on every core-only release. `chimeway_release_created` is set only when
# release-please cuts a crosswake_chimeway release PR.
```

---

### `.github/workflows/release-please.yml` — `clean-room-proof-chimeway` job

**Analog:** Lines 892-924 (`clean-room-proof-sigra` job)

```yaml
clean-room-proof-sigra:
  name: Clean-room proof — crosswake_sigra resolvability + doctor
  needs: [release-please, publish-hex-sigra]
  if: ${{ needs.release-please.outputs.sigra_release_created == 'true' }}
  runs-on: ubuntu-latest
  permissions:
    contents: read
  steps:
    - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
    - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
      with:
        version-file: .tool-versions
        version-type: strict
    - name: Install Hex + Rebar
      run: |
        mix local.hex --force
        mix local.rebar --force
    - name: Run clean-room proof (D-16 — logic lives in script; YAML stays thin)
      run: >
        bash script/verify_companion_cleanroom.sh
        crosswake_sigra
        "${{ needs.release-please.outputs.sigra_version }}"
```

Apply `s/sigra/chimeway/g`. Final `run:` invocation becomes:
```yaml
run: >
  bash script/verify_companion_cleanroom.sh
  crosswake_chimeway
  "${{ needs.release-please.outputs.chimeway_version }}"
```

---

### `.github/workflows/release-please.yml` — `release-as-cleanup` patch (lines 934, 956-958)

**Analog:** Lines 934 and 950-958

Current `if:` condition (line 934):
```yaml
if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' || needs.release-please.outputs.rindle_release_created == 'true' || needs.release-please.outputs.sigra_release_created == 'true' }}
```

Add `|| needs.release-please.outputs.chimeway_release_created == 'true'` to the condition.

Add chimeway strip block after the sigra block (lines 956-958):
```yaml
if [ "${{ needs.release-please.outputs.chimeway_release_created }}" = "true" ]; then
  python3 script/strip_release_as.py crosswake_chimeway
fi
```

---

### `.github/workflows/release-please.yml` — `release-failure-alert` patch (lines 982-1021)

**Analog:** Lines 982-1021

Add to `needs:` list:
```yaml
- publish-hex-chimeway
- clean-room-proof-chimeway
```

Add to the issue body echo block:
```bash
echo "- publish-hex-chimeway: ${{ needs.publish-hex-chimeway.result }}"
echo "- clean-room-proof-chimeway: ${{ needs.clean-room-proof-chimeway.result }}"
```

---

### `script/verify_companion_cleanroom.sh` — chimeway canary patch

**Analog:** Lines 307-320 (rindle canary pattern)

```bash
$(if [ "$PACKAGE" = "crosswake_rindle" ]; then cat <<'CANARYEOF'
  test "Rindle.Contracts.media_state_vocabulary/0 returns a non-empty list (canary: Contracts shipped)" do
    vocab = Crosswake.Companions.Rindle.Contracts.media_state_vocabulary()
    assert is_list(vocab) and vocab != [], ...
  end
CANARYEOF
fi)
```

Add a chimeway-specific elif branch:

```bash
$(if [ "$PACKAGE" = "crosswake_chimeway" ]; then cat <<'CANARYEOF'

  # chimeway-specific: enabled?(%{}) defaults to TRUE (unlike rulestead/rindle/sigra stubs).
  # The no-engine smoke test default assertion (`refute enabled?(%{})`) would FAIL for chimeway.
  # This override replaces that assertion with the chimeway-correct form.
  test "enabled?/1 defaults to true (chimeway enabled by default — no :enabled key required)" do
    assert Crosswake.Companions.Chimeway.enabled?(%{})
  end

  # Telemetry canary: proves Chimeway.Telemetry sub-module shipped in the tarball.
  test "Chimeway.Telemetry.event_names/0 returns 10 notification events (canary: Telemetry shipped)" do
    events = Crosswake.Companions.Chimeway.Telemetry.event_names()
    assert is_list(events) and length(events) == 10,
           "Chimeway.Telemetry.event_names/0 should return 10 events — Telemetry module may be missing from tarball"
  end
CANARYEOF
fi)
```

**Critical:** The standard `refute ${COMPANION_MODULE_SUFFIX}.enabled?(%{})` at line 269 (no-engine smoke test) must be suppressed for chimeway. The planner must decide whether to (a) add an early-exit/skip for chimeway's `enabled?` test block or (b) restructure the no-engine block with an `if [ "$PACKAGE" = "crosswake_chimeway" ]` guard. Option (b) is safer and more explicit.

---

### `examples/phoenix_host/mix.exs` (add chimeway path dep)

**Analog:** `examples/phoenix_host/mix.exs` lines 48-49

```elixir
{:crosswake_rindle, path: "../../packages/crosswake_rindle"},
{:crosswake_sigra, path: "../../packages/crosswake_sigra"},
```

Add after sigra:
```elixir
{:crosswake_chimeway, path: "../../packages/crosswake_chimeway"},
```

Also update the comment at line 46 to mention `crosswake_chimeway`.

---

### `guides/companion_compatibility.md` (add chimeway row)

**Analog:** Line 24 (sigra row)

```markdown
| `crosswake_sigra` | `:sigra` | `0.1.0` | `~> 0.1` | `{:sigra, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_sigra](https://hexdocs.pm/crosswake_sigra) |
```

Add after sigra row:
```markdown
| `crosswake_chimeway` | `:chimeway` | `0.1.0` | `~> 0.1` | none (pure-Elixir notification machinery) | [hexdocs.pm/crosswake_chimeway](https://hexdocs.pm/crosswake_chimeway) |
```

---

### `mix.exs` (remove Chimeway from application env)

**Analog:** `mix.exs` lines 28-31 (Phase-138 extraction comment already present)

Current state:
```elixir
# In-tree registration bridge — Chimeway only after Phase-137 sigra extraction.
# Phase-138 extraction: remove Crosswake.Companions.Chimeway from this list when
# that module is extracted to the crosswake_chimeway package.
env: [companions: [Crosswake.Companions.Chimeway]]
```

After Phase 138 extraction: remove the `env:` line entirely (or replace with `env: []` if the key is required). Remove the extraction comment. This is the sole mutation to core `mix.exs`.

---

### Phase71 test move: `packages/crosswake_sigra/.../phase71_notification_workflow_proof_test.exs` → chimeway

**Analog:** The file itself — move destination `packages/crosswake_chimeway/test/crosswake/proof/phase71_notification_workflow_proof_test.exs`

**Sigra.Contracts dependency resolution (Open Question 3):** Phase71 uses `alias Crosswake.Companions.Sigra.Contracts, as: SigraContracts` for building auth context maps. If `SigraContracts.new_auth_context/1` returns a plain `map()`, replace the alias with plain map literals. If it returns a sigra-specific struct, add to `packages/crosswake_chimeway/mix.exs` deps:
```elixir
{:crosswake_sigra, path: "../../packages/crosswake_sigra", only: :test}
```
Planner must read `packages/crosswake_sigra/lib/crosswake/companions/sigra/contracts.ex` to determine return type of `new_auth_context/1`.

---

### Phase59 split pattern

**Core (stays):** `test/crosswake/proof/phase59_chimeway_support_truth_test.exs`
- Contains only the `SupportMatrix.notification_support_truth/0` assertion
- Analog: `test/crosswake/proof/phase54_sigra_support_truth_test.exs` (same split pattern from Phase 137)

**Package (moves):** `packages/crosswake_chimeway/test/crosswake/proof/phase59_chimeway_contract_test.exs`
- Contains 4 tests: TOKN-02 lifecycle, raw-token absence, public struct aliases, delivery_accepted
- Move these tests verbatim; remove the `SupportMatrix` assertion

---

## Shared Patterns

### `async: false` for all companion registration tests
**Source:** `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs` line 7
```elixir
use ExUnit.Case, async: false
```
**Apply to:** `phase138_chimeway_cleanroom_test.exs` — companion registration via `Application.put_env` is process-global state; must be async: false.

### `on_exit` cleanup for Application env mutations
**Source:** `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs` lines 27-30
```elixir
original = Application.get_env(:crosswake, :companions, [])
Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])
on_exit(fn -> Application.put_env(:crosswake, :companions, original) end)
```
**Apply to:** All chimeway tests that call `Application.put_env`.

### `CROSSWAKE_RELEASE=1` env var for publish jobs
**Source:** `.github/workflows/release-please.yml` line 350
```yaml
env:
  CROSSWAKE_RELEASE: "1"
```
**Apply to:** `publish-hex-chimeway` job — activates `crosswake_dep/0` to emit `{:crosswake, "~> 0.1"}` instead of path dep in the tarball.

### Per-component output gate (not aggregate `releases_created`)
**Source:** `.github/workflows/release-please.yml` lines 338-342
```yaml
# D-8 / D-07: Gate on the PER-COMPONENT output, never the aggregate `releases_created`.
if: ${{ needs.release-please.outputs.sigra_release_created == 'true' }}
```
**Apply to:** `publish-hex-chimeway` and `clean-room-proof-chimeway` — use `chimeway_release_created`, never `releases_created`.

### No-engine mode invocation for `verify_companion_cleanroom.sh`
**Source:** `script/verify_companion_cleanroom.sh` lines 29-30 (usage comment)
```bash
bash script/verify_companion_cleanroom.sh crosswake_sigra 0.1.0
bash script/verify_companion_cleanroom.sh crosswake_sigra 0.1.0 none
```
**Apply to:** chimeway clean-room CI job — invoke as `bash script/verify_companion_cleanroom.sh crosswake_chimeway "${{ needs.release-please.outputs.chimeway_version }}"` (no ENGINE_PACKAGE argument → no-engine mode).

### `files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)` Hex files allowlist
**Source:** `packages/crosswake_sigra/mix.exs` line 69
```elixir
files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
```
**Apply to:** `packages/crosswake_chimeway/mix.exs` — test/ is excluded from tarball (D-24 pattern).

---

## No Analog Found

All files have analogs. No entries in this section.

---

## Key Differences from Sigra (Phase 137)

| Aspect | Sigra (Phase 137) | Chimeway (Phase 138) |
|--------|-------------------|----------------------|
| `auth_authority?/0` callback | Present (`@impl true def auth_authority?, do: ...`) | **ABSENT** — chimeway is NOT an auth companion |
| Clean-room `enabled?(%{})` assertion | `refute enabled?(%{})` ← **WRONG for chimeway** | `assert enabled?(%{})` — chimeway defaults to `true` |
| Non-vacuity proof mechanism | RouteGate.evaluate → `:step_up_required` vs `:dependency_missing` | Telemetry aggregation → chimeway events in `Crosswake.Telemetry.events/0` |
| D-137-A Finding boundary refactor | Required (emit `Finding.t()` not `Denial.t()`) | **NOT required** — chimeway's `Denial.t()` use is structurally fine |
| StubAbsentCompanion has `auth_authority?/0` | Yes (`@impl true def auth_authority?, do: false`) | **No** — do not add `auth_authority?/0` to `StubChimewayAbsentCompanion` |
| Engine dep | None (pure Elixir) | None (pure Elixir) — identical |
| Source files count | 8 sub-modules + facade | 6 sub-modules + facade |
| Phase71 test location before extraction | Sigra package (moved there in Phase 137) | Must move to chimeway package |

## Metadata

**Analog search scope:** `packages/crosswake_sigra/`, `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`, `script/verify_companion_cleanroom.sh`, `test/support/stub_companion.ex`, `examples/phoenix_host/mix.exs`, `guides/companion_compatibility.md`, `mix.exs`
**Files scanned:** 12
**Pattern extraction date:** 2026-07-02
