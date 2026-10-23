defmodule Crosswake.Shell.IOSHostConfig do
  @moduledoc false

  @enforce_keys [
    :router,
    :origin,
    :entry_route_id,
    :app_bundle_id,
    :proof_app_bundle_id,
    :device_signing
  ]
  defstruct @enforce_keys

  @keys @enforce_keys

  def normalize(input) when is_list(input) do
    if Keyword.keyword?(input) and
         length(Keyword.keys(input)) == length(Enum.uniq(Keyword.keys(input))) do
      normalize(Map.new(input))
    else
      {:error, "invalid :ios_host declaration; use unique supported keys"}
    end
  end

  def normalize(input) when is_map(input) do
    keys = Map.keys(input)

    cond do
      Enum.any?(keys, &(not is_atom(&1))) ->
        {:error, "invalid :ios_host declaration keys; use atom keys supported by Crosswake"}

      Enum.sort(keys) != Enum.sort(@keys) ->
        {:error,
         "invalid :ios_host declaration keys; set router, origin, entry_route_id, app_bundle_id, proof_app_bundle_id, and device_signing"}

      true ->
        validate(input)
    end
  end

  def normalize(_), do: {:error, "invalid :ios_host declaration; expected a keyword list or map"}

  defp validate(input) do
    with :ok <- valid_router(input.router),
         {:ok, origin} <- valid_origin(input.origin),
         :ok <- valid_entry(input.entry_route_id),
         :ok <- valid_bundle(input.app_bundle_id, :app_bundle_id),
         :ok <- valid_bundle(input.proof_app_bundle_id, :proof_app_bundle_id),
         :ok <- valid_identity_collision(input.app_bundle_id, input.proof_app_bundle_id),
         {:ok, signing} <- valid_signing(input.device_signing) do
      {:ok, struct!(__MODULE__, %{input | origin: origin, device_signing: signing})}
    end
  end

  defp valid_router(router) when is_atom(router) and router not in [nil, true, false] do
    if Code.ensure_loaded?(router) and function_exported?(router, :__routes__, 0),
      do: :ok,
      else: {:error, "invalid router; compile a Phoenix router with Crosswake route declarations"}
  end

  defp valid_router(_), do: {:error, "invalid router; use a compiled Phoenix router module"}

  defp valid_origin(origin) when is_binary(origin) do
    uri = URI.parse(origin)
    host = uri.host && String.downcase(uri.host)

    authority =
      case Regex.run(~r{\Ahttps://([^/?#]*)}i, origin, capture: :all_but_first) do
        [value] -> value
        _ -> nil
      end

    {authority_host, raw_port} =
      case authority && String.split(authority, ":", parts: 2) do
        [value] -> {String.downcase(value), nil}
        [value, port] -> {String.downcase(value), port}
        _ -> {nil, nil}
      end

    valid_port =
      case raw_port do
        nil -> true
        value -> Regex.match?(~r/\A[0-9]+\z/, value) and String.to_integer(value) in 1..65_535
      end

    cond do
      (String.downcase(uri.scheme || "") != "https" or is_nil(host) or uri.userinfo) || uri.query ||
        uri.fragment ||
          uri.path not in [nil, ""] ->
        {:error,
         "invalid origin; use an absolute HTTPS origin without credentials, path, query, or fragment"}

      authority_host != host or not valid_port ->
        {:error, "invalid origin; use a valid HTTPS authority and decimal port from 1 to 65535"}

      not valid_host?(host) ->
        {:error, "invalid origin; use a valid DNS host without spaces or placeholder values"}

      String.contains?(host, "example") or String.ends_with?(host, ".invalid") ->
        {:error,
         "invalid origin; replace the example or placeholder host with the production host origin"}

      true ->
        canonical_port =
          if raw_port in [nil, "443"], do: "", else: ":#{String.to_integer(raw_port)}"

        {:ok, "https://#{host}#{canonical_port}"}
    end
  rescue
    _ -> {:error, "invalid origin; use an absolute HTTPS origin with a valid decimal port"}
  end

  defp valid_origin(_), do: {:error, "invalid origin; use an absolute HTTPS origin"}

  defp valid_host?(host) do
    labels = String.split(host, ".")

    length(labels) >= 2 and
      Enum.all?(labels, fn label ->
        Regex.match?(~r/\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/, label)
      end)
  end

  defp valid_entry(value) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp valid_entry(_), do: {:error, "invalid entry_route_id; use a non-empty declared route ID"}

  defp valid_bundle(value, _key) when is_binary(value) do
    if Regex.match?(~r/\A[A-Za-z0-9][A-Za-z0-9-]*(?:\.[A-Za-z0-9][A-Za-z0-9-]*)+\z/, value),
      do: :ok,
      else:
        {:error,
         "invalid bundle identifier; use reverse-DNS components with letters, digits, or hyphens"}
  end

  defp valid_bundle(_, key), do: {:error, "invalid #{key}; use a reverse-DNS bundle identifier"}

  defp valid_identity_collision(app, proof) do
    derived = [app <> ".tests", proof <> ".tests", proof <> ".uitests"]

    if app == proof or app in derived or proof in derived or
         length(Enum.uniq(derived)) != length(derived),
       do:
         {:error,
          "invalid app identities; declared and derived bundle identifiers must be unique"},
       else: :ok
  end

  defp valid_signing(values) when is_list(values) do
    if Keyword.keyword?(values) and
         length(Keyword.keys(values)) == length(Enum.uniq(Keyword.keys(values))) and
         Enum.sort(Keyword.keys(values)) == [:mode, :team_id] do
      mode = Keyword.get(values, :mode)
      team = Keyword.get(values, :team_id)

      if mode in [:automatic, :manual] and is_binary(team) and
           Regex.match?(~r/\A[A-Z0-9]{5,10}\z/, team),
         do: {:ok, %{mode: mode, team_id: team}},
         else:
           {:error, "invalid device_signing; set mode to automatic or manual and a valid team_id"}
    else
      {:error, "invalid device_signing keys; set only mode and team_id"}
    end
  end

  defp valid_signing(_), do: {:error, "invalid device_signing; expected mode and team_id"}
end
