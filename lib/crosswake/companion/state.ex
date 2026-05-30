defmodule Crosswake.Companion.State do
  @moduledoc false

  @enforce_keys [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at]
  defstruct [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at, details: %{}]

  @type dependency_status :: :present | {:missing, [module()]}
  @type gate_status :: :active | :inactive | :unconfigured
  @type kill_switch_status :: :inactive | :active | :unconfigured

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
