defmodule Crosswake.NavigationTransition do
  @moduledoc """
  The closed Phoenix-to-native transition seam for the first-adopter iOS shell.

  This module deliberately does not share the capability bridge's request/reply
  machinery. It emits one reserved LiveView event whose receiver may only make a
  best-effort delivery to the dedicated native navigation handler.
  """

  @event "crosswake:navigation_transition"
  @protocol "crosswake.navigation_transition"
  @version "1.0.0"
  @required_keys ~w(protocol version transition_id kind route_id)
  @optional_keys ~w(restoration_ref)
  @allowed_keys @required_keys ++ @optional_keys
  @id_pattern ~r/^(?:nav|route|restore)-[0-9a-f]{16}$/
  @kinds ~w(push_patch push_navigate)

  @type result ::
          {:ok, Phoenix.LiveView.Socket.t()} | {:error, :invalid_envelope | :incompatible_version}

  @doc """
  Validates and emits one D-04 transition envelope.

  Invalid input is returned as a closed error before it can reach a browser or
  native authority. Errors intentionally never include the supplied input.
  """
  @spec push(Phoenix.LiveView.Socket.t(), map()) :: result()
  def push(%Phoenix.LiveView.Socket{} = socket, attrs) when is_map(attrs) do
    with {:ok, envelope} <- validate(attrs) do
      {:ok, Phoenix.LiveView.push_event(socket, @event, envelope)}
    end
  end

  def push(%Phoenix.LiveView.Socket{}, _attrs), do: {:error, :invalid_envelope}

  @doc false
  @spec validate(map()) :: {:ok, map()} | {:error, :invalid_envelope | :incompatible_version}
  def validate(attrs) when is_map(attrs) do
    keys = Map.keys(attrs)

    cond do
      not Enum.all?(keys, &is_binary/1) ->
        {:error, :invalid_envelope}

      MapSet.new(keys) != MapSet.new(@required_keys ++ present_optional_keys(attrs)) ->
        {:error, :invalid_envelope}

      attrs["protocol"] != @protocol ->
        {:error, :invalid_envelope}

      attrs["version"] != @version ->
        {:error, :incompatible_version}

      attrs["kind"] not in @kinds ->
        {:error, :invalid_envelope}

      not opaque_ref?(attrs["transition_id"], "nav-") or
        not opaque_ref?(attrs["route_id"], "route-") or
          not optional_restoration_ref?(attrs) ->
        {:error, :invalid_envelope}

      true ->
        {:ok, canonical_envelope(attrs)}
    end
  end

  def validate(_attrs), do: {:error, :invalid_envelope}

  defp present_optional_keys(attrs), do: Enum.filter(@optional_keys, &Map.has_key?(attrs, &1))

  defp opaque_ref?(value, prefix) when is_binary(value),
    do: String.starts_with?(value, prefix) and value =~ @id_pattern

  defp opaque_ref?(_value, _prefix), do: false

  defp optional_restoration_ref?(attrs) do
    not Map.has_key?(attrs, "restoration_ref") or
      opaque_ref?(attrs["restoration_ref"], "restore-")
  end

  defp canonical_envelope(attrs) do
    Map.take(attrs, @allowed_keys)
  end
end
