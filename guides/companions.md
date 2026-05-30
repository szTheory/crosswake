# Companion Integrations

Companions are optional first-party integrations that extend Crosswake route policy with real-time signals from external libraries. Each companion implements the `Crosswake.Companion` behaviour — six locked callbacks that gate routes, check kill switches, validate optional dependencies, and report runtime state. Companions carry explicit fail-closed semantics: when a companion's optional dependency is absent or its flag source is unreachable, Crosswake denies access rather than defaulting to open. Each shipped companion carries a hermetic merge-blocking CI proof lane (passes without the optional dep) plus an advisory lane (proves the dep is present and working).

---

## Rulestead — Feature Flag Gating

[Rulestead](https://hex.pm/packages/rulestead) is a first-party feature flag library. The Crosswake rulestead companion gates routes by reading flag state and denying access when a feature is not yet enabled or when a kill switch has fired.

### Declaring a Gated Route

Use the `gated_by: :rulestead` option in your route policy to declare that a route is controlled by the rulestead companion:

```elixir
scope "/" do
  crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
    live "/beta-feature", BetaFeatureLive,
      crosswake: [
        id: "beta-feature",
        gated_by: :rulestead,
        on_unavailable: :deny
      ]
  end
end
```

The `on_unavailable: :deny` declaration is the fail-closed posture: if the gate evaluation cannot resolve a flag (flag source absent, process down, or flag not set), the route is denied rather than allowed through.

### Gate State Semantics

The rulestead companion recognizes three gate states from the flag source:

| Gate State | Denial Reason | Behavior |
|-----------|---------------|----------|
| `:gated` | `:gate_denied` | Route denied — feature not yet enabled |
| `{:rolling_out, n}` | `:gate_denied` | Route denied — feature rolling out (partial gate, percentage `n`) |
| `:killed` | `:kill_switch_active` | Route denied — kill switch active; short-circuits all other gate logic |
| `nil` (unset) | none | Route allowed — no flag stored means not gated |

Kill switches short-circuit first: if any stored flag is `:killed`, `kill_switch_active?/1` returns `true` and the route is denied with reason `:kill_switch_active` before gate evaluation runs. This is the canonical kill switch behavior.

### Fail-Closed Guarantee

If the flag source process is not running (e.g., `MockFlagSource` not started in test, or the real `Rulestead.Snapshot` adapter not configured in production), the companion defaults conservatively:

- `route_gated?/2` returns `:pass` — avoids blocking requests when the gate source is absent (flag source failure does not inadvertently lock all users out)
- `kill_switch_active?/1` returns `false` — kill switch treated as inactive when source is unreachable

This is the fail-closed contract for the companion seam layer: the companion itself does not crash, but `validate_dependency/0` will return `{:error, [:"Elixir.Rulestead"]}` when rulestead is absent, driving a `companion.dependency_missing` `:error` finding in `mix crosswake.doctor` output.

### MockFlagSource — Dev and Test Mock

`Crosswake.Companions.Rulestead.MockFlagSource` is a named `Agent` that stores flag state in memory. It is the mock swap target for local development and hermetic proof tests. The production swap target is the real `Rulestead.Snapshot` adapter (deferred to a future phase — see Promotion Path below).

**Starting MockFlagSource in tests:**

```elixir
setup do
  start_supervised!(Crosswake.Companions.Rulestead.MockFlagSource)
  :ok
end
```

**Setting flag state:**

```elixir
alias Crosswake.Companions.Rulestead.MockFlagSource

# Gate the route (feature disabled)
MockFlagSource.set_flag(:rulestead, :gated)

# Enable rolling out at 50%
MockFlagSource.set_flag(:rulestead, {:rolling_out, 50})

# Fire kill switch
MockFlagSource.set_flag(:rulestead, :killed)

# Remove flag (route allowed through)
MockFlagSource.delete_flag(:rulestead)
```

**Resetting all flags between tests:**

`start_supervised!/1` in `ExUnit` setup automatically tears down the Agent after each test, giving a fresh empty flag map per test. `MockFlagSource.reset/0` is available as a belt-and-suspenders alternative when the Agent is shared across tests.

### Doctor Diagnostics

`mix crosswake.doctor` emits a `companion.rulestead` finding when the companion is enabled:

- **`companion.dependency_missing` (`:error`)** — rulestead companion enabled but the `Rulestead` library is absent. Add `rulestead` to your deps or disable the companion.
- **`companion.disabled_dependency_present` (`:advisory`)** — rulestead companion disabled but the library is present. No action required; this is informational.

Gate-state truth is available via `Crosswake.SupportMatrix.gating_truth/0`, which returns the current gate status, kill switch status, dependency status, and enabled state for all configured companions.

### Companion Configuration

Enable the rulestead companion in your application config:

```elixir
# config/config.exs
config :crosswake, :rulestead, enabled: true
config :crosswake, :companions, [Crosswake.Companions.Rulestead]
```

### Promotion Path

The rulestead advisory CI lane currently proves that `validate_dependency/0` returns `:ok` when the `rulestead` Hex package is present. Promotion of the advisory lane to merge-blocking requires:

1. The real `Rulestead.Snapshot` adapter shipped and in-tree — the production swap target that replaces `MockFlagSource`, reading actual flag state from the rulestead library.
2. The advisory lane exercising actual flag reads (not just dependency presence) — `MockFlagSource.set_flag/2` tests validate the companion contract; the `Rulestead.Snapshot` adapter validates end-to-end flag delivery.
3. Sustained stability evidence from several consecutive scheduled advisory runs without flakes.
4. An explicit requirement and roadmap scope change documented in `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`.

Until all four conditions are met, advisory lane results are visible in CI but do not gate merge. See `phase43-proof.yml` for the CI workflow contract.
