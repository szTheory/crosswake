defmodule Crosswake.Compatibility.RouteGate do
  @moduledoc """
  Fail-closed route activation decisions derived from layered compatibility findings.
  """

  alias Crosswake.Compatibility
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Shell.Denial

  defmodule Decision do
    @moduledoc false

    defstruct [:route_id, :status, :denial, denials: [], transition: :activate]

    @type t :: %__MODULE__{
            route_id: String.t(),
            status: :allow | :deny,
            denial: Denial.t() | nil,
            denials: [Denial.t()],
            transition: :activate | :halt | :stay_put
          }
  end

  @spec evaluate(Root.t(), String.t(), Target.t()) :: Decision.t()
  def evaluate(%Root{} = manifest, route_id, %Target{} = target) do
    evaluate(manifest, route_id, target, [])
  end

  @spec evaluate(Root.t(), String.t(), Target.t(), keyword()) :: Decision.t()
  def evaluate(%Root{} = manifest, route_id, %Target{} = target, opts) do
    findings = Compatibility.route_findings(manifest, route_id, target)
    denials = Enum.map(findings, &Compatibility.finding_to_denial(&1, Keyword.put(opts, :route_id, route_id)))
    status = if(denials == [], do: :allow, else: :deny)

    %Decision{
      route_id: route_id,
      status: status,
      denial: List.first(denials),
      denials: denials,
      transition: transition_for(status, opts)
    }
  end

  defp transition_for(:allow, _opts), do: :activate

  defp transition_for(:deny, opts) do
    if Keyword.get(opts, :activation_source) == :in_app_navigation do
      :stay_put
    else
      :halt
    end
  end
end
