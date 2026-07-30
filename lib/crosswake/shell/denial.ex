defmodule Crosswake.Shell.Denial do
  @moduledoc """
  Stable denial envelope shared by shell activation and bounded bridge replies.

  Core-owned denial envelope. Not part of the companion contract surface.
  Companion implementations return `{:deny, Crosswake.Compatibility.Finding.t()}`
  from `route_gated?/2`; core translates findings into `Denial` structs internally.
  Extension authors should never construct or return a `Denial` directly — reach
  for `Crosswake.Compatibility.Finding` instead.
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
    :step_up_required,
    :notification_open_denied,
    # Phase 130: COMPAT-01 RouteGate fail-closed enforcement
    :dependency_missing,
    # Phase 154: CTRL-02 — the bridge seam's single "we could not deliver a shell
    # answer" reason. Four failing moments (details.failing_moment), one reason,
    # never :unavailable_capability (D-12, D-13).
    :shell_unreachable
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
          | :notification_open_denied
          | :dependency_missing
          | :shell_unreachable

  @typedoc """
  The four ways `Bridge.push/3` can fail to deliver a shell answer, carried in
  `details.failing_moment` for the `:shell_unreachable` reason (D-12). One reason,
  four variants — never four reasons.

    * `:no_transport` — the bridge hook is wired and acked, but no native transport
      (`window.webkit.messageHandlers.crosswakeBridge` / the Android WebMessage
      listener) is reachable.
    * `:reply_timeout` — the shell received the request but never answered before
      the reply deadline elapsed.
    * `:transport_error` — the hook found a transport but the call into it itself
      failed.
    * `:hook_not_wired` — no acknowledgement arrived before the server-armed wiring
      deadline; the bridge hook is not wired up on this page at all.
  """
  @type failing_moment :: :no_transport | :reply_timeout | :transport_error | :hook_not_wired

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

  defp ensure_commerce_corridor_payload(:shell_unreachable, details, recovery) do
    details =
      if Map.has_key?(details, :failing_moment) do
        details
      else
        Map.put(details, :failing_moment, :hook_not_wired)
      end

    {details, recovery}
  end

  defp ensure_commerce_corridor_payload(_reason, details, recovery), do: {details, recovery}
end
