defmodule Crosswake.Companion.State do
  @moduledoc """
  Typed runtime state snapshot returned by `report_state/0`.

  Carries the companion's current enabled status, dependency health,
  gate configuration, and kill-switch position at a point in time.
  `checked_at` is a monotonic millisecond timestamp
  (`System.monotonic_time(:millisecond)`).

  ## Stability

  Public stable — part of the Crosswake companion contract surface. Semver-protected
  under `crosswake` >= 0.1.0: no breaking changes to this module's struct fields,
  types, or callbacks without a major version bump. Companion packages
  (`crosswake_rulestead`, `crosswake_rindle`, etc.) may safely `alias` and
  pattern-match on this type.
  """
  @moduledoc since: "0.1.0"

  @enforce_keys [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at]
  defstruct [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at, details: %{}]

  @type dependency_status :: :present | {:missing, [module()]}
  @type gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
  @type kill_switch_status :: :inactive | :active | :unconfigured

  @typedoc "Runtime state snapshot for a companion at a point in time."
  @type t :: %__MODULE__{
          companion_id: atom(),
          enabled: boolean(),
          dependency_status: dependency_status(),
          gate_status: gate_status(),
          kill_switch_status: kill_switch_status(),
          checked_at: non_neg_integer(),
          details: map()
        }
end
