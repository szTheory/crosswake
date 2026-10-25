defmodule Crosswake.Shell.IOSHostOriginMode do
  @moduledoc false
  # Bounded reconcile of the Crosswake-owned local-loopback block in the host-owned
  # CrosswakeShell/Info.plist (182 D-06, D-08, D-23). Pure functions over bytes.
  #
  # Rules:
  #   * The only thing this module ever inserts or strips is the exact block below.
  #   * Under no declared mode a host-owned ATS dict (without the marker) is never touched.
  #   * Under :local_loopback any other ATS shape, forbidden ATS key, or a missing/duplicated
  #     LSRequiresIPhoneOS anchor is a conflict; callers must leave the file unchanged.

  @anchor "    <key>LSRequiresIPhoneOS</key>\n    <true/>"
  @block "\n    <key>NSAppTransportSecurity</key>\n    <dict>\n        <key>NSAllowsLocalNetworking</key>\n        <true/>\n    </dict>\n    <key>CrosswakeOriginMode</key>\n    <string>local_loopback</string>"
  @forbidden_ats_keys ~w(NSAllowsArbitraryLoads NSAllowsArbitraryLoadsInWebContent NSAllowsArbitraryLoadsForMedia NSExceptionDomains)
  @ats_key "NSAppTransportSecurity"
  @marker_key "CrosswakeOriginMode"
  @repair "review and remove or merge the host edit to NSAppTransportSecurity or CrosswakeOriginMode in CrosswakeShell/Info.plist, then rerun mix crosswake.gen.shell ios"
  @banner "Local loopback build for Simulator demonstration. Not physical, adopter, or release evidence."

  @doc "Exact bytes the template splices after the LSRequiresIPhoneOS anchor."
  def block(:local_loopback), do: @block

  def forbidden_ats_keys, do: @forbidden_ats_keys
  def readme_banner, do: @banner

  @doc "Classify the plist: local block, no Crosswake signal, or a conflicting shape."
  def inspect_plist(bytes) when is_binary(bytes) do
    blocks = count(bytes, @block)
    ats = count(bytes, @ats_key)
    markers = count(bytes, @marker_key)

    cond do
      blocks == 1 and ats == 1 and markers == 1 ->
        {:ok, %{mode: :local_loopback, host_ats: false}}

      blocks == 0 and markers == 0 ->
        {:ok, %{mode: nil, host_ats: ats > 0}}

      true ->
        conflict()
    end
  end

  def inspect_plist(_), do: conflict()

  @doc "Desired plist bytes for a declared mode (nil or :local_loopback)."
  def desired(bytes, nil) when is_binary(bytes) do
    case inspect_plist(bytes) do
      {:ok, %{mode: :local_loopback}} ->
        finish(:binary.replace(bytes, @block, ""), nil)

      {:ok, _} ->
        {:ok, bytes}

      error ->
        error
    end
  end

  def desired(bytes, :local_loopback) when is_binary(bytes) do
    with false <- Enum.any?(@forbidden_ats_keys, &String.contains?(bytes, &1)),
         {:ok, inspection} <- inspect_plist(bytes) do
      case inspection do
        %{mode: :local_loopback} ->
          {:ok, bytes}

        %{mode: nil, host_ats: true} ->
          conflict()

        %{mode: nil} ->
          if count(bytes, @anchor) == 1 do
            finish(:binary.replace(bytes, @anchor, @anchor <> @block), :local_loopback)
          else
            conflict()
          end
      end
    else
      true -> conflict()
      error -> error
    end
  end

  def desired(_, _), do: conflict()

  @doc "True when the declared mode disagrees with what the plist read/inspection shows."
  def mismatch?(declared, {:ok, %{mode: mode}}), do: declared != mode
  def mismatch?(:local_loopback, _), do: true
  def mismatch?(nil, {:error, %{cause: "info_plist_conflict"}}), do: true
  def mismatch?(nil, _), do: false

  @doc "Fixed D-12 doctor message for a consistent local-mode host."
  def local_message(origin) when is_binary(origin) do
    "This iOS host is generated in local loopback mode and loads #{origin} over plain HTTP. On an iPhone, 127.0.0.1 means the phone itself, not your Mac. This build is for local Simulator demonstration only and is not production-ready."
  end

  def local_hint,
    do:
      "Before distributing, remove origin_mode from :ios_host, set origin to your HTTPS production origin, and rerun mix crosswake.gen.shell ios."

  @doc "Plain cause for inconsistent generated origin state (D-08, D-12)."
  def mismatch_message,
    do:
      "The generated iOS host files and the :ios_host origin_mode declaration disagree, or the local loopback state cannot be read, so the host cannot be treated as production-ready."

  def mismatch_hint, do: "rerun mix crosswake.gen.shell ios"

  def check_line(origin, :local_loopback) when is_binary(origin) do
    "origin mode: local loopback (#{origin}); Simulator only; not production-ready; before distributing, switch to your HTTPS production origin and regenerate"
  end

  def check_line(_origin, _mode), do: nil

  def conflict_message,
    do: %{cause: "info_plist_conflict", repair: @repair}

  @doc """
  Classifies generated iOS outputs plus the raw `:ios_host` declaration (182 D-08, D-12).

  Returns `:none`, `{:local, canonical_origin}` or `{:mismatch, canonical_origin_or_nil}`.
  Any positive local signal counts; a missing or unreadable Info.plist is never proof of
  production. A host-owned ATS dict without the marker is not a signal. Only the canonical
  `scheme://host[:port]` is ever returned.
  """
  def observe(root, declaration) do
    plist = observe_plist(root)
    activation = observe_activation(root)
    declared = observe_declaration(declaration)

    if signal?(plist, activation, declared) do
      case {plist, activation, declared} do
        {:local_loopback, {"http", origin}, decl}
        when decl == :undeclared or (is_tuple(decl) and elem(decl, 1) == origin) ->
          if loopback_origin?(origin), do: {:local, origin}, else: {:mismatch, origin}

        _ ->
          {:mismatch, mismatch_origin(activation, declared)}
      end
    else
      :none
    end
  end

  defp signal?(plist, activation, declared) do
    plist in [:local_loopback, :conflict] or match?({"http", _}, activation) or
      match?({:local, _}, declared) or declared == :refused
  end

  defp mismatch_origin({_scheme, origin}, _declared), do: origin
  defp mismatch_origin(_activation, {:local, origin}), do: origin
  defp mismatch_origin(_activation, _declared), do: nil

  defp observe_plist(root) when is_binary(root) do
    with {:ok, bytes} <- Crosswake.Shell.ManagedOutputs.read_origin_plist(root) do
      case inspect_plist(bytes) do
        {:ok, %{mode: mode}} -> mode
        _ -> :conflict
      end
    else
      _ -> :unreadable
    end
  end

  defp observe_plist(_), do: :unreadable

  defp observe_activation(root) when is_binary(root) do
    with {:ok, bytes} <- File.read(Path.join(root, "Fixtures/route_activation.json")),
         {:ok, %{"origin" => origin}} when is_binary(origin) <- Jason.decode(bytes),
         {scheme, canonical} when not is_nil(canonical) <- canonical_origin(origin) do
      {scheme, canonical}
    else
      _ -> :none
    end
  end

  defp observe_activation(_), do: :none

  @doc false
  # True only when the activation file decodes to an object whose `origin` is a string that
  # canonicalizes. Used by the physical-iPhone preflight; observe/2 does not call it.
  @spec usable_activation_origin?(term()) :: boolean()
  def usable_activation_origin?(bytes) when is_binary(bytes) do
    with {:ok, %{"origin" => origin}} when is_binary(origin) <- Jason.decode(bytes),
         {_scheme, canonical} when not is_nil(canonical) <- canonical_origin(origin) do
      true
    else
      _ -> false
    end
  end

  def usable_activation_origin?(_), do: false

  defp observe_declaration(nil), do: :undeclared

  defp observe_declaration(raw) do
    case Crosswake.Shell.IOSHostConfig.normalize(raw) do
      {:ok, %{origin_mode: :local_loopback, origin: origin}} ->
        case canonical_origin(origin) do
          {_scheme, canonical} when not is_nil(canonical) -> {:local, canonical}
          _ -> :refused
        end

      {:ok, _} ->
        :production

      {:error, _} ->
        if raw_mode?(raw), do: :refused, else: :undeclared
    end
  rescue
    _ -> :undeclared
  end

  defp raw_mode?(raw) when is_list(raw),
    do: Keyword.keyword?(raw) and Keyword.has_key?(raw, :origin_mode)

  defp raw_mode?(raw) when is_map(raw), do: Map.has_key?(raw, :origin_mode)
  defp raw_mode?(_), do: false

  # Canonical scheme://host[:port] only; never a path, query, credentials, or other value.
  defp canonical_origin(value) do
    case URI.parse(value) do
      %URI{scheme: scheme, host: host, port: port}
      when scheme in ["http", "https"] and is_binary(host) ->
        if Regex.match?(~r/\A[A-Za-z0-9.\-]+\z/, host) do
          host = String.downcase(host)
          default = if scheme == "http", do: 80, else: 443
          suffix = if is_integer(port) and port != default, do: ":#{port}", else: ""
          {scheme, "#{scheme}://#{host}#{suffix}"}
        else
          :error
        end

      _ ->
        :error
    end
  end

  defp loopback_origin?(origin) do
    %URI{host: host} = URI.parse(origin)
    host in ["127.0.0.1", "localhost"]
  end

  defp finish(candidate, mode) do
    expected = if mode == :local_loopback, do: :local_loopback, else: nil

    case inspect_plist(candidate) do
      {:ok, %{mode: ^expected}} -> {:ok, candidate}
      _ -> conflict()
    end
  end

  defp conflict, do: {:error, conflict_message()}

  defp count(bytes, pattern), do: length(:binary.matches(bytes, pattern))
end
