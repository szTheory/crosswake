defmodule Crosswake.Shell.Denial do
  @moduledoc """
  Stable denial envelope shared by shell activation and bounded bridge replies.
  """

  alias Crosswake.Manifest.Types

  @reasons [
    :compatibility_mismatch,
    :undeclared_capability,
    :unavailable_capability,
    :commerce_corridor,
    :origin_denied,
    :inactive_route,
    :external_entry_denied,
    :pack_incompatible,
    :gate_denied,
    :kill_switch_active,
    :step_up_required
  ]

  @enforce_keys [:reason, :code, :message]
  defstruct [:reason, :code, :message, :hint, :route_id, details: %{}, recovery: %{}]

  @type reason ::
          :compatibility_mismatch
          | :undeclared_capability
          | :unavailable_capability
          | :commerce_corridor
          | :origin_denied
          | :inactive_route
          | :external_entry_denied
          | :pack_incompatible
          | :gate_denied
          | :kill_switch_active
          | :step_up_required

  @type t :: %__MODULE__{
          reason: reason(),
          code: String.t(),
          message: String.t(),
          hint: String.t() | nil,
          route_id: String.t() | nil,
          details: map(),
          recovery: map()
        }

  @spec reasons() :: [reason()]
  def reasons, do: @reasons

  @spec new(keyword()) :: t()
  def new(attrs) when is_list(attrs) do
    reason = Keyword.fetch!(attrs, :reason)
    details = Keyword.get(attrs, :details, %{})
    recovery = Keyword.get(attrs, :recovery, %{})
    {details, recovery} = ensure_commerce_corridor_payload(reason, details, recovery)

    struct!(__MODULE__, %{
      reason: reason,
      code: Keyword.get(attrs, :code, Atom.to_string(reason)),
      message: Keyword.fetch!(attrs, :message),
      hint: Keyword.get(attrs, :hint),
      route_id: Keyword.get(attrs, :route_id),
      details: details,
      recovery: recovery
    })
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = denial) do
    %{
      "reason" => Atom.to_string(denial.reason),
      "code" => denial.code,
      "message" => denial.message,
      "route_id" => denial.route_id,
      "hint" => denial.hint,
      "details" => Types.to_map(denial.details),
      "recovery" => Types.to_map(denial.recovery)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
    |> Map.new()
  end

  defp ensure_commerce_corridor_payload(:commerce_corridor, details, recovery) do
    details =
      if details == %{} do
        %{failing_moment: :commerce_route_activation}
      else
        details
      end

    recovery =
      if recovery == %{} do
        %{
          actions: [:return_to_phoenix_guidance, :declare_corridor_or_disable_commerce_route],
          fallback: :return_to_phoenix_guidance
        }
      else
        recovery
      end

    {details, recovery}
  end

  defp ensure_commerce_corridor_payload(_reason, details, recovery), do: {details, recovery}
end
